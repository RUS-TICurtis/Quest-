import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── Auth ──────────────────────────────────────────────────────────────────
    // Extract the raw JWT from the Authorization header.
    //
    // IMPORTANT: In Supabase Edge Functions you MUST call getUser(jwt) passing
    // the JWT explicitly. Calling getUser() without an argument looks for an
    // internal session object that never exists in edge function context, which
    // always returns "Auth session missing!" regardless of the Authorization
    // header set on the client constructor.
    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';

    if (!jwt) {
      console.warn('[batch-interactions] Missing or malformed Authorization header');
      return new Response(
        JSON.stringify({ error: 'Unauthorized', detail: 'Missing Bearer token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // Use the anon client just for auth validation — pass the JWT directly.
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // ✅ Pass the JWT explicitly — this is the only way getUser() works in
    // Edge Function context (no browser session / cookie available here).
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser(jwt);

    if (userError || !user) {
      console.warn('[batch-interactions] Auth failed:', userError?.message ?? 'no user');
      return new Response(
        JSON.stringify({ error: 'Unauthorized', detail: userError?.message ?? 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Parse body ─────────────────────────────────────────────────────────────
    let interactions: any[];
    try {
      interactions = await req.json();
    } catch (_) {
      return new Response(
        JSON.stringify({ error: 'Invalid payload', detail: 'Body must be a JSON array' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    if (!Array.isArray(interactions) || interactions.length === 0) {
      return new Response(
        JSON.stringify({ error: 'Invalid payload', detail: 'Expected a non-empty array' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── Persist ────────────────────────────────────────────────────────────────
    // Attach the verified user_id from the JWT — never trust the client-sent value.
    const payload = interactions.map((interaction: any) => ({
      user_id: user.id,
      video_id: interaction.video_id,
      action: interaction.action,
      watch_time_ms: typeof interaction.watch_time_ms === 'number' ? interaction.watch_time_ms : null,
      duration_ms:   (typeof interaction.duration_ms === 'number' && interaction.duration_ms > 0) ? interaction.duration_ms : null,
      created_at: new Date().toISOString(),
    }));

    // Service-role client for the insert — bypasses RLS overhead on a hot path.
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    const { error: insertError } = await supabaseAdmin
      .from('interaction_logs')
      .insert(payload);

    if (insertError) {
      console.error('[batch-interactions] Insert error:', insertError);
      return new Response(
        JSON.stringify({ error: 'Failed to record interactions', detail: insertError.message }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    console.log(`[batch-interactions] ✅ Recorded ${payload.length} interaction(s) for user ${user.id}`);

    return new Response(
      JSON.stringify({ success: true, count: payload.length }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );

  } catch (error: any) {
    console.error('[batch-interactions] Unhandled error:', error);
    return new Response(
      JSON.stringify({ error: error?.message ?? 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});
