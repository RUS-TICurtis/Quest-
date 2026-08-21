import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Mux from "npm:@mux/mux-node";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * sync-mux-status
 *
 * Admin utility: finds creator_videos rows that are stuck (mux_status='processing'
 * OR mux_status='ready' with missing mux_playback_id), queries Mux for each one,
 * and patches the DB row if the Mux asset is ready.
 *
 * Invoke:
 *   curl -X POST \
 *     -H "x-admin-secret: finishd-sync-2026" \
 *     -H "Authorization: Bearer <SUPABASE_ANON_KEY>" \
 *     https://lihaddxlyychswpkswbp.supabase.co/functions/v1/sync-mux-status
 */

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-admin-secret",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  // ── Guard ──────────────────────────────────────────────────────────────────
  const adminSecret = req.headers.get("x-admin-secret");
  const expectedSecret = Deno.env.get("BACKFILL_ADMIN_SECRET");
  if (!expectedSecret || adminSecret !== expectedSecret) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const muxTokenId = Deno.env.get("MUX_TOKEN_ID");
  const muxTokenSecret = Deno.env.get("MUX_TOKEN_SECRET");

  if (!muxTokenId || !muxTokenSecret) {
    return new Response(
      JSON.stringify({ error: "MUX_TOKEN_ID or MUX_TOKEN_SECRET not set" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  const mux = new Mux({ tokenId: muxTokenId, tokenSecret: muxTokenSecret });

  const results = {
    scanned: 0,
    updated: 0,
    already_ok: 0,
    no_mux_asset: 0,
    errors: [] as string[],
  };

  console.log("[sync-mux-status] Starting DB-first sync...");

  // ── Step 1: Find all stuck videos ─────────────────────────────────────────
  // Case A: mux_status='processing' with mux_asset_id set (normal stuck — Mux webhook missed)
  // Case B: mux_status='ready' but mux_playback_id is null (partial webhook — wrote status but not playback_id)
  const { data: stuckVideos, error: dbErr } = await supabase
    .from("creator_videos")
    .select("id, mux_asset_id, mux_playback_id, mux_status")
    .or(
      "and(mux_status.eq.processing,mux_asset_id.not.is.null)," +
      "and(mux_status.eq.ready,mux_playback_id.is.null)",
    )
    .limit(100);

  if (dbErr) {
    console.error("[sync-mux-status] DB fetch error:", dbErr);
    return new Response(
      JSON.stringify({ error: "DB fetch failed", detail: dbErr.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (!stuckVideos || stuckVideos.length === 0) {
    console.log("[sync-mux-status] No stuck videos found. All good!");
    return new Response(
      JSON.stringify({ ...results, message: "No stuck videos found" }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  console.log(`[sync-mux-status] Found ${stuckVideos.length} stuck video(s). Checking Mux...`);
  results.scanned = stuckVideos.length;

  // ── Helper: resolve a Mux asset by scanning via passthrough ───────────────
  async function findAssetByPassthrough(videoId: string): Promise<any | null> {
    let page: any = await mux.video.assets.list({ limit: 25 });
    while (true) {
      const items: any[] = page.data ?? [];
      for (const a of items) {
        if (a.passthrough === videoId) return a;
      }
      const hasMore = typeof page.hasNextPage === "function"
        ? await page.hasNextPage()
        : false;
      if (!hasMore) break;
      page = await page.getNextPage();
    }
    return null;
  }

  // ── Helper: write a resolved Mux asset back to DB ─────────────────────────
  async function patchRow(videoId: string, asset: any): Promise<boolean> {
    const playbackIds: any[] = asset.playback_ids ?? [];
    const pub = playbackIds.find((p: any) => p.policy === "public") ?? playbackIds[0];
    if (!pub) {
      results.errors.push(`${videoId}: ready in Mux but no public playback ID`);
      return false;
    }
    const { error } = await supabase
      .from("creator_videos")
      .update({
        mux_asset_id: asset.id,
        mux_playback_id: pub.id,
        mux_status: "ready",
        duration_seconds: asset.duration ? Math.round(asset.duration) : undefined,
      })
      .eq("id", videoId);
    if (error) {
      results.errors.push(`${videoId}: DB update failed — ${error.message}`);
      return false;
    }
    results.updated++;
    console.log(`[sync-mux-status] ✅ Fixed ${videoId} → playback=${pub.id}`);
    return true;
  }

  // ── Step 2: Process each stuck video ──────────────────────────────────────
  for (const video of stuckVideos) {
    const videoId = video.id as string;
    const muxAssetId = video.mux_asset_id as string | null;

    try {
      let asset: any;

      if (muxAssetId) {
        // Case A: we have the asset ID — retrieve directly (fast)
        asset = await mux.video.assets.retrieve(muxAssetId);
        if (!asset) {
          results.no_mux_asset++;
          console.warn(`[sync-mux-status] ${videoId}: Asset not found in Mux`);
          continue;
        }
      } else {
        // Case B: no asset ID — scan Mux by passthrough to find the asset
        console.log(`[sync-mux-status] ${videoId}: No mux_asset_id, scanning by passthrough...`);
        asset = await findAssetByPassthrough(videoId);
        if (!asset) {
          results.no_mux_asset++;
          console.warn(`[sync-mux-status] ${videoId}: No matching Mux asset found`);
          continue;
        }
      }

      console.log(`[sync-mux-status] ${videoId}: Mux status=${asset.status}`);

      if (asset.status !== "ready") {
        console.log(`[sync-mux-status] ${videoId}: Still encoding (${asset.status}), skipping`);
        results.already_ok++;
        continue;
      }

      // Check if already fully synced
      if (video.mux_playback_id && video.mux_playback_id === (asset.playback_ids?.[0]?.id)) {
        results.already_ok++;
        console.log(`[sync-mux-status] ${videoId}: Already synced`);
        continue;
      }

      await patchRow(videoId, asset);
    } catch (err: any) {
      const msg = err?.message ?? String(err);
      results.errors.push(`${videoId}: Error — ${msg}`);
      console.error(`[sync-mux-status] Error processing ${videoId}:`, msg);
    }
  }

  console.log(
    `[sync-mux-status] Done. scanned=${results.scanned} updated=${results.updated} errors=${results.errors.length}`,
  );

  return new Response(JSON.stringify(results, null, 2), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
