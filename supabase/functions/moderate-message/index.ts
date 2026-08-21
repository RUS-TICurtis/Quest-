import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

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
        const { messageId, content, authorId, createdAt } = await req.json()

        if (!messageId || !createdAt) {
            return new Response(JSON.stringify({ error: 'Missing messageId or createdAt' }), { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
        }

        // Initialize Supabase admin client
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        let isFlagged = false;
        let aiReason = null;

        // Only moderate if there is text content
        if (content && content.trim() !== '') {
            // Call OpenAI Free Moderation API
            const openAiKey = Deno.env.get('OPENAI_API_KEY')
            if (openAiKey) {
                try {
                    const openAiRes = await fetch('https://api.openai.com/v1/moderations', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${openAiKey}`
                        },
                        body: JSON.stringify({ input: content })
                    })

                    if (openAiRes.ok) {
                        const aiData = await openAiRes.json()
                        isFlagged = aiData.results[0].flagged

                        if (isFlagged) {
                            const categories = aiData.results[0].categories;
                            const flaggedCategories = Object.keys(categories).filter(key => categories[key]);
                            aiReason = `OpenAI Flagged: ${flaggedCategories.join(', ')}`;
                        }
                    } else if (openAiRes.status === 429) {
                        // Rate limit or quota exceeded — skip moderation, don't block message delivery.
                        console.warn(`[moderate-message] OpenAI 429 rate limit / quota exceeded. Message ${messageId} skipped for moderation. Check your OpenAI billing at https://platform.openai.com/settings/organization/billing`)
                        aiReason = 'skipped:openai_rate_limit'
                    } else {
                        const errText = await openAiRes.text()
                        console.error(`[moderate-message] OpenAI API error ${openAiRes.status}:`, errText)
                    }
                } catch (e) {
                    console.error("[moderate-message] OpenAI fetch error:", e)
                }
            } else {
                console.warn("[moderate-message] OPENAI_API_KEY is not set. Skipping AI moderation.");
            }
        }

        // Update the message status.
        const { error: updateError } = await supabaseAdmin
            .from('messages')
            .update({
                moderation_status: isFlagged ? 'flagged' : 'approved',
                content: isFlagged ? 'This message was hidden due to community guidelines violation.' : content,
                media_url: isFlagged ? null : undefined, // undefined means "don't change"
            })
            .eq('id', messageId)
            .eq('created_at', createdAt)

        if (updateError) {
            console.error("Supabase update error:", updateError);
            throw updateError;
        }

        // COMPLIANCE: If flagged by AI, log it directly to public.moderation_actions
        if (isFlagged) {
            // Find a valid admin/reviewer profile to act as system actor, fallback to the author
            let actorId = authorId;
            const { data: adminProfile } = await supabaseAdmin
                .from('profiles')
                .select('id')
                .eq('role', 'admin')
                .limit(1)
                .maybeSingle();

            if (adminProfile) {
                actorId = adminProfile.id;
            }

            const { error: actionError } = await supabaseAdmin
                .from('moderation_actions')
                .insert({
                    actor_id: actorId,
                    target_type: 'chat_message',
                    target_id: messageId,
                    action: 'suppress',
                    reason: aiReason,
                    metadata: {
                        automated: true,
                        detector: 'OpenAI Moderation API',
                        original_author: authorId
                    }
                });

            if (actionError) {
                console.error("Error logging auto-moderation action:", actionError);
            }
        }

        return new Response(
            JSON.stringify({ success: true, flagged: isFlagged, reason: aiReason }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Error:', error)
        return new Response(
            JSON.stringify({ error: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})