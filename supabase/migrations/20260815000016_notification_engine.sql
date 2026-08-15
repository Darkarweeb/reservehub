-- ============================================================
-- ReserveHub Migration 16: Notification Engine
-- Incremental additions to the existing notification schema.
-- Does NOT recreate existing tables/types from migration 12.
-- ============================================================

-- ─── Ensure enum types exist (idempotent bootstrap) ──────────
-- If migration 12 has not run, create the required enum types here.
-- If migration 12 already ran, these DO blocks are no-ops.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_channel' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE TYPE public.notification_channel AS ENUM (
      'email', 'push', 'sms', 'whatsapp', 'in_app'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE TYPE public.notification_event AS ENUM (
      'appointment_created',
      'appointment_confirmed',
      'appointment_rescheduled',
      'appointment_cancelled',
      'appointment_reminder',
      'appointment_no_show',
      'daily_appointment_summary',
      'welcome',
      'password_reset',
      'invitation'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'delivery_status' AND typnamespace = 'public'::regnamespace
  ) THEN
    CREATE TYPE public.delivery_status AS ENUM (
      'pending', 'queued', 'sent', 'delivered', 'failed', 'bounced', 'skipped'
    );
  END IF;
END $$;

-- ─── Add missing notification events to existing enum ────────
-- We extend the existing notification_event enum with new values.
-- Use ALTER TYPE ... ADD VALUE IF NOT EXISTS (idempotent in PG 14+)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_catalog.pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'notification_event'
      AND t.typnamespace = 'public'::regnamespace
      AND e.enumlabel = 'new_appointment'
  ) THEN
    ALTER TYPE public.notification_event ADD VALUE 'new_appointment';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_catalog.pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'notification_event'
      AND t.typnamespace = 'public'::regnamespace
      AND e.enumlabel = 'appointment_reminder_24h'
  ) THEN
    ALTER TYPE public.notification_event ADD VALUE 'appointment_reminder_24h';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_catalog.pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'notification_event'
      AND t.typnamespace = 'public'::regnamespace
      AND e.enumlabel = 'appointment_reminder_2h'
  ) THEN
    ALTER TYPE public.notification_event ADD VALUE 'appointment_reminder_2h';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_catalog.pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'notification_event'
      AND t.typnamespace = 'public'::regnamespace
      AND e.enumlabel = 'business_welcome'
  ) THEN
    ALTER TYPE public.notification_event ADD VALUE 'business_welcome';
  END IF;
END $$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_catalog.pg_type
    WHERE typname = 'notification_event' AND typnamespace = 'public'::regnamespace
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_catalog.pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'notification_event'
      AND t.typnamespace = 'public'::regnamespace
      AND e.enumlabel = 'review_request'
  ) THEN
    ALTER TYPE public.notification_event ADD VALUE 'review_request';
  END IF;
END $$;

-- ─── Ensure notification_queue exists (idempotent) ───────────
-- Migration 12 creates this table; this guard ensures migration 16
-- can run safely even if migration 12 was not applied first.
-- Only creates the table when public.organizations already exists
-- (i.e., migration 2 has run). If organizations is absent the table
-- will be created by migration 12 in the correct order.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'organizations'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) THEN
    EXECUTE $sql$
      CREATE TABLE public.notification_queue (
        id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        organization_id   UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
        business_id       UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
        event             public.notification_event NOT NULL,
        channel           public.notification_channel NOT NULL,
        recipient_type    TEXT NOT NULL DEFAULT 'customer',
        recipient_id      UUID,
        recipient_email   TEXT,
        recipient_phone   TEXT,
        recipient_name    TEXT,
        appointment_id    UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
        subject           TEXT,
        body_text         TEXT,
        body_html         TEXT,
        template_id       TEXT,
        template_data     JSONB NOT NULL DEFAULT '{}'::JSONB,
        delivery_status   public.delivery_status NOT NULL DEFAULT 'pending'::public.delivery_status,
        scheduled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        sent_at           TIMESTAMPTZ,
        delivered_at      TIMESTAMPTZ,
        failed_at         TIMESTAMPTZ,
        failure_reason    TEXT,
        attempt_count     INTEGER NOT NULL DEFAULT 0,
        max_attempts      INTEGER NOT NULL DEFAULT 3,
        next_retry_at     TIMESTAMPTZ,
        provider_name     TEXT,
        provider_message_id TEXT,
        provider_response JSONB,
        created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT notification_queue_attempt_count_non_negative CHECK (attempt_count >= 0),
        CONSTRAINT notification_queue_max_attempts_positive CHECK (max_attempts > 0)
      )
    $sql$;
  END IF;
END $$;

-- ─── Ensure notification_preferences exists (idempotent) ─────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'organizations'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_preferences'
  ) THEN
    EXECUTE $sql$
      CREATE TABLE public.notification_preferences (
        id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
        business_id             UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
        branch_id               UUID REFERENCES public.branches(id) ON DELETE CASCADE,
        event_preferences       JSONB NOT NULL DEFAULT '{}'::JSONB,
        daily_summary_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
        daily_summary_channels  public.notification_channel[] NOT NULL DEFAULT ARRAY['email'::public.notification_channel],
        daily_summary_send_time TIME WITHOUT TIME ZONE NOT NULL DEFAULT '07:00:00',
        summary_recipient_email TEXT,
        summary_recipient_phone TEXT,
        created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT notification_prefs_unique_business UNIQUE (business_id, branch_id),
        CONSTRAINT notification_prefs_summary_time_check
          CHECK (daily_summary_send_time <= '07:00:00'::TIME)
      )
    $sql$;
  END IF;
END $$;

-- ─── Ensure daily_appointment_summaries exists (idempotent) ──
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'organizations'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'daily_appointment_summaries'
  ) THEN
    EXECUTE $sql$
      CREATE TABLE public.daily_appointment_summaries (
        id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
        business_id       UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
        summary_date      DATE NOT NULL,
        business_timezone TEXT NOT NULL DEFAULT 'UTC',
        recipient_email   TEXT,
        recipient_phone   TEXT,
        recipient_name    TEXT,
        appointment_count INTEGER NOT NULL DEFAULT 0,
        summary_data      JSONB NOT NULL DEFAULT '{}'::JSONB,
        delivery_status   public.delivery_status NOT NULL DEFAULT 'pending'::public.delivery_status,
        scheduled_at      TIMESTAMPTZ,
        sent_at           TIMESTAMPTZ,
        failed_at         TIMESTAMPTZ,
        failure_reason    TEXT,
        notification_id   UUID REFERENCES public.notification_queue(id) ON DELETE SET NULL,
        created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT daily_summaries_unique_business_date UNIQUE (business_id, summary_date)
      )
    $sql$;
  END IF;
END $$;

-- ─── Add idempotency_key and retry/locale columns to notification_queue ──────
-- Wrapped in a DO block so these are no-ops when the table doesn't exist yet
-- (migration 12 will create the table with the correct schema in that case).
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) THEN
    -- idempotency_key
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_queue'
        AND column_name = 'idempotency_key'
    ) THEN
      ALTER TABLE public.notification_queue ADD COLUMN idempotency_key TEXT;
    END IF;

    -- first_attempt_at
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_queue'
        AND column_name = 'first_attempt_at'
    ) THEN
      ALTER TABLE public.notification_queue ADD COLUMN first_attempt_at TIMESTAMPTZ;
    END IF;

    -- last_attempt_at
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_queue'
        AND column_name = 'last_attempt_at'
    ) THEN
      ALTER TABLE public.notification_queue ADD COLUMN last_attempt_at TIMESTAMPTZ;
    END IF;

    -- locale
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_queue'
        AND column_name = 'locale'
    ) THEN
      ALTER TABLE public.notification_queue ADD COLUMN locale TEXT NOT NULL DEFAULT 'en';
    END IF;
  END IF;
END $$;

-- Unique index on idempotency_key (partial — only non-null values, only if table exists)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) AND NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'notification_queue'
      AND indexname = 'idx_notif_queue_idempotency_key'
  ) THEN
    EXECUTE $sql$
      CREATE UNIQUE INDEX idx_notif_queue_idempotency_key
        ON public.notification_queue(idempotency_key)
        WHERE idempotency_key IS NOT NULL
    $sql$;
  END IF;
END $$;

-- ─── Add notification_preferences columns ────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_preferences'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_preferences'
        AND column_name = 'appointment_notifications_enabled'
    ) THEN
      ALTER TABLE public.notification_preferences
        ADD COLUMN appointment_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_preferences'
        AND column_name = 'new_appointment_email_enabled'
    ) THEN
      ALTER TABLE public.notification_preferences
        ADD COLUMN new_appointment_email_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_preferences'
        AND column_name = 'cancellation_email_enabled'
    ) THEN
      ALTER TABLE public.notification_preferences
        ADD COLUMN cancellation_email_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'notification_preferences'
        AND column_name = 'reminder_email_enabled'
    ) THEN
      ALTER TABLE public.notification_preferences
        ADD COLUMN reminder_email_enabled BOOLEAN NOT NULL DEFAULT TRUE;
    END IF;
  END IF;
END $$;

-- ─── FUNCTION: queue_notification ────────────────────────────
-- Internal helper to enqueue a notification with idempotency.
-- Called by appointment event triggers and RPCs.
CREATE OR REPLACE FUNCTION public.queue_notification(
  p_organization_id   UUID,
  p_business_id       UUID,
  p_event             public.notification_event,
  p_channel           public.notification_channel,
  p_recipient_type    TEXT,
  p_recipient_id      UUID,
  p_recipient_email   TEXT,
  p_recipient_name    TEXT,
  p_appointment_id    UUID,
  p_template_data     JSONB,
  p_idempotency_key   TEXT,
  p_scheduled_at      TIMESTAMPTZ DEFAULT NOW(),
  p_locale            TEXT DEFAULT 'en'
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  -- Idempotency: skip if already queued/sent with same key
  IF p_idempotency_key IS NOT NULL THEN
    SELECT id INTO v_id
    FROM public.notification_queue
    WHERE idempotency_key = p_idempotency_key
    LIMIT 1;

    IF v_id IS NOT NULL THEN
      RETURN v_id;
    END IF;
  END IF;

  INSERT INTO public.notification_queue (
    organization_id,
    business_id,
    event,
    channel,
    recipient_type,
    recipient_id,
    recipient_email,
    recipient_name,
    appointment_id,
    template_data,
    idempotency_key,
    scheduled_at,
    locale,
    delivery_status,
    attempt_count,
    max_attempts
  ) VALUES (
    p_organization_id,
    p_business_id,
    p_event,
    p_channel,
    p_recipient_type,
    p_recipient_id,
    p_recipient_email,
    p_recipient_name,
    p_appointment_id,
    p_template_data,
    p_idempotency_key,
    p_scheduled_at,
    p_locale,
    'pending'::public.delivery_status,
    0,
    3
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

-- ─── FUNCTION: enqueue_appointment_notifications ─────────────
-- Called after appointment creation/cancellation/update.
-- Respects notification_preferences.
-- Generates both customer and business notifications.
CREATE OR REPLACE FUNCTION public.enqueue_appointment_notifications(
  p_appointment_id  UUID,
  p_event           public.notification_event
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appt              RECORD;
  v_business          RECORD;
  v_branch            RECORD;
  v_service           RECORD;
  v_employee          RECORD;
  v_prefs             RECORD;
  v_customer_email    TEXT;
  v_customer_name     TEXT;
  v_owner_email       TEXT;
  v_owner_name        TEXT;
  v_template_data     JSONB;
  v_idempotency_key   TEXT;
  v_appt_time_local   TEXT;
  v_appt_date_local   TEXT;
  v_tz                TEXT;
BEGIN
  -- ── Load appointment with related data ──────────────────────
  SELECT
    a.id,
    a.organization_id,
    a.business_id,
    a.branch_id,
    a.service_id,
    a.employee_id,
    a.customer_id,
    a.guest_customer_id,
    a.start_time,
    a.end_time,
    a.status,
    a.notes,
    a.booking_source,
    a.appointment_reference
  INTO v_appt
  FROM public.appointments a
  WHERE a.id = p_appointment_id
  LIMIT 1;

  IF v_appt IS NULL THEN
    RAISE NOTICE 'enqueue_appointment_notifications: appointment % not found', p_appointment_id;
    RETURN;
  END IF;

  -- ── Load business ────────────────────────────────────────────
  SELECT b.name, b.timezone, b.slug, b.organization_id
  INTO v_business
  FROM public.businesses b
  WHERE b.id = v_appt.business_id
  LIMIT 1;

  -- ── Load branch ──────────────────────────────────────────────
  SELECT br.name, br.timezone, br.city, br.address
  INTO v_branch
  FROM public.branches br
  WHERE br.id = v_appt.branch_id
  LIMIT 1;

  -- ── Load service ─────────────────────────────────────────────
  SELECT s.name, s.duration_minutes, s.price
  INTO v_service
  FROM public.services s
  WHERE s.id = v_appt.service_id
  LIMIT 1;

  -- ── Load employee (optional) ─────────────────────────────────
  IF v_appt.employee_id IS NOT NULL THEN
    SELECT
      COALESCE(e.display_name, e.first_name || ' ' || e.last_name) AS display_name
    INTO v_employee
    FROM public.employees e
    WHERE e.id = v_appt.employee_id
    LIMIT 1;
  END IF;

  -- ── Determine timezone for display ───────────────────────────
  v_tz := COALESCE(v_branch.timezone, v_business.timezone, 'UTC');

  -- ── Format appointment time in business timezone ─────────────
  v_appt_date_local := TO_CHAR(
    v_appt.start_time AT TIME ZONE v_tz,
    'Day, Month DD, YYYY'
  );
  v_appt_time_local := TO_CHAR(
    v_appt.start_time AT TIME ZONE v_tz,
    'HH12:MI AM'
  );

  -- ── Resolve customer contact ──────────────────────────────────
  IF v_appt.guest_customer_id IS NOT NULL THEN
    SELECT gc.email, gc.full_name
    INTO v_customer_email, v_customer_name
    FROM public.guest_customers gc
    WHERE gc.id = v_appt.guest_customer_id
    LIMIT 1;
  ELSIF v_appt.customer_id IS NOT NULL THEN
    SELECT up.email, up.full_name
    INTO v_customer_email, v_customer_name
    FROM public.user_profiles up
    WHERE up.id = v_appt.customer_id
    LIMIT 1;
  END IF;

  -- ── Resolve business owner email ──────────────────────────────
  SELECT up.email, up.full_name
  INTO v_owner_email, v_owner_name
  FROM public.organization_members om
  JOIN public.user_profiles up ON up.id = om.user_id
  WHERE om.organization_id = v_appt.organization_id
    AND om.role IN ('owner', 'admin')
    AND om.is_active = TRUE
  ORDER BY CASE om.role WHEN 'owner' THEN 0 ELSE 1 END
  LIMIT 1;

  -- ── Load notification preferences ────────────────────────────
  SELECT *
  INTO v_prefs
  FROM public.notification_preferences
  WHERE business_id = v_appt.business_id
  LIMIT 1;

  -- ── Build shared template data ────────────────────────────────
  v_template_data := jsonb_build_object(
    'appointment_id',        v_appt.id,
    'appointment_reference', COALESCE(v_appt.appointment_reference, v_appt.id::TEXT),
    'business_name',         COALESCE(v_business.name, 'Business'),
    'business_slug',         COALESCE(v_business.slug, ''),
    'branch_name',           COALESCE(v_branch.name, ''),
    'branch_city',           COALESCE(v_branch.city, ''),
    'branch_address',        COALESCE(v_branch.address, ''),
    'service_name',          COALESCE(v_service.name, ''),
    'service_duration',      COALESCE(v_service.duration_minutes, 0),
    'service_price',         COALESCE(v_service.price, 0),
    'employee_name',         COALESCE(v_employee.display_name, ''),
    'appointment_date',      v_appt_date_local,
    'appointment_time',      v_appt_time_local,
    'appointment_timezone',  v_tz,
    'appointment_status',    v_appt.status::TEXT,
    'customer_name',         COALESCE(v_customer_name, 'Guest'),
    'customer_email',        COALESCE(v_customer_email, ''),
    'booking_source',        COALESCE(v_appt.booking_source, 'online'),
    'event_type',            p_event::TEXT
  );

  -- ── Enqueue CUSTOMER notification ────────────────────────────
  IF v_customer_email IS NOT NULL AND v_customer_email != '' THEN
    -- Check preferences for mandatory transactional events
    IF p_event IN (
      'appointment_created',
      'appointment_confirmed',
      'appointment_cancelled',
      'appointment_rescheduled'
    ) OR (
      v_prefs IS NULL OR v_prefs.appointment_notifications_enabled = TRUE
    ) THEN
      v_idempotency_key := 'customer:' || p_event::TEXT || ':' || v_appt.id::TEXT;

      PERFORM public.queue_notification(
        v_appt.organization_id,
        v_appt.business_id,
        p_event,
        'email'::public.notification_channel,
        'customer',
        v_appt.guest_customer_id,
        v_customer_email,
        v_customer_name,
        v_appt.id,
        v_template_data || jsonb_build_object('recipient_role', 'customer'),
        v_idempotency_key,
        NOW(),
        'en'
      );
    END IF;
  END IF;

  -- ── Enqueue BUSINESS notification ─────────────────────────────
  IF v_owner_email IS NOT NULL AND v_owner_email != '' THEN
    -- Map customer event to business event
    DECLARE
      v_business_event public.notification_event;
    BEGIN
      v_business_event := CASE p_event
        WHEN 'appointment_created'     THEN 'new_appointment'::public.notification_event
        WHEN 'appointment_cancelled'   THEN 'appointment_cancelled'::public.notification_event
        WHEN 'appointment_rescheduled' THEN 'appointment_rescheduled'::public.notification_event
        ELSE NULL
      END;

      IF v_business_event IS NOT NULL THEN
        IF v_prefs IS NULL
          OR (v_business_event = 'new_appointment' AND v_prefs.new_appointment_email_enabled = TRUE)
          OR (v_business_event = 'appointment_cancelled' AND v_prefs.cancellation_email_enabled = TRUE)
          OR (v_business_event = 'appointment_rescheduled' AND v_prefs.appointment_notifications_enabled = TRUE)
        THEN
          v_idempotency_key := 'business:' || v_business_event::TEXT || ':' || v_appt.id::TEXT;

          PERFORM public.queue_notification(
            v_appt.organization_id,
            v_appt.business_id,
            v_business_event,
            'email'::public.notification_channel,
            'owner',
            NULL,
            v_owner_email,
            v_owner_name,
            v_appt.id,
            v_template_data || jsonb_build_object('recipient_role', 'business'),
            v_idempotency_key,
            NOW(),
            'en'
          );
        END IF;
      END IF;
    END;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'enqueue_appointment_notifications failed for %: %', p_appointment_id, SQLERRM;
END;
$$;

-- ─── FUNCTION: enqueue_appointment_reminders ─────────────────
-- Called by the scheduler to enqueue reminders for upcoming appointments.
-- Timezone-aware. Idempotent.
CREATE OR REPLACE FUNCTION public.enqueue_appointment_reminders(
  p_hours_before INTEGER DEFAULT 24
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appt              RECORD;
  v_business          RECORD;
  v_branch            RECORD;
  v_service           RECORD;
  v_employee          RECORD;
  v_customer_email    TEXT;
  v_customer_name     TEXT;
  v_template_data     JSONB;
  v_idempotency_key   TEXT;
  v_event             public.notification_event;
  v_tz                TEXT;
  v_appt_date_local   TEXT;
  v_appt_time_local   TEXT;
  v_count             INTEGER := 0;
  v_prefs             RECORD;
BEGIN
  -- Determine event type
  v_event := CASE p_hours_before
    WHEN 2  THEN 'appointment_reminder_2h'::public.notification_event
    ELSE         'appointment_reminder_24h'::public.notification_event
  END;

  -- Find appointments due for reminder
  FOR v_appt IN
    SELECT
      a.id,
      a.organization_id,
      a.business_id,
      a.branch_id,
      a.service_id,
      a.employee_id,
      a.guest_customer_id,
      a.customer_id,
      a.start_time,
      a.status,
      a.appointment_reference
    FROM public.appointments a
    WHERE a.status IN ('confirmed', 'pending')
      AND a.start_time BETWEEN
        NOW() + (p_hours_before || ' hours')::INTERVAL - INTERVAL '30 minutes'
        AND NOW() + (p_hours_before || ' hours')::INTERVAL + INTERVAL '30 minutes'
  LOOP
    -- Check preferences
    SELECT * INTO v_prefs
    FROM public.notification_preferences
    WHERE business_id = v_appt.business_id
    LIMIT 1;

    IF v_prefs IS NOT NULL AND v_prefs.reminder_email_enabled = FALSE THEN
      CONTINUE;
    END IF;

    -- Load related data
    SELECT b.name, b.timezone, b.slug INTO v_business
    FROM public.businesses b WHERE b.id = v_appt.business_id LIMIT 1;

    SELECT br.name, br.timezone, br.city INTO v_branch
    FROM public.branches br WHERE br.id = v_appt.branch_id LIMIT 1;

    SELECT s.name, s.duration_minutes INTO v_service
    FROM public.services s WHERE s.id = v_appt.service_id LIMIT 1;

    IF v_appt.employee_id IS NOT NULL THEN
      SELECT COALESCE(e.display_name, e.first_name || ' ' || e.last_name) AS display_name
      INTO v_employee
      FROM public.employees e WHERE e.id = v_appt.employee_id LIMIT 1;
    END IF;

    v_tz := COALESCE(v_branch.timezone, v_business.timezone, 'UTC');
    v_appt_date_local := TO_CHAR(v_appt.start_time AT TIME ZONE v_tz, 'Day, Month DD, YYYY');
    v_appt_time_local := TO_CHAR(v_appt.start_time AT TIME ZONE v_tz, 'HH12:MI AM');

    -- Resolve customer
    IF v_appt.guest_customer_id IS NOT NULL THEN
      SELECT gc.email, gc.full_name INTO v_customer_email, v_customer_name
      FROM public.guest_customers gc WHERE gc.id = v_appt.guest_customer_id LIMIT 1;
    ELSIF v_appt.customer_id IS NOT NULL THEN
      SELECT up.email, up.full_name INTO v_customer_email, v_customer_name
      FROM public.user_profiles up WHERE up.id = v_appt.customer_id LIMIT 1;
    END IF;

    IF v_customer_email IS NULL OR v_customer_email = '' THEN
      CONTINUE;
    END IF;

    v_idempotency_key := 'reminder:' || v_event::TEXT || ':' || v_appt.id::TEXT;

    v_template_data := jsonb_build_object(
      'appointment_id',        v_appt.id,
      'appointment_reference', COALESCE(v_appt.appointment_reference, v_appt.id::TEXT),
      'business_name',         COALESCE(v_business.name, 'Business'),
      'business_slug',         COALESCE(v_business.slug, ''),
      'branch_name',           COALESCE(v_branch.name, ''),
      'branch_city',           COALESCE(v_branch.city, ''),
      'service_name',          COALESCE(v_service.name, ''),
      'employee_name',         COALESCE(v_employee.display_name, ''),
      'appointment_date',      v_appt_date_local,
      'appointment_time',      v_appt_time_local,
      'appointment_timezone',  v_tz,
      'appointment_status',    v_appt.status::TEXT,
      'customer_name',         COALESCE(v_customer_name, 'Guest'),
      'hours_before',          p_hours_before,
      'recipient_role',        'customer',
      'event_type',            v_event::TEXT
    );

    PERFORM public.queue_notification(
      v_appt.organization_id,
      v_appt.business_id,
      v_event,
      'email'::public.notification_channel,
      'customer',
      v_appt.guest_customer_id,
      v_customer_email,
      v_customer_name,
      v_appt.id,
      v_template_data,
      v_idempotency_key,
      NOW(),
      'en'
    );

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ─── FUNCTION: enqueue_daily_summary ─────────────────────────
-- Determines which businesses are due for their daily summary
-- (7:00 AM local time) and enqueues the notification.
-- Idempotent: uses business_id + local_date as idempotency key.
CREATE OR REPLACE FUNCTION public.enqueue_daily_summaries()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business          RECORD;
  v_prefs             RECORD;
  v_owner_email       TEXT;
  v_owner_name        TEXT;
  v_local_now         TIMESTAMPTZ;
  v_local_date        DATE;
  v_local_hour        INTEGER;
  v_appt_count        INTEGER;
  v_appt_list         JSONB;
  v_template_data     JSONB;
  v_idempotency_key   TEXT;
  v_count             INTEGER := 0;
BEGIN
  FOR v_business IN
    SELECT b.id, b.organization_id, b.name, b.slug,
           COALESCE(b.timezone, 'UTC') AS timezone
    FROM public.businesses b
    WHERE b.is_active = TRUE
      AND b.publication_status = 'published'
  LOOP
    -- Compute local time for this business
    v_local_now  := NOW() AT TIME ZONE v_business.timezone;
    v_local_date := v_local_now::DATE;
    v_local_hour := EXTRACT(HOUR FROM v_local_now)::INTEGER;

    -- Only send between 06:45 and 07:15 local time
    IF v_local_hour < 6 OR v_local_hour > 7 THEN
      CONTINUE;
    END IF;
    IF v_local_hour = 7 AND EXTRACT(MINUTE FROM v_local_now) > 15 THEN
      CONTINUE;
    END IF;
    IF v_local_hour = 6 AND EXTRACT(MINUTE FROM v_local_now) < 45 THEN
      CONTINUE;
    END IF;

    -- Check preferences
    SELECT * INTO v_prefs
    FROM public.notification_preferences
    WHERE business_id = v_business.id
    LIMIT 1;

    IF v_prefs IS NOT NULL AND v_prefs.daily_summary_enabled = FALSE THEN
      CONTINUE;
    END IF;

    -- Idempotency: skip if already sent today
    v_idempotency_key := 'daily_summary:' || v_business.id::TEXT || ':' || v_local_date::TEXT;

    IF EXISTS (
      SELECT 1 FROM public.notification_queue
      WHERE idempotency_key = v_idempotency_key
    ) THEN
      CONTINUE;
    END IF;

    -- Resolve recipient
    v_owner_email := COALESCE(v_prefs.summary_recipient_email, NULL);
    IF v_owner_email IS NULL THEN
      SELECT up.email, up.full_name
      INTO v_owner_email, v_owner_name
      FROM public.organization_members om
      JOIN public.user_profiles up ON up.id = om.user_id
      WHERE om.organization_id = v_business.organization_id
        AND om.role IN ('owner', 'admin')
        AND om.is_active = TRUE
      ORDER BY CASE om.role WHEN 'owner' THEN 0 ELSE 1 END
      LIMIT 1;
    END IF;

    IF v_owner_email IS NULL OR v_owner_email = '' THEN
      CONTINUE;
    END IF;

    -- Count today's appointments
    SELECT COUNT(*), jsonb_agg(
      jsonb_build_object(
        'id',         a.id,
        'reference',  COALESCE(a.appointment_reference, a.id::TEXT),
        'start_time', TO_CHAR(a.start_time AT TIME ZONE v_business.timezone, 'HH12:MI AM'),
        'end_time',   TO_CHAR(a.end_time AT TIME ZONE v_business.timezone, 'HH12:MI AM'),
        'status',     a.status::TEXT,
        'service',    s.name,
        'customer',   COALESCE(gc.full_name, up.full_name, 'Guest'),
        'employee',   COALESCE(e.display_name, e.first_name || ' ' || e.last_name, '')
      ) ORDER BY a.start_time
    )
    INTO v_appt_count, v_appt_list
    FROM public.appointments a
    LEFT JOIN public.services s ON s.id = a.service_id
    LEFT JOIN public.guest_customers gc ON gc.id = a.guest_customer_id
    LEFT JOIN public.user_profiles up ON up.id = a.customer_id
    LEFT JOIN public.employees e ON e.id = a.employee_id
    WHERE a.business_id = v_business.id
      AND (a.start_time AT TIME ZONE v_business.timezone)::DATE = v_local_date
      AND a.status NOT IN ('cancelled', 'no_show');

    v_template_data := jsonb_build_object(
      'business_name',       v_business.name,
      'business_slug',       v_business.slug,
      'summary_date',        TO_CHAR(v_local_date, 'Day, Month DD, YYYY'),
      'summary_date_iso',    v_local_date::TEXT,
      'business_timezone',   v_business.timezone,
      'appointment_count',   COALESCE(v_appt_count, 0),
      'appointments',        COALESCE(v_appt_list, '[]'::JSONB),
      'recipient_role',      'business',
      'event_type',          'daily_appointment_summary'
    );

    PERFORM public.queue_notification(
      v_business.organization_id,
      v_business.id,
      'daily_appointment_summary'::public.notification_event,
      'email'::public.notification_channel,
      'owner',
      NULL,
      v_owner_email,
      v_owner_name,
      NULL,
      v_template_data,
      v_idempotency_key,
      NOW(),
      'en'
    );

    -- Track in daily_appointment_summaries
    INSERT INTO public.daily_appointment_summaries (
      organization_id,
      business_id,
      summary_date,
      business_timezone,
      recipient_email,
      recipient_name,
      appointment_count,
      summary_data,
      delivery_status,
      scheduled_at
    ) VALUES (
      v_business.organization_id,
      v_business.id,
      v_local_date,
      v_business.timezone,
      v_owner_email,
      v_owner_name,
      COALESCE(v_appt_count, 0),
      v_template_data,
      'pending'::public.delivery_status,
      NOW()
    )
    ON CONFLICT (business_id, summary_date) DO NOTHING;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- ─── FUNCTION: get_notification_preferences ──────────────────
CREATE OR REPLACE FUNCTION public.get_notification_preferences()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_org_id      UUID;
  v_prefs       RECORD;
BEGIN
  -- Resolve business from current user
  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id = auth.uid() AND om.is_active = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not a member of any organization');
  END IF;

  SELECT b.id INTO v_business_id
  FROM public.businesses b
  WHERE b.organization_id = v_org_id AND b.is_active = TRUE
  LIMIT 1;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'No business found');
  END IF;

  SELECT * INTO v_prefs
  FROM public.notification_preferences
  WHERE business_id = v_business_id
  LIMIT 1;

  IF v_prefs IS NULL THEN
    -- Return defaults
    RETURN jsonb_build_object(
      'status', 'success',
      'business_id', v_business_id,
      'daily_summary_enabled', TRUE,
      'appointment_notifications_enabled', TRUE,
      'new_appointment_email_enabled', TRUE,
      'cancellation_email_enabled', TRUE,
      'reminder_email_enabled', TRUE,
      'daily_summary_send_time', '07:00:00',
      'summary_recipient_email', NULL
    );
  END IF;

  RETURN jsonb_build_object(
    'status', 'success',
    'id', v_prefs.id,
    'business_id', v_business_id,
    'daily_summary_enabled', v_prefs.daily_summary_enabled,
    'appointment_notifications_enabled', v_prefs.appointment_notifications_enabled,
    'new_appointment_email_enabled', v_prefs.new_appointment_email_enabled,
    'cancellation_email_enabled', v_prefs.cancellation_email_enabled,
    'reminder_email_enabled', v_prefs.reminder_email_enabled,
    'daily_summary_send_time', v_prefs.daily_summary_send_time::TEXT,
    'summary_recipient_email', v_prefs.summary_recipient_email
  );
END;
$$;

-- ─── FUNCTION: upsert_notification_preferences ───────────────
CREATE OR REPLACE FUNCTION public.upsert_notification_preferences(
  p_daily_summary_enabled              BOOLEAN DEFAULT TRUE,
  p_appointment_notifications_enabled  BOOLEAN DEFAULT TRUE,
  p_new_appointment_email_enabled      BOOLEAN DEFAULT TRUE,
  p_cancellation_email_enabled         BOOLEAN DEFAULT TRUE,
  p_reminder_email_enabled             BOOLEAN DEFAULT TRUE,
  p_summary_recipient_email            TEXT    DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_business_id UUID;
  v_org_id      UUID;
BEGIN
  SELECT om.organization_id INTO v_org_id
  FROM public.organization_members om
  WHERE om.user_id = auth.uid() AND om.is_active = TRUE
  LIMIT 1;

  IF v_org_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Not authorized');
  END IF;

  -- Verify admin/owner role
  IF NOT public.is_org_admin(v_org_id) THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'Insufficient permissions');
  END IF;

  SELECT b.id INTO v_business_id
  FROM public.businesses b
  WHERE b.organization_id = v_org_id AND b.is_active = TRUE
  LIMIT 1;

  IF v_business_id IS NULL THEN
    RETURN jsonb_build_object('status', 'error', 'message', 'No business found');
  END IF;

  INSERT INTO public.notification_preferences (
    organization_id,
    business_id,
    daily_summary_enabled,
    appointment_notifications_enabled,
    new_appointment_email_enabled,
    cancellation_email_enabled,
    reminder_email_enabled,
    summary_recipient_email
  ) VALUES (
    v_org_id,
    v_business_id,
    p_daily_summary_enabled,
    p_appointment_notifications_enabled,
    p_new_appointment_email_enabled,
    p_cancellation_email_enabled,
    p_reminder_email_enabled,
    p_summary_recipient_email
  )
  ON CONFLICT (business_id, branch_id) DO UPDATE SET
    daily_summary_enabled             = EXCLUDED.daily_summary_enabled,
    appointment_notifications_enabled = EXCLUDED.appointment_notifications_enabled,
    new_appointment_email_enabled     = EXCLUDED.new_appointment_email_enabled,
    cancellation_email_enabled        = EXCLUDED.cancellation_email_enabled,
    reminder_email_enabled            = EXCLUDED.reminder_email_enabled,
    summary_recipient_email           = EXCLUDED.summary_recipient_email,
    updated_at                        = NOW();

  RETURN jsonb_build_object('status', 'success', 'message', 'Preferences saved');
END;
$$;

-- ─── TRIGGER: appointment notification on insert ──────────────
CREATE OR REPLACE FUNCTION public.trg_appointment_created_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.enqueue_appointment_notifications(
    NEW.id,
    'appointment_created'::public.notification_event
  );
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Notification trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointments'
  ) THEN
    DROP TRIGGER IF EXISTS trg_appointment_created_notification ON public.appointments;
    CREATE TRIGGER trg_appointment_created_notification
      AFTER INSERT ON public.appointments
      FOR EACH ROW
      EXECUTE FUNCTION public.trg_appointment_created_notification();
  END IF;
END $$;

-- ─── TRIGGER: appointment notification on status change ───────
CREATE OR REPLACE FUNCTION public.trg_appointment_status_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only fire on meaningful status changes
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  IF NEW.status = 'cancelled' THEN
    PERFORM public.enqueue_appointment_notifications(
      NEW.id,
      'appointment_cancelled'::public.notification_event
    );
  ELSIF NEW.status = 'confirmed' THEN
    PERFORM public.enqueue_appointment_notifications(
      NEW.id,
      'appointment_confirmed'::public.notification_event
    );
  ELSIF NEW.status = 'rescheduled' THEN
    PERFORM public.enqueue_appointment_notifications(
      NEW.id,
      'appointment_rescheduled'::public.notification_event
    );
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Status notification trigger failed: %', SQLERRM;
    RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'appointments'
  ) THEN
    DROP TRIGGER IF EXISTS trg_appointment_status_notification ON public.appointments;
    CREATE TRIGGER trg_appointment_status_notification
      AFTER UPDATE OF status ON public.appointments
      FOR EACH ROW
      EXECUTE FUNCTION public.trg_appointment_status_notification();
  END IF;
END $$;

-- ─── INDEXES for new columns ──────────────────────────────────
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'notification_queue'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename = 'notification_queue'
        AND indexname = 'idx_notif_queue_scheduled_pending'
    ) THEN
      EXECUTE $sql$
        CREATE INDEX idx_notif_queue_scheduled_pending
          ON public.notification_queue(scheduled_at, delivery_status)
          WHERE delivery_status IN ('pending', 'queued')
      $sql$;
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_indexes
      WHERE schemaname = 'public'
        AND tablename = 'notification_queue'
        AND indexname = 'idx_notif_queue_retry'
    ) THEN
      EXECUTE $sql$
        CREATE INDEX idx_notif_queue_retry
          ON public.notification_queue(next_retry_at, delivery_status)
          WHERE delivery_status = 'failed' AND next_retry_at IS NOT NULL
      $sql$;
    END IF;
  END IF;
END $$;
