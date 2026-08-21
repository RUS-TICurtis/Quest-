// Engagement Aggregation Edge Function (v2)
// Reads from pre-aggregated video_daily_stats (incrementally populated by
// the on_engagement_event trigger) instead of scanning raw events.
//
// Previously this loaded ALL raw video_engagement_events for 7 days into
// memory — a viral video with 500k views would crash the Deno Edge Function
// with OOM. Now reads at most 7 rows (one per day).
//
// POST /aggregate-engagement
// Body: { videoId: string }

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
    // Handle CORS preflight
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // Use service role for aggregation (bypasses RLS)
        const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

        if (!supabaseUrl || !supabaseServiceKey) {
            throw new Error('Missing Supabase environment variables');
        }

        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
            auth: { autoRefreshToken: false, persistSession: false },
        });

        let videoId: string;
        try {
            const body = await req.json();
            videoId = body.videoId;
        } catch (_) {
            return new Response(
                JSON.stringify({ error: 'Invalid JSON body' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        if (!videoId || typeof videoId !== 'string') {
            return new Response(
                JSON.stringify({ error: 'videoId required and must be a string' }),
                { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // ── Get video to check existence + created_at (single query) ────────
        const { data: video, error: videoError } = await supabaseAdmin
            .from('creator_videos')
            .select('id, duration_seconds, created_at')
            .eq('id', videoId)
            .single()

        if (videoError || !video) {
            return new Response(
                JSON.stringify({ error: 'Video not found' }),
                { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // ── Read from pre-aggregated video_daily_stats ──────────────────────
        // This table is incrementally populated by the on_engagement_event
        // trigger on video_engagement_events. At most 7 rows for 7 days.
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const sevenDaysAgoDate = sevenDaysAgo.toISOString().split('T')[0]; // YYYY-MM-DD

        const { data: dailyStats, error: statsError } = await supabaseAdmin
            .from('video_daily_stats')
            .select('total_views, total_watch_time, sum_completion_pct')
            .eq('video_id', videoId)
            .gte('date', sevenDaysAgoDate)

        if (statsError) {
            throw statsError
        }

        // ── Calculate aggregates from rollups ────────────────────────────────
        const stats = dailyStats ?? [];
        const viewCount = stats.reduce((sum: number, d: any) => sum + (d.total_views ?? 0), 0);
        const totalWatchTime = stats.reduce((sum: number, d: any) => sum + Number(d.total_watch_time ?? 0), 0);
        const avgCompletion = viewCount > 0
            ? stats.reduce((sum: number, d: any) => sum + Number(d.sum_completion_pct ?? 0), 0) / viewCount
            : 0;

        // ── Calculate engagement score ───────────────────────────────────────
        // Formula: (avg_completion * 0.6) + (view_count_factor * 0.2) + (recency * 0.2)
        const completionScore = avgCompletion * 0.6;
        const viewScore = Math.min(viewCount / 1000, 1) * 0.2; // Cap at 1000 views

        // Recency: video created recently gets boost (decay over 7 days)
        const ageHours = (Date.now() - new Date(video.created_at).getTime()) / (1000 * 60 * 60);
        const recencyScore = Math.max(0, 1 - (ageHours / 168)) * 0.2;

        const engagementScore = completionScore + viewScore + recencyScore;

        // ── Update video with aggregated stats ──────────────────────────────
        const { error: updateError } = await supabaseAdmin
            .from('creator_videos')
            .update({
                view_count: viewCount,
                total_watch_time_seconds: totalWatchTime,
                avg_completion_pct: avgCompletion,
                engagement_score: engagementScore,
                updated_at: new Date().toISOString()
            })
            .eq('id', videoId)

        if (updateError) {
            throw updateError
        }

        return new Response(
            JSON.stringify({
                success: true,
                videoId,
                stats: {
                    viewCount,
                    totalWatchTime,
                    avgCompletion: Number(avgCompletion.toFixed(4)),
                    engagementScore: Number(engagementScore.toFixed(4)),
                    dailyBucketsUsed: stats.length,
                }
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error: any) {
        console.error('[aggregate-engagement] Error:', error)
        return new Response(
            JSON.stringify({ error: error?.message ?? 'Internal server error' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
