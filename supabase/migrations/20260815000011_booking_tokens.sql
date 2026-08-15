-- ============================================================
-- ReserveHub Migration 11: Booking Tokens & Appointment Management
-- Adds:
--   • appointment_tokens table (booking + cancellation tokens)
--   • Secure appointment lookup/confirm/cancel RPCs
--   • Token-based authorization (appointment_id alone ≠ auth)
-- ============================================================

-- ─── ENUM: Token Type ────────────────────────────────────────
DROP TYPE IF EXISTS public.token_type CASCADE;
CREATE TYPE public.token_type AS ENUM (
  'booking',
  'cancellation',
  'reschedule',
  'confirmation'
);

-- ─── ENUM: Token Status ──────────────────────────────────────
DROP TYPE IF EXISTS public.token_status CASCADE;
CREATE TYPE public.token_status AS ENUM (
  'active',
  'used',
  'expired',
  'revoked'
);

-- ─── TABLE: appointment_tokens ───────────────────────────────
-- Cryptographically secure, non-guessable tokens for appointment management.
-- A customer must present the correct token to manage their appointment.
-- appointment_id alone is NOT sufficient authorization.
CREATE TABLE IF NOT EXISTS public.appointment_tokens (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  appointment_id  UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,

  -- The token value — 64 hex chars (32 random bytes)
  token           TEXT NOT NULL,
  token_type      public.token_type   NOT NULL DEFAULT 'booking'::public.token_type,
  token_status    public.token_status NOT NULL DEFAULT 'active'::public.token_status,

  -- Expiry (NULL = no expiry for booking tokens; set for time-limited tokens)
  expires_at      TIMESTAMPTZ,

  -- Usage tracking
  used_at         TIMESTAMPTZ,
  used_ip         INET,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT appointment_tokens_token_not_empty CHECK (char_length(token) >= 32),
  CONSTRAINT appointment_tokens_unique_token UNIQUE (token)
);

-- ─── INDEXES: appointment_tokens ─────────────────────────────
CREATE INDEX IF NOT EXISTS idx_appt_tokens_appointment_id
  ON public.appointment_tokens(appointment_id);
CREATE INDEX IF NOT EXISTS idx_appt_tokens_token
  ON public.appointment_tokens(token)
  WHERE token_status = 'active';
CREATE INDEX IF NOT EXISTS idx_appt_tokens_org_id
  ON public.appointment_tokens(organization_id);

-- ─── TRIGGER: updated_at ─────────────────────────────────────
DROP TRIGGER IF EXISTS trg_appointment_tokens_updated_at ON public.appointment_tokens;
CREATE TRIGGER trg_appointment_tokens_updated_at
  BEFORE UPDATE ON public.appointment_tokens
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- ─── ENABLE RLS: appointment_tokens ──────────────────────────
ALTER TABLE public.appointment_tokens ENABLE ROW LEVEL SECURITY;

-- Org members can read tokens for their organization
DROP POLICY IF EXISTS "appt_tokens_member_select" ON public.appointment_tokens;
CREATE POLICY "appt_tokens_member_select"
  ON public.appointment_tokens FOR SELECT TO authenticated
  USING (public.is_org_member(organization_id));

-- No direct INSERT/UPDATE/DELETE for anon or authenticated app users.
-- All token operations go through SECURITY DEFINER functions.

-- ─── FUNCTION: get_appointment_by_token ──────────────────────
-- Allows a customer to look up their appointment using their secure token.
-- Returns only safe, customer-facing appointment data.
-- Never exposes: internal notes, employee private data, org data, CRM data.
CREATE OR REPLACE FUNCTION public.get_appointment_by_token(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_token   RECORD;
  v_appt    RECORD;
  v_result  JSONB;
BEGIN
  -- Validate token
  SELECT at.id, at.appointment_id, at.token_status, at.expires_at
  INTO v_token
  FROM public.appointment_tokens at
  WHERE at.token        = p_token
    AND at.token_status = 'active'::public.token_status
    AND at.token_type   IN ('booking'::public.token_type, 'confirmation'::public.token_type)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Invalid or expired token.');
  END IF;

  IF v_token.expires_at IS NOT NULL AND v_token.expires_at < NOW() THEN
    -- Mark token as expired
    UPDATE public.appointment_tokens
    SET token_status = 'expired'::public.token_status
    WHERE id = v_token.id;
    RETURN jsonb_build_object('error', 'Token has expired.');
  END IF;

  -- Fetch appointment (safe fields only)
  SELECT
    a.id,
    a.status,
    a.title,
    a.notes,
    a.starts_at,
    a.ends_at,
    a.duration_mins,
    a.timezone,
    a.total_price,
    a.currency,
    a.cancelled_at,
    a.cancellation_reason,
    b.name  AS business_name,
    b.slug  AS business_slug,
    b.phone AS business_phone,
    b.email AS business_email,
    br.name AS branch_name,
    br.address_line1,
    br.city,
    br.state,
    br.country
  INTO v_appt
  FROM public.appointments a
    JOIN public.businesses b  ON b.id  = a.business_id
    JOIN public.branches   br ON br.id = a.branch_id
  WHERE a.id = v_token.appointment_id
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found.');
  END IF;

  SELECT jsonb_build_object(
    'appointment_id',      v_appt.id,
    'status',              v_appt.status,
    'title',               v_appt.title,
    'notes',               v_appt.notes,
    'starts_at',           v_appt.starts_at,
    'ends_at',             v_appt.ends_at,
    'duration_mins',       v_appt.duration_mins,
    'timezone',            v_appt.timezone,
    'total_price',         v_appt.total_price,
    'currency',            v_appt.currency,
    'cancelled_at',        v_appt.cancelled_at,
    'cancellation_reason', v_appt.cancellation_reason,
    'business',            jsonb_build_object(
                             'name',  v_appt.business_name,
                             'slug',  v_appt.business_slug,
                             'phone', v_appt.business_phone,
                             'email', v_appt.business_email
                           ),
    'branch',              jsonb_build_object(
                             'name',         v_appt.branch_name,
                             'address_line1', v_appt.address_line1,
                             'city',          v_appt.city,
                             'state',         v_appt.state,
                             'country',       v_appt.country
                           ),
    'services',            COALESCE((
      SELECT jsonb_agg(jsonb_build_object(
        'name',          aps.service_name,
        'duration_mins', aps.duration_mins,
        'price',         aps.price,
        'currency',      aps.currency
      ))
      FROM public.appointment_services aps
      WHERE aps.appointment_id = v_appt.id
    ), '[]'::JSONB)
  ) INTO v_result;

  RETURN v_result;
END;
$$;

REVOKE ALL ON FUNCTION public.get_appointment_by_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_appointment_by_token(TEXT) TO anon, authenticated;

-- ─── FUNCTION: confirm_appointment_by_token ──────────────────
-- Allows a customer to confirm their pending appointment.
CREATE OR REPLACE FUNCTION public.confirm_appointment_by_token(p_token TEXT)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_token  RECORD;
  v_status public.appointment_status;
BEGIN
  SELECT at.id, at.appointment_id, at.token_status, at.expires_at
  INTO v_token
  FROM public.appointment_tokens at
  WHERE at.token        = p_token
    AND at.token_status = 'active'::public.token_status
    AND at.token_type   IN ('booking'::public.token_type, 'confirmation'::public.token_type)
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Invalid or expired token.');
  END IF;

  IF v_token.expires_at IS NOT NULL AND v_token.expires_at < NOW() THEN
    UPDATE public.appointment_tokens
    SET token_status = 'expired'::public.token_status
    WHERE id = v_token.id;
    RETURN jsonb_build_object('error', 'Token has expired.');
  END IF;

  SELECT status INTO v_status
  FROM public.appointments
  WHERE id = v_token.appointment_id;

  IF v_status IN ('cancelled'::public.appointment_status, 'no_show'::public.appointment_status) THEN
    RETURN jsonb_build_object('error', 'Appointment cannot be confirmed in its current state.');
  END IF;

  UPDATE public.appointments
  SET status       = 'confirmed'::public.appointment_status,
      confirmed_at = NOW()
  WHERE id = v_token.appointment_id
    AND status = 'pending'::public.appointment_status;

  RETURN jsonb_build_object(
    'status',         'success',
    'appointment_id', v_token.appointment_id,
    'confirmed_at',   NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.confirm_appointment_by_token(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_appointment_by_token(TEXT) TO anon, authenticated;

-- ─── FUNCTION: cancel_appointment_by_token ───────────────────
-- Allows a customer to cancel their appointment using their cancellation token.
-- Validates cancellation policy (minimum notice) before allowing cancellation.
CREATE OR REPLACE FUNCTION public.cancel_appointment_by_token(
  p_cancel_token TEXT,
  p_reason       TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_token       RECORD;
  v_appt        RECORD;
  v_policy      RECORD;
  v_min_notice  INTERVAL;
  v_notice_unit TEXT;
BEGIN
  -- Validate cancellation token
  SELECT at.id, at.appointment_id, at.token_status, at.expires_at
  INTO v_token
  FROM public.appointment_tokens at
  WHERE at.token        = p_cancel_token
    AND at.token_status = 'active'::public.token_status
    AND at.token_type   = 'cancellation'::public.token_type
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Invalid or expired cancellation token.');
  END IF;

  IF v_token.expires_at IS NOT NULL AND v_token.expires_at < NOW() THEN
    UPDATE public.appointment_tokens
    SET token_status = 'expired'::public.token_status
    WHERE id = v_token.id;
    RETURN jsonb_build_object('error', 'Cancellation token has expired.');
  END IF;

  -- Fetch appointment
  SELECT a.id, a.status, a.starts_at, a.business_id, a.branch_id, a.cancelled_at
  INTO v_appt
  FROM public.appointments a
  WHERE a.id = v_token.appointment_id
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Appointment not found.');
  END IF;

  IF v_appt.status IN (
    'cancelled'::public.appointment_status,
    'no_show'::public.appointment_status,
    'completed'::public.appointment_status
  ) THEN
    RETURN jsonb_build_object('error', 'Appointment cannot be cancelled in its current state.');
  END IF;

  -- Check cancellation policy
  SELECT cp.cancellation_enabled, cp.min_notice_value, cp.min_notice_unit
  INTO v_policy
  FROM public.cancellation_policies cp
  WHERE cp.business_id = v_appt.business_id
    AND (cp.branch_id = v_appt.branch_id OR cp.branch_id IS NULL)
  ORDER BY cp.branch_id NULLS LAST
  LIMIT 1;

  IF FOUND AND v_policy.cancellation_enabled = FALSE THEN
    RETURN jsonb_build_object('error', 'Cancellations are not permitted for this business.');
  END IF;

  IF FOUND AND v_policy.min_notice_value > 0 THEN
    v_notice_unit := v_policy.min_notice_unit::TEXT;
    v_min_notice  := (v_policy.min_notice_value || ' ' || v_notice_unit)::INTERVAL;

    IF v_appt.starts_at - NOW() < v_min_notice THEN
      RETURN jsonb_build_object(
        'error',
        'Cancellation requires at least ' || v_policy.min_notice_value || ' ' || v_notice_unit || ' notice.'
      );
    END IF;
  END IF;

  -- Cancel the appointment
  UPDATE public.appointments
  SET status              = 'cancelled'::public.appointment_status,
      cancelled_at        = NOW(),
      cancellation_reason = p_reason
  WHERE id = v_token.appointment_id;

  -- Mark cancellation token as used
  UPDATE public.appointment_tokens
  SET token_status = 'used'::public.token_status,
      used_at      = NOW()
  WHERE id = v_token.id;

  -- Revoke the booking token as well
  UPDATE public.appointment_tokens
  SET token_status = 'revoked'::public.token_status
  WHERE appointment_id = v_token.appointment_id
    AND token_type     = 'booking'::public.token_type
    AND token_status   = 'active'::public.token_status;

  RETURN jsonb_build_object(
    'status',         'success',
    'appointment_id', v_token.appointment_id,
    'cancelled_at',   NOW()
  );
END;
$$;

REVOKE ALL ON FUNCTION public.cancel_appointment_by_token(TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_appointment_by_token(TEXT, TEXT) TO anon, authenticated;

-- ─── FUNCTION: store_appointment_tokens (internal) ───────────
-- Called by book_appointment to persist tokens after appointment creation.
-- Separated to keep book_appointment clean.
-- This is called internally — not exposed to anon.
CREATE OR REPLACE FUNCTION public.store_appointment_tokens(
  p_organization_id UUID,
  p_appointment_id  UUID,
  p_booking_token   TEXT,
  p_cancel_token    TEXT
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.appointment_tokens (
    organization_id, appointment_id, token, token_type, token_status
  ) VALUES
    (p_organization_id, p_appointment_id, p_booking_token,
     'booking'::public.token_type, 'active'::public.token_status),
    (p_organization_id, p_appointment_id, p_cancel_token,
     'cancellation'::public.token_type, 'active'::public.token_status)
  ON CONFLICT (token) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.store_appointment_tokens(UUID, UUID, TEXT, TEXT) FROM PUBLIC;
-- Only called internally by book_appointment (SECURITY DEFINER chain)
