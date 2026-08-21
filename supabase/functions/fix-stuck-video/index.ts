import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Mux from "npm:@mux/mux-node";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * fix-stuck-video — ONE-SHOT admin utility
 *
 * Finds a Mux asset by scanning recent uploads for a matching passthrough (video DB id),
 * then patches the creator_videos row with the correct mux_asset_id, mux_playback_id, mux_status.
 *
 * Invoke:
 *   curl -X POST \
 *     -H "x-admin-secret: bassaw" \
 *     -H "Content-Type: application/json" \
 *     -d '{"video_id": "<UUID>"}' \
 *     https://lihaddxlyychswpkswbp.supabase.co/functions/v1/fix-stuck-video
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-secret",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const adminSecret = req.headers.get("x-admin-secret");
  if (adminSecret !== Deno.env.get("BACKFILL_ADMIN_SECRET")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const { video_id } = await req.json();
  if (!video_id) {
    return new Response(JSON.stringify({ error: "video_id required" }), {
      status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const mux = new Mux({
    tokenId: Deno.env.get("MUX_TOKEN_ID")!,
    tokenSecret: Deno.env.get("MUX_TOKEN_SECRET")!,
  });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  console.log(`[fix-stuck-video] Scanning Mux for passthrough=${video_id}...`);

  // Scan recent Mux uploads (direct uploads) for a matching passthrough
  // First check direct uploads, then check assets
  let foundAsset: Record<string, unknown> | null = null;

  // Check assets list for this passthrough
  try {
    let page: Record<string, unknown> = await mux.video.assets.list({ limit: 100 }) as Record<string, unknown>;
    outer: while (true) {
      const items = (page.data as Record<string, unknown>[]) ?? [];
      for (const a of items) {
        if (a.passthrough === video_id) {
          foundAsset = a;
          console.log(`[fix-stuck-video] Found asset: ${a.id} status=${a.status}`);
          break outer;
        }
      }
      const hasMore = typeof (page as { hasNextPage?: () => Promise<boolean> }).hasNextPage === "function"
        ? await (page as { hasNextPage: () => Promise<boolean> }).hasNextPage()
        : false;
      if (!hasMore) break;
      page = await (page as { getNextPage: () => Promise<Record<string, unknown>> }).getNextPage();
    }
  } catch (e) {
    console.error("[fix-stuck-video] Error scanning assets:", e);
  }

  // Also check direct uploads if no asset found
  if (!foundAsset) {
    try {
      const uploads = await mux.video.uploads.list({ limit: 100 });
      const uploadItems = (uploads as unknown as { data: Record<string, unknown>[] }).data ?? [];
      for (const u of uploadItems) {
        const settings = u.new_asset_settings as Record<string, unknown> | undefined;
        if (settings?.passthrough === video_id && u.asset_id) {
          console.log(`[fix-stuck-video] Found via upload: asset_id=${u.asset_id}`);
          try {
            foundAsset = await mux.video.assets.retrieve(u.asset_id as string) as Record<string, unknown>;
          } catch (e) {
            console.error("[fix-stuck-video] Could not retrieve asset:", e);
          }
          break;
        }
      }
    } catch (e) {
      console.error("[fix-stuck-video] Error scanning uploads:", e);
    }
  }

  if (!foundAsset) {
    return new Response(JSON.stringify({
      error: "No Mux asset found for this video ID",
      video_id,
      hint: "The upload may not have completed. Re-upload the video.",
    }), { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  if (foundAsset.status !== "ready") {
    return new Response(JSON.stringify({
      message: `Asset found but status=${foundAsset.status} — not ready yet`,
      asset_id: foundAsset.id,
      status: foundAsset.status,
    }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
  }

  // Get playback ID
  const playbackIds = (foundAsset.playback_ids as Array<{ id: string; policy: string }>) ?? [];
  const pub = playbackIds.find((p) => p.policy === "public") ?? playbackIds[0];

  if (!pub) {
    return new Response(JSON.stringify({ error: "Asset ready but no public playback ID" }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // Patch the DB row
  const { error: updateError } = await supabase
    .from("creator_videos")
    .update({
      mux_asset_id: foundAsset.id as string,
      mux_playback_id: pub.id,
      mux_status: "ready",
      duration_seconds: foundAsset.duration
        ? Math.max(1, Math.round(foundAsset.duration as number))
        : undefined,
      mux_duration_seconds: foundAsset.duration ?? undefined,
    })
    .eq("id", video_id);

  if (updateError) {
    return new Response(JSON.stringify({ error: "DB update failed", detail: updateError.message }), {
      status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  console.log(`[fix-stuck-video] ✅ Fixed ${video_id} → playback=${pub.id}`);

  return new Response(JSON.stringify({
    success: true,
    video_id,
    mux_asset_id: foundAsset.id,
    mux_playback_id: pub.id,
    mux_status: "ready",
  }), { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } });
});
