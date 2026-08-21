import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Mux from "npm:@mux/mux-node";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * create-mux-upload
 *
 * Called by the Flutter client BEFORE uploading a video.
 * - Creates a creator_videos DB row
 * - Creates a Mux Direct Upload URL
 * - Returns { upload_url, video_id } to Flutter
 *
 * Flutter then PUTs the video file bytes directly to upload_url (no Supabase Storage).
 * The thumbnail is uploaded separately to Supabase Storage and PATCH'd onto the row.
 *
 * Required secrets:
 *   MUX_TOKEN_ID          — from Mux Dashboard → Settings → Access Tokens
 *   MUX_TOKEN_SECRET      — from Mux Dashboard → Settings → Access Tokens
 *   SUPABASE_URL          — auto-injected
 *   SUPABASE_SERVICE_ROLE_KEY — auto-injected
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", { status: 405, headers: corsHeaders });
  }

  // ── Auth: Verify user JWT ─────────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(
      JSON.stringify({ error: "Missing or invalid Authorization header" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // Extract the raw token string
  const token = authHeader.replace("Bearer ", "");

  // Verify JWT using anon key client explicitly with the user's token
  const supabaseUser = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!
  );

  const { data: { user }, error: authError } = await supabaseUser.auth.getUser(token);
  if (authError || !user) {
    console.error("[create-mux-upload] Auth error:", authError?.message, authError?.status);
    return new Response(
      JSON.stringify({ error: "Unauthorized", detail: authError?.message }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Parse Request Body ────────────────────────────────────────────────────
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const {
    title,
    description,
    tags = [],
    tmdb_id,
    tmdb_type,
    tmdb_title,
    spoiler = false,
    duration_seconds = 0,
    aspect_ratio = "9:16",
  } = body as {
    title?: string;
    description?: string;
    tags?: string[];
    tmdb_id?: number;
    tmdb_type?: string;
    tmdb_title?: string;
    spoiler?: boolean;
    duration_seconds?: number;
    aspect_ratio?: string;
  };

  // ── Admin Supabase Client (bypasses RLS for insert) ───────────────────────
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Step 1: Insert creator_videos row ─────────────────────────────────────
  // video_url is set to empty string as a placeholder — it will never be
  // populated for Mux-uploaded videos (the HLS URL is derived from mux_playback_id).
  // Using a sentinel value satisfies the NOT NULL constraint on video_url.
  const { data: videoRow, error: insertError } = await supabaseAdmin
    .from("creator_videos")
    .insert({
      creator_id: user.id,
      video_url: "", // sentinel — overridden by mux_playback_id after encoding
      title: title || null,
      description: description ?? "",
      tags,
      tmdb_id: tmdb_id ?? null,
      tmdb_type: tmdb_type ?? null,
      tmdb_title: tmdb_id ? (tmdb_title ?? title ?? null) : null,
      spoiler,
      // Use null when duration is unknown (0) — Mux reports real duration via webhook.
      // DB has CHECK (duration_seconds > 0) so we must not send 0.
      duration_seconds: duration_seconds && duration_seconds > 0 ? duration_seconds : null,
      status: "pending",        // Moderation gate — admin still approves for feed
      mux_status: "processing", // Mux encoding lifecycle
    })
    .select("id")
    .single();

  if (insertError || !videoRow) {
    console.error("[create-mux-upload] DB insert error:", insertError);
    return new Response(
      JSON.stringify({ error: "Failed to create video record", detail: insertError?.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const videoId = videoRow.id as string;
  console.log(`[create-mux-upload] Created creator_videos row: ${videoId}`);

  // ── Step 2: Create Mux Direct Upload URL ─────────────────────────────────
  const mux = new Mux({
    tokenId: Deno.env.get("MUX_TOKEN_ID")!,
    tokenSecret: Deno.env.get("MUX_TOKEN_SECRET")!,
  });

  let directUpload: Awaited<ReturnType<typeof mux.video.uploads.create>>;
  try {
    directUpload = await mux.video.uploads.create({
      cors_origin: "*",
      new_asset_settings: {
        playback_policy: ["public"],
        encoding_tier: "smart", // Cost-efficient HLS with per-title encoding
        passthrough: videoId,   // Used by mux-webhook to find the DB row
      },
    });
  } catch (err) {
    console.error("[create-mux-upload] Mux API error:", err);

    // Clean up the orphaned DB row
    await supabaseAdmin.from("creator_videos").delete().eq("id", videoId);

    return new Response(
      JSON.stringify({ error: "Failed to create Mux upload URL" }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  console.log(`[create-mux-upload] Mux upload ID: ${directUpload.id} for video ${videoId}`);

  // ── Step 3: Return upload URL + video ID to Flutter ───────────────────────
  return new Response(
    JSON.stringify({
      upload_url: directUpload.url,
      mux_upload_id: directUpload.id,
      video_id: videoId,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
