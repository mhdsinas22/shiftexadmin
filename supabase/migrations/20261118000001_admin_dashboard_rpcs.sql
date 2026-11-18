-- ============================================================================
-- Migration: 20261118000001_admin_dashboard_rpcs.sql
-- Purpose : Complete Production Admin Dashboard RPCs, Customer Approval RPCs,
--           and Claim Reservation Redemption Sync.
-- ============================================================================

-- 1. Helper: Release all expired pending claims across all customers
CREATE OR REPLACE FUNCTION private.release_all_expired_claims()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_user RECORD;
  v_total INTEGER := 0;
BEGIN
  FOR v_user IN
    SELECT DISTINCT user_id
    FROM public.reward_claims
    WHERE status = 'pending'
      AND expires_at <= NOW()
  LOOP
    v_total := v_total + private.release_expired_claim_reservations(v_user.user_id);
  END LOOP;

  RETURN v_total;
END;
$$;

REVOKE ALL ON FUNCTION private.release_all_expired_claims() FROM PUBLIC, anon, authenticated;

-- 2. Admin Customer Approval & Rejection RPCs (reused by User Management & Dashboard)
CREATE OR REPLACE FUNCTION public.approve_customer(customer_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_profile public.profiles;
  v_wallet public.customer_wallets;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can approve customers.';
  END IF;

  IF customer_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_CUSTOMER: Customer ID is required.';
  END IF;

  UPDATE public.profiles
  SET
    approval_status = 'approved',
    approved_by = v_admin_id,
    approved_at = NOW(),
    rejection_reason = NULL,
    updated_at = NOW()
  WHERE id = customer_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  -- Provision and sync customer wallet immediately upon approval
  v_wallet := private.admin_sync_customer_wallet(customer_id);

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', v_profile.id,
    'approval_status', v_profile.approval_status,
    'approved_by', v_profile.approved_by,
    'approved_at', v_profile.approved_at,
    'membership_id', v_wallet.customer_code
  );
END;
$$;

REVOKE ALL ON FUNCTION public.approve_customer(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.approve_customer(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.reject_customer(customer_id UUID, reason TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_reason TEXT;
  v_profile public.profiles;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can reject customers.';
  END IF;

  v_reason := trim(COALESCE(reason, ''));
  IF v_reason = '' THEN
    RAISE EXCEPTION 'INVALID_REASON: Rejection reason cannot be empty.';
  END IF;

  UPDATE public.profiles
  SET
    approval_status = 'rejected',
    approved_by = v_admin_id,
    approved_at = NOW(),
    rejection_reason = v_reason,
    updated_at = NOW()
  WHERE id = customer_id
  RETURNING * INTO v_profile;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', v_profile.id,
    'approval_status', v_profile.approval_status,
    'rejection_reason', v_profile.rejection_reason
  );
END;
$$;

REVOKE ALL ON FUNCTION public.reject_customer(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_customer(UUID, TEXT) TO authenticated;

-- 3. Enhance verify_customer_qr_for_pos & redeem_customer_claim_qr to support
--    Pending Claim reservations and Quick Verify seamlessly
CREATE OR REPLACE FUNCTION public.verify_customer_qr_for_pos(
  p_qr_input TEXT,
  p_mode TEXT DEFAULT 'give_reward'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_clean TEXT;
  v_mode TEXT;
  v_token public.customer_qr_tokens;
  v_claim public.reward_claims;
  v_profile public.profiles;
  v_wallet public.customer_wallets;
  v_pts_per_rupee INTEGER;
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
  v_effective_available INTEGER;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can verify POS QR codes.';
  END IF;

  v_clean := trim(COALESCE(p_qr_input, ''));
  IF v_clean = '' THEN
    RAISE EXCEPTION 'INVALID_QR: QR payload or token code is required.';
  END IF;

  IF v_clean ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RAISE EXCEPTION 'INVALID_QR: Raw customer IDs are not valid QR codes.';
  END IF;

  v_mode := lower(trim(COALESCE(p_mode, 'give_reward')));
  IF v_mode NOT IN ('give_reward', 'verify_claim') THEN
    v_mode := 'give_reward';
  END IF;

  SELECT * INTO v_token
  FROM public.customer_qr_tokens
  WHERE qr_payload = v_clean
     OR upper(token_code) = upper(v_clean)
     OR id IN (
       SELECT qr_token_id
       FROM public.reward_claims
       WHERE upper(claim_reference) = upper(v_clean)
         AND qr_token_id IS NOT NULL
     )
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_QR: QR code not recognized or does not exist.';
  END IF;

  IF v_mode = 'give_reward' AND v_token.token_purpose <> 'accrual' THEN
    RAISE EXCEPTION 'WRONG_QR_MODE: This is a Claim QR. Switch to Verify Claim mode to redeem points.';
  END IF;

  IF v_mode = 'verify_claim' AND (v_token.token_purpose <> 'claim' OR NOT v_token.allow_deduction) THEN
    RAISE EXCEPTION 'WRONG_QR_MODE: Personal Member QR cannot be used for deduction. Ask customer for a Claim QR.';
  END IF;

  IF v_token.status = 'revoked' OR v_token.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'QR_REVOKED: This QR code was revoked by the customer.';
  END IF;

  IF v_token.status = 'used' OR v_token.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'QR_ALREADY_USED: This QR code has already been redeemed or processed.';
  END IF;

  IF v_token.status = 'expired' OR v_token.expires_at <= NOW() THEN
    PERFORM private.release_expired_claim_reservations(v_token.user_id);
    UPDATE public.customer_qr_tokens
    SET status = 'expired'
    WHERE id = v_token.id AND status = 'active';
    RAISE EXCEPTION 'QR_EXPIRED: This QR code has expired. Ask customer to refresh their QR.';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = v_token.user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  IF v_profile.approval_status <> 'approved' THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_APPROVED: Customer account is not approved (status: %).', v_profile.approval_status;
  END IF;

  v_wallet := private.admin_sync_customer_wallet(v_profile.id);

  SELECT
    COALESCE(points_per_rupee, 10),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_rupee, v_rate, v_currency
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  -- Check if this token has an active pending reward_claim reservation
  SELECT * INTO v_claim
  FROM public.reward_claims
  WHERE qr_token_id = v_token.id
    AND status = 'pending'
    AND expires_at > NOW()
  ORDER BY created_at DESC
  LIMIT 1;

  v_effective_available := v_wallet.available_points;
  IF v_claim.id IS NOT NULL THEN
    -- Include points reserved specifically for this pending claim
    v_effective_available := v_wallet.available_points + COALESCE(v_claim.points, 0);
    IF COALESCE(v_claim.points_to_inr_rate, 0) > 0 THEN
      v_rate := v_claim.points_to_inr_rate;
      v_pts_per_rupee := GREATEST(1, ROUND((1::numeric / v_rate::numeric))::integer);
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'customer_id', v_profile.id,
    'full_name', v_profile.full_name,
    'email', v_profile.email,
    'mobile_number', v_profile.mobile_number,
    'approval_status', v_profile.approval_status,
    'membership_id', v_wallet.customer_code,
    'membership_tier', v_wallet.membership_tier,
    'available_points', v_effective_available,
    'locked_points', v_wallet.locked_points,
    'lifetime_earned_points', v_wallet.lifetime_earned_points,
    'lifetime_redeemed_points', v_wallet.lifetime_redeemed_points,
    'points_per_rupee', COALESCE(v_pts_per_rupee, 10),
    'points_to_inr_rate', COALESCE(v_rate, 0.100000),
    'currency_code', COALESCE(v_currency, 'INR'),
    'token_id', v_token.id,
    'token_code', v_token.token_code,
    'qr_payload', v_token.qr_payload,
    'token_purpose', v_token.token_purpose,
    'allow_deduction', v_token.allow_deduction,
    'token_expires_at', v_token.expires_at,
    'claim_points', v_claim.points,
    'claim_discount_amount', v_claim.discount_amount,
    'claim_reference', v_claim.claim_reference,
    'verification_method', 'qr'
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.redeem_customer_claim_qr(
  p_token_id UUID,
  p_redeem_points INTEGER,
  p_bill_number TEXT DEFAULT '',
  p_branch_name TEXT DEFAULT 'Counter #1 POS',
  p_idempotency_key TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_admin_email TEXT;
  v_points INTEGER := COALESCE(p_redeem_points, 0);
  v_bill TEXT;
  v_branch TEXT;
  v_idem TEXT;
  v_token public.customer_qr_tokens;
  v_claim public.reward_claims;
  v_profile public.profiles;
  v_wallet public.customer_wallets;
  v_pts_per_rupee INTEGER;
  v_rate NUMERIC(12, 6);
  v_currency TEXT := 'INR';
  v_rate_version_id UUID;
  v_cash_value NUMERIC(12, 2);
  v_tx_id UUID;
  v_reserved_for_claim INTEGER := 0;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can verify and redeem claim QRs.';
  END IF;

  IF p_token_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_QR: Claim QR token ID is required.';
  END IF;

  IF v_points <= 0 OR v_points > 100000 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT: Redeem points must be between 1 and 100,000.';
  END IF;

  v_bill := trim(COALESCE(p_bill_number, ''));
  IF length(v_bill) < 2 OR length(v_bill) > 64 THEN
    RAISE EXCEPTION 'INVALID_BILL: Valid bill reference number is required.';
  END IF;

  v_branch := COALESCE(NULLIF(trim(COALESCE(p_branch_name, '')), ''), 'Counter #1 POS');
  v_idem := NULLIF(trim(COALESCE(p_idempotency_key, '')), '');

  IF v_idem IS NOT NULL AND EXISTS (
    SELECT 1 FROM public.point_transactions WHERE idempotency_key = v_idem || ':claim'
  ) THEN
    RAISE EXCEPTION 'DUPLICATE_TRANSACTION: This claim redemption has already been processed.';
  END IF;

  SELECT * INTO v_token
  FROM public.customer_qr_tokens
  WHERE id = p_token_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_QR: Claim QR token not found.';
  END IF;

  IF v_token.token_purpose <> 'claim' OR NOT v_token.allow_deduction THEN
    RAISE EXCEPTION 'WRONG_QR_MODE: Selected QR does not authorize point deduction.';
  END IF;

  IF v_token.status = 'used' OR v_token.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'QR_ALREADY_USED: This Claim QR has already been redeemed.';
  END IF;

  IF v_token.status = 'revoked' OR v_token.revoked_at IS NOT NULL THEN
    RAISE EXCEPTION 'QR_REVOKED: This Claim QR has been revoked.';
  END IF;

  IF v_token.status = 'expired' OR v_token.expires_at <= NOW() THEN
    PERFORM private.release_expired_claim_reservations(v_token.user_id);
    UPDATE public.customer_qr_tokens SET status = 'expired' WHERE id = v_token.id AND status = 'active';
    RAISE EXCEPTION 'QR_EXPIRED: Claim QR expired. Ask customer to generate a new Claim QR.';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = v_token.user_id;

  IF NOT FOUND OR v_profile.approval_status <> 'approved' THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_APPROVED: Customer account is not approved.';
  END IF;

  PERFORM private.admin_sync_customer_wallet(v_profile.id);

  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = v_profile.id
  FOR UPDATE;

  SELECT * INTO v_claim
  FROM public.reward_claims
  WHERE qr_token_id = v_token.id
  FOR UPDATE
  LIMIT 1;

  IF FOUND AND v_claim.status = 'pending' THEN
    v_reserved_for_claim := COALESCE(v_claim.points, 0);
  END IF;

  IF (v_wallet.available_points + v_reserved_for_claim) < v_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Customer has % instant points available, requested %.',
      (v_wallet.available_points + v_reserved_for_claim), v_points;
  END IF;

  IF v_claim.id IS NOT NULL AND COALESCE(v_claim.points_to_inr_rate, 0) > 0 THEN
    v_rate := v_claim.points_to_inr_rate;
    v_pts_per_rupee := GREATEST(1, ROUND((1::numeric / v_rate::numeric))::integer);
    IF v_claim.points = v_points AND COALESCE(v_claim.discount_amount, 0) > 0 THEN
      v_cash_value := ROUND(v_claim.discount_amount::numeric, 2);
    END IF;
  ELSE
    SELECT
      COALESCE(points_per_rupee, 10),
      COALESCE(points_to_inr_rate, 0.100000),
      COALESCE(currency_code, 'INR')
    INTO v_pts_per_rupee, v_rate, v_currency
    FROM public.reward_settings
    WHERE singleton_key = 'global'
    LIMIT 1;
  END IF;

  v_pts_per_rupee := COALESCE(v_pts_per_rupee, 10);
  v_rate := COALESCE(v_rate, ROUND((1::numeric / v_pts_per_rupee::numeric), 6));
  v_cash_value := COALESCE(v_cash_value, ROUND((v_points::numeric / v_pts_per_rupee::numeric), 2));

  SELECT id INTO v_rate_version_id
  FROM public.points_to_cash_rate_history
  ORDER BY created_at DESC, version_number DESC
  LIMIT 1;

  v_admin_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');

  UPDATE public.customer_qr_tokens
  SET
    status = 'used',
    used_at = NOW(),
    allow_deduction = false
  WHERE id = v_token.id;

  UPDATE public.customer_wallets
  SET
    available_points = GREATEST(0, available_points + v_reserved_for_claim - v_points),
    reserved_points = GREATEST(0, reserved_points - v_reserved_for_claim),
    lifetime_redeemed_points = lifetime_redeemed_points + v_points,
    updated_at = NOW()
  WHERE user_id = v_profile.id
  RETURNING * INTO v_wallet;

  INSERT INTO public.point_transactions (
    user_id,
    transaction_type,
    title,
    description,
    points_delta,
    is_locked_allocation,
    reference_id,
    idempotency_key,
    points_per_rupee,
    points_per_currency_unit,
    points_to_inr_rate,
    cash_value,
    currency_code,
    rate_version_id,
    metadata
  ) VALUES (
    v_profile.id,
    'discount_redemption',
    'Claim Verified & Redeemed',
    'Redeemed ' || v_points || ' pts • Bill #' || v_bill,
    -v_points,
    false,
    v_token.id,
    CASE WHEN v_idem IS NOT NULL THEN v_idem || ':claim' ELSE NULL END,
    v_pts_per_rupee,
    v_pts_per_rupee::numeric(12, 4),
    v_rate,
    v_cash_value,
    v_currency,
    v_rate_version_id,
    jsonb_build_object(
      'admin_id', v_admin_id,
      'admin_email', v_admin_email,
      'bill_number', v_bill,
      'branch_name', v_branch,
      'qr_token_id', v_token.id,
      'token_code', v_token.token_code,
      'points_per_rupee', v_pts_per_rupee,
      'rate', v_rate,
      'inr_equivalent', v_cash_value,
      'currency_code', v_currency,
      'rate_version_id', v_rate_version_id,
      'source', 'pos_scanner_claim'
    )
  )
  RETURNING id INTO v_tx_id;

  IF v_claim.id IS NOT NULL AND v_claim.status = 'pending' THEN
    UPDATE public.reward_claims
    SET
      status = 'redeemed',
      redeemed_at = NOW(),
      redeemed_by = v_admin_id,
      redeemed_by_email = v_admin_email,
      bill_number = v_bill,
      branch_name = v_branch,
      transaction_id = v_tx_id,
      updated_at = NOW()
    WHERE id = v_claim.id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', v_profile.id,
    'full_name', v_profile.full_name,
    'membership_id', v_wallet.customer_code,
    'token_code', v_token.token_code,
    'redeemed_points', v_points,
    'inr_value', v_cash_value,
    'points_per_rupee', v_pts_per_rupee,
    'points_to_inr_rate', v_rate,
    'currency_code', v_currency,
    'bill_number', v_bill,
    'branch_name', v_branch,
    'available_points', v_wallet.available_points,
    'locked_points', v_wallet.locked_points,
    'lifetime_redeemed_points', v_wallet.lifetime_redeemed_points,
    'transaction_id', v_tx_id,
    'redeemed_at', NOW()
  );
END;
$$;

-- 4. Master Ledger RPC with Server-Side Category Filtering, Search & Pagination
CREATE OR REPLACE FUNCTION public.get_admin_master_ledger(
  p_category TEXT DEFAULT 'all',
  p_search TEXT DEFAULT '',
  p_limit INTEGER DEFAULT 15,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_category TEXT := lower(trim(COALESCE(p_category, 'all')));
  v_search TEXT := trim(COALESCE(p_search, ''));
  v_limit INTEGER := LEAST(GREATEST(COALESCE(p_limit, 15), 1), 100);
  v_offset INTEGER := GREATEST(COALESCE(p_offset, 0), 0);
  v_rows JSONB;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can access the Master Ledger.';
  END IF;

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_rows
  FROM (
    SELECT jsonb_build_object(
      'id', t.id,
      'short_tx_code', 'TXN-' || UPPER(SUBSTR(REPLACE(t.id::text, '-', ''), 1, 5)),
      'user_id', t.user_id,
      'customer_name', COALESCE(NULLIF(trim(p.full_name), ''), 'SHIIFTEX Member'),
      'membership_id', COALESCE(
        w.customer_code,
        'SHFT-' || UPPER(SUBSTR(REPLACE(t.user_id::text, '-', ''), 1, 4))
      ),
      'transaction_type', t.transaction_type,
      'category', CASE
        WHEN t.transaction_type = 'merchant_reward' THEN 'purchases'
        WHEN t.transaction_type = 'discount_redemption' THEN 'redemptions'
        WHEN t.transaction_type IN ('daily_streak', 'streak_unlock') THEN 'streak'
        ELSE 'other'
      END,
      'title', CASE
        WHEN t.transaction_type = 'merchant_reward' THEN
          COALESCE(
            NULLIF(trim(t.metadata->>'branch_name'), ''),
            NULLIF(trim(t.title), ''),
            'POS Reward Allocation'
          )
        WHEN t.transaction_type = 'discount_redemption' THEN
          COALESCE(
            NULLIF(trim(t.metadata->>'branch_name'), ''),
            NULLIF(trim(t.title), ''),
            'POS Claim Redemption'
          )
        WHEN t.transaction_type = 'daily_streak' THEN
          COALESCE(NULLIF(trim(t.title), ''), 'Daily Shift Streak Bonus')
        WHEN t.transaction_type = 'streak_unlock' THEN
          COALESCE(NULLIF(trim(t.title), ''), 'Locked Points Auto-Released')
        ELSE
          COALESCE(NULLIF(trim(t.title), ''), 'Ledger Entry')
      END,
      'description', COALESCE(t.description, ''),
      'bill_number', COALESCE(t.metadata->>'bill_number', ''),
      'branch_name', COALESCE(t.metadata->>'branch_name', ''),
      'points_delta', t.points_delta,
      'is_locked_allocation', COALESCE(t.is_locked_allocation, false),
      'points_per_rupee', COALESCE(t.points_per_rupee, 10),
      'points_to_inr_rate', COALESCE(t.points_to_inr_rate, 0.100000),
      'inr_value', COALESCE(
        t.cash_value,
        ROUND((ABS(t.points_delta) * COALESCE(t.points_to_inr_rate, 0.100000))::numeric, 2)
      ),
      'currency_code', COALESCE(t.currency_code, 'INR'),
      'is_auto_bonus', (t.transaction_type IN ('daily_streak', 'streak_unlock')),
      'created_at', t.created_at
    ) AS row_data
    FROM public.point_transactions t
    LEFT JOIN public.profiles p ON p.id = t.user_id
    LEFT JOIN public.customer_wallets w ON w.user_id = t.user_id
    WHERE (
      v_category = 'all'
      OR (v_category = 'purchases' AND t.transaction_type = 'merchant_reward')
      OR (v_category = 'redemptions' AND t.transaction_type = 'discount_redemption')
      OR (v_category = 'streak' AND t.transaction_type IN ('daily_streak', 'streak_unlock'))
    )
    AND (
      v_search = ''
      OR p.full_name ILIKE '%' || v_search || '%'
      OR w.customer_code ILIKE '%' || v_search || '%'
      OR t.title ILIKE '%' || v_search || '%'
      OR t.description ILIKE '%' || v_search || '%'
      OR COALESCE(t.metadata->>'bill_number', '') ILIKE '%' || v_search || '%'
      OR COALESCE(t.metadata->>'branch_name', '') ILIKE '%' || v_search || '%'
      OR ('TXN-' || UPPER(SUBSTR(REPLACE(t.id::text, '-', ''), 1, 5))) ILIKE '%' || v_search || '%'
    )
    ORDER BY t.created_at DESC
    LIMIT v_limit
    OFFSET v_offset
  ) sub;

  RETURN v_rows;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_master_ledger(TEXT, TEXT, INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_admin_master_ledger(TEXT, TEXT, INTEGER, INTEGER) TO authenticated;

-- 5. Complete Production Admin Dashboard Overview RPC
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_overview(
  p_ledger_category TEXT DEFAULT 'all'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_admin_name TEXT;
  v_admin_email TEXT;
  v_pts_per_rupee INTEGER := 10;
  v_pts_to_inr_rate NUMERIC(12, 6) := 0.100000;
  v_currency_code TEXT := 'INR';
  v_total_claims_processed INTEGER := 0;
  v_claims_current_30d INTEGER := 0;
  v_claims_prev_30d INTEGER := 0;
  v_claims_growth_pct NUMERIC(8, 1) := NULL;
  v_net_value_inr NUMERIC(14, 2) := 0.00;
  v_total_points_given BIGINT := 0;
  v_liquid_points BIGINT := 0;
  v_liquid_pool_inr NUMERIC(14, 2) := 0.00;
  v_locked_points BIGINT := 0;
  v_locked_pool_inr NUMERIC(14, 2) := 0.00;
  v_pending_verifications_count INTEGER := 0;
  v_pending_verifications JSONB := '[]'::jsonb;
  v_pending_claims_count INTEGER := 0;
  v_pending_claims JSONB := '[]'::jsonb;
  v_master_ledger JSONB := '[]'::jsonb;
  v_top_users JSONB := '[]'::jsonb;
  v_system_activity JSONB := '[]'::jsonb;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view the Admin Dashboard.';
  END IF;

  -- Step 1: Release any expired pending claim reservations so liquid balances & pending claims are accurate
  PERFORM private.release_all_expired_claims();

  -- Step 2: Resolve Admin Profile Identity
  SELECT
    COALESCE(
      NULLIF(trim(p.full_name), ''),
      NULLIF(trim(u.raw_user_meta_data->>'full_name'), ''),
      NULLIF(split_part(COALESCE(p.email, u.email, ''), '@', 1), ''),
      'Admin'
    ),
    COALESCE(p.email, u.email, '')
  INTO v_admin_name, v_admin_email
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  WHERE u.id = v_admin_id;

  v_admin_name := COALESCE(v_admin_name, 'Admin');
  v_admin_email := COALESCE(v_admin_email, '');

  -- Step 3: Active Conversion Rate
  SELECT
    COALESCE(points_per_rupee, 10),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_rupee, v_pts_to_inr_rate, v_currency_code
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_pts_per_rupee := GREATEST(COALESCE(v_pts_per_rupee, 10), 1);
  v_pts_to_inr_rate := COALESCE(v_pts_to_inr_rate, ROUND((1::numeric / v_pts_per_rupee::numeric), 6));

  -- Step 4: Business Statistics (Total Claims Processed, Net Value, Liquid Points, Locked Points)
  WITH all_redeemed_claims AS (
    SELECT
      id::text AS claim_key,
      COALESCE(redeemed_at, updated_at, created_at) AS processed_at
    FROM public.reward_claims
    WHERE status = 'redeemed'
    UNION ALL
    SELECT
      t.id::text AS claim_key,
      t.created_at AS processed_at
    FROM public.point_transactions t
    WHERE t.transaction_type = 'discount_redemption'
      AND NOT EXISTS (
        SELECT 1
        FROM public.reward_claims rc
        WHERE rc.transaction_id = t.id
          AND rc.status = 'redeemed'
      )
  )
  SELECT
    COUNT(*)::INTEGER,
    COUNT(*) FILTER (WHERE processed_at >= NOW() - INTERVAL '30 days')::INTEGER,
    COUNT(*) FILTER (
      WHERE processed_at >= NOW() - INTERVAL '60 days'
        AND processed_at < NOW() - INTERVAL '30 days'
    )::INTEGER
  INTO
    v_total_claims_processed,
    v_claims_current_30d,
    v_claims_prev_30d
  FROM all_redeemed_claims;

  IF v_claims_prev_30d > 0 THEN
    v_claims_growth_pct := ROUND(
      (((v_claims_current_30d - v_claims_prev_30d)::numeric / v_claims_prev_30d::numeric) * 100.0),
      1
    );
  ELSE
    v_claims_growth_pct := NULL;
  END IF;

  -- Net Value & Total Points Given (preserving historical immutable cash_value snapshots)
  SELECT
    COALESCE(
      ROUND(
        SUM(
          COALESCE(
            t.cash_value,
            ROUND((t.points_delta * COALESCE(t.points_to_inr_rate, v_pts_to_inr_rate))::numeric, 2)
          )
        )::numeric,
        2
      ),
      0.00
    ),
    COALESCE(SUM(t.points_delta), 0)::BIGINT
  INTO v_net_value_inr, v_total_points_given
  FROM public.point_transactions t
  WHERE t.points_delta > 0
    AND t.transaction_type <> 'streak_unlock';

  -- Liquid Points & Locked Points across approved customer wallets
  SELECT
    COALESCE(SUM(GREATEST(w.available_points, 0)), 0)::BIGINT,
    COALESCE(SUM(GREATEST(w.locked_points, 0)), 0)::BIGINT
  INTO v_liquid_points, v_locked_points
  FROM public.customer_wallets w
  JOIN public.profiles p ON p.id = w.user_id
  WHERE p.approval_status = 'approved';

  v_liquid_pool_inr := ROUND((v_liquid_points::numeric / v_pts_per_rupee::numeric), 2);
  v_locked_pool_inr := ROUND((v_locked_points::numeric / v_pts_per_rupee::numeric), 2);

  -- Step 5: Pending User Verifications
  SELECT COUNT(*)::INTEGER
  INTO v_pending_verifications_count
  FROM public.profiles
  WHERE approval_status = 'pending';

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_pending_verifications
  FROM (
    SELECT jsonb_build_object(
      'id', p.id,
      'full_name', COALESCE(NULLIF(trim(p.full_name), ''), 'New Customer'),
      'email', COALESCE(p.email, ''),
      'mobile_number', COALESCE(NULLIF(trim(p.mobile_number), ''), 'No mobile'),
      'approval_status', p.approval_status,
      'customer_code', COALESCE(
        w.customer_code,
        'SHFT-' || UPPER(SUBSTR(REPLACE(p.id::text, '-', ''), 1, 4))
      ),
      'onboarding_code', 'Code: MERCH-IND-' || UPPER(SUBSTR(REPLACE(p.id::text, '-', ''), 5, 2)),
      'created_at', p.created_at
    ) AS row_data
    FROM public.profiles p
    LEFT JOIN public.customer_wallets w ON w.user_id = p.id
    WHERE p.approval_status = 'pending'
    ORDER BY p.created_at DESC
    LIMIT 5
  ) pv;

  -- Step 6: Active Pending Claims (only status = 'pending' and not expired)
  SELECT COUNT(*)::INTEGER
  INTO v_pending_claims_count
  FROM public.reward_claims c
  WHERE c.status = 'pending'
    AND c.expires_at > NOW();

  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_pending_claims
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'qr_token_id', c.qr_token_id,
      'claim_reference', c.claim_reference,
      'qr_payload', COALESCE(t.qr_payload, c.claim_reference),
      'user_id', c.user_id,
      'customer_name', COALESCE(NULLIF(trim(p.full_name), ''), 'SHIIFTEX Member'),
      'membership_id', COALESCE(
        w.customer_code,
        'SHFT-' || UPPER(SUBSTR(REPLACE(c.user_id::text, '-', ''), 1, 4))
      ),
      'merchant_counter', COALESCE(NULLIF(trim(c.branch_name), ''), 'SHIIFTEX POS Counter'),
      'status_subtitle', 'Point deduction verified',
      'points', c.points,
      'points_to_inr_rate', c.points_to_inr_rate,
      'discount_amount', c.discount_amount,
      'status', c.status,
      'expires_at', c.expires_at,
      'created_at', c.created_at
    ) AS row_data
    FROM public.reward_claims c
    JOIN public.profiles p ON p.id = c.user_id
    LEFT JOIN public.customer_wallets w ON w.user_id = c.user_id
    LEFT JOIN public.customer_qr_tokens t ON t.id = c.qr_token_id
    WHERE c.status = 'pending'
      AND c.expires_at > NOW()
    ORDER BY c.expires_at ASC
    LIMIT 10
  ) pc;

  -- Step 7: Master Ledger Preview (top 5 for selected category)
  v_master_ledger := public.get_admin_master_ledger(p_ledger_category, '', 5, 0);

  -- Step 8: Top Performing Users (Top 3 ranked by total earned points)
  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_top_users
  FROM (
    SELECT jsonb_build_object(
      'rank', ROW_NUMBER() OVER (
        ORDER BY
          GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) DESC,
          COALESCE(tx.pos_scans, 0) DESC,
          p.created_at ASC
      ),
      'customer_id', p.id,
      'full_name', COALESCE(NULLIF(trim(p.full_name), ''), 'SHIIFTEX Member'),
      'membership_id', COALESCE(
        w.customer_code,
        'SHFT-' || UPPER(SUBSTR(REPLACE(p.id::text, '-', ''), 1, 4))
      ),
      'tier_badge', CASE
        WHEN GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) >= 3000 THEN 'Elite Tier'
        WHEN GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) >= 1000 THEN 'Gold Tier'
        WHEN GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) >= 200 THEN 'Elite Tier'
        ELSE 'Silver Tier'
      END,
      'hub_name', COALESCE(NULLIF(trim(tx.last_branch), ''), 'Central Hub'),
      'total_points_earned', GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)),
      'pos_scan_count', COALESCE(tx.pos_scans, 0)
    ) AS row_data
    FROM public.profiles p
    LEFT JOIN public.customer_wallets w ON w.user_id = p.id
    LEFT JOIN LATERAL (
      SELECT
        COALESCE(SUM(pt.points_delta) FILTER (WHERE pt.points_delta > 0 AND pt.transaction_type <> 'streak_unlock'), 0)::INTEGER AS earned_points,
        COUNT(*) FILTER (WHERE pt.transaction_type IN ('merchant_reward', 'discount_redemption'))::INTEGER AS pos_scans,
        (
          SELECT pt2.metadata->>'branch_name'
          FROM public.point_transactions pt2
          WHERE pt2.user_id = p.id
            AND COALESCE(pt2.metadata->>'branch_name', '') <> ''
          ORDER BY pt2.created_at DESC
          LIMIT 1
        ) AS last_branch
      FROM public.point_transactions pt
      WHERE pt.user_id = p.id
    ) tx ON TRUE
    WHERE p.approval_status = 'approved'
      AND (
        GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) > 0
        OR NOT EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = p.id)
      )
    ORDER BY
      GREATEST(COALESCE(w.lifetime_earned_points, 0), COALESCE(tx.earned_points, 0)) DESC,
      COALESCE(tx.pos_scans, 0) DESC,
      p.created_at ASC
    LIMIT 3
  ) tu;

  -- Step 9: Real System Activity Log (aggregated across audit logs, rate history, POS transactions & KYC approvals)
  SELECT COALESCE(jsonb_agg(row_data), '[]'::jsonb)
  INTO v_system_activity
  FROM (
    SELECT jsonb_build_object(
      'id', evt.id,
      'activity_type', evt.activity_type,
      'title', evt.title,
      'subtitle', evt.subtitle,
      'occurred_at', evt.occurred_at
    ) AS row_data
    FROM (
      -- 1) Points-to-cash conversion rate updates
      SELECT
        'rate_' || r.id::text AS id,
        'rate_update' AS activity_type,
        'Ledger Rate Updated to ' || r.new_points_per_rupee || ' PTS = ₹1.00' AS title,
        COALESCE(NULLIF(r.changed_by_email, ''), 'Super Admin') || ' • 2FA Verified' AS subtitle,
        r.created_at AS occurred_at
      FROM public.points_to_cash_rate_history r

      UNION ALL

      -- 2) Daily Streak & Rule Engine audit logs
      SELECT
        'audit_' || a.id::text AS id,
        'rule_update' AS activity_type,
        CASE
          WHEN a.setting_key = 'points_to_cash_rate' THEN
            'Central Points-to-Cash Rule Synchronized'
          WHEN a.new_enabled IS FALSE THEN
            'Daily Login Streak Paused'
          ELSE
            'Daily Streak Rule Saved (+' || COALESCE(a.new_points, 15) || ' pts/day)'
        END AS title,
        COALESCE(NULLIF(a.changed_by_email, ''), 'Super Admin') || ' • Rules Engine' AS subtitle,
        a.created_at AS occurred_at
      FROM public.reward_settings_audit_logs a
      WHERE COALESCE(a.setting_key, '') <> 'points_to_cash_rate'

      UNION ALL

      -- 3) POS Allocations, Claim Redemptions & Batch Unlocks
      SELECT
        'tx_' || t.id::text AS id,
        CASE
          WHEN t.transaction_type = 'streak_unlock' THEN 'batch_unlock'
          WHEN t.transaction_type = 'discount_redemption' THEN 'claim_redeemed'
          ELSE 'terminal_pos'
        END AS activity_type,
        CASE
          WHEN t.transaction_type = 'streak_unlock' THEN
            'Batch settlement auto-released ' || ABS(t.points_delta) || ' pts'
          WHEN t.transaction_type = 'discount_redemption' THEN
            'Claim Verified & Redeemed (' || ABS(t.points_delta) || ' pts)'
          ELSE
            'Terminal POS Reward Allocated (+' || t.points_delta || ' pts)'
        END AS title,
        CASE
          WHEN t.transaction_type = 'streak_unlock' THEN
            'Routine Vault Scheduled Sweep'
          ELSE
            COALESCE(NULLIF(t.metadata->>'branch_name', ''), 'Counter #1 POS') ||
            CASE
              WHEN COALESCE(t.metadata->>'bill_number', '') <> '' THEN ' • Bill #' || (t.metadata->>'bill_number')
              ELSE ' • Encryption OK'
            END
        END AS subtitle,
        t.created_at AS occurred_at
      FROM public.point_transactions t
      WHERE t.transaction_type IN ('merchant_reward', 'discount_redemption', 'streak_unlock')

      UNION ALL

      -- 4) Customer KYC Approvals / Restrictions
      SELECT
        'kyc_' || p.id::text AS id,
        'user_verification' AS activity_type,
        CASE
          WHEN p.approval_status = 'approved' THEN
            'Member Verification Approved: ' || COALESCE(NULLIF(trim(p.full_name), ''), 'Customer')
          ELSE
            'Member Account Restricted: ' || COALESCE(NULLIF(trim(p.full_name), ''), 'Customer')
        END AS title,
        'KYC Registry • ' || UPPER(p.approval_status) AS subtitle,
        COALESCE(p.approved_at, p.updated_at) AS occurred_at
      FROM public.profiles p
      WHERE p.approved_at IS NOT NULL
        AND p.approval_status IN ('approved', 'rejected')
    ) evt
    ORDER BY evt.occurred_at DESC
    LIMIT 8
  ) sa;

  RETURN jsonb_build_object(
    'admin_profile', jsonb_build_object(
      'id', v_admin_id,
      'full_name', v_admin_name,
      'email', v_admin_email,
      'role_label', 'Super Admin',
      'organization_label', 'ShiftEx Central Control'
    ),
    'statistics', jsonb_build_object(
      'total_claims_processed', v_total_claims_processed,
      'claims_current_30d', v_claims_current_30d,
      'claims_prev_30d', v_claims_prev_30d,
      'claims_growth_pct', v_claims_growth_pct,
      'net_value_inr', v_net_value_inr,
      'total_points_given', v_total_points_given,
      'active_points_per_rupee', v_pts_per_rupee,
      'active_points_to_inr_rate', v_pts_to_inr_rate,
      'currency_code', v_currency_code,
      'liquid_points', v_liquid_points,
      'liquid_pool_inr', v_liquid_pool_inr,
      'locked_points', v_locked_points,
      'locked_pool_inr', v_locked_pool_inr
    ),
    'pending_verifications_count', v_pending_verifications_count,
    'pending_verifications', v_pending_verifications,
    'pending_claims_count', v_pending_claims_count,
    'pending_claims', v_pending_claims,
    'master_ledger', v_master_ledger,
    'top_performing_users', v_top_users,
    'system_activity_log', v_system_activity,
    'fetched_at', NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_dashboard_overview(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_admin_dashboard_overview(TEXT) TO authenticated;

-- 6. Supporting Covering Indexes for Dashboard Aggregation & Claims Lookups
CREATE INDEX IF NOT EXISTS idx_reward_claims_transaction_id
  ON public.reward_claims (transaction_id);

CREATE INDEX IF NOT EXISTS idx_reward_claims_redeemed_by
  ON public.reward_claims (redeemed_by);

CREATE INDEX IF NOT EXISTS idx_reward_claims_status_expires_at
  ON public.reward_claims (status, expires_at);

CREATE INDEX IF NOT EXISTS idx_profiles_approval_status_created_at
  ON public.profiles (approval_status, created_at DESC);
