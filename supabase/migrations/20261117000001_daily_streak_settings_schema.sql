-- Migration: 20261117000001_daily_streak_settings_schema.sql
-- Description: Daily Login Streak configuration on reward_settings, audit logs,
--              check-in analytics ledger, strict admin-only RLS, and RPCs.

-- 1. Create or safely extend public.reward_settings
CREATE TABLE IF NOT EXISTS public.reward_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  singleton_key TEXT NOT NULL DEFAULT 'global' UNIQUE CHECK (singleton_key = 'global'),
  daily_login_enabled BOOLEAN NOT NULL DEFAULT true,
  daily_login_points INTEGER NOT NULL DEFAULT 15 CHECK (daily_login_points >= 1 AND daily_login_points <= 1000),
  streak_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (streak_duration_days = 7),
  lock_duration_days INTEGER NOT NULL DEFAULT 7 CHECK (lock_duration_days = 7),
  eligibility_scans_per_cycle INTEGER NOT NULL DEFAULT 1 CHECK (eligibility_scans_per_cycle = 1),
  timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata' CHECK (timezone = 'Asia/Kolkata'),
  daily_reset_time TIME NOT NULL DEFAULT '06:00:00'::time CHECK (daily_reset_time = '06:00:00'::time),
  points_to_inr_rate NUMERIC(10, 4) NOT NULL DEFAULT 0.1000,
  updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure columns exist if reward_settings already existed in another environment
ALTER TABLE public.reward_settings
  ADD COLUMN IF NOT EXISTS singleton_key TEXT NOT NULL DEFAULT 'global',
  ADD COLUMN IF NOT EXISTS daily_login_enabled BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS daily_login_points INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS streak_duration_days INTEGER NOT NULL DEFAULT 7,
  ADD COLUMN IF NOT EXISTS lock_duration_days INTEGER NOT NULL DEFAULT 7,
  ADD COLUMN IF NOT EXISTS eligibility_scans_per_cycle INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS timezone TEXT NOT NULL DEFAULT 'Asia/Kolkata',
  ADD COLUMN IF NOT EXISTS daily_reset_time TIME NOT NULL DEFAULT '06:00:00'::time,
  ADD COLUMN IF NOT EXISTS points_to_inr_rate NUMERIC(10, 4) NOT NULL DEFAULT 0.1000,
  ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Seed default singleton configuration if empty
INSERT INTO public.reward_settings (
  singleton_key,
  daily_login_enabled,
  daily_login_points,
  streak_duration_days,
  lock_duration_days,
  eligibility_scans_per_cycle,
  timezone,
  daily_reset_time,
  points_to_inr_rate
) VALUES (
  'global',
  true,
  15,
  7,
  7,
  1,
  'Asia/Kolkata',
  '06:00:00'::time,
  0.1000
)
ON CONFLICT (singleton_key) DO NOTHING;

-- 2. Trigger function in private schema to enforce fixed system rules & admin protection
CREATE OR REPLACE FUNCTION private.protect_reward_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  IF current_user IN ('authenticated', 'anon') AND NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only administrators can modify reward settings.';
  END IF;

  IF NEW.daily_login_points IS NULL OR NEW.daily_login_points < 1 OR NEW.daily_login_points > 1000 THEN
    RAISE EXCEPTION 'INVALID_POINTS: Points per daily check-in must be between 1 and 1000.';
  END IF;

  -- Enforce fixed system rules that admins cannot override
  NEW.streak_duration_days := 7;
  NEW.lock_duration_days := 7;
  NEW.eligibility_scans_per_cycle := 1;
  NEW.timezone := 'Asia/Kolkata';
  NEW.daily_reset_time := '06:00:00'::time;
  NEW.updated_at := NOW();

  IF auth.uid() IS NOT NULL THEN
    NEW.updated_by := auth.uid();
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_reward_settings ON public.reward_settings;
CREATE TRIGGER trg_protect_reward_settings
  BEFORE INSERT OR UPDATE ON public.reward_settings
  FOR EACH ROW
  EXECUTE FUNCTION private.protect_reward_settings();

-- 3. RLS for public.reward_settings
ALTER TABLE public.reward_settings ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'reward_settings'
      AND policyname = 'Authenticated users can read reward settings'
  ) THEN
    CREATE POLICY "Authenticated users can read reward settings"
      ON public.reward_settings
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'reward_settings'
      AND policyname = 'Admins can insert reward settings'
  ) THEN
    CREATE POLICY "Admins can insert reward settings"
      ON public.reward_settings
      FOR INSERT
      TO authenticated
      WITH CHECK (private.is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'reward_settings'
      AND policyname = 'Admins can update reward settings'
  ) THEN
    CREATE POLICY "Admins can update reward settings"
      ON public.reward_settings
      FOR UPDATE
      TO authenticated
      USING (private.is_admin())
      WITH CHECK (private.is_admin());
  END IF;
END $$;

-- 4. Audit Logs Table for Daily Streak Rule Changes
CREATE TABLE IF NOT EXISTS public.reward_settings_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key TEXT NOT NULL DEFAULT 'daily_login_streak',
  previous_enabled BOOLEAN,
  new_enabled BOOLEAN NOT NULL,
  previous_points INTEGER,
  new_points INTEGER NOT NULL,
  changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  changed_by_email TEXT,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_reward_settings_audit_created_at
  ON public.reward_settings_audit_logs (created_at DESC);

ALTER TABLE public.reward_settings_audit_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'reward_settings_audit_logs'
      AND policyname = 'Admins can view reward settings audit logs'
  ) THEN
    CREATE POLICY "Admins can view reward settings audit logs"
      ON public.reward_settings_audit_logs
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'reward_settings_audit_logs'
      AND policyname = 'Admins can insert reward settings audit logs'
  ) THEN
    CREATE POLICY "Admins can insert reward settings audit logs"
      ON public.reward_settings_audit_logs
      FOR INSERT
      TO authenticated
      WITH CHECK (private.is_admin());
  END IF;
END $$;

-- 5. Daily Streak Check-ins Ledger Table (preserves future customer check-in & 7-day individual unlock rules)
CREATE TABLE IF NOT EXISTS public.daily_streak_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_date DATE NOT NULL,
  streak_day INTEGER NOT NULL CHECK (streak_day >= 1 AND streak_day <= 7),
  points_awarded INTEGER NOT NULL CHECK (points_awarded > 0),
  checkin_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlock_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  is_unlocked BOOLEAN NOT NULL DEFAULT false,
  unlocked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, cycle_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_streak_checkins_user_cycle
  ON public.daily_streak_checkins (user_id, cycle_date DESC);

CREATE INDEX IF NOT EXISTS idx_daily_streak_checkins_checkin_at
  ON public.daily_streak_checkins (checkin_at DESC);

CREATE INDEX IF NOT EXISTS idx_daily_streak_checkins_pending_unlock
  ON public.daily_streak_checkins (unlock_at)
  WHERE is_unlocked = false;

ALTER TABLE public.daily_streak_checkins ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'daily_streak_checkins'
      AND policyname = 'Admins can view all daily streak checkins'
  ) THEN
    CREATE POLICY "Admins can view all daily streak checkins"
      ON public.daily_streak_checkins
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'daily_streak_checkins'
      AND policyname = 'Customers can view own daily streak checkins'
  ) THEN
    CREATE POLICY "Customers can view own daily streak checkins"
      ON public.daily_streak_checkins
      FOR SELECT
      TO authenticated
      USING ((SELECT auth.uid()) = user_id);
  END IF;
END $$;

-- 6. Admin RPC: Atomically update daily streak settings + record audit log
CREATE OR REPLACE FUNCTION public.update_daily_streak_settings(
  p_enabled BOOLEAN,
  p_points INTEGER,
  p_note TEXT DEFAULT NULL
)
RETURNS public.reward_settings
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_email TEXT;
  v_prev public.reward_settings;
  v_updated public.reward_settings;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can modify daily streak settings.';
  END IF;

  IF p_points IS NULL OR p_points < 1 OR p_points > 1000 THEN
    RAISE EXCEPTION 'INVALID_POINTS: Points per daily check-in must be between 1 and 1000.';
  END IF;

  SELECT * INTO v_prev
  FROM public.reward_settings
  WHERE singleton_key = 'global'
  LIMIT 1;

  IF NOT FOUND THEN
    INSERT INTO public.reward_settings (
      singleton_key,
      daily_login_enabled,
      daily_login_points,
      updated_by
    ) VALUES (
      'global',
      p_enabled,
      p_points,
      v_uid
    )
    RETURNING * INTO v_updated;
  ELSE
    UPDATE public.reward_settings
    SET
      daily_login_enabled = p_enabled,
      daily_login_points = p_points,
      updated_by = v_uid,
      updated_at = NOW()
    WHERE id = v_prev.id
    RETURNING * INTO v_updated;
  END IF;

  v_email := COALESCE(
    (SELECT auth.jwt())->>'email',
    'admin'
  );

  INSERT INTO public.reward_settings_audit_logs (
    setting_key,
    previous_enabled,
    new_enabled,
    previous_points,
    new_points,
    changed_by,
    changed_by_email,
    note
  ) VALUES (
    'daily_login_streak',
    v_prev.daily_login_enabled,
    v_updated.daily_login_enabled,
    v_prev.daily_login_points,
    v_updated.daily_login_points,
    v_uid,
    v_email,
    p_note
  );

  RETURN v_updated;
END;
$$;

-- 7. Admin RPC: Real database statistics for Daily Login Streak
CREATE OR REPLACE FUNCTION public.get_daily_streak_statistics()
RETURNS TABLE (
  total_points_distributed BIGINT,
  distributed_points_30d BIGINT,
  active_streakers BIGINT,
  completion_rate_7d NUMERIC,
  completed_streaks_30d BIGINT,
  total_checkins_count BIGINT,
  analytics_available BOOLEAN,
  current_cycle_date DATE
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_cycle_date DATE;
  v_total_points BIGINT;
  v_points_30d BIGINT;
  v_active_streakers BIGINT;
  v_completed_30d BIGINT;
  v_participants_30d BIGINT;
  v_total_checkins BIGINT;
  v_completion_rate NUMERIC;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized admins can view daily streak statistics.';
  END IF;

  -- Current daily cycle date in Asia/Kolkata with 06:00 AM reset boundary
  v_cycle_date := ((NOW() AT TIME ZONE 'Asia/Kolkata') - INTERVAL '6 hours')::date;

  SELECT
    COALESCE(SUM(c.points_awarded), 0),
    COALESCE(SUM(c.points_awarded) FILTER (WHERE c.checkin_at >= NOW() - INTERVAL '30 days'), 0),
    COUNT(DISTINCT c.user_id) FILTER (WHERE c.cycle_date >= (v_cycle_date - 1)),
    COUNT(*) FILTER (WHERE c.streak_day = 7 AND c.checkin_at >= NOW() - INTERVAL '30 days'),
    COUNT(DISTINCT c.user_id) FILTER (WHERE c.checkin_at >= NOW() - INTERVAL '30 days'),
    COUNT(*)
  INTO
    v_total_points,
    v_points_30d,
    v_active_streakers,
    v_completed_30d,
    v_participants_30d,
    v_total_checkins
  FROM public.daily_streak_checkins c;

  IF v_participants_30d > 0 THEN
    v_completion_rate := ROUND((v_completed_30d::numeric / v_participants_30d::numeric) * 100.0, 1);
    IF v_completion_rate > 100 THEN
      v_completion_rate := 100.0;
    END IF;
  ELSE
    v_completion_rate := 0.0;
  END IF;

  RETURN QUERY SELECT
    v_total_points,
    v_points_30d,
    v_active_streakers,
    v_completion_rate,
    v_completed_30d,
    v_total_checkins,
    (v_total_checkins > 0),
    v_cycle_date;
END;
$$;

REVOKE ALL ON FUNCTION public.update_daily_streak_settings(BOOLEAN, INTEGER, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_daily_streak_settings(BOOLEAN, INTEGER, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.get_daily_streak_statistics() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_daily_streak_statistics() TO authenticated;
