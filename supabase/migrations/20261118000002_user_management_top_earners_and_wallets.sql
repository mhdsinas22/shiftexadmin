-- ============================================================================
-- Migration: 20261118000002_user_management_top_earners_and_wallets.sql
-- Purpose : Dynamic Server-Side Top Earners RPC (Weekly / Monthly / All-Time)
--           for Admin User Management module.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_user_management_top_earners(
  p_range TEXT DEFAULT 'weekly',
  p_limit INTEGER DEFAULT 3
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_range TEXT := lower(trim(COALESCE(p_range, 'weekly')));
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 3), 1), 20);
  v_pts_per_rupee INTEGER := 10;
  v_pts_to_inr_rate NUMERIC(12, 6) := 0.100000;
  v_since TIMESTAMPTZ := NULL;
  v_rows JSONB := '[]'::jsonb;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view top earners.';
  END IF;

  IF v_range = 'weekly' THEN
    v_since := NOW() - INTERVAL '7 days';
  ELSIF v_range = 'monthly' THEN
    v_since := NOW() - INTERVAL '30 days';
  ELSE
    v_since := NULL;
  END IF;

  SELECT
    GREATEST(COALESCE(points_per_rupee, 10), 1),
    COALESCE(points_to_inr_rate, 0.100000)
  INTO v_pts_per_rupee, v_pts_to_inr_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_pts_per_rupee := GREATEST(COALESCE(v_pts_per_rupee, 10), 1);
  v_pts_to_inr_rate := COALESCE(v_pts_to_inr_rate, ROUND((1::numeric / v_pts_per_rupee::numeric), 6));

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT jsonb_build_object(
      'id', p.id,
      'full_name', COALESCE(NULLIF(trim(p.full_name), ''), 'SHIIFTEX Member'),
      'email', COALESCE(p.email, ''),
      'mobile_number', COALESCE(p.mobile_number, ''),
      'approval_status', p.approval_status,
      'approved_by', p.approved_by,
      'approved_at', p.approved_at,
      'rejection_reason', p.rejection_reason,
      'created_at', p.created_at,
      'updated_at', p.updated_at,
      'customer_code', COALESCE(
        w.customer_code,
        'SHFT-' || UPPER(SUBSTR(REPLACE(p.id::text, '-', ''), 1, 4))
      ),
      'membership_tier', COALESCE(w.membership_tier, 'Pebble Black Member'),
      'instant_points', COALESCE(w.available_points, 0),
      'instant_rupees', ROUND((COALESCE(w.available_points, 0)::numeric / v_pts_per_rupee::numeric), 2),
      'future_points', COALESCE(w.locked_points, 0),
      'points_per_rupee', v_pts_per_rupee,
      'earned_points', sub_pts.earned_points,
      'earned_rupees', sub_pts.earned_rupees,
      'earned_tx_count', sub_pts.tx_count
    ) AS row_data
    FROM public.profiles p
    LEFT JOIN public.customer_wallets w ON w.user_id = p.id
    CROSS JOIN LATERAL (
      SELECT
        CASE
          WHEN v_since IS NULL THEN
            GREATEST(
              COALESCE(w.lifetime_earned_points, 0),
              COALESCE(SUM(pt.points_delta) FILTER (WHERE pt.points_delta > 0 AND pt.transaction_type <> 'streak_unlock'), 0)::INTEGER,
              COALESCE(w.available_points, 0) + COALESCE(w.locked_points, 0)
            )
          ELSE
            COALESCE(
              SUM(pt.points_delta) FILTER (
                WHERE pt.points_delta > 0
                  AND pt.transaction_type <> 'streak_unlock'
                  AND pt.created_at >= v_since
              ),
              0
            )::INTEGER
        END AS earned_points,
        CASE
          WHEN v_since IS NULL THEN
            COALESCE(
              ROUND(
                SUM(
                  COALESCE(
                    pt.cash_value,
                    ROUND((pt.points_delta * COALESCE(pt.points_to_inr_rate, v_pts_to_inr_rate))::numeric, 2)
                  )
                ) FILTER (WHERE pt.points_delta > 0 AND pt.transaction_type <> 'streak_unlock')::numeric,
                2
              ),
              ROUND(
                (
                  GREATEST(
                    COALESCE(w.lifetime_earned_points, 0),
                    COALESCE(w.available_points, 0) + COALESCE(w.locked_points, 0)
                  )::numeric / v_pts_per_rupee::numeric
                ),
                2
              )
            )
          ELSE
            COALESCE(
              ROUND(
                SUM(
                  COALESCE(
                    pt.cash_value,
                    ROUND((pt.points_delta * COALESCE(pt.points_to_inr_rate, v_pts_to_inr_rate))::numeric, 2)
                  )
                ) FILTER (
                  WHERE pt.points_delta > 0
                    AND pt.transaction_type <> 'streak_unlock'
                    AND pt.created_at >= v_since
                )::numeric,
                2
              ),
              0.00
            )
        END AS earned_rupees,
        COUNT(*) FILTER (
          WHERE pt.points_delta > 0
            AND pt.transaction_type <> 'streak_unlock'
            AND (v_since IS NULL OR pt.created_at >= v_since)
        )::INTEGER AS tx_count
      FROM public.point_transactions pt
      WHERE pt.user_id = p.id
    ) sub_pts
    WHERE p.approval_status = 'approved'
      AND sub_pts.earned_points > 0
    ORDER BY
      sub_pts.earned_points DESC,
      COALESCE(w.available_points, 0) DESC,
      p.created_at ASC
    LIMIT v_limit
  ) ranked;

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.get_user_management_top_earners(TEXT, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_user_management_top_earners(TEXT, INTEGER) TO authenticated;
