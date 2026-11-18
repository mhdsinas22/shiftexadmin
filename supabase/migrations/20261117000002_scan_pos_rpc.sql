-- Migration: 20261117000002_scan_pos_rpc.sql
-- Description: Admin POS QR Scanner verification, Phone/ID fallback search,
--              atomic instant & locked future points allocation, claim QR redemption,
--              idempotency protection, and paginated scan history RPCs.

-- 1. Add optional idempotency_key to point_transactions for duplicate allocation protection
ALTER TABLE public.point_transactions
  ADD COLUMN IF NOT EXISTS idempotency_key TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_point_transactions_idempotency_key
  ON public.point_transactions (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_point_transactions_pos_history
  ON public.point_transactions (transaction_type, created_at DESC);

-- 2. Private helper: ensure customer wallet exists & unlock matured 7-day allocations (Admin / server safe)
CREATE OR REPLACE FUNCTION private.admin_sync_customer_wallet(p_user_id UUID)
RETURNS public.customer_wallets
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_wallet public.customer_wallets;
  v_code TEXT;
  v_alloc RECORD;
  v_unlocked_sum INTEGER := 0;
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_CUSTOMER: Customer ID is required.';
  END IF;

  v_code := 'SHFT-' || upper(substr(replace(p_user_id::text, '-', ''), 1, 4));

  INSERT INTO public.customer_wallets (
    user_id,
    customer_code,
    membership_tier
  ) VALUES (
    p_user_id,
    v_code,
    'Pebble Black Member'
  )
  ON CONFLICT (user_id) DO NOTHING;

  FOR v_alloc IN
    SELECT id, points, description
    FROM public.point_allocations
    WHERE user_id = p_user_id
      AND status = 'locked'
      AND unlock_at <= NOW()
    FOR UPDATE
  LOOP
    UPDATE public.point_allocations
    SET
      status = 'unlocked',
      unlocked_at = NOW()
    WHERE id = v_alloc.id;

    v_unlocked_sum := v_unlocked_sum + v_alloc.points;

    INSERT INTO public.point_transactions (
      user_id,
      transaction_type,
      title,
      description,
      points_delta,
      is_locked_allocation,
      reference_id,
      metadata
    ) VALUES (
      p_user_id,
      'streak_unlock',
      'Locked Points Unlocked',
      v_alloc.description,
      v_alloc.points,
      false,
      v_alloc.id,
      jsonb_build_object('unlocked_from_allocation', v_alloc.id)
    );
  END LOOP;

  IF v_unlocked_sum > 0 THEN
    UPDATE public.customer_wallets
    SET
      locked_points = GREATEST(0, locked_points - v_unlocked_sum),
      available_points = available_points + v_unlocked_sum,
      lifetime_earned_points = lifetime_earned_points + v_unlocked_sum,
      updated_at = NOW()
    WHERE user_id = p_user_id;

    UPDATE public.daily_streak_checkins
    SET
      is_unlocked = true,
      unlocked_at = COALESCE(unlocked_at, NOW())
    WHERE user_id = p_user_id
      AND is_unlocked = false
      AND unlock_at <= NOW();
  END IF;

  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = p_user_id;

  RETURN v_wallet;
END;
$$;

-- 3. Admin RPC: Verify scanned QR payload or manual token code
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
  v_profile public.profiles;
  v_wallet public.customer_wallets;
  v_rate NUMERIC;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can verify POS QR codes.';
  END IF;

  v_clean := trim(COALESCE(p_qr_input, ''));
  IF v_clean = '' THEN
    RAISE EXCEPTION 'INVALID_QR: QR payload or token code is required.';
  END IF;

  -- Reject raw UUIDs: scanner must only accept Customer QR payloads/token codes
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
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVALID_QR: QR code not recognized or does not exist.';
  END IF;

  -- Validate token purpose against selected POS mode
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

  SELECT COALESCE(points_to_inr_rate, 0.1000)
  INTO v_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  RETURN jsonb_build_object(
    'customer_id', v_profile.id,
    'full_name', v_profile.full_name,
    'email', v_profile.email,
    'mobile_number', v_profile.mobile_number,
    'approval_status', v_profile.approval_status,
    'membership_id', v_wallet.customer_code,
    'membership_tier', v_wallet.membership_tier,
    'available_points', v_wallet.available_points,
    'locked_points', v_wallet.locked_points,
    'lifetime_earned_points', v_wallet.lifetime_earned_points,
    'lifetime_redeemed_points', v_wallet.lifetime_redeemed_points,
    'points_to_inr_rate', COALESCE(v_rate, 0.1000),
    'token_id', v_token.id,
    'token_code', v_token.token_code,
    'qr_payload', v_token.qr_payload,
    'token_purpose', v_token.token_purpose,
    'allow_deduction', v_token.allow_deduction,
    'token_expires_at', v_token.expires_at,
    'verification_method', 'qr'
  );
END;
$$;

-- 4. Admin RPC: Fallback search by Phone Number, Membership ID, or Customer Name
CREATE OR REPLACE FUNCTION public.search_pos_customers(
  p_query TEXT,
  p_limit INTEGER DEFAULT 10
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_clean TEXT;
  v_normalized_phone TEXT;
  v_rate NUMERIC;
  v_results JSONB;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can search POS customers.';
  END IF;

  v_clean := trim(COALESCE(p_query, ''));
  IF length(v_clean) < 2 THEN
    RETURN '[]'::jsonb;
  END IF;

  v_normalized_phone := private.normalize_mobile(v_clean);

  SELECT COALESCE(points_to_inr_rate, 0.1000)
  INTO v_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'customer_id', sub.id,
        'full_name', sub.full_name,
        'email', sub.email,
        'mobile_number', sub.mobile_number,
        'approval_status', sub.approval_status,
        'membership_id', sub.customer_code,
        'membership_tier', sub.membership_tier,
        'available_points', sub.available_points,
        'locked_points', sub.locked_points,
        'lifetime_earned_points', sub.lifetime_earned_points,
        'lifetime_redeemed_points', sub.lifetime_redeemed_points,
        'points_to_inr_rate', COALESCE(v_rate, 0.1000),
        'verification_method', 'manual_search'
      )
      ORDER BY sub.created_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_results
  FROM (
    SELECT
      p.id,
      p.full_name,
      p.email,
      p.mobile_number,
      p.approval_status,
      p.created_at,
      COALESCE(w.customer_code, 'SHFT-' || upper(substr(replace(p.id::text, '-', ''), 1, 4))) AS customer_code,
      COALESCE(w.membership_tier, 'Pebble Black Member') AS membership_tier,
      COALESCE(w.available_points, 0) AS available_points,
      COALESCE(w.locked_points, 0) AS locked_points,
      COALESCE(w.lifetime_earned_points, 0) AS lifetime_earned_points,
      COALESCE(w.lifetime_redeemed_points, 0) AS lifetime_redeemed_points
    FROM public.profiles p
    LEFT JOIN public.customer_wallets w ON w.user_id = p.id
    WHERE (
      p.full_name ILIKE '%' || v_clean || '%'
      OR p.email ILIKE '%' || v_clean || '%'
      OR p.mobile_number ILIKE '%' || v_clean || '%'
      OR (v_normalized_phone <> '' AND p.mobile_number ILIKE '%' || v_normalized_phone || '%')
      OR COALESCE(w.customer_code, 'SHFT-' || upper(substr(replace(p.id::text, '-', ''), 1, 4))) ILIKE '%' || v_clean || '%'
    )
    ORDER BY
      CASE WHEN p.approval_status = 'approved' THEN 0 ELSE 1 END,
      p.created_at DESC
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 10), 25))
  ) sub;

  RETURN v_results;
END;
$$;

-- 5. Admin RPC: Atomic POS Points Allocation (Instant + Future Locked Points)
CREATE OR REPLACE FUNCTION public.allocate_pos_points(
  p_customer_id UUID,
  p_instant_points INTEGER DEFAULT 0,
  p_future_points INTEGER DEFAULT 0,
  p_bill_number TEXT DEFAULT '',
  p_branch_name TEXT DEFAULT 'Counter #1 POS',
  p_token_id UUID DEFAULT NULL,
  p_idempotency_key TEXT DEFAULT NULL,
  p_unlock_days INTEGER DEFAULT 7,
  p_expiry_days INTEGER DEFAULT 365
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_admin_email TEXT;
  v_instant INTEGER := COALESCE(p_instant_points, 0);
  v_future INTEGER := COALESCE(p_future_points, 0);
  v_total INTEGER;
  v_bill TEXT;
  v_branch TEXT;
  v_unlock_days INTEGER := COALESCE(p_unlock_days, 7);
  v_expiry_days INTEGER := COALESCE(p_expiry_days, 365);
  v_idem TEXT;
  v_profile public.profiles;
  v_token public.customer_qr_tokens;
  v_wallet public.customer_wallets;
  v_rate NUMERIC;
  v_unlock_at TIMESTAMPTZ;
  v_expires_at TIMESTAMPTZ;
  v_allocation_id UUID;
  v_instant_tx_id UUID;
  v_future_tx_id UUID;
  v_existing_tx_id UUID;
BEGIN
  -- 1. Verify Admin authorization strictly server-side
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can allocate customer points.';
  END IF;

  -- 2. Validate amounts & inputs
  IF v_instant < 0 OR v_future < 0 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT: Points values cannot be negative.';
  END IF;

  v_total := v_instant + v_future;
  IF v_total <= 0 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT: Enter at least 1 Instant or Future point to allocate.';
  END IF;

  IF v_instant > 100000 OR v_future > 100000 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT: Single POS allocation exceeds maximum threshold (100,000 pts).';
  END IF;

  v_bill := trim(COALESCE(p_bill_number, ''));
  IF length(v_bill) < 2 OR length(v_bill) > 64 THEN
    RAISE EXCEPTION 'INVALID_BILL: Valid bill reference number is required.';
  END IF;

  v_branch := COALESCE(NULLIF(trim(COALESCE(p_branch_name, '')), ''), 'Counter #1 POS');
  IF v_unlock_days < 1 OR v_unlock_days > 90 THEN
    v_unlock_days := 7;
  END IF;
  IF v_expiry_days < 30 OR v_expiry_days > 1095 THEN
    v_expiry_days := 365;
  END IF;

  -- 3. Idempotency check to prevent duplicate submissions
  v_idem := NULLIF(trim(COALESCE(p_idempotency_key, '')), '');
  IF v_idem IS NOT NULL THEN
    SELECT id INTO v_existing_tx_id
    FROM public.point_transactions
    WHERE idempotency_key IN (v_idem || ':instant', v_idem || ':future')
    LIMIT 1;

    IF FOUND THEN
      RAISE EXCEPTION 'DUPLICATE_TRANSACTION: This allocation request has already been processed.';
    END IF;
  END IF;

  -- 4. Verify approved & active customer
  IF p_customer_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_CUSTOMER: Customer ID is required.';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = p_customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  IF v_profile.approval_status <> 'approved' THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_APPROVED: Customer must be approved before receiving points (status: %).', v_profile.approval_status;
  END IF;

  -- Verify QR token if provided
  IF p_token_id IS NOT NULL THEN
    SELECT * INTO v_token
    FROM public.customer_qr_tokens
    WHERE id = p_token_id
      AND user_id = p_customer_id
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'INVALID_QR: QR token does not match selected customer.';
    END IF;

    IF v_token.token_purpose <> 'accrual' THEN
      RAISE EXCEPTION 'WRONG_QR_MODE: Claim QR codes cannot be used for point allocation.';
    END IF;

    IF v_token.status = 'revoked' OR v_token.revoked_at IS NOT NULL THEN
      RAISE EXCEPTION 'QR_REVOKED: Customer QR code was revoked.';
    END IF;

    IF v_token.status = 'expired' OR v_token.expires_at <= NOW() THEN
      UPDATE public.customer_qr_tokens SET status = 'expired' WHERE id = v_token.id AND status = 'active';
      RAISE EXCEPTION 'QR_EXPIRED: Customer QR code expired. Re-scan or refresh QR.';
    END IF;
  END IF;

  -- 5. Sync unlocks, lock wallet row, and update balances atomically
  PERFORM private.admin_sync_customer_wallet(p_customer_id);

  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = p_customer_id
  FOR UPDATE;

  SELECT COALESCE(points_to_inr_rate, 0.1000)
  INTO v_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_rate := COALESCE(v_rate, 0.1000);
  v_admin_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');
  v_unlock_at := NOW() + make_interval(days => v_unlock_days);
  v_expires_at := NOW() + make_interval(days => v_expiry_days);

  UPDATE public.customer_wallets
  SET
    available_points = available_points + v_instant,
    locked_points = locked_points + v_future,
    lifetime_earned_points = lifetime_earned_points + v_instant,
    updated_at = NOW()
  WHERE user_id = p_customer_id
  RETURNING * INTO v_wallet;

  -- 6. Record Instant Points ledger entry
  IF v_instant > 0 THEN
    INSERT INTO public.point_transactions (
      user_id,
      transaction_type,
      title,
      description,
      points_delta,
      is_locked_allocation,
      reference_id,
      idempotency_key,
      metadata
    ) VALUES (
      p_customer_id,
      'merchant_reward',
      'POS Reward Allocated',
      'Allocated ' || v_instant || ' pts • Bill #' || v_bill,
      v_instant,
      false,
      p_token_id,
      CASE WHEN v_idem IS NOT NULL THEN v_idem || ':instant' ELSE NULL END,
      jsonb_build_object(
        'admin_id', v_admin_id,
        'admin_email', v_admin_email,
        'bill_number', v_bill,
        'branch_name', v_branch,
        'qr_token_id', p_token_id,
        'token_code', v_token.token_code,
        'allocation_kind', 'instant',
        'rate', v_rate,
        'inr_equivalent', round((v_instant * v_rate)::numeric, 2),
        'expiry_days', v_expiry_days,
        'expires_at', v_expires_at,
        'source', 'pos_scanner'
      )
    )
    RETURNING id INTO v_instant_tx_id;
  END IF;

  -- 7. Record Future Locked Points allocation + ledger entry
  IF v_future > 0 THEN
    INSERT INTO public.point_allocations (
      user_id,
      source_type,
      idempotency_key,
      points,
      status,
      description,
      locked_at,
      unlock_at
    ) VALUES (
      p_customer_id,
      'merchant_settlement',
      CASE WHEN v_idem IS NOT NULL THEN v_idem || ':future' ELSE NULL END,
      v_future,
      'locked',
      'POS Future Reward • Bill #' || v_bill,
      NOW(),
      v_unlock_at
    )
    RETURNING id INTO v_allocation_id;

    INSERT INTO public.point_transactions (
      user_id,
      transaction_type,
      title,
      description,
      points_delta,
      is_locked_allocation,
      reference_id,
      idempotency_key,
      metadata
    ) VALUES (
      p_customer_id,
      'merchant_reward',
      'Future POS Reward Locked',
      'Locked ' || v_future || ' pts (' || v_unlock_days || 'd hold) • Bill #' || v_bill,
      v_future,
      true,
      v_allocation_id,
      CASE WHEN v_idem IS NOT NULL THEN v_idem || ':future' ELSE NULL END,
      jsonb_build_object(
        'admin_id', v_admin_id,
        'admin_email', v_admin_email,
        'bill_number', v_bill,
        'branch_name', v_branch,
        'qr_token_id', p_token_id,
        'token_code', v_token.token_code,
        'allocation_id', v_allocation_id,
        'allocation_kind', 'future',
        'rate', v_rate,
        'inr_equivalent', round((v_future * v_rate)::numeric, 2),
        'unlock_days', v_unlock_days,
        'unlock_at', v_unlock_at,
        'expiry_days', v_expiry_days,
        'expires_at', v_expires_at,
        'source', 'pos_scanner'
      )
    )
    RETURNING id INTO v_future_tx_id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', p_customer_id,
    'full_name', v_profile.full_name,
    'membership_id', v_wallet.customer_code,
    'instant_points_allocated', v_instant,
    'future_points_allocated', v_future,
    'total_points_allocated', v_total,
    'total_inr_equivalent', round((v_total * v_rate)::numeric, 2),
    'bill_number', v_bill,
    'branch_name', v_branch,
    'available_points', v_wallet.available_points,
    'locked_points', v_wallet.locked_points,
    'lifetime_earned_points', v_wallet.lifetime_earned_points,
    'lifetime_redeemed_points', v_wallet.lifetime_redeemed_points,
    'instant_transaction_id', v_instant_tx_id,
    'future_transaction_id', v_future_tx_id,
    'future_allocation_id', v_allocation_id,
    'unlock_at', CASE WHEN v_future > 0 THEN v_unlock_at ELSE NULL END,
    'allocated_at', NOW()
  );
END;
$$;

-- 6. Admin RPC: Separate Claim Verification & Redemption (reuses customer_qr_tokens claim contract)
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
  v_profile public.profiles;
  v_wallet public.customer_wallets;
  v_rate NUMERIC;
  v_tx_id UUID;
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

  -- Lock claim QR row atomically to prevent double redemption
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

  IF v_wallet.available_points < v_points THEN
    RAISE EXCEPTION 'INSUFFICIENT_BALANCE: Customer has % instant points available, requested %.', v_wallet.available_points, v_points;
  END IF;

  SELECT COALESCE(points_to_inr_rate, 0.1000)
  INTO v_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_rate := COALESCE(v_rate, 0.1000);
  v_admin_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');

  -- Consume single-use claim token atomically
  UPDATE public.customer_qr_tokens
  SET
    status = 'used',
    used_at = NOW(),
    allow_deduction = false
  WHERE id = v_token.id;

  -- Deduct from customer available wallet balance
  UPDATE public.customer_wallets
  SET
    available_points = available_points - v_points,
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
    jsonb_build_object(
      'admin_id', v_admin_id,
      'admin_email', v_admin_email,
      'bill_number', v_bill,
      'branch_name', v_branch,
      'qr_token_id', v_token.id,
      'token_code', v_token.token_code,
      'rate', v_rate,
      'inr_equivalent', round((v_points * v_rate)::numeric, 2),
      'source', 'pos_scanner_claim'
    )
  )
  RETURNING id INTO v_tx_id;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', v_profile.id,
    'full_name', v_profile.full_name,
    'membership_id', v_wallet.customer_code,
    'token_code', v_token.token_code,
    'redeemed_points', v_points,
    'inr_value', round((v_points * v_rate)::numeric, 2),
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

-- 7. Admin RPC: Paginated Recent POS Scan & Claim History
CREATE OR REPLACE FUNCTION public.get_pos_recent_transactions(
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
  v_rate NUMERIC;
  v_rows JSONB;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view POS scan history.';
  END IF;

  SELECT COALESCE(points_to_inr_rate, 0.1000)
  INTO v_rate
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_rate := COALESCE(v_rate, 0.1000);

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', sub.id,
        'customer_id', sub.user_id,
        'customer_name', sub.full_name,
        'membership_id', sub.customer_code,
        'token_code', sub.token_code,
        'transaction_type', sub.transaction_type,
        'title', sub.title,
        'description', sub.description,
        'points_delta', sub.points_delta,
        'is_locked_allocation', sub.is_locked_allocation,
        'bill_number', sub.bill_number,
        'branch_name', sub.branch_name,
        'admin_id', sub.admin_id,
        'inr_equivalent', sub.inr_equivalent,
        'status', sub.status,
        'created_at', sub.created_at
      )
      ORDER BY sub.created_at DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT
      t.id,
      t.user_id,
      COALESCE(p.full_name, 'SHIIFTEX Member') AS full_name,
      COALESCE(w.customer_code, 'SHFT-' || upper(substr(replace(t.user_id::text, '-', ''), 1, 4))) AS customer_code,
      NULLIF(t.metadata->>'token_code', '') AS token_code,
      t.transaction_type,
      t.title,
      t.description,
      t.points_delta,
      t.is_locked_allocation,
      NULLIF(t.metadata->>'bill_number', '') AS bill_number,
      COALESCE(NULLIF(t.metadata->>'branch_name', ''), 'Counter #1 POS') AS branch_name,
      NULLIF(t.metadata->>'admin_id', '') AS admin_id,
      COALESCE(
        NULLIF(t.metadata->>'inr_equivalent', '')::numeric,
        round((abs(t.points_delta) * v_rate)::numeric, 2)
      ) AS inr_equivalent,
      CASE
        WHEN t.is_locked_allocation THEN 'Locked'
        ELSE 'Completed'
      END AS status,
      t.created_at
    FROM public.point_transactions t
    LEFT JOIN public.profiles p ON p.id = t.user_id
    LEFT JOIN public.customer_wallets w ON w.user_id = t.user_id
    WHERE t.transaction_type IN ('merchant_reward', 'discount_redemption')
    ORDER BY t.created_at DESC
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 15), 50))
    OFFSET GREATEST(0, COALESCE(p_offset, 0))
  ) sub;

  RETURN v_rows;
END;
$$;

-- Restrict RPC execution strictly to authenticated users (enforced admin-only inside each function)
REVOKE ALL ON FUNCTION public.verify_customer_qr_for_pos(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_customer_qr_for_pos(TEXT, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.search_pos_customers(TEXT, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.search_pos_customers(TEXT, INTEGER) TO authenticated;

REVOKE ALL ON FUNCTION public.allocate_pos_points(UUID, INTEGER, INTEGER, TEXT, TEXT, UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.allocate_pos_points(UUID, INTEGER, INTEGER, TEXT, TEXT, UUID, TEXT, INTEGER, INTEGER) TO authenticated;

REVOKE ALL ON FUNCTION public.redeem_customer_claim_qr(UUID, INTEGER, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.redeem_customer_claim_qr(UUID, INTEGER, TEXT, TEXT, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.get_pos_recent_transactions(INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_pos_recent_transactions(INTEGER, INTEGER) TO authenticated;
