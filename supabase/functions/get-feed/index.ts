// Feed Edge Function (v2) — Materialized Rankings + Cursor Pagination
//
// ARCHITECTURE:
//   1. Reads from feed_rankings (materialized every 15 min by pg_cron)
//   2. Cursor pagination on (rank_position, video_id) — stable between pages
//   3. Backend seen-video filtering via p_seen_ids
//   4. Tiered shuffle via session seed — variety without breaking cursor
//   5. No post-processing diversity filter (baked into ranking)
//
// POST /get-feed
// Body: {
//   seed: string,           // session seed (frozen per session, ~30 min)
//   cursor: { rank: number, id: string } | null,
//   limit: number,          // max 50
//   seen_ids: string[],     // up to 200 UUIDs to exclude
//   recent_genres: string[],
//   session_time: string,   // ISO timestamp (for logging only)
// }

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { getSupabaseAdmin, getSupabaseClient, verifyAuth } from '../_shared/supabase.ts';

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    let userId: string | null = null;
    try {
      const anonClient = getSupabaseClient(req);
      const user = await verifyAuth(req, anonClient);
      userId = user.id;
    } catch (e) {
      console.warn('[get-feed] Invalid bearer token, falling back to guest mode:', (e as any).message);
    }

    // ── Parse body with strict type safety ────────────────────────────────
    let seed = 'default';
    let cursor: { rank: number; id: string } | null = null;
    let limit = 15;
    let seenIds: string[] = [];
    let recentGenres: string[] = [];
    let localBlockedIds: string[] = [];

    try {
      const body = await req.json();

      seed = typeof body.seed === 'string' ? body.seed : 'default';
      limit = Math.min(Math.max(Number(body.limit) || 15, 1), 50);

      // Parse cursor — must be { rank: number, id: string } or null
      if (body.cursor && typeof body.cursor === 'object') {
        const rank = Number(body.cursor.rank);
        const id = body.cursor.id;
        if (!isNaN(rank) && typeof id === 'string' && id.length > 0) {
          cursor = { rank, id };
        }
      }

      // Parse seen_ids — cap at 200 to prevent query bloat
      if (Array.isArray(body.seen_ids)) {
        seenIds = body.seen_ids
          .filter((id: any) => typeof id === 'string' && id.length > 0)
          .slice(0, 200);
      }

      // Parse recent_genres
      if (Array.isArray(body.recent_genres)) {
        recentGenres = body.recent_genres
          .filter((g: any) => typeof g === 'string')
          .slice(0, 10);
      }

      // Parse local_blocked_ids - cap at 500
      if (Array.isArray(body.local_blocked_ids)) {
        localBlockedIds = body.local_blocked_ids
          .filter((id: any) => typeof id === 'string' && id.length > 0)
          .slice(0, 500);
      }
    } catch (_parseError) {
      console.warn('[get-feed] Could not parse request body, using defaults');
    }

    // ── Admin client for the RPC ──────────────────────────────────────────
    const supabaseAdmin = getSupabaseAdmin();

    // ── Call get_edge_feed v2 RPC ─────────────────────────────────────────
    const queryArgs: Record<string, any> = {
      p_user_id:       userId,
      p_limit:         limit,
      p_cursor_rank:   cursor?.rank ?? 0,
      p_cursor_id:     cursor?.id ?? null,
      p_session_seed:  seed,
      p_seen_ids:      seenIds.length > 0 ? seenIds : null,
      p_recent_genres: recentGenres,
      p_local_blocked_ids: localBlockedIds.length > 0 ? localBlockedIds : null,
    };

    const { data: rawVideos, error: rpcError } = await supabaseAdmin.rpc('get_edge_feed', queryArgs);

    if (rpcError) {
      console.error('[get-feed] RPC Error:', rpcError);
      return new Response(JSON.stringify({ error: 'Failed to fetch feed', detail: rpcError.message }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const videos: any[] = rawVideos || [];

    // ── Map flat RPC columns → nested { profiles: { username, avatar_url } }
    // so CreatorVideo.fromJson() deserialises without changes.
    const mappedVideos = videos.map((v: any) => {
      const { creator_username, creator_avatar_url, rank_position: rp, ...rest } = v;
      return {
        ...rest,
        profiles: {
          username:   creator_username  ?? null,
          avatar_url: creator_avatar_url ?? null,
        },
      };
    });

    // ── Build next cursor ────────────────────────────────────────────────
    // Cursor is based on the last video's rank_position and id.
    // If we received fewer videos than the limit, there are no more pages.
    let nextCursor: { rank: number; id: string } | null = null;
    if (videos.length === limit && videos.length > 0) {
      const lastVideo = videos[videos.length - 1];
      nextCursor = {
        rank: lastVideo.rank_position,
        id: lastVideo.id,
      };
    }

    return new Response(
      JSON.stringify({ videos: mappedVideos, next_cursor: nextCursor }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );

  } catch (error: any) {
    console.error('[get-feed] Unhandled error:', error);
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
