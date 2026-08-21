import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { getSupabaseAdmin, getSupabaseClient, verifyAuth } from "../_shared/supabase.ts";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Create a single user-scoped anon client and pass it to verifyAuth so
    // we don't spin up a second internal client inside verifyAuth.
    const anonClient = getSupabaseClient(req);
    const user = await verifyAuth(req, anonClient);
    const supabaseAdmin = getSupabaseAdmin();

    const body = await req.json();
    const {
      community_id,
      show_id,
      content,
      media_urls = [],
      media_types = [],
      hashtags = [],
      is_spoiler = false
    } = body;

    if (!community_id || !content) {
      throw new Error("community_id and content are required");
    }

    // 1. Insert Post
    const { data: post, error: insertError } = await supabaseAdmin
      .from('community_posts')
      .insert({
        community_id,
        show_id,
        author_id: user.id,
        content,
        media_urls,
        media_types,
        hashtags,
        is_spoiler,
      })
      .select()
      .single();

    if (insertError || !post) {
      throw new Error(`Failed to insert post: ${insertError?.message}`);
    }

    // 2. Queue Notification Job
    const jobPayload = {
      community_id,
      post_id: post.id,
      author_id: user.id,
      content,
      show_id
    };

    const { error: jobError } = await supabaseAdmin
      .from('notification_jobs')
      .insert({
        type: 'community_post',
        payload: jobPayload
      });

    if (jobError) {
      console.error("Failed to queue notification job:", jobError);
      // We don't fail the post creation if notification queuing fails,
      // but we log it. In a stricter system, you might want a transaction.
    }

    return new Response(JSON.stringify({ success: true, post }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("create-community-post error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
