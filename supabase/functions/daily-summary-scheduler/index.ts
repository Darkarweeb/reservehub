import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ─── Daily Summary Scheduler ──────────────────────────────────────────────────
// This function is called by Supabase Cron every 15 minutes.
// It determines which businesses are due for their 7:00 AM local summary,
// enqueues the notifications, and then triggers the send-notification function.
//
// Cron schedule: */15 * * * *  (every 15 minutes)
// This ensures the 7:00 AM window is caught regardless of exact timing.

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
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Step 1: Enqueue daily summaries via DB function ───────────────────
    const { data: summaryResult, error: summaryError } = await supabase
      .rpc("enqueue_daily_summaries");

    if (summaryError) {
      console.error("enqueue_daily_summaries error:", summaryError);
    }

    // ── Step 2: Enqueue 24h reminders ─────────────────────────────────────
    const { data: reminder24Result, error: reminder24Error } = await supabase
      .rpc("enqueue_appointment_reminders", { p_hours_before: 24 });

    if (reminder24Error) {
      console.error("enqueue_appointment_reminders(24h) error:", reminder24Error);
    }

    // ── Step 3: Enqueue 2h reminders ──────────────────────────────────────
    const { data: reminder2Result, error: reminder2Error } = await supabase
      .rpc("enqueue_appointment_reminders", { p_hours_before: 2 });

    if (reminder2Error) {
      console.error("enqueue_appointment_reminders(2h) error:", reminder2Error);
    }

    // ── Step 4: Trigger send-notification to process the queue ────────────
    const sendUrl = `${SUPABASE_URL}/functions/v1/send-notification`;
    const sendResponse = await fetch(sendUrl, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ trigger: "scheduler" }),
    });

    const sendResult = await sendResponse.json();

    return new Response(
      JSON.stringify({
        success: true,
        summaries_enqueued: summaryResult ?? 0,
        reminders_24h_enqueued: reminder24Result ?? 0,
        reminders_2h_enqueued: reminder2Result ?? 0,
        notifications_sent: sendResult,
        timestamp: new Date().toISOString(),
      }),
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
