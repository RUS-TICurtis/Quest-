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
        if (req.method !== 'POST') {
            return new Response(
                JSON.stringify({ error: 'Method not allowed' }),
                { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        const authHeader = req.headers.get('Authorization')
        if (!authHeader) {
            return new Response(
                JSON.stringify({ error: 'Missing authorization header' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // 1. Create standard client to verify user
        const supabaseClient = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            {
                global: {
                    headers: { Authorization: authHeader },
                },
            }
        )

        const { data: { user }, error: authError } = await supabaseClient.auth.getUser()

        if (authError || !user) {
            return new Response(
                JSON.stringify({ error: 'Unauthorized', details: authError }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        let userId = user.id

        // Check if body has a target_user_id
        let body: any = {}
        try {
            body = await req.json()
        } catch (e) {
            // body is optional
        }

        if (body.target_user_id) {
            // Setup admin client to check caller's role
            const supabaseAdmin = createClient(
                Deno.env.get('SUPABASE_URL') ?? '',
                Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
            )
            
            const { data: profile } = await supabaseAdmin
                .from('profiles')
                .select('role')
                .eq('id', user.id)
                .single()
                
            if (profile?.role === 'admin' || profile?.role === 'super_admin') {
                userId = body.target_user_id
            } else {
                return new Response(
                    JSON.stringify({ error: 'Forbidden: Only admins can delete other users' }),
                    { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
                )
            }
        }
        // 2. Setup admin client for bypass queries
        const supabaseAdmin = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
        )

        const randomSuffix = crypto.randomUUID().split('-')[0]
        const scrambledEmail = `deleted_${userId.substring(0, 8)}_${randomSuffix}@deleted.finishd.app`
        const scrambledPassword = crypto.randomUUID() + crypto.randomUUID()

        // 3. Scramble the auth.users entry and ban
        const { error: updateUserError } = await supabaseAdmin.auth.admin.updateUserById(userId, {
            email: scrambledEmail,
            password: scrambledPassword,
            ban_duration: '876000h', // Approx 100 years ban
            user_metadata: {},
            app_metadata: {}
        })

        if (updateUserError) {
            throw new Error(`Failed to scramble auth user: ${updateUserError.message}`)
        }

        // 4. Anonymize profiles
        const { error: profileError } = await supabaseAdmin
            .from('profiles')
            .update({
                username: `deleted_user_${randomSuffix}`,
                first_name: 'Deleted',
                last_name: 'User',
                avatar_url: null,
                bio: null,
                firebase_uid: null,
                is_banned: true,
                ban_reason: 'Account completely deleted by user',
            })
            .eq('id', userId)

        if (profileError) {
            throw new Error(`Failed to anonymize profile: ${profileError.message}`)
        }

        // 5. Delete specific PII / Data tables
        const tablesToDeleteFrom = [
            // Social graph
            { table: 'follows', columns: ['follower_id', 'following_id'] },
            { table: 'user_blocks', columns: ['blocker_id', 'blocked_id'] },
            { table: 'activities', columns: ['user_id'] },
            // Access and Applications
            { table: 'creator_applications', columns: ['user_id'] },
            { table: 'appeals', columns: ['user_id'] },
            // User Content Tracking
            { table: 'user_titles', columns: ['user_id'] },
            { table: 'user_ratings', columns: ['user_id'] },
            { table: 'seen_history', columns: ['user_id'] },
            { table: 'feed_cache', columns: ['user_id'] },
            // Interactions
            { table: 'recommendations', columns: ['from_user_id', 'to_user_id'] }
        ]

        await Promise.all(tablesToDeleteFrom.map(async ({ table, columns }) => {
            for (const column of columns) {
                const { error: deleteError } = await supabaseAdmin
                    .from(table)
                    .delete()
                    .eq(column, userId)
                
                if (deleteError) {
                    console.error(`Failed to delete from ${table} where ${column} = ${userId}:`, deleteError.message)
                }
            }
        }))

        // We specifically leave:
        // - creator_videos
        // - video_comments
        // - messages
        // - chat_participants (can be left as they are just pointers and no PII if their profile is anonymized)

        return new Response(
            JSON.stringify({
                success: true,
                message: 'Account soft-deleted, anonymized, and banned successfully.'
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error: any) {
        console.error('Delete Account Error:', error)
        return new Response(
            JSON.stringify({ error: error.message || 'Internal Server Error' }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
