import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * mux-webhook
 *
 * Receives and validates Mux webhook events, then updates the corresponding
 * creator_videos row in Supabase.
 *
 * Signature verification is implemented with Deno's native Web Crypto API
 * (HMAC-SHA256), avoiding the broken `Mux.Webhooks.verifyHeader` static call.
 *
 * Required secrets:
 *   MUX_WEBHOOK_SECRET        — from Mux Dashboard → Webhooks → Secret column
 *   SUPABASE_URL              — auto-injected
 *   SUPABASE_SERVICE_ROLE_KEY — auto-injected
 *
 * Handled events:
 *   video.asset.ready   → sets mux_playback_id, mux_asset_id, mux_status='ready'
 *   video.asset.errored → sets mux_status='errored'
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, mux-signature",
};

// ── HMAC-SHA256 Mux signature verification ───────────────────────────────────
// Mux signs webhooks by computing HMAC-SHA256 over "<timestamp>.<rawBody>"
// and placing "t=<ts>,v1=<hex-sig>" in the "mux-signature" header.
async function verifyMuxSignature(
  rawBody: string,
  signatureHeader: string,
  secret: string,
): Promise<boolean> {
  if (!signatureHeader || !secret) return false;

  let timestamp = "";
  const expectedSigs: string[] = [];

  // Parse the header: "t=1234567890,v1=abc123...,v1=def456..."
  for (const part of signatureHeader.split(",")) {
    const trimmed = part.trim();
    const idx = trimmed.indexOf("=");
    if (idx > 0) {
      const key = trimmed.slice(0, idx);
      const val = trimmed.slice(idx + 1);
      if (key === "t") timestamp = val;
      if (key === "v1") expectedSigs.push(val);
    }
  }

  if (!timestamp || expectedSigs.length === 0) return false;

  // Import the secret as an HMAC-SHA256 key
  const keyMaterial = new TextEncoder().encode(secret);
  const key = await crypto.subtle.importKey(
    "raw",
    keyMaterial,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  // Compute HMAC over "<timestamp>.<rawBody>"
  const signedPayload = new TextEncoder().encode(`${timestamp}.${rawBody}`);
  const sigBuffer = await crypto.subtle.sign("HMAC", key, signedPayload);

  // Convert to hex
  const computedSig = Array.from(new Uint8Array(sigBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return expectedSigs.includes(computedSig);
}

// ─────────────────────────────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  // Read raw body before any parsing — required for signature verification
  const rawBody = await req.text();
  const muxSignature = req.headers.get("mux-signature") ?? "";
  const webhookSecret = Deno.env.get("MUX_WEBHOOK_SECRET") ?? "";

  // ── Signature Verification ────────────────────────────────────────────────
  const isValid = await verifyMuxSignature(rawBody, muxSignature, webhookSecret);
  if (!isValid) {
    console.error(
      "[mux-webhook] ❌ Signature invalid.",
      "header:", muxSignature.slice(0, 40) + "...",
      "secret_len:", webhookSecret.length,
    );
    // Return 401 — Mux will retry with exponential back-off
    return new Response("Unauthorized", { status: 401 });
  }
  console.log("[mux-webhook] ✅ Signature verified");

  // ── Parse Event ───────────────────────────────────────────────────────────
  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return new Response("Bad Request: invalid JSON", { status: 400 });
  }

  const eventType = event.type as string;
  const asset = event.data as Record<string, unknown>;

  console.log(`[mux-webhook] Received event: ${eventType}`);

  // ── Supabase Admin Client ─────────────────────────────────────────────────
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Event Routing ─────────────────────────────────────────────────────────
  switch (eventType) {
    case "video.asset.ready": {
      const videoId = asset.passthrough as string | undefined;
      if (!videoId) {
        console.warn("[mux-webhook] video.asset.ready missing passthrough");
        return new Response("OK (no passthrough)", { status: 200 });
      }

      const playbackIds =
        (asset.playback_ids as Array<{ id: string; policy: string }>) ?? [];
      const publicPlayback =
        playbackIds.find((p) => p.policy === "public") ?? playbackIds[0];

      if (!publicPlayback) {
        console.error("[mux-webhook] No playback ID on ready asset:", asset.id);
        return new Response("OK (no playback id)", { status: 200 });
      }

      const { error } = await supabase
        .from("creator_videos")
        .update({
          mux_asset_id: asset.id as string,
          mux_playback_id: publicPlayback.id,
          mux_status: "ready",
          duration_seconds: asset.duration
            ? Math.max(1, Math.round(asset.duration as number))
            : undefined,
          mux_duration_seconds: asset.duration ? (asset.duration as number) : undefined,
        })
        .eq("id", videoId);

      if (error) {
        console.error("[mux-webhook] DB update failed:", error);
        return new Response("Internal Server Error", { status: 500 });
      }

      console.log(`[mux-webhook] ✅ video ${videoId} → ready (${publicPlayback.id})`);
      break;
    }

    case "video.asset.errored": {
      const videoId = asset.passthrough as string | undefined;
      if (!videoId) {
        console.warn("[mux-webhook] video.asset.errored missing passthrough");
        return new Response("OK (no passthrough)", { status: 200 });
      }

      await supabase
        .from("creator_videos")
        .update({ mux_status: "errored" })
        .eq("id", videoId);

      console.log(`[mux-webhook] ⚠️ video ${videoId} → errored`);
      break;
    }

    default:
      console.log(`[mux-webhook] ℹ️ Unhandled event: ${eventType}`);
  }

  return new Response("OK", {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "text/plain" },
  });
});
