import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js";

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

  const token = authHeader.replace("Bearer ", "");

  const supabaseUser = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );

  const { data: { user }, error: authError } = await supabaseUser.auth.getUser(token);
  if (authError || !user) {
    return new Response(
      JSON.stringify({ error: "Unauthorized" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Parse Request Body ────────────────────────────────────────────────────
  let body: Record<string, any>;
  try {
    body = await req.json();
  } catch {
    return new Response(
      JSON.stringify({ error: "Invalid JSON body" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const { id: videoId } = body;
  if (!videoId) {
    return new Response(
      JSON.stringify({ error: "Missing required parameter: id" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Step 1: Fetch video and verify ownership ──────────────────────────────
  const { data: video, error: fetchError } = await supabaseAdmin
    .from("creator_videos")
    .select("creator_id, mux_asset_id, thumbnail_url, status")
    .eq("id", videoId)
    .single();

  if (fetchError || !video) {
    return new Response(
      JSON.stringify({ error: "Video not found" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (video.creator_id !== user.id) {
    return new Response(
      JSON.stringify({ error: "Forbidden: You do not own this video" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Step 2: Delete Mux asset (prevents continued CDN billing) ────────────
  const muxTokenId = Deno.env.get("MUX_TOKEN_ID");
  const muxTokenSecret = Deno.env.get("MUX_TOKEN_SECRET");
  const muxAssetId = video.mux_asset_id;

  if (muxAssetId && muxTokenId && muxTokenSecret) {
    try {
      const muxAuth = btoa(`${muxTokenId}:${muxTokenSecret}`);
      const muxRes = await fetch(`https://api.mux.com/video/v1/assets/${muxAssetId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Basic ${muxAuth}`,
          "Content-Type": "application/json",
        },
      });

      if (muxRes.ok || muxRes.status === 404) {
        // 404 means already deleted — treat as success
        console.log(`[delete-creator-video] Mux asset ${muxAssetId} deleted (status: ${muxRes.status})`);
      } else {
        const body = await muxRes.text();
        console.warn(`[delete-creator-video] Mux delete returned ${muxRes.status}: ${body}. Continuing with DB cleanup.`);
      }
    } catch (muxErr) {
      // Non-fatal — log and continue. DB row will still be removed.
      console.warn(`[delete-creator-video] Mux API error (non-fatal): ${muxErr}. Continuing with DB cleanup.`);
    }
  } else {
    console.log(`[delete-creator-video] No mux_asset_id or Mux credentials — skipping Mux cleanup.`);
  }

  // ── Step 3: Delete Storage thumbnail ─────────────────────────────────────
  const thumbnailUrl = video.thumbnail_url as string | null;
  if (thumbnailUrl && thumbnailUrl.includes("/storage/v1/object/")) {
    try {
      // Extract bucket and path from the URL
      const match = thumbnailUrl.match(/\/storage\/v1\/object\/(?:public\/)?([^/]+)\/(.+)$/);
      if (match) {
        const [, bucket, path] = match;
        const { error: storageErr } = await supabaseAdmin.storage.from(bucket).remove([path]);
        if (storageErr) {
          console.warn(`[delete-creator-video] Storage delete error (non-fatal): ${storageErr.message}`);
        } else {
          console.log(`[delete-creator-video] Thumbnail deleted from Storage: ${bucket}/${path}`);
        }
      }
    } catch (storageErr) {
      console.warn(`[delete-creator-video] Storage cleanup error (non-fatal): ${storageErr}`);
    }
  }

  // ── Step 4: Delete related records then the video row ────────────────────
  // Delete in dependency order to avoid FK violations.
  await supabaseAdmin.from("video_comments").delete().eq("video_id", videoId);
  await supabaseAdmin.from("video_interactions").delete().eq("video_id", videoId);
  await supabaseAdmin.from("video_reactions").delete().eq("video_id", videoId);
  await supabaseAdmin.from("creator_video_reports").delete().eq("video_id", videoId);

  const { error: deleteError } = await supabaseAdmin
    .from("creator_videos")
    .delete()
    .eq("id", videoId);

  if (deleteError) {
    console.error("[delete-creator-video] DB delete error:", deleteError);
    return new Response(
      JSON.stringify({ error: "Failed to delete video record", detail: deleteError.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  console.log(`[delete-creator-video] Successfully deleted video ${videoId} for user ${user.id}`);

  return new Response(
    JSON.stringify({ success: true }),
    { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
  );
});
