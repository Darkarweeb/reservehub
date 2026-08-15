import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Email Design System ──────────────────────────────────────────────────────

const BRAND = {
  primary: "#1E293B",
  accent: "#6366F1",
  accentLight: "#EEF2FF",
  success: "#10B981",
  warning: "#F59E0B",
  danger: "#EF4444",
  muted: "#64748B",
  border: "#E2E8F0",
  bg: "#F8FAFC",
  white: "#FFFFFF",
  text: "#1E293B",
  textLight: "#64748B",
};

// ─── App URL (production-configurable) ───────────────────────────────────────
// Set RESERVEHUB_APP_URL in Edge Function secrets for production.
// Falls back to the published preview URL.
function getAppUrl(): string {
  return Deno.env.get("RESERVEHUB_APP_URL") || "https://reservehub-9q3y-prod.rocketpreview.app";
}

function emailLayout(content: string, previewText: string): string {
  const appUrl = getAppUrl();
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <title>ReserveHub</title>
  <!--[if mso]><noscript><xml><o:OfficeDocumentSettings><o:PixelsPerInch>96</o:PixelsPerInch></o:OfficeDocumentSettings></xml></noscript><![endif]-->
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { background-color: ${BRAND.bg}; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; color: ${BRAND.text}; -webkit-text-size-adjust: 100%; }
    .email-wrapper { width: 100%; background-color: ${BRAND.bg}; padding: 32px 16px; }
    .email-container { max-width: 600px; margin: 0 auto; background-color: ${BRAND.white}; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.06); }
    .email-header { background: linear-gradient(135deg, ${BRAND.primary} 0%, #334155 100%); padding: 32px 40px; text-align: center; }
    .email-header .logo { display: inline-flex; align-items: center; gap: 10px; }
    .email-header .logo-icon { width: 36px; height: 36px; background: ${BRAND.accent}; border-radius: 10px; display: inline-flex; align-items: center; justify-content: center; }
    .email-header .logo-text { font-size: 20px; font-weight: 700; color: ${BRAND.white}; letter-spacing: -0.3px; }
    .email-body { padding: 40px; }
    .email-footer { background-color: ${BRAND.bg}; border-top: 1px solid ${BRAND.border}; padding: 24px 40px; text-align: center; }
    .email-footer p { font-size: 12px; color: ${BRAND.textLight}; line-height: 1.6; }
    .email-footer a { color: ${BRAND.accent}; text-decoration: none; }
    h1 { font-size: 24px; font-weight: 700; color: ${BRAND.text}; line-height: 1.3; margin-bottom: 8px; }
    h2 { font-size: 18px; font-weight: 600; color: ${BRAND.text}; margin-bottom: 16px; }
    p { font-size: 15px; color: ${BRAND.textLight}; line-height: 1.7; margin-bottom: 16px; }
    .greeting { font-size: 15px; color: ${BRAND.textLight}; margin-bottom: 24px; }
    .appointment-card { background: ${BRAND.bg}; border: 1px solid ${BRAND.border}; border-radius: 12px; padding: 24px; margin: 24px 0; }
    .appointment-card .date-time { display: flex; align-items: flex-start; gap: 16px; margin-bottom: 20px; padding-bottom: 20px; border-bottom: 1px solid ${BRAND.border}; }
    .appointment-card .date-badge { background: ${BRAND.accent}; color: ${BRAND.white}; border-radius: 10px; padding: 12px 16px; text-align: center; min-width: 64px; flex-shrink: 0; }
    .appointment-card .date-badge .day { font-size: 22px; font-weight: 800; line-height: 1; }
    .appointment-card .date-badge .month { font-size: 11px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; margin-top: 2px; }
    .appointment-card .time-info { flex: 1; }
    .appointment-card .time-info .time { font-size: 20px; font-weight: 700; color: ${BRAND.text}; }
    .appointment-card .time-info .tz { font-size: 12px; color: ${BRAND.textLight}; margin-top: 2px; }
    .detail-row { display: flex; align-items: flex-start; gap: 12px; margin-bottom: 12px; }
    .detail-row:last-child { margin-bottom: 0; }
    .detail-label { font-size: 12px; font-weight: 600; color: ${BRAND.textLight}; text-transform: uppercase; letter-spacing: 0.5px; min-width: 80px; padding-top: 2px; }
    .detail-value { font-size: 14px; font-weight: 500; color: ${BRAND.text}; flex: 1; }
    .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; text-transform: capitalize; }
    .status-confirmed { background: #D1FAE5; color: #065F46; }
    .status-pending { background: #FEF3C7; color: #92400E; }
    .status-cancelled { background: #FEE2E2; color: #991B1B; }
    .status-rescheduled { background: #E0E7FF; color: #3730A3; }
    .reference-box { background: ${BRAND.accentLight}; border: 1px solid #C7D2FE; border-radius: 8px; padding: 12px 16px; margin: 16px 0; display: flex; align-items: center; gap: 12px; }
    .reference-box .ref-label { font-size: 12px; color: ${BRAND.accent}; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
    .reference-box .ref-value { font-size: 14px; font-weight: 700; color: ${BRAND.accent}; font-family: 'Courier New', monospace; }
    .cta-button { display: block; width: fit-content; margin: 24px auto; background: ${BRAND.accent}; color: ${BRAND.white} !important; text-decoration: none; padding: 14px 32px; border-radius: 10px; font-size: 15px; font-weight: 600; text-align: center; letter-spacing: -0.1px; }
    .cta-button-secondary { display: block; width: fit-content; margin: 12px auto; background: transparent; color: ${BRAND.accent} !important; text-decoration: none; padding: 12px 28px; border-radius: 10px; font-size: 14px; font-weight: 600; text-align: center; border: 2px solid ${BRAND.accent}; }
    .divider { border: none; border-top: 1px solid ${BRAND.border}; margin: 24px 0; }
    .alert-box { border-radius: 10px; padding: 16px 20px; margin: 20px 0; }
    .alert-warning { background: #FFFBEB; border-left: 4px solid ${BRAND.warning}; }
    .alert-danger { background: #FFF5F5; border-left: 4px solid ${BRAND.danger}; }
    .alert-success { background: #F0FDF4; border-left: 4px solid ${BRAND.success}; }
    .summary-table { width: 100%; border-collapse: collapse; margin: 16px 0; }
    .summary-table th { background: ${BRAND.primary}; color: ${BRAND.white}; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; padding: 10px 12px; text-align: left; }
    .summary-table td { font-size: 13px; color: ${BRAND.text}; padding: 10px 12px; border-bottom: 1px solid ${BRAND.border}; }
    .summary-table tr:last-child td { border-bottom: none; }
    .summary-table tr:nth-child(even) td { background: ${BRAND.bg}; }
    .count-badge { display: inline-block; background: ${BRAND.accent}; color: white; border-radius: 20px; padding: 2px 10px; font-size: 13px; font-weight: 700; }
    @media (max-width: 600px) {
      .email-body { padding: 24px 20px; }
      .email-header { padding: 24px 20px; }
      .appointment-card { padding: 16px; }
      .appointment-card .date-time { flex-direction: column; gap: 12px; }
      .cta-button, .cta-button-secondary { width: 100%; display: block; }
    }
  </style>
</head>
<body>
  <div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">${previewText}</div>
  <div class="email-wrapper">
    <div class="email-container">
      <div class="email-header">
        <div class="logo">
          <div class="logo-icon">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="3" y="4" width="18" height="18" rx="3" stroke="white" stroke-width="2"/>
              <path d="M3 9H21" stroke="white" stroke-width="2"/>
              <path d="M8 2V6M16 2V6" stroke="white" stroke-width="2" stroke-linecap="round"/>
              <rect x="7" y="13" width="3" height="3" rx="0.5" fill="white"/>
              <rect x="11" y="13" width="3" height="3" rx="0.5" fill="white"/>
            </svg>
          </div>
          <span class="logo-text">ReserveHub</span>
        </div>
      </div>
      <div class="email-body">
        ${content}
      </div>
      <div class="email-footer">
        <p>This email was sent by <strong>ReserveHub</strong> on behalf of the business.<br/>
        If you have questions, please contact the business directly.</p>
        <p style="margin-top:8px;">
          <a href="${appUrl}">ReserveHub</a> &middot; 
          Appointment Management Platform
        </p>
      </div>
    </div>
  </div>
</body>
</html>`;
}

function appointmentCard(data: Record<string, unknown>): string {
  const dateParts = String(data.appointment_date || "").split(",");
  const dayNum = dateParts.length > 1 ? dateParts[1]?.trim().split(" ")[1] || "" : "";
  const monthStr = dateParts.length > 1 ? dateParts[1]?.trim().split(" ")[0] || "" : "";
  const statusClass = `status-${String(data.appointment_status || "pending").toLowerCase()}`;

  return `
    <div class="appointment-card">
      <div class="date-time">
        <div class="date-badge">
          <div class="day">${dayNum}</div>
          <div class="month">${monthStr.substring(0, 3)}</div>
        </div>
        <div class="time-info">
          <div class="time">${data.appointment_time || ""}</div>
          <div class="tz">${data.appointment_timezone || "UTC"}</div>
          <div style="margin-top:6px;">
            <span class="status-badge ${statusClass}">${data.appointment_status || "pending"}</span>
          </div>
        </div>
      </div>
      <div class="detail-row">
        <span class="detail-label">Business</span>
        <span class="detail-value">${data.business_name || ""}</span>
      </div>
      ${data.branch_name ? `<div class="detail-row"><span class="detail-label">Branch</span><span class="detail-value">${data.branch_name}${data.branch_city ? `, ${data.branch_city}` : ""}</span></div>` : ""}
      <div class="detail-row">
        <span class="detail-label">Service</span>
        <span class="detail-value">${data.service_name || ""}${data.service_duration ? ` <span style="color:${BRAND.textLight};font-size:12px;">(${data.service_duration} min)</span>` : ""}</span>
      </div>
      ${data.employee_name ? `<div class="detail-row"><span class="detail-label">With</span><span class="detail-value">${data.employee_name}</span></div>` : ""}
      ${data.service_price && Number(data.service_price) > 0 ? `<div class="detail-row"><span class="detail-label">Price</span><span class="detail-value">$${Number(data.service_price).toFixed(2)} <span style="color:${BRAND.textLight};font-size:12px;">(informational)</span></span></div>` : ""}
    </div>`;
}

function referenceBox(ref: string): string {
  return `<div class="reference-box">
    <div>
      <div class="ref-label">Booking Reference</div>
      <div class="ref-value">${ref}</div>
    </div>
  </div>`;
}

function manageLink(token: string): string {
  const url = `${getAppUrl()}/appointments/${token}`;
  return `<a href="${url}" class="cta-button">Manage Appointment</a>
  <p style="text-align:center;font-size:12px;color:${BRAND.textLight};">Or copy this link: <a href="${url}" style="color:${BRAND.accent};">${url}</a></p>`;
}

// ─── Template: Customer Booking Confirmation ──────────────────────────────────
function templateCustomerBookingConfirmation(data: Record<string, unknown>, token: string): { subject: string; html: string; text: string } {
  const subject = `Booking Confirmed – ${data.service_name} at ${data.business_name}`;
  const appUrl = getAppUrl();
  const content = `
    <h1>Your appointment is booked! 🎉</h1>
    <p class="greeting">Hi ${data.customer_name},</p>
    <p>Your appointment has been successfully booked. Here are your details:</p>
    ${appointmentCard(data)}
    ${referenceBox(String(data.appointment_reference || ""))}
    ${token ? manageLink(token) : ""}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">Need to cancel or reschedule? Use the link above to manage your appointment. Please check the cancellation policy before making changes.</p>
  `;
  const manageUrl = token ? `${appUrl}/appointments/${token}` : appUrl;
  const text = `Booking Confirmed\n\nHi ${data.customer_name},\n\nYour appointment is confirmed.\n\nBusiness: ${data.business_name}\nService: ${data.service_name}\nDate: ${data.appointment_date}\nTime: ${data.appointment_time} ${data.appointment_timezone}\nReference: ${data.appointment_reference}\n\nManage: ${manageUrl}`;
  return { subject, html: emailLayout(content, `Your ${data.service_name} appointment is confirmed`), text };
}

// ─── Template: Business New Appointment ──────────────────────────────────────
function templateBusinessNewAppointment(data: Record<string, unknown>): { subject: string; html: string; text: string } {
  const subject = `New Booking – ${data.customer_name} for ${data.service_name}`;
  const content = `
    <h1>New appointment booked</h1>
    <p class="greeting">Hi ${data.business_name} team,</p>
    <p>A new appointment has been booked through ${data.booking_source === "online" ? "your online booking page" : "the dashboard"}.</p>
    ${appointmentCard(data)}
    <div class="detail-row" style="margin-top:8px;">
      <span class="detail-label">Customer</span>
      <span class="detail-value">${data.customer_name}${data.customer_email ? ` &lt;${data.customer_email}&gt;` : ""}</span>
    </div>
    ${referenceBox(String(data.appointment_reference || ""))}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">Log in to your ReserveHub dashboard to manage this appointment.</p>
  `;
  const text = `New Booking\n\nCustomer: ${data.customer_name}\nService: ${data.service_name}\nDate: ${data.appointment_date}\nTime: ${data.appointment_time}\nBranch: ${data.branch_name}\nReference: ${data.appointment_reference}`;
  return { subject, html: emailLayout(content, `New booking from ${data.customer_name}`), text };
}

// ─── Template: Customer Cancellation Confirmation ────────────────────────────
function templateCustomerCancellationConfirmation(data: Record<string, unknown>): { subject: string; html: string; text: string } {
  const subject = `Appointment Cancelled – ${data.service_name} at ${data.business_name}`;
  const content = `
    <h1>Appointment cancelled</h1>
    <p class="greeting">Hi ${data.customer_name},</p>
    <div class="alert-box alert-warning">
      <p style="margin:0;font-size:14px;color:#92400E;">Your appointment has been cancelled. If this was a mistake, please contact the business to rebook.</p>
    </div>
    ${appointmentCard({ ...data, appointment_status: "cancelled" })}
    ${referenceBox(String(data.appointment_reference || ""))}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">To book a new appointment, visit the business page on ReserveHub.</p>
  `;
  const text = `Appointment Cancelled\n\nHi ${data.customer_name},\n\nYour appointment has been cancelled.\n\nBusiness: ${data.business_name}\nService: ${data.service_name}\nDate: ${data.appointment_date}\nTime: ${data.appointment_time}\nReference: ${data.appointment_reference}`;
  return { subject, html: emailLayout(content, `Your appointment has been cancelled`), text };
}

// ─── Template: Business Cancellation Notification ────────────────────────────
function templateBusinessCancellationNotification(data: Record<string, unknown>): { subject: string; html: string; text: string } {
  const subject = `Appointment Cancelled – ${data.customer_name} (${data.service_name})`;
  const content = `
    <h1>Appointment cancelled</h1>
    <p class="greeting">Hi ${data.business_name} team,</p>
    <div class="alert-box alert-danger">
      <p style="margin:0;font-size:14px;color:#991B1B;">A customer has cancelled their appointment.</p>
    </div>
    ${appointmentCard({ ...data, appointment_status: "cancelled" })}
    <div class="detail-row" style="margin-top:8px;">
      <span class="detail-label">Customer</span>
      <span class="detail-value">${data.customer_name}${data.customer_email ? ` &lt;${data.customer_email}&gt;` : ""}</span>
    </div>
    ${referenceBox(String(data.appointment_reference || ""))}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">The slot is now available for new bookings. Log in to your dashboard to manage your schedule.</p>
  `;
  const text = `Appointment Cancelled\n\nCustomer: ${data.customer_name}\nService: ${data.service_name}\nDate: ${data.appointment_date}\nTime: ${data.appointment_time}\nBranch: ${data.branch_name}\nReference: ${data.appointment_reference}`;
  return { subject, html: emailLayout(content, `Cancellation: ${data.customer_name}`), text };
}

// ─── Template: Customer Rescheduled ──────────────────────────────────────────
function templateCustomerRescheduled(data: Record<string, unknown>, token: string): { subject: string; html: string; text: string } {
  const subject = `Appointment Rescheduled – ${data.service_name} at ${data.business_name}`;
  const appUrl = getAppUrl();
  const content = `
    <h1>Appointment rescheduled</h1>
    <p class="greeting">Hi ${data.customer_name},</p>
    <div class="alert-box alert-success">
      <p style="margin:0;font-size:14px;color:#065F46;">Your appointment has been rescheduled to a new time.</p>
    </div>
    ${appointmentCard({ ...data, appointment_status: "rescheduled" })}
    ${referenceBox(String(data.appointment_reference || ""))}
    ${token ? manageLink(token) : ""}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">If you need to make further changes, use the link above.</p>
  `;
  const manageUrl = token ? `${appUrl}/appointments/${token}` : appUrl;
  const text = `Appointment Rescheduled\n\nHi ${data.customer_name},\n\nYour appointment has been rescheduled.\n\nBusiness: ${data.business_name}\nService: ${data.service_name}\nNew Date: ${data.appointment_date}\nNew Time: ${data.appointment_time}\nReference: ${data.appointment_reference}\n\nManage: ${manageUrl}`;
  return { subject, html: emailLayout(content, `Your appointment has been rescheduled`), text };
}

// ─── Template: Appointment Reminder ──────────────────────────────────────────
function templateAppointmentReminder(data: Record<string, unknown>, token: string, hoursLabel: string): { subject: string; html: string; text: string } {
  const subject = `Reminder: ${data.service_name} at ${data.business_name} – ${hoursLabel}`;
  const appUrl = getAppUrl();
  const content = `
    <h1>Appointment reminder</h1>
    <p class="greeting">Hi ${data.customer_name},</p>
    <p>This is a reminder that you have an upcoming appointment <strong>${hoursLabel}</strong>.</p>
    ${appointmentCard(data)}
    ${referenceBox(String(data.appointment_reference || ""))}
    ${token ? manageLink(token) : ""}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">If you need to cancel or reschedule, please do so as soon as possible to respect the business's cancellation policy.</p>
  `;
  const manageUrl = token ? `${appUrl}/appointments/${token}` : appUrl;
  const text = `Appointment Reminder\n\nHi ${data.customer_name},\n\nYou have an appointment ${hoursLabel}.\n\nBusiness: ${data.business_name}\nService: ${data.service_name}\nDate: ${data.appointment_date}\nTime: ${data.appointment_time}\nReference: ${data.appointment_reference}\n\nManage: ${manageUrl}`;
  return { subject, html: emailLayout(content, `Reminder: ${data.service_name} ${hoursLabel}`), text };
}

// ─── Template: Daily Summary ──────────────────────────────────────────────────
function templateDailySummary(data: Record<string, unknown>): { subject: string; html: string; text: string } {
  const subject = `Daily Summary – ${data.business_name} – ${data.summary_date}`;
  const appointments = (data.appointments as Array<Record<string, unknown>>) || [];
  const rows = appointments.map((a) => `
    <tr>
      <td>${a.time || ""}</td>
      <td>${a.customer_name || ""}</td>
      <td>${a.service_name || ""}</td>
      <td>${a.employee_name || ""}</td>
      <td><span class="status-badge status-${String(a.status || "pending").toLowerCase()}">${a.status || ""}</span></td>
    </tr>
  `).join("");

  const content = `
    <h1>Daily appointment summary</h1>
    <p class="greeting">Hi ${data.business_name} team,</p>
    <p>Here is your appointment summary for <strong>${data.summary_date}</strong>.</p>
    <div style="margin:16px 0;padding:12px 16px;background:${BRAND.accentLight};border-radius:8px;display:flex;gap:24px;flex-wrap:wrap;">
      <div><span style="font-size:24px;font-weight:800;color:${BRAND.accent};">${data.total_count || 0}</span><br/><span style="font-size:12px;color:${BRAND.textLight};">Total</span></div>
      <div><span style="font-size:24px;font-weight:800;color:#065F46;">${data.confirmed_count || 0}</span><br/><span style="font-size:12px;color:${BRAND.textLight};">Confirmed</span></div>
      <div><span style="font-size:24px;font-weight:800;color:#92400E;">${data.pending_count || 0}</span><br/><span style="font-size:12px;color:${BRAND.textLight};">Pending</span></div>
    </div>
    ${appointments.length > 0 ? `
    <table class="summary-table">
      <thead>
        <tr>
          <th>Time</th>
          <th>Customer</th>
          <th>Service</th>
          <th>Staff</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>` : `<p style="text-align:center;color:${BRAND.textLight};padding:24px 0;">No appointments scheduled for this day.</p>`}
    <hr class="divider" />
    <p style="font-size:13px;color:${BRAND.textLight};">Log in to your ReserveHub dashboard to manage today's schedule.</p>
  `;
  const text = `Daily Summary – ${data.business_name} – ${data.summary_date}\n\nTotal: ${data.total_count || 0} | Confirmed: ${data.confirmed_count || 0} | Pending: ${data.pending_count || 0}\n\n${appointments.map((a) => `${a.time} – ${a.customer_name} – ${a.service_name}`).join("\n")}`;
  return { subject, html: emailLayout(content, `${data.total_count || 0} appointments today`), text };
}

// ─── Template Router ──────────────────────────────────────────────────────────
function buildEmail(
  event: string,
  data: Record<string, unknown>,
  token: string
): { subject: string; html: string; text: string } | null {
  switch (event) {
    case "appointment_created":
    case "new_appointment":
      return templateCustomerBookingConfirmation(data, token);
    case "appointment_confirmed":
      return templateCustomerBookingConfirmation(data, token);
    case "appointment_cancelled":
      if (data.recipient_type === "business") {
        return templateBusinessCancellationNotification(data);
      }
      return templateCustomerCancellationConfirmation(data);
    case "appointment_rescheduled":
      return templateCustomerRescheduled(data, token);
    case "appointment_reminder":
    case "appointment_reminder_24h":
      return templateAppointmentReminder(data, token, "in 24 hours");
    case "appointment_reminder_2h":
      return templateAppointmentReminder(data, token, "in 2 hours");
    case "daily_appointment_summary":
      return templateDailySummary(data);
    case "business_new_appointment":
      return templateBusinessNewAppointment(data);
    default:
      return null;
  }
}

// ─── Retry backoff ────────────────────────────────────────────────────────────
function nextRetryAt(attemptCount: number): string {
  const delayMinutes = Math.min(Math.pow(2, attemptCount) * 5, 60);
  return new Date(Date.now() + delayMinutes * 60 * 1000).toISOString();
}

// ─── Main Handler ─────────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  try {
    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") || "";
    const RESEND_FROM_EMAIL = Deno.env.get("RESEND_FROM_EMAIL") || "onboarding@resend.dev";
    const RESEND_FROM_NAME = Deno.env.get("RESEND_FROM_NAME") || "ReserveHub";
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    if (!RESEND_API_KEY) {
      return new Response(JSON.stringify({ error: "RESEND_API_KEY not configured" }), {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Fetch pending notifications ────────────────────────────────────────
    const { data: notifications, error: fetchError } = await supabase
      .from("notification_queue")
      .select("*")
      .in("delivery_status", ["pending", "queued"])
      .lte("scheduled_at", new Date().toISOString())
      .lt("attempt_count", 3)
      .order("scheduled_at", { ascending: true })
      .limit(50);

    if (fetchError) throw fetchError;
    if (!notifications || notifications.length === 0) {
      return new Response(JSON.stringify({ processed: 0, message: "No pending notifications" }), {
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      });
    }

    let processed = 0;
    let failed = 0;

    for (const notification of notifications) {
      // Mark as queued to prevent double-processing
      await supabase
        .from("notification_queue")
        .update({
          delivery_status: "queued",
          first_attempt_at: notification.first_attempt_at || new Date().toISOString(),
          last_attempt_at: new Date().toISOString(),
          attempt_count: (notification.attempt_count || 0) + 1,
        })
        .eq("id", notification.id);

      try {
        // Resolve appointment token for manage links
        // Use 'booking' token type (as defined in appointment_tokens table)
        let appointmentToken = "";
        if (notification.appointment_id) {
          const { data: tokenRow } = await supabase
            .from("appointment_tokens")
            .select("token")
            .eq("appointment_id", notification.appointment_id)
            .eq("token_type", "booking")
            .eq("token_status", "active")
            .limit(1)
            .maybeSingle();
          appointmentToken = tokenRow?.token || "";
        }

        const templateData = notification.template_data || {};
        const email = buildEmail(notification.event, templateData, appointmentToken);

        if (!email) {
          await supabase
            .from("notification_queue")
            .update({
              delivery_status: "skipped",
              failure_reason: `No template for event: ${notification.event}`,
            })
            .eq("id", notification.id);
          continue;
        }

        // Send via Resend
        const resendResponse = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${RESEND_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: `${RESEND_FROM_NAME} <${RESEND_FROM_EMAIL}>`,
            to: [notification.recipient_email],
            subject: email.subject,
            html: email.html,
            text: email.text,
            tags: [
              { name: "event", value: notification.event },
              { name: "business_id", value: notification.business_id || "unknown" },
            ],
          }),
        });

        const resendData = await resendResponse.json();

        if (resendResponse.ok && resendData.id) {
          await supabase
            .from("notification_queue")
            .update({
              delivery_status: "sent",
              sent_at: new Date().toISOString(),
              provider_name: "resend",
              provider_message_id: resendData.id,
              provider_response: resendData,
              subject: email.subject,
              body_text: email.text,
            })
            .eq("id", notification.id);

          // Update daily summary if applicable
          if (notification.event === "daily_appointment_summary" && notification.business_id) {
            await supabase
              .from("daily_appointment_summaries")
              .update({
                delivery_status: "sent",
                sent_at: new Date().toISOString(),
                notification_id: notification.id,
              })
              .eq("business_id", notification.business_id)
              .eq("delivery_status", "pending");
          }

          processed++;
        } else {
          const errorMsg = resendData.message || resendData.error || "Unknown Resend error";
          const isPermanent = resendResponse.status === 422 || resendResponse.status === 400;

          await supabase
            .from("notification_queue")
            .update({
              delivery_status: isPermanent ? "failed" : "pending",
              failed_at: isPermanent ? new Date().toISOString() : null,
              failure_reason: errorMsg,
              next_retry_at: isPermanent ? null : nextRetryAt(notification.attempt_count || 0),
            })
            .eq("id", notification.id);

          failed++;
        }
      } catch (sendError) {
        const errMsg = sendError instanceof Error ? sendError.message : String(sendError);
        await supabase
          .from("notification_queue")
          .update({
            delivery_status: "pending",
            failure_reason: errMsg,
            next_retry_at: nextRetryAt(notification.attempt_count || 0),
          })
          .eq("id", notification.id);
        failed++;
      }
    }

    return new Response(
      JSON.stringify({ processed, failed, total: notifications.length }),
      { headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : String(error) }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
      }
    );
  }
});
