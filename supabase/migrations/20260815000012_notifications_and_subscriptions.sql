-- ============================================================
-- ReserveHub Migration 12: Notification Foundation,
--                          Daily Summary, & Subscription Plans
-- ============================================================

-- ─── ENUM: Notification Channel ──────────────────────────────
DROP TYPE IF EXISTS public.notification_channel CASCADE;
CREATE TYPE public.notification_channel AS ENUM (
  'email',
  'push',
  'sms',
  'whatsapp',
  'in_app'
);

-- ─── ENUM: Notification Event ────────────────────────────────
DROP TYPE IF EXISTS public.notification_event CASCADE;
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

-- ─── ENUM: Delivery Status ───────────────────────────────────
DROP TYPE IF EXISTS public.delivery_status CASCADE;
CREATE TYPE public.delivery_status AS ENUM (
  'pending',
  'queued',
  'sent',
  'delivered',
  'failed',
  'bounced',
  'skipped'
);

-- ─── ENUM: Subscription Plan Status ─────────────────────────
DROP TYPE IF EXISTS public.subscription_plan_status CASCADE;
CREATE TYPE public.subscription_plan_status AS ENUM (
  'active',
  'inactive',
  'deprecated'
);

-- ─── ENUM: Business Subscription Status ─────────────────────
DROP TYPE IF EXISTS public.business_subscription_status CASCADE;
CREATE TYPE public.business_subscription_status AS ENUM (
  'active',
  'trialing',
  'past_due',
  'cancelled',
  'expired',
  'free'
);

-- ─── TABLE: notification_preferences ─────────────────────────
-- Per-business (and optionally per-branch) notification preferences.
-- Controls which events trigger which channels.
CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id         UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id             UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  branch_id               UUID REFERENCES public.branches(id) ON DELETE CASCADE,

  -- Event toggles (one row per business; JSONB for flexibility)
  -- Structure: { "appointment_created": { "email": true, "sms": false, ... }, ... }
  event_preferences       JSONB NOT NULL DEFAULT '{}'::JSONB,

  -- Daily summary settings
  daily_summary_enabled   BOOLEAN NOT NULL DEFAULT TRUE,
  daily_summary_channels  public.notification_channel[] NOT NULL DEFAULT ARRAY['email'::public.notification_channel],
  -- Time of day to send summary (in business local timezone) — must be <= 07:00
  daily_summary_send_time TIME WITHOUT TIME ZONE NOT NULL DEFAULT '07:00:00',

  -- Recipient overrides (NULL = use business owner)
  summary_recipient_email TEXT,
  summary_recipient_phone TEXT,

  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT notification_prefs_unique_business UNIQUE (business_id, branch_id),
  CONSTRAINT notification_prefs_summary_time_check
    CHECK (daily_summary_send_time <= '07:00:00'::TIME)
);

-- ─── TABLE: notification_queue ───────────────────────────────
-- Outbound notification queue. Each row represents one delivery attempt.
-- The scheduler/worker reads from this table and dispatches via providers.
-- DO NOT integrate external providers yet — only the schema foundation.
CREATE TABLE IF NOT EXISTS public.notification_queue (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID REFERENCES public.organizations(id) ON DELETE SET NULL,
  business_id       UUID REFERENCES public.businesses(id) ON DELETE SET NULL,

  -- Event that triggered this notification
  event             public.notification_event NOT NULL,

  -- Delivery channel
  channel           public.notification_channel NOT NULL,

  -- Recipient
  recipient_type    TEXT NOT NULL DEFAULT 'customer',  -- 'customer', 'employee', 'owner'
  recipient_id      UUID,                              -- user_profile or guest_customer id
  recipient_email   TEXT,
  recipient_phone   TEXT,
  recipient_name    TEXT,

  -- Related entity
  appointment_id    UUID REFERENCES public.appointments(id) ON DELETE SET NULL,

  -- Payload (rendered template data — provider-agnostic)
  subject           TEXT,
  body_text         TEXT,
  body_html         TEXT,
  template_id       TEXT,
  template_data     JSONB NOT NULL DEFAULT '{}'::JSONB,

  -- Delivery tracking
  delivery_status   public.delivery_status NOT NULL DEFAULT 'pending'::public.delivery_status,
  scheduled_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  sent_at           TIMESTAMPTZ,
  delivered_at      TIMESTAMPTZ,
  failed_at         TIMESTAMPTZ,
  failure_reason    TEXT,
  attempt_count     INTEGER NOT NULL DEFAULT 0,
  max_attempts      INTEGER NOT NULL DEFAULT 3,
  next_retry_at     TIMESTAMPTZ,

  -- Provider tracking (populated when sent)
  provider_name     TEXT,
  provider_message_id TEXT,
  provider_response JSONB,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT notification_queue_attempt_count_non_negative CHECK (attempt_count >= 0),
  CONSTRAINT notification_queue_max_attempts_positive CHECK (max_attempts > 0)
);

-- ─── TABLE: daily_appointment_summaries ──────────────────────
-- Tracks daily summary delivery per business per date.
-- The scheduler uses this to determine what to send and when.
-- Sends no later than 07:00 in the business's local timezone.
CREATE TABLE IF NOT EXISTS public.daily_appointment_summaries (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id   UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id       UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,

  -- The appointment date this summary covers
  summary_date      DATE NOT NULL,

  -- Business timezone at time of generation
  business_timezone TEXT NOT NULL DEFAULT 'UTC',

  -- Recipient
  recipient_email   TEXT,
  recipient_phone   TEXT,
  recipient_name    TEXT,

  -- Summary content snapshot
  appointment_count INTEGER NOT NULL DEFAULT 0,
  summary_data      JSONB NOT NULL DEFAULT '{}'::JSONB,

  -- Delivery tracking
  delivery_status   public.delivery_status NOT NULL DEFAULT 'pending'::public.delivery_status,
  scheduled_at      TIMESTAMPTZ,  -- computed: summary_date 07:00 in business_timezone
  sent_at           TIMESTAMPTZ,
  failed_at         TIMESTAMPTZ,
  failure_reason    TEXT,

  -- Linked notification queue entry
  notification_id   UUID REFERENCES public.notification_queue(id) ON DELETE SET NULL,

  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT daily_summaries_unique_business_date UNIQUE (business_id, summary_date)
);

-- ─── TABLE: subscription_plans ───────────────────────────────
-- Reference table for available subscription plans.
-- ReserveHub starts free; paid plans added later.
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                TEXT NOT NULL UNIQUE,
  slug                TEXT NOT NULL UNIQUE,
  description         TEXT,
  status              public.subscription_plan_status NOT NULL DEFAULT 'active'::public.subscription_plan_status,
  is_free             BOOLEAN NOT NULL DEFAULT FALSE,
  price_monthly       DECIMAL(10, 2),
  price_yearly        DECIMAL(10, 2),
  currency            TEXT NOT NULL DEFAULT 'USD',

  -- Plan limits (NULL = unlimited)
  max_businesses      INTEGER,
  max_branches        INTEGER,
  max_employees       INTEGER,
  max_services        INTEGER,
  max_appointments_pm INTEGER,  -- per month

  -- Feature flags
  features            JSONB NOT NULL DEFAULT '{}'::JSONB,

  sort_order          INTEGER NOT NULL DEFAULT 0,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT subscription_plans_slug_format CHECK (slug ~ '^[a-z0-9\-]+$'),
  CONSTRAINT subscription_plans_price_non_negative
    CHECK (price_monthly IS NULL OR price_monthly >= 0),
  CONSTRAINT subscription_plans_price_yearly_non_negative
    CHECK (price_yearly IS NULL OR price_yearly >= 0)
);

-- ─── TABLE: business_subscriptions ───────────────────────────
-- Tracks which plan each business is on.
-- No payment processing at this stage.
CREATE TABLE IF NOT EXISTS public.business_subscriptions (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id     UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  business_id         UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  plan_id             UUID NOT NULL REFERENCES public.subscription_plans(id) ON DELETE RESTRICT,

  status              public.business_subscription_status NOT NULL DEFAULT 'free'::public.business_subscription_status,

  -- Subscription period
  started_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at             TIMESTAMPTZ,
  trial_ends_at       TIMESTAMPTZ,
  cancelled_at        TIMESTAMPTZ,
  cancellation_reason TEXT,

  -- Usage tracking (updated periodically)
  current_period_start TIMESTAMPTZ,
  current_period_end   TIMESTAMPTZ,
  appointments_this_period INTEGER NOT NULL DEFAULT 0,

  -- Future: payment provider reference
  external_subscription_id TEXT,

  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT business_subscriptions_unique_business UNIQUE (business_id)
);

-- ─── TRIGGERS: updated_at ────────────────────────────────────
DROP TRIGGER IF EXISTS trg_notification_prefs_updated_at ON public.notification_preferences;
CREATE TRIGGER trg_notification_prefs_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_notification_queue_updated_at ON public.notification_queue;
CREATE TRIGGER trg_notification_queue_updated_at
  BEFORE UPDATE ON public.notification_queue
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_daily_summaries_updated_at ON public.daily_appointment_summaries;
CREATE TRIGGER trg_daily_summaries_updated_at
  BEFORE UPDATE ON public.daily_appointment_summaries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_subscription_plans_updated_at ON public.subscription_plans;
CREATE TRIGGER trg_subscription_plans_updated_at
  BEFORE UPDATE ON public.subscription_plans
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS trg_business_subscriptions_updated_at ON public.business_subscriptions;
CREATE TRIGGER trg_business_subscriptions_updated_at
  BEFORE UPDATE ON public.business_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── INDEXES ─────────────────────────────────────────────────
-- notification_preferences
CREATE INDEX IF NOT EXISTS idx_notif_prefs_business_id
  ON public.notification_preferences(business_id);
CREATE INDEX IF NOT EXISTS idx_notif_prefs_org_id
  ON public.notification_preferences(organization_id);

-- notification_queue
CREATE INDEX IF NOT EXISTS idx_notif_queue_org_id
  ON public.notification_queue(organization_id);
CREATE INDEX IF NOT EXISTS idx_notif_queue_business_id
  ON public.notification_queue(business_id);
CREATE INDEX IF NOT EXISTS idx_notif_queue_appointment_id
  ON public.notification_queue(appointment_id);
CREATE INDEX IF NOT EXISTS idx_notif_queue_status_scheduled
  ON public.notification_queue(delivery_status, scheduled_at)
  WHERE delivery_status IN ('pending', 'queued');
CREATE INDEX IF NOT EXISTS idx_notif_queue_event
  ON public.notification_queue(event, delivery_status);

-- daily_appointment_summaries
CREATE INDEX IF NOT EXISTS idx_daily_summaries_business_date
  ON public.daily_appointment_summaries(business_id, summary_date);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_org_id
  ON public.daily_appointment_summaries(organization_id);
CREATE INDEX IF NOT EXISTS idx_daily_summaries_status
  ON public.daily_appointment_summaries(delivery_status, scheduled_at)
  WHERE delivery_status = 'pending';

-- subscription_plans
CREATE INDEX IF NOT EXISTS idx_subscription_plans_slug
  ON public.subscription_plans(slug);
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active
  ON public.subscription_plans(status, sort_order)
  WHERE status = 'active';

-- business_subscriptions
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_org_id
  ON public.business_subscriptions(organization_id);
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_plan_id
  ON public.business_subscriptions(plan_id);
CREATE INDEX IF NOT EXISTS idx_business_subscriptions_status
  ON public.business_subscriptions(status);

-- ─── ENABLE RLS ──────────────────────────────────────────────
ALTER TABLE public.notification_preferences     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_queue           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_appointment_summaries  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_plans           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.business_subscriptions       ENABLE ROW LEVEL SECURITY;

-- ─── RLS: notification_preferences ───────────────────────────
DROP POLICY IF EXISTS "notif_prefs_member_select" ON public.notification_preferences;
CREATE POLICY "notif_prefs_member_select"
  ON public.notification_preferences FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "notif_prefs_admin_insert" ON public.notification_preferences;
CREATE POLICY "notif_prefs_admin_insert"
  ON public.notification_preferences FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "notif_prefs_admin_update" ON public.notification_preferences;
CREATE POLICY "notif_prefs_admin_update"
  ON public.notification_preferences FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "notif_prefs_admin_delete" ON public.notification_preferences;
CREATE POLICY "notif_prefs_admin_delete"
  ON public.notification_preferences FOR DELETE TO authenticated
  USING (public.is_org_admin(organization_id));

-- ─── RLS: notification_queue ─────────────────────────────────
-- Org members can read their notification queue
DROP POLICY IF EXISTS "notif_queue_member_select" ON public.notification_queue;
CREATE POLICY "notif_queue_member_select"
  ON public.notification_queue FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

-- No direct INSERT/UPDATE/DELETE from app layer — only via SECURITY DEFINER functions

-- ─── RLS: daily_appointment_summaries ────────────────────────
DROP POLICY IF EXISTS "daily_summaries_member_select" ON public.daily_appointment_summaries;
CREATE POLICY "daily_summaries_member_select"
  ON public.daily_appointment_summaries FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

-- ─── RLS: subscription_plans ─────────────────────────────────
-- Public read — plans are a reference table
DROP POLICY IF EXISTS "subscription_plans_public_select" ON public.subscription_plans;
CREATE POLICY "subscription_plans_public_select"
  ON public.subscription_plans FOR SELECT TO anon, authenticated
  USING (status = 'active'::public.subscription_plan_status);

-- ─── RLS: business_subscriptions ─────────────────────────────
DROP POLICY IF EXISTS "business_subscriptions_member_select" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_member_select"
  ON public.business_subscriptions FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "business_subscriptions_admin_insert" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_admin_insert"
  ON public.business_subscriptions FOR INSERT TO authenticated
  WITH CHECK (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "business_subscriptions_admin_update" ON public.business_subscriptions;
CREATE POLICY "business_subscriptions_admin_update"
  ON public.business_subscriptions FOR UPDATE TO authenticated
  USING (public.is_org_admin(organization_id))
  WITH CHECK (public.is_org_admin(organization_id));

-- ─── SEED: subscription plans ────────────────────────────────
INSERT INTO public.subscription_plans (
  name, slug, description, status, is_free,
  price_monthly, price_yearly, currency,
  max_businesses, max_branches, max_employees, max_services, max_appointments_pm,
  features, sort_order
) VALUES
  (
    'Free',
    'free',
    'Get started with ReserveHub at no cost. Perfect for new businesses.',
    'active'::public.subscription_plan_status,
    TRUE,
    0.00, 0.00, 'USD',
    1, 1, 5, 10, 100,
    jsonb_build_object(
      'online_booking',       TRUE,
      'email_notifications',  TRUE,
      'sms_notifications',    FALSE,
      'analytics',            FALSE,
      'custom_branding',      FALSE,
      'api_access',           FALSE,
      'priority_support',     FALSE
    ),
    1
  ),
  (
    'Starter',
    'starter',
    'For growing businesses that need more capacity and features.',
    'inactive'::public.subscription_plan_status,
    FALSE,
    29.00, 290.00, 'USD',
    1, 3, 15, 50, 500,
    jsonb_build_object(
      'online_booking',       TRUE,
      'email_notifications',  TRUE,
      'sms_notifications',    TRUE,
      'analytics',            TRUE,
      'custom_branding',      FALSE,
      'api_access',           FALSE,
      'priority_support',     FALSE
    ),
    2
  ),
  (
    'Professional',
    'professional',
    'For established businesses with multiple locations and staff.',
    'inactive'::public.subscription_plan_status,
    FALSE,
    79.00, 790.00, 'USD',
    3, 10, 50, NULL, NULL,
    jsonb_build_object(
      'online_booking',       TRUE,
      'email_notifications',  TRUE,
      'sms_notifications',    TRUE,
      'analytics',            TRUE,
      'custom_branding',      TRUE,
      'api_access',           TRUE,
      'priority_support',     TRUE
    ),
    3
  )
ON CONFLICT (slug) DO NOTHING;
