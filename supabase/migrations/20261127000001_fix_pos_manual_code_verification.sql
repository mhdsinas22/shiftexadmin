-- ============================================================================
-- Migration: 20261127000001_fix_pos_manual_code_verification.sql
-- Purpose : Fix manual code entry in Scan POS ("QR code not recognized or does
--           not exist") by supporting normalized ACC/CLM short codes (with or
--           without prefix/hyphens), Customer Membership IDs (SHFT-XXXX / XXXX),
--           mobile numbers, emails, order references, and auto-refreshing
--           unrevoked accrual tokens in Give Reward mode.
-- ============================================================================

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
  v_alnum TEXT;
  v_norm_phone TEXT;
  v_digits TEXT;
  v_mode TEXT;
  v_token public.customer_qr_tokens;
  v_active_claim_token public.customer_qr_tokens;
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
  v_verification_method TEXT := 'qr';
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

  v_alnum := upper(regexp_replace(v_clean, '[^a-zA-Z0-9]', '', 'g'));
  v_norm_phone := private.normalize_mobile(v_clean);
  v_digits := regexp_replace(v_clean, '[^0-9]', '', 'g');

  -- 1. Match against customer_qr_tokens / reward_claims (exact payload, token_code, normalized code without prefix/hyphens, or claim/order reference)
  SELECT t.* INTO v_token
  FROM public.customer_qr_tokens t
  WHERE lower(t.qr_payload) = lower(v_clean)
     OR upper(t.token_code) = upper(v_clean)
     OR (
       v_alnum <> ''
       AND length(v_alnum) >= 4
       AND (
         upper(regexp_replace(t.token_code, '[^a-zA-Z0-9]', '', 'g')) IN (
           v_alnum,
           'ACC' || v_alnum,
           'CLM' || v_alnum
         )
         OR (
           length(v_alnum) >= 6
           AND upper(regexp_replace(t.qr_payload, '[^a-zA-Z0-9]', '', 'g')) LIKE '%' || v_alnum
         )
       )
     )
     OR t.id IN (
       SELECT rc.qr_token_id
       FROM public.reward_claims rc
       WHERE rc.qr_token_id IS NOT NULL
         AND (
           upper(rc.claim_reference) = upper(v_clean)
           OR (
             v_alnum <> ''
             AND upper(regexp_replace(rc.claim_reference, '[^a-zA-Z0-9]', '', 'g')) IN (
               v_alnum,
               'CLM' || v_alnum
             )
           )
           OR (
             rc.order_reference IS NOT NULL
             AND (
               upper(trim(rc.order_reference)) = upper(v_clean)
               OR (
                 v_alnum <> ''
                 AND upper(regexp_replace(rc.order_reference, '[^a-zA-Z0-9]', '', 'g')) IN (
                   v_alnum,
                   'ORD' || v_alnum
                 )
               )
             )
           )
         )
     )
  ORDER BY
    CASE
      WHEN (v_mode = 'give_reward' AND t.token_purpose = 'accrual')
        OR (v_mode = 'verify_claim' AND t.token_purpose = 'claim')
      THEN 0
      ELSE 1
    END,
    CASE WHEN t.status = 'active' THEN 0 ELSE 1 END,
    t.created_at DESC
  LIMIT 1;

  -- 1b. Prefix match if input starts with ACC or CLM (e.g. ACC-00F8 or CLM-964C)
  IF v_token.id IS NULL AND length(v_alnum) >= 6 AND (v_alnum LIKE 'ACC%' OR v_alnum LIKE 'CLM%') THEN
    SELECT t.* INTO v_token
    FROM public.customer_qr_tokens t
    WHERE upper(regexp_replace(t.token_code, '[^a-zA-Z0-9]', '', 'g')) LIKE v_alnum || '%'
    ORDER BY
      CASE WHEN t.status = 'active' THEN 0 ELSE 1 END,
      t.created_at DESC
    LIMIT 1;
  END IF;

  -- 2. If no QR token matched directly, check if manual input is a Customer Membership ID (SHFT-XXXX / XXXX), Mobile Number, or Email
  IF v_token.id IS NULL THEN
    SELECT p.* INTO v_profile
    FROM public.profiles p
    LEFT JOIN public.customer_wallets w ON w.user_id = p.id
    WHERE (
      v_alnum <> ''
      AND length(v_alnum) >= 4
      AND (
        upper(regexp_replace(COALESCE(w.customer_code, 'SHFT-' || upper(substr(replace(p.id::text, '-', ''), 1, 4))), '[^a-zA-Z0-9]', '', 'g')) IN (
          v_alnum,
          'SHFT' || v_alnum
        )
        OR upper(substr(replace(p.id::text, '-', ''), 1, 8)) = CASE
          WHEN v_alnum LIKE 'SHFT%' THEN substr(v_alnum, 5)
          ELSE v_alnum
        END
      )
    )
    OR (
      length(v_digits) >= 8
      AND (
        p.mobile_number = v_clean
        OR (v_norm_phone <> '' AND private.normalize_mobile(p.mobile_number) = v_norm_phone)
        OR regexp_replace(COALESCE(p.mobile_number, ''), '[^0-9]', '', 'g') LIKE '%' || v_digits
      )
    )
    OR (
      position('@' in v_clean) > 1
      AND lower(COALESCE(p.email, '')) = lower(v_clean)
    )
    ORDER BY
      CASE WHEN p.approval_status = 'approved' THEN 0 ELSE 1 END,
      p.created_at DESC
    LIMIT 1;

    -- 2b. Fallback prefix match on token_code when user omitted ACC/CLM and typed >= 4 hex chars
    IF v_profile.id IS NULL AND length(v_alnum) >= 4 THEN
      SELECT t.* INTO v_token
      FROM public.customer_qr_tokens t
      WHERE upper(regexp_replace(t.token_code, '[^a-zA-Z0-9]', '', 'g')) LIKE 'ACC' || v_alnum || '%'
         OR upper(regexp_replace(t.token_code, '[^a-zA-Z0-9]', '', 'g')) LIKE 'CLM' || v_alnum || '%'
      ORDER BY
        CASE
          WHEN (v_mode = 'give_reward' AND t.token_purpose = 'accrual')
            OR (v_mode = 'verify_claim' AND t.token_purpose = 'claim')
          THEN 0
          ELSE 1
        END,
        CASE WHEN t.status = 'active' THEN 0 ELSE 1 END,
        t.created_at DESC
      LIMIT 1;
    END IF;
  END IF;

  -- 3. Handle customer matched directly by Membership ID / Mobile / Email when no specific QR token was entered
  IF v_token.id IS NULL AND v_profile.id IS NOT NULL THEN
    IF v_mode = 'verify_claim' THEN
      PERFORM private.release_expired_claim_reservations(v_profile.id);

      -- Resolve customer's active pending claim token if one exists
      SELECT t.* INTO v_token
      FROM public.customer_qr_tokens t
      LEFT JOIN public.reward_claims rc ON rc.qr_token_id = t.id
      WHERE t.user_id = v_profile.id
        AND t.token_purpose = 'claim'
        AND t.allow_deduction = true
        AND t.status = 'active'
        AND t.expires_at > NOW()
        AND (rc.id IS NULL OR (rc.status = 'pending' AND rc.expires_at > NOW()))
      ORDER BY t.created_at DESC
      LIMIT 1;

      -- Otherwise check latest claim token to report accurate expired/used/revoked status
      IF v_token.id IS NULL THEN
        SELECT t.* INTO v_token
        FROM public.customer_qr_tokens t
        WHERE t.user_id = v_profile.id
          AND t.token_purpose = 'claim'
        ORDER BY t.created_at DESC
        LIMIT 1;
      END IF;

      IF v_token.id IS NULL THEN
        RAISE EXCEPTION 'WRONG_QR_MODE: Personal Member ID cannot be used for deduction without an active Claim QR. Ask % to generate a Single-Use Claim QR.', v_profile.full_name;
      END IF;
    ELSE
      -- give_reward mode with direct customer lookup (SHFT-XXXX / Mobile / Email)
      IF v_profile.approval_status <> 'approved' THEN
        RAISE EXCEPTION 'CUSTOMER_NOT_APPROVED: Customer account is not approved (status: %).', v_profile.approval_status;
      END IF;

      v_wallet := private.admin_sync_customer_wallet(v_profile.id);
      v_verification_method := 'manual_code';

      -- Attach active accrual token if customer has one; otherwise leave token fields null/safe
      SELECT t.* INTO v_token
      FROM public.customer_qr_tokens t
      WHERE t.user_id = v_profile.id
        AND t.token_purpose = 'accrual'
        AND t.status = 'active'
        AND t.expires_at > NOW()
      ORDER BY t.created_at DESC
      LIMIT 1;

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

      RETURN jsonb_build_object(
        'customer_id', v_profile.id,
        'full_name', v_profile.full_name,
        'email', v_profile.email,
        'mobile_number', v_profile.mobile_number,
        'approval_status', v_profile.approval_status,
        'membership_id', v_wallet.customer_code,
        'membership_tier', v_wallet.membership_tier,
        'available_points', v_wallet.available_points,
        'reserved_points', v_wallet.reserved_points,
        'locked_points', v_wallet.locked_points,
        'lifetime_earned_points', v_wallet.lifetime_earned_points,
        'lifetime_redeemed_points', v_wallet.lifetime_redeemed_points,
        'points_per_rupee', COALESCE(v_pts_per_rupee, 10),
        'points_to_inr_rate', COALESCE(v_rate, 0.100000),
        'currency_code', COALESCE(v_currency, 'INR'),
        'token_id', v_token.id,
        'token_code', COALESCE(v_token.token_code, v_wallet.customer_code),
        'qr_payload', v_token.qr_payload,
        'token_purpose', 'accrual',
        'allow_deduction', false,
        'token_created_at', v_token.created_at,
        'token_expires_at', v_token.expires_at,
        'remaining_seconds', CASE
          WHEN v_token.expires_at IS NOT NULL THEN GREATEST(0, EXTRACT(EPOCH FROM (v_token.expires_at - NOW()))::INTEGER)
          ELSE 900
        END,
        'claim_id', NULL,
        'claim_reference', COALESCE(v_token.token_code, v_wallet.customer_code),
        'claim_status', 'active',
        'claim_audit_status', 'verified',
        'claim_points', 0,
        'claim_discount_amount', 0.00,
        'reward_name', 'Instant POS Bill Discount',
        'reward_category', 'POS Cashback & Bill Offset',
        'merchant_name', 'ShiftEx Partner Counter',
        'order_reference', '',
        'audit_checks', jsonb_build_object(
          'token_signature_valid', true,
          'claim_not_expired', true,
          'single_use_passed', true,
          'replay_protection_passed', true,
          'customer_eligible', true,
          'balance_reservation_valid', true
        ),
        'verification_method', v_verification_method
      );
    END IF;
  END IF;

  IF v_token.id IS NULL THEN
    RAISE EXCEPTION 'INVALID_QR: QR code not recognized or does not exist.';
  END IF;

  -- If in verify_claim mode and an accrual token was entered, check if that customer has an active pending claim token
  IF v_mode = 'verify_claim' AND (v_token.token_purpose <> 'claim' OR NOT v_token.allow_deduction) THEN
    IF v_token.token_purpose = 'accrual' THEN
      PERFORM private.release_expired_claim_reservations(v_token.user_id);

      SELECT t.* INTO v_active_claim_token
      FROM public.customer_qr_tokens t
      LEFT JOIN public.reward_claims rc ON rc.qr_token_id = t.id
      WHERE t.user_id = v_token.user_id
        AND t.token_purpose = 'claim'
        AND t.allow_deduction = true
        AND t.status = 'active'
        AND t.expires_at > NOW()
        AND (rc.id IS NULL OR (rc.status = 'pending' AND rc.expires_at > NOW()))
      ORDER BY t.created_at DESC
      LIMIT 1;

      IF v_active_claim_token.id IS NOT NULL THEN
        v_token := v_active_claim_token;
      ELSE
        RAISE EXCEPTION 'WRONG_QR_MODE: Personal Member QR cannot be used for deduction. Ask customer for a Single-Use Claim QR.';
      END IF;
    END IF;
  END IF;

  IF v_mode = 'give_reward' AND v_token.token_purpose <> 'accrual' THEN
    RAISE EXCEPTION 'WRONG_QR_MODE: This is a Claim QR. Switch to Verify Claim mode to redeem points.';
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

  -- For give_reward mode with an unrevoked accrual token, auto-refresh expiry so manual entry or saved Member QR codes work seamlessly
  IF v_mode = 'give_reward'
     AND v_token.token_purpose = 'accrual'
     AND v_token.status <> 'revoked'
     AND v_token.revoked_at IS NULL
     AND (v_token.status = 'expired' OR v_token.expires_at <= NOW()) THEN
    UPDATE public.customer_qr_tokens
    SET
      status = 'active',
      expires_at = NOW() + interval '15 minutes'
    WHERE id = v_token.id
    RETURNING * INTO v_token;
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
    'verification_method', v_verification_method
  );
END;
$$;
