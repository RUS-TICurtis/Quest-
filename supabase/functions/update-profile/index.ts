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
    const { username, full_name, avatarUrl, avatar_url, bio } = body;

    // Sanitize fields and build updates object
    const updates: Record<string, any> = {
      id: userId,
      updated_at: new Date().toISOString(),
    };

    if (username !== undefined) updates.username = String(username).trim();
    if (full_name !== undefined) updates.full_name = String(full_name).trim();
    if (bio !== undefined) updates.bio = String(bio).trim();
    
    // Handle both snake_case and camelCase
    const resolvedAvatar = avatar_url ?? avatarUrl;
    if (resolvedAvatar !== undefined) {
      updates.avatarUrl = resolvedAvatar;
      updates.avatar_url = resolvedAvatar;
    }

    const admin = getSupabaseAdmin();
    const { data, error } = await admin
      .from('profiles')
      .upsert(updates)
      .select()
      .single();

    if (error) {
      throw error;
    }

    return new Response(JSON.stringify({ success: true, profile: data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
