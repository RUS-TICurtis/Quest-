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
    Deno.env.get("SUPABASE_ANON_KEY")!
  );

  const { data: { user }, error: authError } = await supabaseUser.auth.getUser(token);
  if (authError || !user) {
    console.error("[update-creator-video] Auth error:", authError?.message);
    return new Response(
      JSON.stringify({ error: "Unauthorized", detail: authError?.message }),
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

  const {
    id,
    title,
    tmdb_title,
    description,
    tags,
    spoiler,
    tmdb_id,
    tmdb_type,
    thumbnail_url,
    // status_action is used for owner-initiated visibility toggles only.
    // Accepted values: 'disable' | 'enable'
    // Other status transitions (approve/reject/remove) are admin-only.
    status_action,
  } = body;

  if (!id) {
    return new Response(
      JSON.stringify({ error: "Missing required parameter: id" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Admin Supabase Client (bypasses RLS for validation and update) ─────────
  const supabaseAdmin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ── Step 1: Fetch current record & verify ownership ────────────────────────
  const { data: currentVideo, error: fetchError } = await supabaseAdmin
    .from("creator_videos")
    .select("creator_id, status, title, description, tags, spoiler, tmdb_id, tmdb_title, tmdb_type, thumbnail_url")
    .eq("id", id)
    .single();

  if (fetchError || !currentVideo) {
    console.error("[update-creator-video] Fetch error:", fetchError);
    return new Response(
      JSON.stringify({ error: "Video not found" }),
      { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  if (currentVideo.creator_id !== user.id) {
    return new Response(
      JSON.stringify({ error: "Forbidden: You do not own this video" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Branch A: Status toggle (disable/enable) ──────────────────────────────
  // Owners can only toggle between 'approved' and 'disabled'.
  // Any other status_action value is rejected.
  if (status_action) {
    if (!['disable', 'enable'].includes(status_action)) {
      return new Response(
        JSON.stringify({ error: `Invalid status_action: ${status_action}. Must be 'disable' or 'enable'.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const allowedFromStatus = status_action === 'disable' ? 'approved' : 'disabled';
    if (currentVideo.status !== allowedFromStatus) {
      return new Response(
        JSON.stringify({ error: `Cannot ${status_action} a video with status '${currentVideo.status}'` }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const newStatus = status_action === 'disable' ? 'disabled' : 'approved';
    const { error: toggleError } = await supabaseAdmin
      .from("creator_videos")
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq("id", id);

    if (toggleError) {
      console.error("[update-creator-video] Toggle error:", toggleError);
      return new Response(
        JSON.stringify({ error: "Failed to toggle video status", detail: toggleError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log(`[update-creator-video] Video ${id} status toggled to '${newStatus}' by owner.`);
    return new Response(
      JSON.stringify({ success: true, status: newStatus }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  // ── Branch B: Metadata update ──────────────────────────────────────────────
  // We reset to 'pending' if the user modifies sensitive textual content or show associations.
  // Edits to description (captions) and tags do not require admin permissions/moderation.
  const isSensitiveContentChanged =
    (title !== undefined && title !== null && currentVideo.title !== title) ||
    (spoiler !== undefined && spoiler !== null && currentVideo.spoiler !== spoiler) ||
    (tmdb_id !== undefined && currentVideo.tmdb_id !== tmdb_id);

  let newStatus = currentVideo.status;
  if (isSensitiveContentChanged && currentVideo.status === "approved") {
    newStatus = "pending";
    console.log(`[update-creator-video] Resetting status to pending for video ${id} due to sensitive content edits.`);
  } else if (isSensitiveContentChanged && currentVideo.status === "rejected") {
    newStatus = "pending";
    console.log(`[update-creator-video] Resetting rejected status to pending for video ${id} on resubmission.`);
  }

  // ── Step 3: Perform the update ─────────────────────────────────────────────
  const updatedPayload: Record<string, any> = {
    status: newStatus,
    updated_at: new Date().toISOString(),
  };

  if (title !== undefined) updatedPayload.title = title;
  if (description !== undefined) updatedPayload.description = description;
  if (tags !== undefined) updatedPayload.tags = tags;
  if (spoiler !== undefined) updatedPayload.spoiler = spoiler;
  if (tmdb_id !== undefined) updatedPayload.tmdb_id = tmdb_id;
  if (tmdb_type !== undefined) updatedPayload.tmdb_type = tmdb_type;
  if (thumbnail_url !== undefined) updatedPayload.thumbnail_url = thumbnail_url;

  if (tmdb_title !== undefined) {
    updatedPayload.tmdb_title = tmdb_title;
  } else if (tmdb_id !== undefined) {
    updatedPayload.tmdb_title = tmdb_id ? (title ?? currentVideo.title) : null;
  }

  const { data: updatedVideo, error: updateError } = await supabaseAdmin
    .from("creator_videos")
    .update(updatedPayload)
    .eq("id", id)
    .select()
    .single();

  if (updateError) {
    console.error("[update-creator-video] DB update error:", updateError);
    return new Response(
      JSON.stringify({ error: "Failed to update video record", detail: updateError.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }

  console.log(`[update-creator-video] Successfully updated creator_videos row: ${id}`);

  return new Response(
    JSON.stringify({ success: true, video: updatedVideo }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    },
  );
});
