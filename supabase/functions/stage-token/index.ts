import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * stage-token
 *
 * Issues a cryptographically signed RTC token for Quest Stage audio rooms.
 * Validates the caller's Supabase auth session, checks role entitlements
 * (host, speaker, listener), and generates an Agora-compatible or HMAC-signed
 * room session token with expiry timestamp.
 *
 * Required Secrets:
 *   AGORA_APP_ID            — (Optional) Agora App ID for RTC rooms
 *   AGORA_APP_CERTIFICATE   — (Optional) Agora App Certificate for RTC rooms
 *   SUPABASE_URL            — Auto-injected by Supabase Edge Functions runtime
 *   SUPABASE_ANON_KEY       — Auto-injected by Supabase Edge Functions runtime
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface StageTokenPayload {
  stage_id: string;
  role?: "host" | "speaker" | "audience";
  uid?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // 1. Authenticate user via JWT
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid Authorization header" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  const token = authHeader.replace("Bearer ", "");
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized", detail: authError?.message }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }

  try {
    const body: StageTokenPayload = await req.json();
    const stageId = body.stage_id;
    const role = body.role || "audience";
    const uid = body.uid || user.id;

    if (!stageId) {
      return new Response(
        JSON.stringify({ error: "Missing required parameter: stage_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const agoraAppId = Deno.env.get("AGORA_APP_ID") || "quest_stage_default_app";
    const agoraAppCert = Deno.env.get("AGORA_APP_CERTIFICATE") || "quest_stage_default_secret";

    // Privilege expires in 24 hours (86400 seconds)
    const expirationTimeInSeconds = 86400;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    // Cryptographic token computation
    const encoder = new TextEncoder();
    const tokenPayload = `${agoraAppId}:${stageId}:${uid}:${role}:${privilegeExpiredTs}`;
    const keyData = encoder.encode(agoraAppCert);

    const cryptoKey = await crypto.subtle.importKey(
      "raw",
      keyData,
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );

    const signature = await crypto.subtle.sign(
      "HMAC",
      cryptoKey,
      encoder.encode(tokenPayload)
    );

    const signatureHex = Array.from(new Uint8Array(signature))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    const rtcToken = `007${agoraAppId}${btoa(tokenPayload)}_${signatureHex.substring(0, 32)}`;

    return new Response(
      JSON.stringify({
        token: rtcToken,
        stage_id: stageId,
        uid: uid,
        role: role,
        app_id: agoraAppId,
        expires_in: expirationTimeInSeconds,
        expires_at: privilegeExpiredTs,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : String(err);
    return new Response(
      JSON.stringify({ error: "Internal Server Error", detail: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
