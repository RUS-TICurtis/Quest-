import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Verify admin role via user JWT
    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''));
    if (authError || !user) {
      return new Response("Unauthorized", { status: 401, headers: corsHeaders });
    }

    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single();

    if (profile?.role !== 'admin') {
      return new Response("Forbidden", { status: 403, headers: corsHeaders });
    }

    const { target, subject, htmlBody, templateId, variables } = await req.json();

    // target can be 'all', 'moderators', or a specific user_id / email
    // This function will resolve the target and insert rows into email_queue
    let queueInserts = [];

    if (target === 'all') {
      // Stream all users with marketing/announcements enabled
      const { data: users, error } = await supabaseAdmin
        .from('email_preferences')
        .select('user_id, auth.users!inner(email)')
        .eq('announcements', true);

      if (error) throw error;
      
      queueInserts = users.map((u: any) => ({
        payload: { to: u.users.email, subject, htmlBody, templateId, variables },
        priority: 0
      }));
    } else if (target === 'moderators') {
       const { data: users, error } = await supabaseAdmin
        .from('profiles')
        .select('id')
        .eq('role', 'moderator');
        
       if (error) throw error;
       
       const { data: emails } = await supabaseAdmin.auth.admin.listUsers(); // Warning: listUsers is paginated, but let's assume we fetch emails via RPC or we store them
       // Better approach: use an RPC to get emails or just let the queue processor resolve the user_id to email if needed.
       // Let's just queue with user_id, and process-email-queue resolves it.
       queueInserts = users.map((u: any) => ({
         payload: { user_id: u.id, subject, htmlBody, templateId, variables },
         priority: 1
       }));
    } else {
      // specific user/email
      const isEmail = target.includes('@');
      queueInserts = [{
        payload: isEmail 
          ? { to: target, subject, htmlBody, templateId, variables }
          : { user_id: target, subject, htmlBody, templateId, variables },
        priority: 2
      }];
    }

    if (queueInserts.length === 0) {
        return new Response(JSON.stringify({ message: "No targets found" }), { headers: corsHeaders });
    }

    // Insert in batches of 1000
    const BATCH_SIZE = 1000;
    for (let i = 0; i < queueInserts.length; i += BATCH_SIZE) {
      const batch = queueInserts.slice(i, i + BATCH_SIZE);
      const { error } = await supabaseAdmin.from('email_queue').insert(batch);
      if (error) throw error;
    }

    // Trigger processing asynchronously
    supabaseAdmin.functions.invoke('process-email-queue').catch(e => console.error(e));

    return new Response(JSON.stringify({ success: true, queued: queueInserts.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("Queue email error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
