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
    const { roomId, text, type = 'text', time } = body;

    if (!roomId || !text) {
      return new Response(JSON.stringify({ error: 'Missing roomId or text' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const admin = getSupabaseAdmin();
    const messageTime = time || new Date().toISOString();

    // 1. Insert message
    const { data: message, error: msgError } = await admin
      .from('chat_messages')
      .insert({
        roomId,
        senderId: userId,
        text,
        time: messageTime,
        type,
        status: 'sent',
      })
      .select()
      .single();

    if (msgError) {
      throw msgError;
    }

    // 2. Update room lastMessage info atomically
    await admin
      .from('chat_rooms')
      .update({
        lastMessageText: text,
        lastMessageTime: messageTime,
      })
      .eq('id', roomId);

    return new Response(JSON.stringify({ success: true, message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
