import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ----------------------------------------------------------------------------
// Community Trending Score Formula:
//   base  = posts_24h*2 + comments_24h*4 + active_users_24h*5 + shares_24h*8
//   score = base / (hours_since_last_activity + 2)^1.2
// ----------------------------------------------------------------------------

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceKey);

  try {
    const since24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

    // 1. Fetch all active communities
    const { data: communities, error: commErr } = await supabase
      .from("communities")
      .select("id, show_id, title, last_activity_at, post_count")
      .eq("status", "active");

    if (commErr) throw commErr;
    if (!communities || communities.length === 0) {
      return new Response(JSON.stringify({ success: true, updated: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const communityIds = communities.map((c: any) => c.id);

    // 2. Count posts in last 24h per community
    const { data: postCounts, error: pcErr } = await supabase
      .from("community_posts")
      .select("community_id")
      .in("community_id", communityIds)
      .gte("created_at", since24h)
      .is("deleted_at", null);

    if (pcErr) throw pcErr;

    const posts24hMap: Record<number, number> = {};
    for (const row of postCounts ?? []) {
      posts24hMap[row.community_id] = (posts24hMap[row.community_id] ?? 0) + 1;
    }

    // 3. Get posts created in last 24h for comment + user counting
    const recentPostIds = (postCounts ?? []).map((r: any) => r.community_id);
    
    // Count comments on recent posts per community
    const { data: recentPosts, error: rpErr } = await supabase
      .from("community_posts")
      .select("id, community_id, author_id")
      .in("community_id", communityIds)
      .gte("created_at", since24h)
      .is("deleted_at", null);

    if (rpErr) throw rpErr;

    const recentPostIdsList = (recentPosts ?? []).map((p: any) => p.id);
    
    // Map community -> active authors (from posts)
    const activeUsersMap: Record<number, Set<string>> = {};
    for (const post of recentPosts ?? []) {
      if (!activeUsersMap[post.community_id]) {
        activeUsersMap[post.community_id] = new Set();
      }
      activeUsersMap[post.community_id].add(post.author_id);
    }

    // Count comments and comment authors
    let commentCountsMap: Record<number, number> = {};
    if (recentPostIdsList.length > 0) {
      const { data: comments, error: cErr } = await supabase
        .from("community_comments")
        .select("post_id, author_id, community_posts!inner(community_id)")
        .in("post_id", recentPostIdsList)
        .gte("created_at", since24h)
        .is("deleted_at", null);

      if (cErr) throw cErr;

      for (const comment of comments ?? []) {
        const commId = comment.community_posts?.community_id;
        if (!commId) continue;
        commentCountsMap[commId] = (commentCountsMap[commId] ?? 0) + 1;
        if (!activeUsersMap[commId]) activeUsersMap[commId] = new Set();
        if (comment.author_id) activeUsersMap[commId].add(comment.author_id);
      }
    }

    // 4. Compute and batch-update trending scores
    const now = Date.now();
    const updates: any[] = [];

    for (const community of communities) {
      const commId = community.id;
      const posts24h = posts24hMap[commId] ?? 0;
      const comments24h = commentCountsMap[commId] ?? 0;
      const activeUsers24h = activeUsersMap[commId]?.size ?? 0;
      const shares24h = 0; // Future: track via community_posts.shares_count sum

      const base = posts24h * 2 + comments24h * 4 + activeUsers24h * 5 + shares24h * 8;

      const lastActivity = community.last_activity_at
        ? new Date(community.last_activity_at).getTime()
        : now - 24 * 60 * 60 * 1000;
      const hoursSince = (now - lastActivity) / (1000 * 60 * 60);
      const trendingScore = base > 0 ? base / Math.pow(hoursSince + 2, 1.2) : 0;

      updates.push({
        id: commId,
        show_id: community.show_id,
        title: community.title,
        trending_score: Math.round(trendingScore * 10000) / 10000,
        posts_24h: posts24h,
        comments_24h: comments24h,
        active_users_24h: activeUsers24h,
        shares_24h: shares24h,
      });
    }

    // Batch upsert in chunks of 100
    const chunkSize = 100;
    let totalUpdated = 0;
    for (let i = 0; i < updates.length; i += chunkSize) {
      const chunk = updates.slice(i, i + chunkSize);
      const { error: upErr } = await supabase
        .from("communities")
        .upsert(chunk, { onConflict: "id" });
      if (upErr) throw upErr;
      totalUpdated += chunk.length;
    }

    console.log(`[recalculate-community-trending] Updated ${totalUpdated} communities`);

    return new Response(
      JSON.stringify({ success: true, updated: totalUpdated, timestamp: new Date().toISOString() }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    console.error("[recalculate-community-trending] Error:", err.message);
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
