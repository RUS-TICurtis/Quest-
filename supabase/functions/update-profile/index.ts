import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { getSupabaseAdmin, getSupabaseClient, verifyAuth } from '../_shared/supabase.ts';

const USERNAME_RE = /^[a-z0-9_]{3,30}$/;
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  let user: any;
  try {
    user = await verifyAuth(req, getSupabaseClient(req));
  } catch (err: any) {
    return json({ error: 'unauthorized', message: err.message }, 401);
  }
  // Guests (anonymous sessions) never own a profile row.
  if (user.is_anonymous) {
    return json({ error: 'guest_forbidden', message: 'Sign in to edit a profile.' }, 403);
  }

  try {
    const body = await req.json();
    // Whitelist: server-owned columns (xp, level, role, badges…) are never accepted.
    const updates: Record<string, unknown> = {
      id: user.id,
      updated_at: new Date().toISOString(),
    };

    if (body.name !== undefined) {
      const name = String(body.name).trim();
      if (name.length < 1 || name.length > 60) {
        return json({ error: 'invalid_name', message: 'Name must be 1–60 characters.' }, 400);
      }
      updates.name = name;
    }
    if (body.username !== undefined && body.username !== null) {
      const username = String(body.username).trim().toLowerCase().replace(/^@/, '');
      if (!USERNAME_RE.test(username)) {
        return json({ error: 'invalid_username', message: 'Invalid username format.' }, 400);
      }
      updates.username = username;
    }
    if (body.bio !== undefined) updates.bio = String(body.bio ?? '').trim().slice(0, 300);
    const avatar = body.avatar_url ?? body.avatarUrl;
    if (avatar !== undefined) {
      updates.avatar_url = avatar;
      updates.avatarUrl = avatar;
    }
    if (body.onboarding_completed !== undefined) {
      updates.onboarding_completed = body.onboarding_completed === true;
    }
    if (Array.isArray(body.archetypes)) {
      updates.archetypes = body.archetypes.map((a: unknown) => String(a)).slice(0, 4);
    }

    const { data, error } = await getSupabaseAdmin()
      .from('profiles')
      .upsert(updates)
      .select()
      .single();

    if (error) {
      // 23505 = unique_violation → another account owns this username.
      if ((error as any).code === '23505') {
        return json({ error: 'username_taken', message: 'That username is taken.' }, 409);
      }
      throw error;
    }
    return json({ success: true, profile: data });
  } catch (err: any) {
    console.error('update-profile failed', err);
    return json({ error: 'internal', message: 'Could not save profile.' }, 500);
  }
});
