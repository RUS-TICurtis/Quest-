import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ----------------------------------------------------------------------------
// Post Trending Score Formula:
//   base     = upvotes*2 + comments*4 + shares*6 + views*0.02
//   freshness = 1 / (hours_since_posted + 2)^1.3
//   score    = base * freshness
//
// Only recalculates posts created within the last 7 days.
// Posts older than 7 days have their trending_score reset to 0.
// ----------------------------------------------------------------------------

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceKey);

  try {
    const since7d = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();
    const now = Date.now();

    // 1. Fetch all active posts from the last 7 days
    const { data: posts, error: postsErr } = await supabase
      .from("community_posts")
      .select("id, author_id, upvotes, comment_count, shares_count, view_count, created_at")
      .gte("created_at", since7d)
      .is("deleted_at", null)
      .eq("is_hidden", false);

    if (postsErr) throw postsErr;
    if (!posts || posts.length === 0) {
      return new Response(JSON.stringify({ success: true, updated: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Compute trending score for each post
    const updates: { id: string; trending_score: number; engagement_velocity: number }[] = [];

    for (const post of posts) {
      const upvotes = post.upvotes ?? 0;
      const comments = post.comment_count ?? 0;
      const shares = post.shares_count ?? 0;
      const views = post.view_count ?? 0;

      const base = upvotes * 2 + comments * 4 + shares * 6 + views * 0.02;

      const createdMs = new Date(post.created_at).getTime();
      const hoursSince = (now - createdMs) / (1000 * 60 * 60);
      const freshness = 1 / Math.pow(hoursSince + 2, 1.3);

      const trendingScore = base * freshness;

      // Velocity: simple proxy using score / hours (future: use 30-min window)
      const velocity = hoursSince > 0 ? (upvotes + comments) / hoursSince : 0;

      updates.push({
        id: post.id,
        author_id: post.author_id,
        trending_score: Math.round(trendingScore * 10000) / 10000,
        engagement_velocity: Math.round(velocity * 10000) / 10000,
      });
    }

    // 3. Reset trending_score for posts older than 7 days in a single query
    const { error: resetErr } = await supabase
      .from("community_posts")
      .update({ trending_score: 0, engagement_velocity: 0 })
      .lt("created_at", since7d)
      .gt("trending_score", 0);  // only touch rows that need resetting

    if (resetErr) console.warn("[recalculate-post-trending] Reset error:", resetErr.message);

    // 4. Batch upsert in chunks of 200
    const chunkSize = 200;
    let totalUpdated = 0;
    for (let i = 0; i < updates.length; i += chunkSize) {
      const chunk = updates.slice(i, i + chunkSize);
      const { error: upErr } = await supabase
        .from("community_posts")
        .upsert(chunk, { onConflict: "id" });
      if (upErr) throw upErr;
      totalUpdated += chunk.length;
    }

    console.log(`[recalculate-post-trending] Updated ${totalUpdated} posts`);

    return new Response(
      JSON.stringify({ success: true, updated: totalUpdated, timestamp: new Date().toISOString() }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("[recalculate-post-trending] Error:", err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
