-- Migration: 20261116000001_advertisements_schema.sql
-- Description: Production-ready Advertisements & Events schema, RLS, Storage bucket, and delivery RPCs

-- 1. Create advertisements table
CREATE TABLE IF NOT EXISTS public.advertisements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  offer_details TEXT NOT NULL,
  image_url TEXT,
  image_path TEXT,
  popup_duration_seconds INTEGER NOT NULL DEFAULT 6,
  frequency_type TEXT NOT NULL DEFAULT 'once_per_session', -- once_per_session, once_per_day, once_per_user, custom
  frequency_limit INTEGER NOT NULL DEFAULT 1,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'draft', -- draft, scheduled, published, deactivated
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  deactivated_at TIMESTAMPTZ
);

-- Index for querying active ads and date ranges
CREATE INDEX IF NOT EXISTS idx_ads_status_dates ON public.advertisements (status, start_at, end_at);
CREATE INDEX IF NOT EXISTS idx_ads_created_at ON public.advertisements (created_at DESC);

-- 2. Create advertisement_events table (Analytics)
CREATE TABLE IF NOT EXISTS public.advertisement_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  advertisement_id UUID NOT NULL REFERENCES public.advertisements(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL, -- impression, click, claim
  session_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ad_events_ad_id ON public.advertisement_events (advertisement_id);
CREATE INDEX IF NOT EXISTS idx_ad_events_type_created ON public.advertisement_events (event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ad_events_user_session ON public.advertisement_events (advertisement_id, user_id, session_id);

-- 3. Enable RLS
ALTER TABLE public.advertisements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advertisement_events ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for advertisements
DO $$
BEGIN
  -- Admin full access
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'advertisements' AND policyname = 'Admins full access on advertisements'
  ) THEN
    CREATE POLICY "Admins full access on advertisements"
      ON public.advertisements
      FOR ALL
      TO authenticated
      USING (private.is_admin())
      WITH CHECK (private.is_admin());
  END IF;

  -- Customers can read published & active advertisements
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'advertisements' AND policyname = 'Public and customers can view active published ads'
  ) THEN
    CREATE POLICY "Public and customers can view active published ads"
      ON public.advertisements
      FOR SELECT
      TO authenticated, anon
      USING (
        status = 'published'
        AND start_at <= NOW()
        AND end_at >= NOW()
        AND deactivated_at IS NULL
      );
  END IF;
END $$;

-- 5. RLS Policies for advertisement_events
DO $$
BEGIN
  -- Admins can view all events
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'advertisement_events' AND policyname = 'Admins can view all advertisement events'
  ) THEN
    CREATE POLICY "Admins can view all advertisement events"
      ON public.advertisement_events
      FOR SELECT
      TO authenticated
      USING (private.is_admin());
  END IF;

  -- Anyone (or authenticated customer) can insert impression / click / claim events
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'advertisement_events' AND policyname = 'Customers can record ad events'
  ) THEN
    CREATE POLICY "Customers can record ad events"
      ON public.advertisement_events
      FOR INSERT
      TO authenticated, anon
      WITH CHECK (true);
  END IF;
END $$;

-- 6. Storage Bucket for Advertisements
INSERT INTO storage.buckets (id, name, public)
VALUES ('advertisements', 'advertisements', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Public can view images
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public can view advertisement images'
  ) THEN
    CREATE POLICY "Public can view advertisement images"
      ON storage.objects FOR SELECT
      TO public
      USING (bucket_id = 'advertisements');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Admins can manage advertisement images'
  ) THEN
    CREATE POLICY "Admins can manage advertisement images"
      ON storage.objects FOR ALL
      TO authenticated
      USING (bucket_id = 'advertisements' AND private.is_admin())
      WITH CHECK (bucket_id = 'advertisements' AND private.is_admin());
  END IF;
END $$;

-- 7. Customer Delivery RPC: get_active_customer_advertisements
CREATE OR REPLACE FUNCTION public.get_active_customer_advertisements(
  p_customer_id UUID DEFAULT NULL,
  p_session_id TEXT DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  offer_details TEXT,
  image_url TEXT,
  popup_duration_seconds INTEGER,
  frequency_type TEXT,
  frequency_limit INTEGER,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.title,
    a.offer_details,
    a.image_url,
    a.popup_duration_seconds,
    a.frequency_type,
    a.frequency_limit,
    a.start_at,
    a.end_at
  FROM public.advertisements a
  WHERE a.status = 'published'
    AND a.start_at <= NOW()
    AND a.end_at >= NOW()
    AND a.deactivated_at IS NULL
    -- Frequency check: session cap
    AND (
      a.frequency_type != 'once_per_session' 
      OR p_session_id IS NULL 
      OR NOT EXISTS (
        SELECT 1 FROM public.advertisement_events e
        WHERE e.advertisement_id = a.id
          AND e.event_type = 'impression'
          AND e.session_id = p_session_id
      )
    )
    -- Frequency check: user cap
    AND (
      a.frequency_type != 'once_per_user' 
      OR p_customer_id IS NULL 
      OR NOT EXISTS (
        SELECT 1 FROM public.advertisement_events e
        WHERE e.advertisement_id = a.id
          AND e.event_type = 'impression'
          AND e.user_id = p_customer_id
      )
    )
    -- Frequency check: day cap
    AND (
      a.frequency_type != 'once_per_day' 
      OR p_customer_id IS NULL 
      OR NOT EXISTS (
        SELECT 1 FROM public.advertisement_events e
        WHERE e.advertisement_id = a.id
          AND e.event_type = 'impression'
          AND e.user_id = p_customer_id
          AND e.created_at >= NOW() - INTERVAL '24 hours'
      )
    )
  ORDER BY a.created_at DESC;
END;
$$;

-- 8. Event Recording RPC
CREATE OR REPLACE FUNCTION public.track_advertisement_event(
  p_advertisement_id UUID,
  p_event_type TEXT,
  p_session_id TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_event_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  INSERT INTO public.advertisement_events (
    advertisement_id,
    user_id,
    event_type,
    session_id,
    metadata
  ) VALUES (
    p_advertisement_id,
    v_user_id,
    p_event_type,
    p_session_id,
    p_metadata
  ) RETURNING id INTO v_event_id;

  RETURN v_event_id;
END;
$$;
