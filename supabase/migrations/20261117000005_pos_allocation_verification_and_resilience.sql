-- Migration: 20261117000005_pos_allocation_verification_and_resilience.sql
-- Description: Strengthens atomic POS allocation verification, collision-safe wallet provisioning,
--              advisory idempotency serialization, and authoritative post-allocation wallet refresh RPC.

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

  BEGIN
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
  EXCEPTION WHEN unique_violation THEN
    v_code := 'SHFT-' || upper(substr(replace(p_user_id::text, '-', ''), 1, 6));
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
  END;

  PERFORM private.release_expired_claim_reservations(p_user_id);

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
  v_before_available INTEGER;
  v_before_locked INTEGER;
  v_pts_per_rupee INTEGER;
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
  v_rate_version_id UUID;
  v_instant_cash NUMERIC(12, 2);
  v_future_cash NUMERIC(12, 2);
  v_total_cash NUMERIC(12, 2);
  v_unlock_at TIMESTAMPTZ;
  v_expires_at TIMESTAMPTZ;
  v_allocation_id UUID;
  v_instant_tx_id UUID;
  v_future_tx_id UUID;
  v_existing_tx_id UUID;
  v_existing_alloc_id UUID;
  v_verify_count INTEGER;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can allocate customer points.';
  END IF;

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

  v_idem := NULLIF(trim(COALESCE(p_idempotency_key, '')), '');
  IF v_idem IS NOT NULL THEN
    PERFORM pg_advisory_xact_lock(hashtext('pos_alloc:' || v_idem));

    SELECT id INTO v_existing_tx_id
    FROM public.point_transactions
    WHERE idempotency_key IN (v_idem || ':instant', v_idem || ':future')
    LIMIT 1;

    IF FOUND THEN
      RAISE EXCEPTION 'DUPLICATE_TRANSACTION: This allocation request has already been processed.';
    END IF;

    SELECT id INTO v_existing_alloc_id
    FROM public.point_allocations
    WHERE idempotency_key = v_idem || ':future'
    LIMIT 1;

    IF FOUND THEN
      RAISE EXCEPTION 'DUPLICATE_TRANSACTION: This allocation request has already been processed.';
    END IF;
  END IF;

  IF p_customer_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_CUSTOMER: Customer ID is required.';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = p_customer_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  IF v_profile.approval_status <> 'approved' THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_APPROVED: Customer must be approved before receiving points (status: %).', v_profile.approval_status;
  END IF;

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

  PERFORM private.admin_sync_customer_wallet(p_customer_id);

  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = p_customer_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'WALLET_NOT_FOUND: Failed to provision customer wallet.';
  END IF;

  v_before_available := v_wallet.available_points;
  v_before_locked := v_wallet.locked_points;

  SELECT
    COALESCE(points_per_rupee, 10),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_rupee, v_rate, v_currency
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_pts_per_rupee := COALESCE(v_pts_per_rupee, 10);
  v_rate := COALESCE(v_rate, ROUND((1::numeric / v_pts_per_rupee::numeric), 6));
  v_currency := COALESCE(v_currency, 'INR');

  SELECT id INTO v_rate_version_id
  FROM public.points_to_cash_rate_history
  ORDER BY created_at DESC, version_number DESC
  LIMIT 1;

  v_instant_cash := ROUND((v_instant::numeric / v_pts_per_rupee::numeric), 2);
  v_future_cash := ROUND((v_future::numeric / v_pts_per_rupee::numeric), 2);
  v_total_cash := ROUND((v_total::numeric / v_pts_per_rupee::numeric), 2);

  v_admin_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');
  v_unlock_at := NOW() + make_interval(days => v_unlock_days);
  v_expires_at := NOW() + make_interval(days => v_expiry_days);

  UPDATE public.customer_wallets
  SET
    available_points = available_points + v_instant,
    locked_points = locked_points + v_future,
    lifetime_earned_points = lifetime_earned_points + v_instant,
    updated_at = NOW()
  WHERE user_id = p_customer_id;

  BEGIN
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
        points_per_rupee,
        points_per_currency_unit,
        points_to_inr_rate,
        cash_value,
        currency_code,
        rate_version_id,
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
        v_pts_per_rupee,
        v_pts_per_rupee::numeric(12, 4),
        v_rate,
        v_instant_cash,
        v_currency,
        v_rate_version_id,
        jsonb_build_object(
          'admin_id', v_admin_id,
          'admin_email', v_admin_email,
          'customer_id', p_customer_id,
          'bill_number', v_bill,
          'branch_name', v_branch,
          'qr_token_id', p_token_id,
          'token_code', v_token.token_code,
          'allocation_kind', 'instant',
          'points_per_rupee', v_pts_per_rupee,
          'rate', v_rate,
          'inr_equivalent', v_instant_cash,
          'currency_code', v_currency,
          'rate_version_id', v_rate_version_id,
          'expiry_days', v_expiry_days,
          'expires_at', v_expires_at,
          'source', 'pos_scanner'
        )
      )
      RETURNING id INTO v_instant_tx_id;
    END IF;

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
        points_per_rupee,
        points_per_currency_unit,
        points_to_inr_rate,
        cash_value,
        currency_code,
        rate_version_id,
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
        v_pts_per_rupee,
        v_pts_per_rupee::numeric(12, 4),
        v_rate,
        v_future_cash,
        v_currency,
        v_rate_version_id,
        jsonb_build_object(
          'admin_id', v_admin_id,
          'admin_email', v_admin_email,
          'customer_id', p_customer_id,
          'bill_number', v_bill,
          'branch_name', v_branch,
          'qr_token_id', p_token_id,
          'token_code', v_token.token_code,
          'allocation_id', v_allocation_id,
          'allocation_kind', 'future',
          'points_per_rupee', v_pts_per_rupee,
          'rate', v_rate,
          'inr_equivalent', v_future_cash,
          'currency_code', v_currency,
          'rate_version_id', v_rate_version_id,
          'unlock_days', v_unlock_days,
          'unlock_at', v_unlock_at,
          'expiry_days', v_expiry_days,
          'expires_at', v_expires_at,
          'source', 'pos_scanner'
        )
      )
      RETURNING id INTO v_future_tx_id;
    END IF;
  EXCEPTION WHEN unique_violation THEN
    RAISE EXCEPTION 'DUPLICATE_TRANSACTION: This allocation request has already been processed.';
  END;

  SELECT * INTO v_wallet
  FROM public.customer_wallets
  WHERE user_id = p_customer_id;

  IF v_wallet.available_points <> v_before_available + v_instant
     OR v_wallet.locked_points <> v_before_locked + v_future THEN
    RAISE EXCEPTION 'WALLET_VERIFICATION_FAILED: Customer wallet balances did not match expected credit.';
  END IF;

  IF v_instant > 0 THEN
    SELECT COUNT(*) INTO v_verify_count
    FROM public.point_transactions
    WHERE id = v_instant_tx_id AND user_id = p_customer_id;
    IF v_verify_count <> 1 THEN
      RAISE EXCEPTION 'LEDGER_VERIFICATION_FAILED: Instant point ledger entry missing.';
    END IF;
  END IF;

  IF v_future > 0 THEN
    SELECT COUNT(*) INTO v_verify_count
    FROM public.point_allocations
    WHERE id = v_allocation_id AND user_id = p_customer_id AND status = 'locked';
    IF v_verify_count <> 1 THEN
      RAISE EXCEPTION 'ALLOCATION_VERIFICATION_FAILED: Future locked allocation missing.';
    END IF;

    SELECT COUNT(*) INTO v_verify_count
    FROM public.point_transactions
    WHERE id = v_future_tx_id AND user_id = p_customer_id;
    IF v_verify_count <> 1 THEN
      RAISE EXCEPTION 'LEDGER_VERIFICATION_FAILED: Future point ledger entry missing.';
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'customer_id', p_customer_id,
    'full_name', v_profile.full_name,
    'membership_id', v_wallet.customer_code,
    'instant_points_allocated', v_instant,
    'future_points_allocated', v_future,
    'total_points_allocated', v_total,
    'instant_inr_equivalent', v_instant_cash,
    'future_inr_equivalent', v_future_cash,
    'total_inr_equivalent', v_total_cash,
    'points_per_rupee', v_pts_per_rupee,
    'points_to_inr_rate', v_rate,
    'currency_code', v_currency,
    'rate_version_id', v_rate_version_id,
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

CREATE OR REPLACE FUNCTION public.get_pos_customer_wallet(
  p_customer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_admin_id UUID;
  v_profile public.profiles;
  v_wallet public.customer_wallets;
  v_pts_per_rupee INTEGER;
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can query customer POS wallets.';
  END IF;

  IF p_customer_id IS NULL THEN
    RAISE EXCEPTION 'INVALID_CUSTOMER: Customer ID is required.';
  END IF;

  SELECT * INTO v_profile
  FROM public.profiles
  WHERE id = p_customer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'CUSTOMER_NOT_FOUND: Customer profile not found.';
  END IF;

  v_wallet := private.admin_sync_customer_wallet(p_customer_id);

  SELECT
    COALESCE(points_per_rupee, 10),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_rupee, v_rate, v_currency
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
    'points_per_rupee', COALESCE(v_pts_per_rupee, 10),
    'points_to_inr_rate', COALESCE(v_rate, 0.100000),
    'currency_code', COALESCE(v_currency, 'INR'),
    'verification_method', 'wallet_refresh'
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_pos_customer_wallet(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_pos_customer_wallet(UUID) TO authenticated;
REVOKE ALL ON FUNCTION public.allocate_pos_points(UUID, INTEGER, INTEGER, TEXT, TEXT, UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.allocate_pos_points(UUID, INTEGER, INTEGER, TEXT, TEXT, UUID, TEXT, INTEGER, INTEGER) TO authenticated;
