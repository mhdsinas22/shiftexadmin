-- ============================================================================
-- Migration: 20261118000003_admin_access_and_permissions.sql
-- Purpose : Complete Production Admin Access, Role-Based Permission Engine,
--           Admin Credential Invitations, Owner Lockout Protection & Audit Logs
-- ============================================================================

-- 1. Extend public.admin_users additively (preserving separate admin table)
ALTER TABLE public.admin_users
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'super_admin',
  ADD COLUMN IF NOT EXISTS terminal_assignment TEXT NOT NULL DEFAULT 'ShiftEx Central Control',
  ADD COLUMN IF NOT EXISTS permission_summary TEXT NOT NULL DEFAULT 'All Permissions',
  ADD COLUMN IF NOT EXISTS badge_label TEXT NOT NULL DEFAULT 'All Access',
  ADD COLUMN IF NOT EXISTS is_key_master BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS permissions TEXT[] NOT NULL DEFAULT ARRAY[
    'dashboard.view',
    'users.view',
    'users.approve',
    'users.reject',
    'pos.view',
    'pos.give_reward',
    'pos.verify_claim',
    'ledger.view',
    'ads.manage',
    'settings.view',
    'settings.manage',
    'streak.manage',
    'valuation.manage',
    'admins.view',
    'admins.invite',
    'admins.manage',
    'audit.view'
  ]::TEXT[],
  ADD COLUMN IF NOT EXISTS invited_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Backfill existing admin_users from auth.users & profiles
UPDATE public.admin_users a
SET
  email = COALESCE(NULLIF(a.email, ''), u.email, p.email, 'admin@shiftex.vault'),
  full_name = COALESCE(
    NULLIF(trim(a.full_name), ''),
    NULLIF(trim(p.full_name), ''),
    NULLIF(trim(u.raw_user_meta_data->>'full_name'), ''),
    NULLIF(split_part(COALESCE(u.email, p.email, ''), '@', 1), ''),
    'ShiftEx Admin'
  ),
  updated_at = NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE a.user_id = u.id;

-- Mark earliest Super Admin as Key Master owner if none marked yet
UPDATE public.admin_users
SET
  is_key_master = true,
  role = 'super_admin',
  permission_summary = 'All Permissions',
  badge_label = 'Key Master'
WHERE user_id = (
  SELECT user_id
  FROM public.admin_users
  ORDER BY is_key_master DESC, created_at ASC
  LIMIT 1
);

-- 2. Create public.admin_invitations table
CREATE TABLE IF NOT EXISTS public.admin_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'store_manager', 'auditor')),
  terminal_assignment TEXT NOT NULL DEFAULT 'Term #01',
  permission_summary TEXT NOT NULL DEFAULT 'Verify Only',
  badge_label TEXT NOT NULL DEFAULT 'Verify Only',
  permissions TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  invite_code TEXT NOT NULL UNIQUE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked', 'expired')),
  invited_by UUID NOT NULL REFERENCES auth.users(id),
  invited_by_email TEXT,
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_by UUID REFERENCES auth.users(id),
  accepted_at TIMESTAMPTZ,
  revoked_by UUID REFERENCES auth.users(id),
  revoked_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_invitations_email_status
  ON public.admin_invitations (lower(email), status);

CREATE INDEX IF NOT EXISTS idx_admin_invitations_invited_by
  ON public.admin_invitations (invited_by);

ALTER TABLE public.admin_invitations ENABLE ROW LEVEL SECURITY;

-- 3. Create public.admin_access_audit_logs table
CREATE TABLE IF NOT EXISTS public.admin_access_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id UUID REFERENCES auth.users(id),
  actor_email TEXT,
  target_user_id UUID,
  target_email TEXT,
  action TEXT NOT NULL,
  previous_role TEXT,
  new_role TEXT,
  previous_permissions TEXT[],
  new_permissions TEXT[],
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_access_audit_logs_created_at
  ON public.admin_access_audit_logs (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_access_audit_logs_actor
  ON public.admin_access_audit_logs (actor_user_id);

ALTER TABLE public.admin_access_audit_logs ENABLE ROW LEVEL SECURITY;

-- 4. Update private.is_admin() and add private.has_admin_permission(TEXT)
CREATE OR REPLACE FUNCTION private.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE user_id = (SELECT auth.uid())
      AND COALESCE(status, 'active') = 'active'
  );
$$;

CREATE OR REPLACE FUNCTION private.has_admin_permission(p_permission TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.admin_users
    WHERE user_id = (SELECT auth.uid())
      AND COALESCE(status, 'active') = 'active'
      AND (
        is_key_master = true
        OR role = 'super_admin'
        OR p_permission = ANY(permissions)
      )
  );
$$;

REVOKE ALL ON FUNCTION private.has_admin_permission(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION private.has_admin_permission(TEXT) TO authenticated;

-- RLS Policies for admin_invitations & admin_access_audit_logs
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_invitations'
      AND policyname = 'Admins can view admin invitations'
  ) THEN
    CREATE POLICY "Admins can view admin invitations"
      ON public.admin_invitations
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'admin_access_audit_logs'
      AND policyname = 'Admins can view admin access audit logs'
  ) THEN
    CREATE POLICY "Admins can view admin access audit logs"
      ON public.admin_access_audit_logs
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;
END
$$;

-- 5. Helper to compute default summary & badge for role + permissions
CREATE OR REPLACE FUNCTION private.resolve_admin_role_labels(
  p_role TEXT,
  p_permissions TEXT[],
  p_is_key_master BOOLEAN DEFAULT false
)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_role TEXT := lower(trim(COALESCE(p_role, 'store_manager')));
  v_summary TEXT;
  v_badge TEXT;
BEGIN
  IF p_is_key_master THEN
    RETURN jsonb_build_object(
      'permission_summary', 'All Permissions',
      'badge_label', 'Key Master'
    );
  END IF;

  IF v_role = 'super_admin' THEN
    v_summary := 'All Permissions';
    v_badge := 'Full Access';
  ELSIF v_role = 'store_manager' THEN
    IF 'pos.give_reward' = ANY(p_permissions) AND 'pos.verify_claim' = ANY(p_permissions) THEN
      v_summary := 'POS Reward & Verify';
      v_badge := 'POS Operator';
    ELSIF 'pos.verify_claim' = ANY(p_permissions) THEN
      v_summary := 'Verify Claim Only';
      v_badge := 'Verify Only';
    ELSE
      v_summary := 'Terminal Operations';
      v_badge := 'Verify Only';
    END IF;
  ELSE
    -- auditor
    IF 'users.approve' = ANY(p_permissions) THEN
      v_summary := 'Read-only Ledger';
      v_badge := 'KYC Verify';
    ELSE
      v_summary := 'Read-only Ledger';
      v_badge := 'Audit Only';
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'permission_summary', v_summary,
    'badge_label', v_badge
  );
END;
$$;

-- 6. Claim Pending Invitation Upon Authenticated Admin Login (if invited email matches)
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
  v_invite public.admin_invitations;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Please sign in first.';
  END IF;

  SELECT
    u.email,
    COALESCE(
      NULLIF(trim(p.full_name), ''),
      NULLIF(trim(u.raw_user_meta_data->>'full_name'), ''),
      NULLIF(split_part(COALESCE(u.email, ''), '@', 1), ''),
      'Admin Operator'
    )
  INTO v_email, v_name
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  WHERE u.id = v_uid;

  -- Expire stale invitations
  UPDATE public.admin_invitations
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'pending' AND expires_at <= NOW();

  -- Check if user is already in admin_users
  SELECT * INTO v_admin
  FROM public.admin_users
  WHERE user_id = v_uid;

  IF NOT FOUND AND v_email IS NOT NULL THEN
    -- Check if there is a valid pending invitation for this email
    SELECT * INTO v_invite
    FROM public.admin_invitations
    WHERE lower(email) = lower(v_email)
      AND status = 'pending'
      AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
    FOR UPDATE;

    IF FOUND THEN
      INSERT INTO public.admin_users (
        user_id,
        full_name,
        email,
        role,
        terminal_assignment,
        permission_summary,
        badge_label,
        is_key_master,
        status,
        permissions,
        invited_by
      ) VALUES (
        v_uid,
        COALESCE(NULLIF(trim(v_invite.full_name), ''), v_name),
        v_email,
        v_invite.role,
        v_invite.terminal_assignment,
        v_invite.permission_summary,
        v_invite.badge_label,
        false,
        'active',
        v_invite.permissions,
        v_invite.invited_by
      )
      ON CONFLICT (user_id) DO UPDATE SET
        role = EXCLUDED.role,
        terminal_assignment = EXCLUDED.terminal_assignment,
        permission_summary = EXCLUDED.permission_summary,
        badge_label = EXCLUDED.badge_label,
        status = 'active',
        permissions = EXCLUDED.permissions,
        updated_at = NOW()
      RETURNING * INTO v_admin;

      UPDATE public.admin_invitations
      SET
        status = 'accepted',
        accepted_by = v_uid,
        accepted_at = NOW(),
        updated_at = NOW()
      WHERE id = v_invite.id;

      INSERT INTO public.admin_access_audit_logs (
        actor_user_id,
        actor_email,
        target_user_id,
        target_email,
        action,
        new_role,
        new_permissions,
        note
      ) VALUES (
        v_uid,
        v_email,
        v_uid,
        v_email,
        'ACCEPT_ADMIN_INVITE',
        v_admin.role,
        v_admin.permissions,
        'Accepted invitation ' || v_invite.invite_code
      );
    END IF;
  END IF;

  IF v_admin.user_id IS NULL THEN
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

-- 7. Get Complete Admin Access Overview RPC
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
  v_invitations JSONB := '[]'::jsonb;
  v_audit_logs JSONB := '[]'::jsonb;
BEGIN
  v_uid := (SELECT auth.uid());
  IF v_uid IS NULL OR NOT private.is_admin() THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized console operators can view Admin Access settings.';
  END IF;

  -- Sync current session & expire stale invitations
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
        NULLIF(trim(p.full_name), ''),
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
      'created_at', a.created_at,
      'updated_at', a.updated_at
    ) AS op_row
    FROM public.admin_users a
    LEFT JOIN auth.users u ON u.id = a.user_id
    LEFT JOIN public.profiles p ON p.id = a.user_id
    WHERE a.status <> 'revoked'
    ORDER BY
      (a.user_id = v_uid) DESC,
      a.is_key_master DESC,
      a.created_at ASC
  ) ops;

  SELECT COALESCE(jsonb_agg(inv_row), '[]'::jsonb)
  INTO v_invitations
  FROM (
    SELECT jsonb_build_object(
      'id', i.id,
      'email', i.email,
      'full_name', i.full_name,
      'role', i.role,
      'terminal_assignment', i.terminal_assignment,
      'permission_summary', i.permission_summary,
      'badge_label', i.badge_label,
      'permissions', to_jsonb(i.permissions),
      'invite_code', i.invite_code,
      'status', i.status,
      'invited_by', i.invited_by,
      'invited_by_email', COALESCE(i.invited_by_email, ''),
      'expires_at', i.expires_at,
      'created_at', i.created_at
    ) AS inv_row
    FROM public.admin_invitations i
    WHERE i.status = 'pending'
      AND i.expires_at > NOW()
    ORDER BY i.created_at DESC
  ) invs;

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
    'pending_invitations', v_invitations,
    'audit_logs', v_audit_logs
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_access_overview() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_admin_access_overview() TO authenticated;

-- 8. Invite New Admin Credential RPC
CREATE OR REPLACE FUNCTION public.invite_admin_credential(
  p_full_name TEXT,
  p_email TEXT,
  p_role TEXT,
  p_terminal_assignment TEXT DEFAULT 'Term #01',
  p_permissions TEXT[] DEFAULT NULL,
  p_expiry_hours INTEGER DEFAULT 72
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor_id UUID;
  v_actor_email TEXT;
  v_name TEXT := trim(COALESCE(p_full_name, ''));
  v_email TEXT := lower(trim(COALESCE(p_email, '')));
  v_role TEXT := lower(trim(COALESCE(p_role, 'store_manager')));
  v_terminal TEXT := COALESCE(NULLIF(trim(COALESCE(p_terminal_assignment, '')), ''), 'Term #01');
  v_hours INTEGER := LEAST(GREATEST(COALESCE(p_expiry_hours, 72), 1), 720);
  v_perms TEXT[];
  v_labels JSONB;
  v_summary TEXT;
  v_badge TEXT;
  v_code TEXT;
  v_invite public.admin_invitations;
BEGIN
  v_actor_id := (SELECT auth.uid());
  IF v_actor_id IS NULL OR NOT (
    private.has_admin_permission('admins.invite')
    OR private.has_admin_permission('admins.manage')
  ) THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only Super Admins with invitation permissions can invite new admin credentials.';
  END IF;

  IF length(v_name) < 2 THEN
    RAISE EXCEPTION 'INVALID_NAME: Full name must be at least 2 characters.';
  END IF;

  IF v_email !~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
    RAISE EXCEPTION 'INVALID_EMAIL: Please enter a valid email address.';
  END IF;

  IF v_role NOT IN ('super_admin', 'store_manager', 'auditor') THEN
    RAISE EXCEPTION 'INVALID_ROLE: Role must be super_admin, store_manager, or auditor.';
  END IF;

  -- Check if active admin already exists with this email
  IF EXISTS (
    SELECT 1
    FROM public.admin_users a
    LEFT JOIN auth.users u ON u.id = a.user_id
    WHERE lower(COALESCE(a.email, u.email, '')) = v_email
      AND a.status <> 'revoked'
  ) THEN
    RAISE EXCEPTION 'DUPLICATE_ADMIN: An admin operator with email % is already registered.', v_email;
  END IF;

  -- Expire stale invitations first
  UPDATE public.admin_invitations
  SET status = 'expired', updated_at = NOW()
  WHERE status = 'pending' AND expires_at <= NOW();

  -- Prevent duplicate active invitation
  IF EXISTS (
    SELECT 1
    FROM public.admin_invitations
    WHERE lower(email) = v_email
      AND status = 'pending'
      AND expires_at > NOW()
  ) THEN
    RAISE EXCEPTION 'DUPLICATE_INVITE: A pending invitation for % already exists.', v_email;
  END IF;

  -- Resolve default permissions if omitted
  IF p_permissions IS NULL OR array_length(p_permissions, 1) IS NULL THEN
    IF v_role = 'super_admin' THEN
      v_perms := ARRAY[
        'dashboard.view','users.view','users.approve','users.reject',
        'pos.view','pos.give_reward','pos.verify_claim','ledger.view',
        'ads.manage','settings.view','settings.manage','streak.manage',
        'valuation.manage','admins.view','admins.invite','admins.manage','audit.view'
      ]::TEXT[];
    ELSIF v_role = 'store_manager' THEN
      v_perms := ARRAY[
        'dashboard.view','pos.view','pos.verify_claim','users.view'
      ]::TEXT[];
    ELSE
      v_perms := ARRAY[
        'dashboard.view','ledger.view','audit.view','users.view','users.approve'
      ]::TEXT[];
    END IF;
  ELSE
    v_perms := p_permissions;
  END IF;

  v_labels := private.resolve_admin_role_labels(v_role, v_perms, false);
  v_summary := v_labels->>'permission_summary';
  v_badge := v_labels->>'badge_label';

  v_actor_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');
  v_code := 'ADM-' || upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 4))
            || '-' || upper(substr(encode(extensions.gen_random_bytes(6), 'hex'), 1, 4));

  INSERT INTO public.admin_invitations (
    email,
    full_name,
    role,
    terminal_assignment,
    permission_summary,
    badge_label,
    permissions,
    invite_code,
    status,
    invited_by,
    invited_by_email,
    expires_at
  ) VALUES (
    v_email,
    v_name,
    v_role,
    v_terminal,
    v_summary,
    v_badge,
    v_perms,
    v_code,
    'pending',
    v_actor_id,
    v_actor_email,
    NOW() + make_interval(hours => v_hours)
  )
  RETURNING * INTO v_invite;

  INSERT INTO public.admin_access_audit_logs (
    actor_user_id,
    actor_email,
    target_email,
    action,
    new_role,
    new_permissions,
    note
  ) VALUES (
    v_actor_id,
    v_actor_email,
    v_email,
    'INVITE_ADMIN',
    v_role,
    v_perms,
    'Invited ' || v_name || ' (' || v_role || ' • ' || v_terminal || ') code ' || v_code
  );

  RETURN jsonb_build_object(
    'id', v_invite.id,
    'email', v_invite.email,
    'full_name', v_invite.full_name,
    'role', v_invite.role,
    'terminal_assignment', v_invite.terminal_assignment,
    'permission_summary', v_invite.permission_summary,
    'badge_label', v_invite.badge_label,
    'permissions', to_jsonb(v_invite.permissions),
    'invite_code', v_invite.invite_code,
    'status', v_invite.status,
    'invited_by', v_invite.invited_by,
    'invited_by_email', v_invite.invited_by_email,
    'expires_at', v_invite.expires_at,
    'created_at', v_invite.created_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.invite_admin_credential(TEXT, TEXT, TEXT, TEXT, TEXT[], INTEGER) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.invite_admin_credential(TEXT, TEXT, TEXT, TEXT, TEXT[], INTEGER) TO authenticated;

-- 9. Revoke Admin Invitation RPC
CREATE OR REPLACE FUNCTION public.revoke_admin_invitation(p_invitation_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor_id UUID;
  v_actor_email TEXT;
  v_invite public.admin_invitations;
BEGIN
  v_actor_id := (SELECT auth.uid());
  IF v_actor_id IS NULL OR NOT (
    private.has_admin_permission('admins.manage')
    OR private.has_admin_permission('admins.invite')
  ) THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only authorized Super Admins can revoke invitations.';
  END IF;

  UPDATE public.admin_invitations
  SET
    status = 'revoked',
    revoked_by = v_actor_id,
    revoked_at = NOW(),
    updated_at = NOW()
  WHERE id = p_invitation_id
    AND status = 'pending'
  RETURNING * INTO v_invite;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INVITATION_NOT_FOUND: Pending invitation not found or already processed.';
  END IF;

  v_actor_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');

  INSERT INTO public.admin_access_audit_logs (
    actor_user_id,
    actor_email,
    target_email,
    action,
    previous_role,
    note
  ) VALUES (
    v_actor_id,
    v_actor_email,
    v_invite.email,
    'REVOKE_INVITATION',
    v_invite.role,
    'Revoked invitation ' || v_invite.invite_code || ' for ' || v_invite.email
  );

  RETURN jsonb_build_object(
    'success', true,
    'invitation_id', v_invite.id,
    'status', v_invite.status
  );
END;
$$;

REVOKE ALL ON FUNCTION public.revoke_admin_invitation(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.revoke_admin_invitation(UUID) TO authenticated;

-- 10. Update Admin Operator Role, Terminal, Permissions & Status RPC
CREATE OR REPLACE FUNCTION public.update_admin_operator_permissions(
  p_target_user_id UUID,
  p_role TEXT,
  p_terminal_assignment TEXT,
  p_permissions TEXT[],
  p_status TEXT DEFAULT 'active'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor_id UUID;
  v_actor_email TEXT;
  v_target public.admin_users;
  v_updated public.admin_users;
  v_role TEXT := lower(trim(COALESCE(p_role, 'store_manager')));
  v_status TEXT := lower(trim(COALESCE(p_status, 'active')));
  v_terminal TEXT := COALESCE(NULLIF(trim(COALESCE(p_terminal_assignment, '')), ''), 'ShiftEx Central Control');
  v_labels JSONB;
BEGIN
  v_actor_id := (SELECT auth.uid());
  IF v_actor_id IS NULL OR NOT private.has_admin_permission('admins.manage') THEN
    RAISE EXCEPTION 'UNAUTHORIZED: Only Super Admins with admins.manage permission can modify operator permissions.';
  END IF;

  IF v_role NOT IN ('super_admin', 'store_manager', 'auditor') THEN
    RAISE EXCEPTION 'INVALID_ROLE: Invalid role specified.';
  END IF;

  IF v_status NOT IN ('active', 'suspended', 'revoked') THEN
    RAISE EXCEPTION 'INVALID_STATUS: Invalid account status specified.';
  END IF;

  SELECT * INTO v_target
  FROM public.admin_users
  WHERE user_id = p_target_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'OPERATOR_NOT_FOUND: Console operator not found.';
  END IF;

  -- Protect Key Master primary owner from demotion, suspension, or lockout
  IF v_target.is_key_master THEN
    IF v_role <> 'super_admin' OR v_status <> 'active' OR NOT ('admins.manage' = ANY(p_permissions)) THEN
      RAISE EXCEPTION 'OWNER_PROTECTED: The primary Key Master owner account cannot be demoted, suspended, or stripped of administrative permissions.';
    END IF;
  END IF;

  -- Protect current admin against accidental self-lockout
  IF p_target_user_id = v_actor_id THEN
    IF v_status <> 'active' OR v_role <> 'super_admin' OR NOT ('admins.manage' = ANY(p_permissions)) THEN
      RAISE EXCEPTION 'SELF_LOCKOUT_PREVENTED: You cannot demote, suspend, or remove admin management permissions from your own account.';
    END IF;
  END IF;

  v_labels := private.resolve_admin_role_labels(v_role, p_permissions, v_target.is_key_master);

  UPDATE public.admin_users
  SET
    role = v_role,
    terminal_assignment = v_terminal,
    permission_summary = v_labels->>'permission_summary',
    badge_label = CASE WHEN v_target.is_key_master THEN 'Key Master' ELSE (v_labels->>'badge_label') END,
    permissions = p_permissions,
    status = v_status,
    updated_at = NOW()
  WHERE user_id = p_target_user_id
  RETURNING * INTO v_updated;

  v_actor_email := COALESCE((SELECT auth.jwt())->>'email', 'admin');

  INSERT INTO public.admin_access_audit_logs (
    actor_user_id,
    actor_email,
    target_user_id,
    target_email,
    action,
    previous_role,
    new_role,
    previous_permissions,
    new_permissions,
    note
  ) VALUES (
    v_actor_id,
    v_actor_email,
    v_updated.user_id,
    v_updated.email,
    CASE
      WHEN v_status = 'suspended' THEN 'SUSPEND_ADMIN'
      WHEN v_status = 'revoked' THEN 'REVOKE_ADMIN'
      ELSE 'UPDATE_ADMIN_PERMISSIONS'
    END,
    v_target.role,
    v_updated.role,
    v_target.permissions,
    v_updated.permissions,
    'Updated ' || COALESCE(v_updated.full_name, v_updated.email, 'operator')
      || ' to ' || v_updated.role || ' (' || v_updated.status || ')'
  );

  RETURN jsonb_build_object(
    'user_id', v_updated.user_id,
    'full_name', v_updated.full_name,
    'email', v_updated.email,
    'role', v_updated.role,
    'terminal_assignment', v_updated.terminal_assignment,
    'permission_summary', v_updated.permission_summary,
    'badge_label', v_updated.badge_label,
    'is_key_master', v_updated.is_key_master,
    'status', v_updated.status,
    'permissions', to_jsonb(v_updated.permissions),
    'updated_at', v_updated.updated_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.update_admin_operator_permissions(UUID, TEXT, TEXT, TEXT[], TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_admin_operator_permissions(UUID, TEXT, TEXT, TEXT[], TEXT) TO authenticated;
