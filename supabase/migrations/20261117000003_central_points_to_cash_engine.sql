-- Migration: 20261117000003_central_points_to_cash_engine.sql
-- Description: Centralized Points-to-Cash Rule Engine on reward_settings,
--              immutable versioned rate history, 2FA (AAL2) enforcement on rate changes,
--              immutable historical rate snapshots on point_transactions,
--              and numeric/decimal POS RPC updates.

-- 1. Extend public.reward_settings with central Points-to-Cash columns
ALTER TABLE public.reward_settings
  ALTER COLUMN points_to_inr_rate TYPE NUMERIC(12, 6);

ALTER TABLE public.reward_settings
  ADD COLUMN IF NOT EXISTS points_per_currency_unit NUMERIC(12, 4) NOT NULL DEFAULT 10.0000,
  ADD COLUMN IF NOT EXISTS currency_code TEXT NOT NULL DEFAULT 'INR',
  ADD COLUMN IF NOT EXISTS effective_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_reward_settings_points_per_currency_unit'
      AND conrelid = 'public.reward_settings'::regclass
  ) THEN
    ALTER TABLE public.reward_settings
      ADD CONSTRAINT chk_reward_settings_points_per_currency_unit
      CHECK (points_per_currency_unit > 0 AND points_per_currency_unit <= 10000);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'chk_reward_settings_points_to_inr_rate'
      AND conrelid = 'public.reward_settings'::regclass
  ) THEN
    ALTER TABLE public.reward_settings
      ADD CONSTRAINT chk_reward_settings_points_to_inr_rate
      CHECK (points_to_inr_rate > 0 AND points_to_inr_rate <= 100);
  END IF;
END $$;

-- Sync existing global row cleanly using NUMERIC arithmetic
UPDATE public.reward_settings
SET
  points_per_currency_unit = CASE
    WHEN COALESCE(points_to_inr_rate, 0) > 0
      THEN ROUND((1::numeric / points_to_inr_rate::numeric), 4)
    ELSE 10.0000
  END,
  points_to_inr_rate = CASE
    WHEN COALESCE(points_to_inr_rate, 0) > 0
      THEN ROUND(points_to_inr_rate::numeric, 6)
    ELSE 0.100000
  END,
  currency_code = 'INR',
  effective_at = COALESCE(effective_at, updated_at, NOW())
WHERE singleton_key = 'global';

-- 2. Immutable Versioned Rate History Table
CREATE TABLE IF NOT EXISTS public.points_to_cash_rate_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version_number BIGINT GENERATED ALWAYS AS IDENTITY,
  setting_id UUID NOT NULL REFERENCES public.reward_settings(id) ON DELETE CASCADE,
  previous_points_per_currency_unit NUMERIC(12, 4),
  new_points_per_currency_unit NUMERIC(12, 4) NOT NULL CHECK (new_points_per_currency_unit > 0),
  previous_points_to_inr_rate NUMERIC(12, 6),
  new_points_to_inr_rate NUMERIC(12, 6) NOT NULL CHECK (new_points_to_inr_rate > 0),
  currency_code TEXT NOT NULL DEFAULT 'INR',
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_email TEXT,
  mfa_verified BOOLEAN NOT NULL DEFAULT true,
  mfa_factor_id UUID,
  aal_level TEXT NOT NULL DEFAULT 'aal2',
  note TEXT,
  effective_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_points_to_cash_rate_history_created_at
  ON public.points_to_cash_rate_history (created_at DESC);

ALTER TABLE public.points_to_cash_rate_history ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'points_to_cash_rate_history'
      AND policyname = 'Admins can view points to cash rate history'
  ) THEN
    CREATE POLICY "Admins can view points to cash rate history"
      ON public.points_to_cash_rate_history
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'points_to_cash_rate_history'
      AND policyname = 'Admins with AAL2 can insert points to cash rate history'
  ) THEN
    CREATE POLICY "Admins with AAL2 can insert points to cash rate history"
      ON public.points_to_cash_rate_history
      FOR INSERT
      TO authenticated
      WITH CHECK (
        private.is_admin()
        AND COALESCE((SELECT auth.jwt())->>'aal', 'aal1') = 'aal2'
      );
  END IF;
END $$;

-- Protect points_to_cash_rate_history against UPDATE/DELETE (strictly append-only)
CREATE OR REPLACE FUNCTION private.protect_points_to_cash_history_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_AUDIT: Rate history records are immutable and cannot be modified or deleted.';
END;
$$;

CREATE OR REPLACE TRIGGER trg_protect_points_to_cash_history_immutability
  BEFORE UPDATE OR DELETE ON public.points_to_cash_rate_history
  FOR EACH ROW
  EXECUTE FUNCTION private.protect_points_to_cash_history_immutability();

-- Seed baseline v1 history entry if empty
INSERT INTO public.points_to_cash_rate_history (
  setting_id,
  previous_points_per_currency_unit,
  new_points_per_currency_unit,
  previous_points_to_inr_rate,
  new_points_to_inr_rate,
  currency_code,
  changed_by,
  changed_by_email,
  mfa_verified,
  aal_level,
  note,
  effective_at
)
SELECT
  rs.id,
  NULL,
  rs.points_per_currency_unit,
  NULL,
  rs.points_to_inr_rate,
  rs.currency_code,
  rs.updated_by,
  u.email,
  false,
  'baseline',
  'Initial baseline points-to-cash configuration',
  rs.effective_at
FROM public.reward_settings rs
LEFT JOIN auth.users u ON u.id = rs.updated_by
WHERE rs.singleton_key = 'global'
  AND NOT EXISTS (SELECT 1 FROM public.points_to_cash_rate_history);

-- 3. Strengthen private.protect_reward_settings() so direct table updates cannot bypass Admin or 2FA
CREATE OR REPLACE FUNCTION private.protect_reward_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_aal TEXT;
  v_has_verified_mfa BOOLEAN;
BEGIN
  v_uid := (SELECT auth.uid());

  IF current_user IN ('authenticated', 'anon') THEN
    IF v_uid IS NULL OR NOT private.is_admin() THEN
      RAISE EXCEPTION 'UNAUTHORIZED: Only administrators can modify reward settings.';
    END IF;
  END IF;

  IF NEW.daily_login_points IS NULL OR NEW.daily_login_points < 1 OR NEW.daily_login_points > 1000 THEN
    RAISE EXCEPTION 'INVALID_POINTS: Points per daily check-in must be between 1 and 1000.';
  END IF;

  -- Enforce 2FA (verified MFA factor + AAL2 session) whenever conversion rate or currency changes from client roles
  IF TG_OP = 'UPDATE' THEN
    IF OLD.points_per_currency_unit IS DISTINCT FROM NEW.points_per_currency_unit
       OR OLD.points_to_inr_rate IS DISTINCT FROM NEW.points_to_inr_rate
       OR OLD.currency_code IS DISTINCT FROM NEW.currency_code THEN
      IF current_user IN ('authenticated', 'anon') THEN
        SELECT EXISTS (
          SELECT 1 FROM auth.mfa_factors f
          WHERE f.user_id = v_uid AND f.status::text = 'verified'
        ) INTO v_has_verified_mfa;

        IF NOT v_has_verified_mfa THEN
          RAISE EXCEPTION 'MFA_NOT_CONFIGURED: Two-Factor Authentication (2FA) is not configured for this admin account and cannot be bypassed.';
        END IF;

        v_aal := COALESCE((SELECT auth.jwt())->>'aal', 'aal1');
        IF v_aal <> 'aal2' THEN
          RAISE EXCEPTION 'MFA_REQUIRED: Two-Factor Authentication (2FA / AAL2) verification is required to modify conversion rates.';
        END IF;
      END IF;
    END IF;
  END IF;

  -- Synchronize points_per_currency_unit and points_to_inr_rate cleanly using NUMERIC math
  IF TG_OP = 'INSERT' THEN
    IF NEW.points_per_currency_unit IS NULL OR NEW.points_per_currency_unit <= 0 OR NEW.points_per_currency_unit > 10000 THEN
      RAISE EXCEPTION 'INVALID_RATE: Points per ₹1.00 must be greater than 0 and at most 10,000.';
    END IF;
    NEW.points_per_currency_unit := ROUND(NEW.points_per_currency_unit::numeric, 4);
    NEW.points_to_inr_rate := ROUND((1::numeric / NEW.points_per_currency_unit::numeric), 6);
  ELSE
    IF OLD.points_per_currency_unit IS DISTINCT FROM NEW.points_per_currency_unit THEN
      IF NEW.points_per_currency_unit IS NULL OR NEW.points_per_currency_unit <= 0 OR NEW.points_per_currency_unit > 10000 THEN
        RAISE EXCEPTION 'INVALID_RATE: Points per ₹1.00 must be greater than 0 and at most 10,000.';
      END IF;
      NEW.points_per_currency_unit := ROUND(NEW.points_per_currency_unit::numeric, 4);
      NEW.points_to_inr_rate := ROUND((1::numeric / NEW.points_per_currency_unit::numeric), 6);
    ELSIF OLD.points_to_inr_rate IS DISTINCT FROM NEW.points_to_inr_rate THEN
      IF NEW.points_to_inr_rate IS NULL OR NEW.points_to_inr_rate <= 0 OR NEW.points_to_inr_rate > 100 THEN
        RAISE EXCEPTION 'INVALID_RATE: Points-to-INR rate must be between 0.0001 and 100.';
      END IF;
      NEW.points_to_inr_rate := ROUND(NEW.points_to_inr_rate::numeric, 6);
      NEW.points_per_currency_unit := ROUND((1::numeric / NEW.points_to_inr_rate::numeric), 4);
    END IF;
  END IF;

  -- Enforce fixed system rules that admins cannot override
  NEW.currency_code := 'INR';
  NEW.streak_duration_days := 7;
  NEW.lock_duration_days := 7;
  NEW.eligibility_scans_per_cycle := 1;
  NEW.timezone := 'Asia/Kolkata';
  NEW.daily_reset_time := '06:00:00'::time;
  NEW.updated_at := NOW();

  IF v_uid IS NOT NULL THEN
    NEW.updated_by := v_uid;
  END IF;

  RETURN NEW;
END;
$$;

-- 4. Historical Rate Snapshot Columns & Immutability Protection on public.point_transactions
ALTER TABLE public.point_transactions
  ADD COLUMN IF NOT EXISTS points_per_currency_unit NUMERIC(12, 4),
  ADD COLUMN IF NOT EXISTS points_to_inr_rate NUMERIC(12, 6),
  ADD COLUMN IF NOT EXISTS cash_value NUMERIC(12, 2),
  ADD COLUMN IF NOT EXISTS currency_code TEXT DEFAULT 'INR',
  ADD COLUMN IF NOT EXISTS rate_version_id UUID REFERENCES public.points_to_cash_rate_history(id) ON DELETE SET NULL;

-- Backfill existing historical rows cleanly before enforcing immutability trigger
UPDATE public.point_transactions t
SET
  points_per_currency_unit = COALESCE(
    NULLIF(t.metadata->>'points_per_currency_unit', '')::numeric(12, 4),
    CASE
      WHEN COALESCE(NULLIF(t.metadata->>'rate', '')::numeric, 0) > 0
        THEN ROUND((1::numeric / (t.metadata->>'rate')::numeric), 4)
      ELSE 10.0000
    END
  ),
  points_to_inr_rate = COALESCE(
    NULLIF(t.metadata->>'rate', '')::numeric(12, 6),
    0.100000
  ),
  cash_value = COALESCE(
    NULLIF(t.metadata->>'inr_equivalent', '')::numeric(12, 2),
    ROUND((ABS(t.points_delta)::numeric * COALESCE(NULLIF(t.metadata->>'rate', '')::numeric, 0.100000)), 2)
  ),
  currency_code = COALESCE(NULLIF(t.metadata->>'currency_code', ''), 'INR'),
  rate_version_id = COALESCE(
    t.rate_version_id,
    (SELECT h.id FROM public.points_to_cash_rate_history h ORDER BY h.created_at ASC LIMIT 1)
  )
WHERE t.cash_value IS NULL
   OR t.points_per_currency_unit IS NULL
   OR t.points_to_inr_rate IS NULL;

-- Auto-snapshot rate at creation time for any insert into point_transactions if not explicitly supplied
CREATE OR REPLACE FUNCTION private.snapshot_point_transaction_rate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_pts_per_unit NUMERIC(12, 4);
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
  v_version_id UUID;
BEGIN
  IF NEW.points_per_currency_unit IS NULL OR NEW.points_to_inr_rate IS NULL OR NEW.cash_value IS NULL THEN
    SELECT
      COALESCE(rs.points_per_currency_unit, 10.0000),
      COALESCE(rs.points_to_inr_rate, 0.100000),
      COALESCE(rs.currency_code, 'INR')
    INTO v_pts_per_unit, v_rate, v_currency
    FROM public.reward_settings rs
    WHERE rs.singleton_key = 'global'
    LIMIT 1;

    v_pts_per_unit := COALESCE(NEW.points_per_currency_unit, v_pts_per_unit, 10.0000);
    v_rate := COALESCE(NEW.points_to_inr_rate, v_rate, 0.100000);
    v_currency := COALESCE(NEW.currency_code, v_currency, 'INR');

    IF NEW.rate_version_id IS NULL THEN
      SELECT h.id INTO v_version_id
      FROM public.points_to_cash_rate_history h
      ORDER BY h.created_at DESC
      LIMIT 1;
      NEW.rate_version_id := v_version_id;
    END IF;

    NEW.points_per_currency_unit := v_pts_per_unit;
    NEW.points_to_inr_rate := v_rate;
    NEW.currency_code := v_currency;
    IF NEW.cash_value IS NULL THEN
      NEW.cash_value := ROUND((ABS(COALESCE(NEW.points_delta, 0))::numeric / v_pts_per_unit::numeric), 2);
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_snapshot_point_transaction_rate
  BEFORE INSERT ON public.point_transactions
  FOR EACH ROW
  EXECUTE FUNCTION private.snapshot_point_transaction_rate();

-- Enforce immutable ledger snapshot columns on UPDATE or DELETE of point_transactions
CREATE OR REPLACE FUNCTION private.protect_point_transactions_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'IMMUTABLE_LEDGER: Financial point transactions cannot be deleted.';
  END IF;

  IF OLD.user_id IS DISTINCT FROM NEW.user_id
     OR OLD.transaction_type IS DISTINCT FROM NEW.transaction_type
     OR OLD.points_delta IS DISTINCT FROM NEW.points_delta
     OR OLD.points_per_currency_unit IS DISTINCT FROM NEW.points_per_currency_unit
     OR OLD.points_to_inr_rate IS DISTINCT FROM NEW.points_to_inr_rate
     OR OLD.cash_value IS DISTINCT FROM NEW.cash_value
     OR OLD.currency_code IS DISTINCT FROM NEW.currency_code
     OR OLD.rate_version_id IS DISTINCT FROM NEW.rate_version_id
     OR OLD.created_at IS DISTINCT FROM NEW.created_at THEN
    RAISE EXCEPTION 'IMMUTABLE_LEDGER: Historical transaction amounts and conversion rate snapshots cannot be altered.';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_protect_point_transactions_immutability
  BEFORE UPDATE OR DELETE ON public.point_transactions
  FOR EACH ROW
  EXECUTE FUNCTION private.protect_point_transactions_immutability();

-- 5. Central Rate Engine RPCs
CREATE OR REPLACE FUNCTION public.get_points_to_cash_config()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_rs public.reward_settings;
  v_email TEXT;
  v_mfa_configured BOOLEAN;
  v_aal TEXT;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can access valuation settings.';
  END IF;

  SELECT * INTO v_rs
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Global reward settings row is missing.';
  END IF;

  SELECT email INTO v_email
  FROM auth.users
  WHERE id = v_rs.updated_by;

  SELECT EXISTS (
    SELECT 1 FROM auth.mfa_factors f
    WHERE f.user_id = v_uid AND f.status::text = 'verified'
  ) INTO v_mfa_configured;

  v_aal := COALESCE((SELECT auth.jwt())->>'aal', 'aal1');

  RETURN jsonb_build_object(
    'id', v_rs.id,
    'points_per_currency_unit', COALESCE(v_rs.points_per_currency_unit, 10.0000),
    'points_to_inr_rate', COALESCE(v_rs.points_to_inr_rate, 0.100000),
    'currency_code', COALESCE(v_rs.currency_code, 'INR'),
    'effective_at', COALESCE(v_rs.effective_at, v_rs.updated_at),
    'updated_at', v_rs.updated_at,
    'updated_by', v_rs.updated_by,
    'updated_by_email', v_email,
    'mfa_configured', v_mfa_configured,
    'current_aal', v_aal
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_points_to_cash_rate(
  p_points_per_currency_unit NUMERIC,
  p_note TEXT DEFAULT NULL,
  p_factor_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_email TEXT;
  v_aal TEXT;
  v_factor_id UUID;
  v_prev public.reward_settings;
  v_updated public.reward_settings;
  v_new_pts_per_unit NUMERIC(12, 4);
  v_new_rate NUMERIC(12, 6);
  v_clean_note TEXT;
  v_history_id UUID;
BEGIN
  -- 1. Strict admin verification
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can modify the points-to-cash rate.';
  END IF;

  -- 2. Enforce configured 2FA & AAL2 session assurance
  IF p_factor_id IS NOT NULL THEN
    SELECT f.id INTO v_factor_id
    FROM auth.mfa_factors f
    WHERE f.id = p_factor_id
      AND f.user_id = v_uid
      AND f.status::text = 'verified'
    LIMIT 1;
  ELSE
    SELECT f.id INTO v_factor_id
    FROM auth.mfa_factors f
    WHERE f.user_id = v_uid
      AND f.status::text = 'verified'
    ORDER BY f.created_at ASC
    LIMIT 1;
  END IF;

  IF v_factor_id IS NULL THEN
    RAISE EXCEPTION 'MFA_NOT_CONFIGURED: Two-Factor Authentication (2FA) is not configured for your admin account. Configure an authenticator factor before changing conversion rates.';
  END IF;

  v_aal := COALESCE((SELECT auth.jwt())->>'aal', 'aal1');
  IF v_aal <> 'aal2' THEN
    RAISE EXCEPTION 'MFA_REQUIRED: 2FA verification (AAL2) is required to update the points-to-cash conversion rate.';
  END IF;

  -- 3. Validate numeric conversion rate bounds (no zero, negative, or absurd values)
  IF p_points_per_currency_unit IS NULL
     OR p_points_per_currency_unit < 1
     OR p_points_per_currency_unit > 10000 THEN
    RAISE EXCEPTION 'INVALID_RATE: Points per ₹1.00 must be between 1 and 10,000.';
  END IF;

  v_new_pts_per_unit := ROUND(p_points_per_currency_unit::numeric, 4);
  v_new_rate := ROUND((1::numeric / v_new_pts_per_unit::numeric), 6);
  v_clean_note := NULLIF(trim(COALESCE(p_note, '')), '');

  -- 4. Lock global settings row and update atomically
  SELECT * INTO v_prev
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NOT_FOUND: Global reward settings row not found.';
  END IF;

  SELECT email INTO v_email
  FROM auth.users
  WHERE id = v_uid;

  UPDATE public.reward_settings
  SET
    points_per_currency_unit = v_new_pts_per_unit,
    points_to_inr_rate = v_new_rate,
    currency_code = 'INR',
    effective_at = NOW(),
    updated_by = v_uid,
    updated_at = NOW()
  WHERE id = v_prev.id
  RETURNING * INTO v_updated;

  -- 5. Append immutable audit entry
  INSERT INTO public.points_to_cash_rate_history (
    setting_id,
    previous_points_per_currency_unit,
    new_points_per_currency_unit,
    previous_points_to_inr_rate,
    new_points_to_inr_rate,
    currency_code,
    changed_by,
    changed_by_email,
    mfa_verified,
    mfa_factor_id,
    aal_level,
    note,
    effective_at
  ) VALUES (
    v_updated.id,
    v_prev.points_per_currency_unit,
    v_updated.points_per_currency_unit,
    v_prev.points_to_inr_rate,
    v_updated.points_to_inr_rate,
    v_updated.currency_code,
    v_uid,
    COALESCE(v_email, (SELECT auth.jwt())->>'email', 'admin'),
    true,
    v_factor_id,
    v_aal,
    v_clean_note,
    v_updated.effective_at
  )
  RETURNING id INTO v_history_id;

  RETURN jsonb_build_object(
    'id', v_updated.id,
    'history_id', v_history_id,
    'points_per_currency_unit', v_updated.points_per_currency_unit,
    'points_to_inr_rate', v_updated.points_to_inr_rate,
    'currency_code', v_updated.currency_code,
    'effective_at', v_updated.effective_at,
    'updated_at', v_updated.updated_at,
    'updated_by', v_updated.updated_by,
    'updated_by_email', COALESCE(v_email, (SELECT auth.jwt())->>'email', 'admin'),
    'mfa_configured', true,
    'current_aal', v_aal
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_points_to_cash_rate_history(
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_rows JSONB;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view conversion rate audit history.';
  END IF;

  SELECT COALESCE(
    jsonb_agg(
      jsonb_build_object(
        'id', sub.id,
        'version_number', sub.version_number,
        'previous_points_per_currency_unit', sub.previous_points_per_currency_unit,
        'new_points_per_currency_unit', sub.new_points_per_currency_unit,
        'previous_points_to_inr_rate', sub.previous_points_to_inr_rate,
        'new_points_to_inr_rate', sub.new_points_to_inr_rate,
        'currency_code', sub.currency_code,
        'changed_by', sub.changed_by,
        'changed_by_email', sub.changed_by_email,
        'mfa_verified', sub.mfa_verified,
        'mfa_factor_id', sub.mfa_factor_id,
        'aal_level', sub.aal_level,
        'note', sub.note,
        'effective_at', sub.effective_at,
        'created_at', sub.created_at
      )
      ORDER BY sub.created_at DESC, sub.version_number DESC
    ),
    '[]'::jsonb
  )
  INTO v_rows
  FROM (
    SELECT *
    FROM public.points_to_cash_rate_history
    ORDER BY created_at DESC, version_number DESC
    LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 50), 100))
    OFFSET GREATEST(0, COALESCE(p_offset, 0))
  ) sub;

  RETURN v_rows;
END;
$$;

-- 6. Update POS RPCs to use centralized NUMERIC rate & persist immutable snapshots
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
  v_pts_per_unit NUMERIC(12, 4);
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
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
    COALESCE(points_per_currency_unit, 10.0000),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_unit, v_rate, v_currency
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
    'points_per_currency_unit', COALESCE(v_pts_per_unit, 10.0000),
    'points_to_inr_rate', COALESCE(v_rate, 0.100000),
    'currency_code', COALESCE(v_currency, 'INR'),
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
  v_pts_per_unit NUMERIC(12, 4);
  v_rate NUMERIC(12, 6);
  v_currency TEXT;
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

  SELECT
    COALESCE(points_per_currency_unit, 10.0000),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_unit, v_rate, v_currency
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
        'points_per_currency_unit', COALESCE(v_pts_per_unit, 10.0000),
        'points_to_inr_rate', COALESCE(v_rate, 0.100000),
        'currency_code', COALESCE(v_currency, 'INR'),
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
  v_pts_per_unit NUMERIC(12, 4);
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
    SELECT id INTO v_existing_tx_id
    FROM public.point_transactions
    WHERE idempotency_key IN (v_idem || ':instant', v_idem || ':future')
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
  WHERE id = p_customer_id;

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

  -- Fetch authoritative backend conversion rate using exact NUMERIC math
  SELECT
    COALESCE(points_per_currency_unit, 10.0000),
    COALESCE(points_to_inr_rate, 0.100000),
    COALESCE(currency_code, 'INR')
  INTO v_pts_per_unit, v_rate, v_currency
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  v_pts_per_unit := COALESCE(v_pts_per_unit, 10.0000);
  v_rate := COALESCE(v_rate, 0.100000);
  v_currency := COALESCE(v_currency, 'INR');

  SELECT id INTO v_rate_version_id
  FROM public.points_to_cash_rate_history
  ORDER BY created_at DESC, version_number DESC
  LIMIT 1;

  v_instant_cash := ROUND((v_instant::numeric / v_pts_per_unit::numeric), 2);
  v_future_cash := ROUND((v_future::numeric / v_pts_per_unit::numeric), 2);
  v_total_cash := ROUND((v_total::numeric / v_pts_per_unit::numeric), 2);

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
      v_pts_per_unit,
      v_rate,
      v_instant_cash,
      v_currency,
      v_rate_version_id,
      jsonb_build_object(
        'admin_id', v_admin_id,
        'admin_email', v_admin_email,
        'bill_number', v_bill,
        'branch_name', v_branch,
        'qr_token_id', p_token_id,
        'token_code', v_token.token_code,
        'allocation_kind', 'instant',
        'points_per_currency_unit', v_pts_per_unit,
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
      v_pts_per_unit,
      v_rate,
      v_future_cash,
      v_currency,
      v_rate_version_id,
      jsonb_build_object(
        'admin_id', v_admin_id,
        'admin_email', v_admin_email,
        'bill_number', v_bill,
        'branch_name', v_branch,
        'qr_token_id', p_token_id,
        'token_code', v_token.token_code,
        'allocation_id', v_allocation_id,
        'allocation_kind', 'future',
        'points_per_currency_unit', v_pts_per_unit,
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
    'points_per_currency_unit', v_pts_per_unit,
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
  v_pts_per_unit NUMERIC(12, 4);
  v_rate NUMERIC(12, 6);
  v_currency TEXT := 'INR';
  v_rate_version_id UUID;
  v_cash_value NUMERIC(12, 2);
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

  SELECT * INTO v_claim
  FROM public.reward_claims
  WHERE qr_token_id = v_token.id
  LIMIT 1;

  IF FOUND AND COALESCE(v_claim.points_to_inr_rate, 0) > 0 THEN
    -- Preserve pre-locked rate from pending reward_claims if generated under an earlier rate
    v_rate := v_claim.points_to_inr_rate;
    v_pts_per_unit := ROUND((1::numeric / v_rate::numeric), 4);
    IF v_claim.points = v_points AND COALESCE(v_claim.discount_amount, 0) > 0 THEN
      v_cash_value := ROUND(v_claim.discount_amount::numeric, 2);
    END IF;
  ELSE
    SELECT
      COALESCE(points_per_currency_unit, 10.0000),
      COALESCE(points_to_inr_rate, 0.100000),
      COALESCE(currency_code, 'INR')
    INTO v_pts_per_unit, v_rate, v_currency
    FROM public.reward_settings
    WHERE singleton_key = 'global'
    LIMIT 1;
  END IF;

  v_pts_per_unit := COALESCE(v_pts_per_unit, 10.0000);
  v_rate := COALESCE(v_rate, 0.100000);
  v_cash_value := COALESCE(v_cash_value, ROUND((v_points::numeric / v_pts_per_unit::numeric), 2));

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
    v_pts_per_unit,
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
      'points_per_currency_unit', v_pts_per_unit,
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
    'points_per_currency_unit', v_pts_per_unit,
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
  v_rows JSONB;
BEGIN
  v_admin_id := (SELECT auth.uid());
  IF v_admin_id IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view POS scan history.';
  END IF;

  -- Strictly read persisted historical cash_value & snapshot rate per transaction row (never recalculate)
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
        'points_per_currency_unit', sub.points_per_currency_unit,
        'points_to_inr_rate', sub.points_to_inr_rate,
        'currency_code', sub.currency_code,
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
        t.points_per_currency_unit,
        NULLIF(t.metadata->>'points_per_currency_unit', '')::numeric(12, 4),
        10.0000
      ) AS points_per_currency_unit,
      COALESCE(
        t.points_to_inr_rate,
        NULLIF(t.metadata->>'rate', '')::numeric(12, 6),
        0.100000
      ) AS points_to_inr_rate,
      COALESCE(
        t.currency_code,
        NULLIF(t.metadata->>'currency_code', ''),
        'INR'
      ) AS currency_code,
      COALESCE(
        t.cash_value,
        NULLIF(t.metadata->>'inr_equivalent', '')::numeric(12, 2),
        0.00
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

REVOKE ALL ON FUNCTION public.get_points_to_cash_config() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_points_to_cash_config() TO authenticated;

REVOKE ALL ON FUNCTION public.update_points_to_cash_rate(NUMERIC, TEXT, UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_points_to_cash_rate(NUMERIC, TEXT, UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_points_to_cash_rate_history(INTEGER, INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_points_to_cash_rate_history(INTEGER, INTEGER) TO authenticated;
