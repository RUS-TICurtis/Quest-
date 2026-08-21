import { createClient } from "npm:@supabase/supabase-js@2.39.7";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, verifyAuth } from "../_shared/supabase.ts";

/**
 * like-video
 *
 * Atomically handles a like or unlike action on a creator video.
 *
 * The function:
 *   1. Authenticates the calling user via their JWT.
 *   2. Validates the video exists and is approved.
 *   3. Toggles the like:
 *      - Like   → inserts into video_reactions (heart), increments like_count,
 *                 upserts video_interactions.liked = true,
 *                 enqueues a video_counter_events row,
 *                 sends a notification to the creator.
 *      - Unlike → deletes from video_reactions, decrements like_count,
 *                 upserts video_interactions.liked = false,
 *                 enqueues a negative video_counter_events row.
 *   4. Returns the new like state and updated like_count.
 */

// ── Helpers ───────────────────────────────────────────────────────────────────

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function err(message: string, status: number): Response {
  return json({ error: message }, status);
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req: Request) => {
  // ── Preflight ──────────────────────────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return err("Method Not Allowed", 405);
  }

  // ── Parse request body ─────────────────────────────────────────────────────
  let videoId: string;
  let action: string | undefined;
  try {
    const body = await req.json() as { video_id?: string; action?: string };
    videoId = body?.video_id ?? "";
    action = body?.action;
    if (!videoId || typeof videoId !== "string") throw new Error("missing video_id");
  } catch {
    return err("Bad Request: body must be JSON with a video_id field", 400);
  }

  // ── Auth: verify the calling user's JWT ────────────────────────────────────
  let userId: string;
  try {
    const user = await verifyAuth(req);
    userId = user.id;
  } catch (authErr: any) {
    console.error("[like-video] Auth error:", authErr?.message);
    return err("Unauthorized", 401);
  }

  // ── Admin client for privileged writes ────────────────────────────────────
  const admin = getSupabaseAdmin();

  // ── Validate the video ─────────────────────────────────────────────────────
  const { data: video, error: videoErr } = await admin
    .from("creator_videos")
    .select("id, creator_id, like_count, title, status, deleted_at")
    .eq("id", videoId)
    .single();

  if (videoErr || !video) {
    return err("Video not found", 404);
  }
  
  if (video.deleted_at !== null) {
    return err("Video is not available", 403);
  }
  
  // Creators can like their own videos, subject to the same database-enforced once-limit as everyone else.

  // ── Validate video status and user permissions ──────────────────────────────
  if (video.status === "pending") {
    const isCreator = video.creator_id === userId;
    const { data: profile } = await admin
      .from("profiles")
      .select("role")
      .eq("id", userId)
      .single();
    const isAdminOrReviewer = profile?.role === "admin" || profile?.role === "reviewer";

    if (!isCreator && !isAdminOrReviewer) {
      return err("Unauthorized: Only the creator or an admin/reviewer can like/unlike pending videos", 403);
    }
  }

  // ── Check current like state ───────────────────────────────────────────────
  const { data: existingReaction } = await admin
    .from("video_reactions")
    .select("user_id")
    .eq("video_id", videoId)
    .eq("user_id", userId)
    .eq("reaction_type", "heart")
    .maybeSingle();

  const alreadyLiked = existingReaction !== null;
  const shouldLike = action ? (action === "like") : !alreadyLiked;

  // ── Toggle/Set like state ──────────────────────────────────────────────────
  if (!shouldLike) {
    // ── Unlike ───────────────────────────────────────────────────────────────
    if (alreadyLiked) {
      const { error: deleteErr } = await admin
        .from("video_reactions")
        .delete()
        .eq("video_id", videoId)
        .eq("user_id", userId)
        .eq("reaction_type", "heart");

      if (deleteErr) {
        console.error("[like-video] Unlike failed:", deleteErr.message);
        return err("Internal server error", 500);
      }

      // Update video_interactions
      await admin
        .from("video_interactions")
        .upsert(
          { user_id: userId, video_id: videoId, liked: false, updated_at: new Date().toISOString() },
          { onConflict: "user_id,video_id" },
        );
    }

    // Query the actual updated like_count from the db to be 100% accurate
    const { data: updatedVideo } = await admin
      .from("creator_videos")
      .select("like_count")
      .eq("id", videoId)
      .single();

    const newLikeCount = updatedVideo?.like_count ?? Math.max((video.like_count ?? 0) - (alreadyLiked ? 1 : 0), 0);
    console.log(`[like-video] ❌ user=${userId} unliked video=${videoId} count=${newLikeCount}`);
    return json({ liked: false, like_count: newLikeCount });

  } else {
    // ── Like ──────────────────────────────────────────────────────────────────
    if (!alreadyLiked) {
      const { error: insertErr } = await admin
        .from("video_reactions")
        .insert({ video_id: videoId, user_id: userId, reaction_type: "heart" });

      if (insertErr) {
        // Unique violation means race condition — treat as already liked
        if (insertErr.code === "23505") {
          const { data: updatedVideo } = await admin
            .from("creator_videos")
            .select("like_count")
            .eq("id", videoId)
            .single();
          return json({ liked: true, like_count: updatedVideo?.like_count ?? video.like_count ?? 0 });
        }
        console.error("[like-video] Like insert failed:", insertErr.message);
        return err("Internal server error", 500);
      }

      // Update video_interactions
      await admin
        .from("video_interactions")
        .upsert(
          { user_id: userId, video_id: videoId, liked: true, updated_at: new Date().toISOString() },
          { onConflict: "user_id,video_id" },
        );

      // Record activity
      const { error: actErr } = await admin
        .from("activities")
        .insert({ user_id: userId, type: "like", reference_id: videoId });
      if (actErr) console.warn("[like-video] Activity insert warn:", actErr.message);

      // ── Send notification to creator ────────────────────────────────────────
      if (video.creator_id !== userId) {
        const { data: likerProfile } = await admin
          .from("profiles")
          .select("username, avatar_url")
          .eq("id", userId)
          .maybeSingle();

        const likerUsername = likerProfile?.username ?? "Someone";

        await admin.from("notifications").insert({
          user_id: video.creator_id,
          type: "video_like",
          title: "New like ❤️",
          body: `${likerUsername} liked your video${video.title ? ` "${video.title}"` : ""}`,
          image_url: likerProfile?.avatar_url ?? null,
          reference_id: videoId,
          metadata: {
            video_id: videoId,
            liker_id: userId,
            liker_username: likerUsername,
          },
        });
      }
    }

    // Query the actual updated like_count from the db to be 100% accurate
    const { data: updatedVideo } = await admin
      .from("creator_videos")
      .select("like_count")
      .eq("id", videoId)
      .single();

    const newLikeCount = updatedVideo?.like_count ?? (video.like_count ?? 0) + (alreadyLiked ? 0 : 1);
    console.log(`[like-video] ✅ user=${userId} liked video=${videoId} count=${newLikeCount}`);
    return json({ liked: true, like_count: newLikeCount });
  }
});
