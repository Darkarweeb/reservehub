import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { createHmac } from "https://deno.land/std@0.192.0/node/crypto.ts";

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
    const RESEND_WEBHOOK_SECRET = Deno.env.get("RESEND_WEBHOOK_SECRET") || "";
    const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

    const rawBody = await req.text();

    // ── Verify webhook signature ───────────────────────────────────────────
    if (RESEND_WEBHOOK_SECRET) {
      const svixId = req.headers.get("svix-id") || "";
      const svixTimestamp = req.headers.get("svix-timestamp") || "";
      const svixSignature = req.headers.get("svix-signature") || "";

      if (!svixId || !svixTimestamp || !svixSignature) {
        return new Response(JSON.stringify({ error: "Missing webhook signature headers" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }

      // Verify timestamp is within 5 minutes
      const timestampMs = parseInt(svixTimestamp) * 1000;
      if (Math.abs(Date.now() - timestampMs) > 5 * 60 * 1000) {
        return new Response(JSON.stringify({ error: "Webhook timestamp too old" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }

      // Compute expected signature
      const signedContent = `${svixId}.${svixTimestamp}.${rawBody}`;
      const secretBytes = RESEND_WEBHOOK_SECRET.startsWith("whsec_")
        ? atob(RESEND_WEBHOOK_SECRET.slice(6))
        : RESEND_WEBHOOK_SECRET;

      const hmac = createHmac("sha256", secretBytes);
      hmac.update(signedContent);
      const computedSig = `v1,${btoa(hmac.digest("binary"))}`;

      const signatures = svixSignature.split(" ");
      const isValid = signatures.some((sig: string) => sig === computedSig);

      if (!isValid) {
        return new Response(JSON.stringify({ error: "Invalid webhook signature" }), {
          status: 401,
          headers: { "Content-Type": "application/json" },
        });
      }
    }

    const payload = JSON.parse(rawBody);
    const eventType = payload.type as string;
    const emailData = payload.data as Record<string, unknown>;

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Map Resend event to delivery_status ───────────────────────────────
    let deliveryStatus: string | null = null;
    let updateFields: Record<string, unknown> = {};

    switch (eventType) {
      case "email.delivered":
        deliveryStatus = "delivered";
        updateFields = {
          delivery_status: "delivered",
          delivered_at: new Date().toISOString(),
          provider_response: emailData,
        };
        break;
      case "email.bounced":
        deliveryStatus = "bounced";
        updateFields = {
          delivery_status: "bounced",
          failed_at: new Date().toISOString(),
          failure_reason: `Bounced: ${emailData.bounce_type || "unknown"}`,
          provider_response: emailData,
        };
        break;
      case "email.complained":
        deliveryStatus = "failed";
        updateFields = {
          delivery_status: "failed",
          failed_at: new Date().toISOString(),
          failure_reason: "Spam complaint received",
          provider_response: emailData,
        };
        break;
      case "email.delivery_delayed":
        // Keep as sent, just log the delay
        updateFields = {
          provider_response: emailData,
        };
        break;
      default:
        return new Response(JSON.stringify({ received: true, event: eventType, action: "ignored" }), {
          headers: { "Content-Type": "application/json" },
        });
    }

    // ── Find notification by provider_message_id ──────────────────────────
    const messageId = emailData.email_id as string;
    if (!messageId) {
      return new Response(JSON.stringify({ received: true, warning: "No email_id in payload" }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: notification } = await supabase
      .from("notification_queue")
      .select("id, business_id, event")
      .eq("provider_message_id", messageId)
      .limit(1)
      .maybeSingle();

    if (notification) {
      await supabase
        .from("notification_queue")
        .update({ ...updateFields, updated_at: new Date().toISOString() })
        .eq("id", notification.id);

      // Update daily summary if applicable
      if (
        notification.event === "daily_appointment_summary" &&
        notification.business_id &&
        deliveryStatus === "delivered"
      ) {
        await supabase
          .from("daily_appointment_summaries")
          .update({ delivery_status: "delivered" })
          .eq("business_id", notification.business_id)
          .eq("notification_id", notification.id);
      }
    }

    return new Response(
      JSON.stringify({ received: true, event: eventType, notification_id: notification?.id }),
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
