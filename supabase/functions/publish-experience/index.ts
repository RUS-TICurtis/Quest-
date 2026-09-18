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
    const mediaUrl = body.media_url;
    const muxPlaybackId = body.mux_playback_id;
    const muxAssetId = body.mux_asset_id;
    const caption = body.caption || '';
    const destinations = Array.isArray(body.destinations) ? body.destinations : [];
    const communityId = body.community_id;

    const insertPayloads = [];

    const baseVideo = {
      user_id: userId,
      video_url: muxPlaybackId ? `https://stream.mux.com/${muxPlaybackId}.m3u8` : mediaUrl,
      thumbnail_url: mediaUrl ?? (muxPlaybackId ? `https://image.mux.com/${muxPlaybackId}/thumbnail.jpg` : ''),
      mux_playback_id: muxPlaybackId,
      mux_asset_id: muxAssetId,
      title: caption.substring(0, 50) || 'New Experience',
      description: caption,
      duration_seconds: 15,
    };

    if (destinations.includes('feed')) {
      insertPayloads.push({
        ...baseVideo,
        video_type: 'feed',
      });
    }

    if (destinations.includes('story')) {
      insertPayloads.push({
        ...baseVideo,
        video_type: 'story',
      });
    }

    if (destinations.includes('community')) {
      insertPayloads.push({
        ...baseVideo,
        video_type: 'community',
        community_id: communityId,
      });
    }

    if (insertPayloads.length === 0) {
      return new Response(JSON.stringify({ error: 'No destinations provided' }), { 
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      });
    }

    const supabaseAdmin = getSupabaseAdmin();
    const { data: insertedVideos, error } = await supabaseAdmin
      .from('videos')
      .insert(insertPayloads)
      .select(`
        *,
        profiles!inner(username, avatar_url)
      `);

    if (error) {
      console.error('[publish-experience] Error inserting videos:', error);
      throw error;
    }

    // Map back profile data to match the app's models (CreatorVideo / StoryItem)
    const mappedVideos = insertedVideos.map((v: any) => ({
      ...v,
      creator_username: v.profiles?.username,
      creator_avatar_url: v.profiles?.avatar_url,
      // CreatorVideo expects creator_id mapped from user_id
      creator_id: v.user_id,
    }));

    return new Response(JSON.stringify({ success: true, videos: mappedVideos }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    console.error('[publish-experience] Error:', error);
    return new Response(JSON.stringify({ error: (error as Error).message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
