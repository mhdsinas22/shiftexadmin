-- Migration: 20261116000000_customer_approval_rpc.sql
-- Description: Admin helper function, RPCs for Customer Approval & Rejection, and RLS policies

-- 1. Helper function: verify if authenticated user is in admin_users
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE user_id = auth.uid()
  );
$$;

-- 2. Approve Customer RPC: Atomic server-side operation
CREATE OR REPLACE FUNCTION public.approve_customer(customer_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_id UUID;
  v_updated RECORD;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: only authorized admins can approve customers';
  END IF;

  UPDATE public.profiles
  SET 
    approval_status = 'approved',
    approved_by = v_admin_id,
    approved_at = NOW(),
    rejection_reason = NULL,
    updated_at = NOW()
  WHERE id = customer_id
  RETURNING * INTO v_updated;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer profile with ID % not found', customer_id;
  END IF;

  RETURN to_jsonb(v_updated);
END;
$$;

-- 3. Reject Customer RPC: Atomic server-side operation
CREATE OR REPLACE FUNCTION public.reject_customer(customer_id UUID, reason TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_admin_id UUID;
  v_updated RECORD;
BEGIN
  v_admin_id := auth.uid();
  IF v_admin_id IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: only authorized admins can reject customers';
  END IF;

  IF reason IS NULL OR TRIM(reason) = '' THEN
    RAISE EXCEPTION 'Rejection reason is required';
  END IF;

  UPDATE public.profiles
  SET 
    approval_status = 'rejected',
    approved_by = v_admin_id,
    approved_at = NOW(),
    rejection_reason = TRIM(reason),
    updated_at = NOW()
  WHERE id = customer_id
  RETURNING * INTO v_updated;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer profile with ID % not found', customer_id;
  END IF;

  RETURN to_jsonb(v_updated);
END;
$$;

-- 4. RLS Policy: Allow authorized admins to SELECT from public.profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND policyname = 'Admins can view all profiles'
  ) THEN
    CREATE POLICY "Admins can view all profiles"
      ON public.profiles
      FOR SELECT
      TO authenticated
      USING (public.is_admin());
  END IF;
END $$;

-- 5. RLS Policy: Allow authorized admins to UPDATE public.profiles
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
      AND tablename = 'profiles' 
      AND policyname = 'Admins can update profiles'
  ) THEN
    CREATE POLICY "Admins can update profiles"
      ON public.profiles
      FOR UPDATE
      TO authenticated
      USING (public.is_admin())
      WITH CHECK (public.is_admin());
  END IF;
END $$;
