import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { getSupabaseAdmin, getSupabaseClient, verifyAuth } from '../_shared/supabase.ts';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const anonClient = getSupabaseClient(req);
    const user = await verifyAuth(req, anonClient);
    const userId = user.id;

    const body = await req.json();
    const { video_id, action, comment_text } = body;

    if (!video_id || !action) {
      return new Response(JSON.stringify({ error: 'Missing video_id or action' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const admin = getSupabaseAdmin();

    // Fetch the target video
    const { data: video, error: fetchErr } = await admin
      .from('videos')
      .select('id, like_count, comment_count, engagement_score')
      .eq('id', video_id)
      .single();

    if (fetchErr || !video) {
      return new Response(JSON.stringify({ error: 'Video not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    let updatedLikeCount = video.like_count ?? 0;
    let updatedCommentCount = video.comment_count ?? 0;
    let updatedEngagement = Number(video.engagement_score ?? 0);

    if (action === 'like') {
      updatedLikeCount += 1;
      updatedEngagement += 1.0;
    } else if (action === 'comment') {
      updatedCommentCount += 1;
      updatedEngagement += 2.0;
    } else {
      return new Response(JSON.stringify({ error: 'Invalid action' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { error: updateErr } = await admin
      .from('videos')
      .update({
        like_count: updatedLikeCount,
        comment_count: updatedCommentCount,
        engagement_score: updatedEngagement,
        updated_at: new Date().toISOString(),
      })
      .eq('id', video_id);

    if (updateErr) {
      throw updateErr;
    }

    return new Response(
      JSON.stringify({
        success: true,
        like_count: updatedLikeCount,
        comment_count: updatedCommentCount,
        engagement_score: updatedEngagement,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
