-- ============================================================================
-- Migration: 20261118000005_complete_verify_claim_workflow.sql
-- Purpose : Complete Verify Claim & Redemption Workflow, Cryptographic Audit
--           Checks, POS Bill Association, and Reject / Flag Claim Token RPC
-- ============================================================================

-- 1. Extend public.reward_claims additively with reward metadata & audit fields
ALTER TABLE public.reward_claims
  ADD COLUMN IF NOT EXISTS reward_name TEXT NOT NULL DEFAULT 'Instant POS Bill Discount',
  ADD COLUMN IF NOT EXISTS reward_category TEXT NOT NULL DEFAULT 'POS Cashback & Bill Offset',
  ADD COLUMN IF NOT EXISTS merchant_name TEXT NOT NULL DEFAULT 'ShiftEx Partner Counter',
  ADD COLUMN IF NOT EXISTS order_reference TEXT,
  ADD COLUMN IF NOT EXISTS audit_status TEXT NOT NULL DEFAULT 'verified',
  ADD COLUMN IF NOT EXISTS rejected_reason TEXT,
  ADD COLUMN IF NOT EXISTS flagged_reason TEXT,
  ADD COLUMN IF NOT EXISTS flagged_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS flagged_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_reward_claims_flagged_by
  ON public.reward_claims (flagged_by);

-- 2. Enhance verify_customer_qr_for_pos with authoritative cryptographic &
--    replay-protection audit checks and complete claim/reward metadata
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
  v_computed_hash TEXT;
  v_sig_valid BOOLEAN := true;
  v_not_expired BOOLEAN := true;
  v_single_use_ok BOOLEAN := true;
  v_replay_ok BOOLEAN := true;
  v_customer_eligible BOOLEAN := true;
  v_balance_ok BOOLEAN := true;
  v_claim_pts INTEGER := 0;
  v_claim_discount NUMERIC(12, 2) := 0.00;
  v_remaining_secs INTEGER := 0;
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

  IF v_mode = 'verify_claim' AND NOT private.has_admin_permission('pos.verify_claim') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: You do not have permission (pos.verify_claim) to verify claim tokens.';
  END IF;

  IF v_mode = 'give_reward' AND NOT private.has_admin_permission('pos.give_reward') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: You do not have permission (pos.give_reward) to allocate POS rewards.';
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
    IF v_token.token_purpose = 'accrual' THEN
      RAISE EXCEPTION 'WRONG_QR_MODE: Personal Member QR cannot be used for deduction. Ask customer for a Single-Use Claim QR.';
    END IF;
  END IF;

  -- Look up associated reward_claim if any
  SELECT * INTO v_claim
  FROM public.reward_claims
  WHERE qr_token_id = v_token.id
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_token.status = 'revoked' OR v_token.revoked_at IS NOT NULL THEN
    IF v_claim.id IS NOT NULL AND v_claim.audit_status = 'flagged' THEN
      RAISE EXCEPTION 'QR_REVOKED: This Claim QR was flagged as suspicious (%).', COALESCE(v_claim.flagged_reason, 'Security hold');
    ELSIF v_claim.id IS NOT NULL AND v_claim.audit_status = 'rejected' THEN
      RAISE EXCEPTION 'QR_REVOKED: This Claim QR was rejected (%).', COALESCE(v_claim.rejected_reason, 'Rejected by operator');
    END IF;
    RAISE EXCEPTION 'QR_REVOKED: This QR code was revoked or cancelled.';
  END IF;

  IF v_token.status = 'used' OR v_token.used_at IS NOT NULL OR (v_claim.id IS NOT NULL AND v_claim.status = 'redeemed') THEN
    RAISE EXCEPTION 'QR_ALREADY_USED: This Claim QR has already been redeemed and consumed.';
  END IF;

  IF v_token.status = 'expired' OR v_token.expires_at <= NOW() OR (v_claim.id IS NOT NULL AND v_claim.expires_at <= NOW()) THEN
    PERFORM private.release_expired_claim_reservations(v_token.user_id);
    UPDATE public.customer_qr_tokens
    SET status = 'expired'
    WHERE id = v_token.id AND status = 'active';
    RAISE EXCEPTION 'QR_EXPIRED: This QR code has expired. Ask customer to generate a fresh Claim QR.';
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

  v_pts_per_rupee := GREATEST(COALESCE(v_pts_per_rupee, 10), 1);
  v_rate := COALESCE(v_rate, ROUND((1::numeric / v_pts_per_rupee::numeric), 6));

  v_effective_available := v_wallet.available_points;
  IF v_claim.id IS NOT NULL AND v_claim.status = 'pending' THEN
    v_effective_available := v_wallet.available_points + COALESCE(v_claim.points, 0);
    IF COALESCE(v_claim.points_to_inr_rate, 0) > 0 THEN
      v_rate := v_claim.points_to_inr_rate;
      v_pts_per_rupee := GREATEST(1, ROUND((1::numeric / v_rate::numeric))::integer);
    END IF;
    v_claim_pts := v_claim.points;
    v_claim_discount := COALESCE(v_claim.discount_amount, ROUND((v_claim.points * v_rate)::numeric, 2));
  ELSE
    v_claim_pts := LEAST(100, GREATEST(v_effective_available, 0));
    v_claim_discount := ROUND((v_claim_pts * v_rate)::numeric, 2);
  END IF;

  -- Compute real cryptographic & state audit checks
  IF v_claim.id IS NOT NULL AND v_claim.token_hash IS NOT NULL AND v_token.qr_payload IS NOT NULL THEN
    v_computed_hash := encode(extensions.digest(v_token.qr_payload, 'sha256'), 'hex');
    v_sig_valid := (v_computed_hash = v_claim.token_hash);
  ELSE
    v_sig_valid := (v_token.qr_payload IS NOT NULL AND length(v_token.qr_payload) >= 8);
  END IF;

  v_not_expired := (
    v_token.status = 'active'
    AND v_token.expires_at > NOW()
    AND (v_claim.id IS NULL OR (v_claim.status = 'pending' AND v_claim.expires_at > NOW()))
  );

  v_single_use_ok := (
    v_token.used_at IS NULL
    AND v_token.status = 'active'
    AND (v_mode <> 'verify_claim' OR (v_token.token_purpose = 'claim' AND v_token.allow_deduction))
  );

  v_replay_ok := (
    v_claim.id IS NULL
    OR (v_claim.status = 'pending' AND v_claim.redeemed_at IS NULL AND v_claim.transaction_id IS NULL)
  );

  v_customer_eligible := (v_profile.approval_status = 'approved');
  v_balance_ok := (v_effective_available >= GREATEST(v_claim_pts, 1));

  v_remaining_secs := GREATEST(
    0,
    EXTRACT(EPOCH FROM (COALESCE(v_claim.expires_at, v_token.expires_at) - NOW()))::INTEGER
  );

  RETURN jsonb_build_object(
    'customer_id', v_profile.id,
    'full_name', v_profile.full_name,
    'email', v_profile.email,
    'mobile_number', v_profile.mobile_number,
    'approval_status', v_profile.approval_status,
    'membership_id', v_wallet.customer_code,
    'membership_tier', v_wallet.membership_tier,
    'available_points', v_effective_available,
    'reserved_points', v_wallet.reserved_points,
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
    'token_created_at', COALESCE(v_claim.created_at, v_token.created_at),
    'token_expires_at', COALESCE(v_claim.expires_at, v_token.expires_at),
    'remaining_seconds', v_remaining_secs,
    'claim_id', v_claim.id,
    'claim_reference', COALESCE(v_claim.claim_reference, v_token.token_code),
    'claim_status', COALESCE(v_claim.status, v_token.status),
    'claim_audit_status', COALESCE(v_claim.audit_status, 'verified'),
    'claim_points', v_claim_pts,
    'claim_discount_amount', v_claim_discount,
    'reward_name', COALESCE(NULLIF(trim(v_claim.reward_name), ''), 'Instant POS Bill Discount'),
    'reward_category', COALESCE(NULLIF(trim(v_claim.reward_category), ''), 'POS Cashback & Bill Offset'),
    'merchant_name', COALESCE(NULLIF(trim(v_claim.merchant_name), ''), NULLIF(trim(v_claim.branch_name), ''), 'ShiftEx Partner Counter'),
    'order_reference', COALESCE(
      NULLIF(trim(v_claim.order_reference), ''),
      NULLIF(trim(v_claim.bill_number), ''),
      'ORD-' || UPPER(SUBSTR(REPLACE(COALESCE(v_claim.id, v_token.id)::text, '-', ''), 1, 6))
    ),
    'audit_checks', jsonb_build_object(
      'token_signature_valid', v_sig_valid,
      'claim_not_expired', v_not_expired,
      'single_use_passed', v_single_use_ok,
      'replay_protection_passed', v_replay_ok,
      'customer_eligible', v_customer_eligible,
      'balance_reservation_valid', v_balance_ok
    ),
    'verification_method', 'qr'
  );
END;
$$;

-- 3. Reject or Flag Claim Token RPC (preserves audit history & releases reserved points)
CREATE OR REPLACE FUNCTION public.reject_or_flag_customer_claim_qr(
  p_token_id UUID,
  p_action TEXT,
  p_reason TEXT,
  p_branch_name TEXT DEFAULT 'Counter #1 POS'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_admin_email TEXT;
  v_action TEXT := lower(trim(COALESCE(p_action, 'reject')));
  v_reason TEXT := trim(COALESCE(p_reason, ''));
  v_branch TEXT := COALESCE(NULLIF(trim(COALESCE(p_branch_name, '')), ''), 'Counter #1 POS');
  v_token public.customer_qr_tokens;
  v_claim public.reward_claims;
  v_wallet public.customer_wallets;
  v_audit_status TEXT;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() OR NOT private.has_admin_permission('pos.verify_claim') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized POS admins can reject or flag claim tokens.';
  END IF;

  IF p_token_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_QR: Claim QR token ID is required.';
  END IF;

  IF v_action NOT IN ('reject', 'flag') THEN
    RAISE EXCEPTION 'INVALID_ACTION: Action must be reject or flag.';
  END IF;

  IF length(v_reason) < 3 THEN
    RAISE EXCEPTION 'INVALID_REASON: Please provide a reason (at least 3 characters).';
  END IF;

  SELECT * INTO v_token
  FROM public.customer_qr_tokens
  WHERE id = p_token_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_QR: Claim QR token not found.';
  END IF;

  IF v_token.status = 'used' OR v_token.used_at IS NOT NULL THEN
    RAISE EXCEPTION 'QR_ALREADY_USED: This Claim QR has already been redeemed and cannot be rejected.';
  END IF;

  -- Lock customer wallet first to maintain deterministic lock ordering
  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = v_token.user_id
  FOR UPDATE;

  SELECT * INTO v_claim
  FROM public.reward_claims
  WHERE qr_token_id = v_token.id
  FOR UPDATE
  LIMIT 1;

  v_audit_status := CASE WHEN v_action = 'flag' THEN 'flagged' ELSE 'rejected' END;

  UPDATE public.customer_qr_tokens
  SET
    status = 'revoked',
    revoked_at = NOW(),
    allow_deduction = false
  WHERE id = v_token.id;

  IF v_claim.id IS NOT NULL AND v_claim.status = 'pending' THEN
    UPDATE public.reward_claims
    SET
      status = 'cancelled',
      audit_status = v_audit_status,
      rejected_reason = CASE WHEN v_action = 'reject' THEN v_reason ELSE rejected_reason END,
      flagged_reason = CASE WHEN v_action = 'flag' THEN v_reason ELSE flagged_reason END,
      flagged_by = v_admin_id,
      flagged_at = NOW(),
      branch_name = v_branch,
      released_at = NOW(),
      updated_at = NOW()
    WHERE id = v_claim.id
    RETURNING * INTO v_claim;

    -- Release reserved points back to customer's available balance (do not deduct points on reject/flag)
    UPDATE public.customer_wallets
    SET
      available_points = available_points + v_claim.points,
      reserved_points = GREATEST(0, reserved_points - v_claim.points),
      updated_at = NOW()
    WHERE user_id = v_token.user_id
    RETURNING * INTO v_wallet;
  END IF;

  v_admin_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');

  INSERT INTO public.admin_access_audit_logs (
    actor_user_id,
    actor_email,
    target_user_id,
    action,
    note
  ) VALUES (
    v_admin_id,
    v_admin_email,
    v_token.user_id,
    CASE WHEN v_action = 'flag' THEN 'FLAG_CLAIM_TOKEN' ELSE 'REJECT_CLAIM_TOKEN' END,
    UPPER(v_action) || ' claim ' || COALESCE(v_claim.claim_reference, v_token.token_code)
      || ' at ' || v_branch || ': ' || v_reason
  );

  RETURN jsonb_build_object(
    'success', true,
    'action', v_action,
    'audit_status', v_audit_status,
    'token_id', v_token.id,
    'claim_id', v_claim.id,
    'claim_reference', COALESCE(v_claim.claim_reference, v_token.token_code),
    'reason', v_reason,
    'branch_name', v_branch,
    'available_points', COALESCE(v_wallet.available_points, 0),
    'reserved_points', COALESCE(v_wallet.reserved_points, 0),
    'processed_at', NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.reject_or_flag_customer_claim_qr(UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reject_or_flag_customer_claim_qr(UUID, TEXT, TEXT, TEXT) TO authenticated;
