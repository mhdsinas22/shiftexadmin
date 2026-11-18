-- ============================================================================
-- Migration: 20261118000004_direct_admin_account_creation.sql
-- Purpose : Direct Admin Account Creation Support, Separate Admin/Customer
--           Auth Trigger Isolation, and Removal of Invitation-Based Login Claim
-- ============================================================================

-- 1. Add created_by column to public.admin_users
ALTER TABLE public.admin_users
  ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

CREATE INDEX IF NOT EXISTS idx_admin_users_created_by
  ON public.admin_users (created_by);

CREATE INDEX IF NOT EXISTS idx_admin_users_email_lower
  ON public.admin_users (lower(email));

-- 2. Isolate Admin accounts from Customer profiles in auth.users trigger
--    When an Admin account is created via the Edge Function using service_role
--    (which sets raw_app_meta_data->>'is_admin_account' = 'true'), do NOT create
--    a customer row in public.profiles.
CREATE OR REPLACE FUNCTION private.handle_verified_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_full_name text;
  v_mobile text;
  v_email text;
BEGIN
  -- Admin accounts created via Admin API have app_metadata.is_admin_account = true.
  -- Keep Admin accounts strictly separate from customer profiles.
  IF COALESCE((NEW.raw_app_meta_data->>'is_admin_account')::boolean, false) THEN
    RETURN NEW;
  END IF;

  IF NEW.email_confirmed_at IS NOT NULL AND NEW.email IS NOT NULL THEN
    v_email := lower(trim(NEW.email));
    v_full_name := trim(COALESCE(
      NULLIF(trim(NEW.raw_user_meta_data->>'full_name'), ''),
      NULLIF(trim(concat_ws(' ', NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'last_name')), ''),
      split_part(v_email, '@', 1)
    ));
    v_mobile := private.normalize_mobile(COALESCE(
      NULLIF(trim(NEW.raw_user_meta_data->>'mobile_number'), ''),
      NULLIF(trim(NEW.phone), ''),
      '+910000000000'
    ));

    INSERT INTO public.profiles (
      id,
      full_name,
      email,
      mobile_number,
      approval_status,
      created_at,
      updated_at
    ) VALUES (
      NEW.id,
      v_full_name,
      v_email,
      v_mobile,
      'pending',
      now(),
      now()
    )
    ON CONFLICT (id) DO UPDATE
    SET
      email = EXCLUDED.email,
      full_name = CASE
        WHEN public.profiles.full_name = '' THEN EXCLUDED.full_name
        ELSE public.profiles.full_name
      END,
      mobile_number = CASE
        WHEN public.profiles.mobile_number IN ('', '+910000000000') THEN EXCLUDED.mobile_number
        ELSE public.profiles.mobile_number
      END,
      updated_at = now();
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Update verify_and_sync_admin_session to strictly verify active admin_users record
--    without any email invitation workflow
CREATE OR REPLACE FUNCTION public.verify_and_sync_admin_session()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_email TEXT;
  v_name TEXT;
  v_admin public.admin_users;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Please sign in first.';
  END IF;

  SELECT
    u.email,
    COALESCE(
      NULLIF(trim(u.raw_user_meta_data->>'full_name'), ''),
      NULLIF(split_part(COALESCE(u.email, ''), '@', 1), ''),
      'Admin Operator'
    )
  INTO v_email, v_name
  FROM auth.users u
  WHERE u.id = v_uid;

  SELECT * INTO v_admin
  FROM public.admin_users
  WHERE user_id = v_uid;

  IF NOT FOUND OR v_admin.user_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHORIZED: You are not authorized to access the SHIIFTEX Admin Console.';
  END IF;

  IF v_admin.status <> 'active' THEN
    RAISE EXCEPTION 'ACCOUNT_SUSPENDED: Your admin credential has been % by a Super Admin.', v_admin.status;
  END IF;

  RETURN jsonb_build_object(
    'user_id', v_admin.user_id,
    'full_name', COALESCE(NULLIF(trim(v_admin.full_name), ''), v_name),
    'email', COALESCE(NULLIF(trim(v_admin.email), ''), v_email),
    'role', v_admin.role,
    'terminal_assignment', v_admin.terminal_assignment,
    'permission_summary', v_admin.permission_summary,
    'badge_label', v_admin.badge_label,
    'is_key_master', v_admin.is_key_master,
    'status', v_admin.status,
    'permissions', to_jsonb(v_admin.permissions),
    'created_at', v_admin.created_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.verify_and_sync_admin_session() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.verify_and_sync_admin_session() TO authenticated;

-- 4. Update get_admin_access_overview() to return direct operators & audit logs
CREATE OR REPLACE FUNCTION public.get_admin_access_overview()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_uid UUID;
  v_current_admin JSONB;
  v_operators JSONB := '[]'::jsonb;
  v_operators_count INTEGER := 0;
  v_audit_logs JSONB := '[]'::jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized console operators can view Admin Access settings.';
  END IF;

  v_current_admin := public.verify_and_sync_admin_session();

  SELECT COUNT(*)::INTEGER
  INTO v_operators_count
  FROM public.admin_users
  WHERE status <> 'revoked';

  SELECT COALESCE(jsonb_agg(op_row), '[]'::jsonb)
  INTO v_operators
  FROM (
    SELECT jsonb_build_object(
      'user_id', a.user_id,
      'full_name', COALESCE(
        NULLIF(trim(a.full_name), ''),
        NULLIF(trim(u.raw_user_meta_data->>'full_name'), ''),
        NULLIF(split_part(COALESCE(a.email, u.email, ''), '@', 1), ''),
        'Admin Operator'
      ),
      'email', COALESCE(NULLIF(trim(a.email), ''), u.email, ''),
      'role', a.role,
      'terminal_assignment', a.terminal_assignment,
      'permission_summary', a.permission_summary,
      'badge_label', CASE WHEN a.is_key_master THEN 'Key Master' ELSE a.badge_label END,
      'is_key_master', a.is_key_master,
      'is_current_user', (a.user_id = v_uid),
      'status', a.status,
      'permissions', to_jsonb(a.permissions),
      'created_by', COALESCE(a.created_by, a.invited_by),
      'created_at', a.created_at,
      'updated_at', a.updated_at
    ) AS op_row
    FROM public.admin_users a
    LEFT JOIN auth.users u ON u.id = a.user_id
    WHERE a.status <> 'revoked'
    ORDER BY
      (a.user_id = v_uid) DESC,
      a.is_key_master DESC,
      a.created_at ASC
  ) ops;

  SELECT COALESCE(jsonb_agg(log_row), '[]'::jsonb)
  INTO v_audit_logs
  FROM (
    SELECT jsonb_build_object(
      'id', l.id,
      'actor_user_id', l.actor_user_id,
      'actor_email', COALESCE(l.actor_email, ''),
      'target_user_id', l.target_user_id,
      'target_email', COALESCE(l.target_email, ''),
      'action', l.action,
      'previous_role', l.previous_role,
      'new_role', l.new_role,
      'previous_permissions', to_jsonb(COALESCE(l.previous_permissions, '{}'::TEXT[])),
      'new_permissions', to_jsonb(COALESCE(l.new_permissions, '{}'::TEXT[])),
      'note', COALESCE(l.note, ''),
      'created_at', l.created_at
    ) AS log_row
    FROM public.admin_access_audit_logs l
    ORDER BY l.created_at DESC
    LIMIT 15
  ) logs;

  RETURN jsonb_build_object(
    'current_admin', v_current_admin,
    'operators_count', v_operators_count,
    'operators', v_operators,
    'audit_logs', v_audit_logs
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_access_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_admin_access_overview() TO authenticated;
