import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import Mux from "npm:@mux/mux-node";
import { createClient } from "npm:@supabase/supabase-js";

/**
 * backfill-mux
 *
 * Admin-only Edge Function that submits all legacy approved videos
 * (those with video_url set but no mux_playback_id) to Mux for HLS encoding.
 *
 * This is a ONE-TIME operation and should be triggered manually:
 *   curl -X POST \
 *     -H "x-admin-secret: <BACKFILL_ADMIN_SECRET>" \
 *     https://<project>.supabase.co/functions/v1/backfill-mux
 *
 * Required secrets:
 *   MUX_TOKEN_ID            — Mux API token ID
 *   MUX_TOKEN_SECRET        — Mux API token secret
 *   BACKFILL_ADMIN_SECRET   — Random string you set; guards this endpoint
 *   SUPABASE_URL            — auto-injected
 *   SUPABASE_SERVICE_ROLE_KEY — auto-injected
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

  // ── Guard: admin-only ─────────────────────────────────────────────────────
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

  const mux = new Mux({
    tokenId: Deno.env.get("MUX_TOKEN_ID")!,
    tokenSecret: Deno.env.get("MUX_TOKEN_SECRET")!,
  });

  // ── Fetch all videos eligible for backfill ────────────────────────────────
  // Eligible: has a video_url (Storage path), no mux_playback_id yet
  const { data: rows, error: fetchErr } = await supabase
    .from("creator_videos")
    .select("id, video_url, status")
    .is("mux_playback_id", null)
    .not("video_url", "is", null)
    .neq("video_url", "")
    .order("created_at", { ascending: true });

  if (fetchErr) {
    return new Response(
      JSON.stringify({ error: "DB query failed", detail: fetchErr.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (!rows || rows.length === 0) {
    return new Response(
      JSON.stringify({ message: "No videos need backfill", submitted: 0 }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  console.log(`[backfill-mux] Found ${rows.length} videos to backfill`);

  const results = { submitted: 0, skipped: 0, errors: [] as string[] };

  for (const row of rows) {
    try {
      // Generate a public URL for the video since creator-videos is a public bucket
      const bucket = "creator-videos";
      const storagePath = row.video_url as string;

      const { data } = supabase.storage
        .from(bucket)
        .getPublicUrl(storagePath);

      if (!data?.publicUrl) {
        console.error(`[backfill-mux] Could not get public URL for ${row.id}`);
        results.errors.push(`${row.id}: public URL failed`);
        results.skipped++;
        continue;
      }

      // Create Mux asset from the public URL
      await mux.video.assets.create({
        input: [{ url: data.publicUrl }],
        playback_policy: ["public"],
        encoding_tier: "smart",
        passthrough: row.id,
      });

      // Mark as processing in the DB so we know Mux has it
      await supabase.from("creator_videos").update({
        mux_status: "processing",
      }).eq("id", row.id);

      results.submitted++;
      console.log(`[backfill-mux] Submitted ${row.id}`);

      // Rate-limit: space out submissions to avoid hitting Mux API limits
      await sleep(150);
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      console.error(`[backfill-mux] Error on ${row.id}: ${msg}`);
      results.errors.push(`${row.id}: ${msg}`);
      results.skipped++;
    }
  }

  console.log(
    `[backfill-mux] Done. submitted=${results.submitted} skipped=${results.skipped} errors=${results.errors.length}`,
  );

  return new Response(JSON.stringify(results), {
    status: 200,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
