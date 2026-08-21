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
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const resendApiKey = Deno.env.get("RESEND_API_KEY")!;
    
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Claim jobs atomically via RPC
    const { data: jobs, error: claimError } = await supabaseAdmin.rpc('claim_email_jobs', { p_limit: 100 });
    
    if (claimError) throw claimError;
    if (!jobs || jobs.length === 0) {
      return new Response(JSON.stringify({ message: "No pending emails" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    for (const job of jobs) {
      try {
        let recipientEmail = job.payload.to;
        
        // If payload provides user_id instead of email, fetch the email from auth.users (via admin api)
        if (!recipientEmail && job.payload.user_id) {
          if (job.payload.user_id.includes('@')) {
             recipientEmail = job.payload.user_id;
          } else {
             const { data: { user }, error: userError } = await supabaseAdmin.auth.admin.getUserById(job.payload.user_id);
             if (userError || !user) throw new Error(`User not found: ${job.payload.user_id}`);
             recipientEmail = user.email;
          }
        }

        if (!recipientEmail) throw new Error("No recipient email provided");

        let body = job.payload.htmlBody || '';
        let subject = job.payload.subject || 'No Subject';

        // Fetch template if provided
        if (job.payload.templateId) {
           const { data: template, error: templateError } = await supabaseAdmin
             .from('email_templates')
             .select('html_body, subject')
             .eq('id', job.payload.templateId)
             .single();
             
           if (template && !templateError) {
             body = template.html_body;
             subject = job.payload.subject || template.subject; // Override subject if provided in payload
           }
        }

        // Apply variables
        const variables = job.payload.variables || {};
        for (const [key, value] of Object.entries(variables)) {
           body = body.replace(new RegExp(`{{${key}}}`, 'g'), String(value));
           subject = subject.replace(new RegExp(`{{${key}}}`, 'g'), String(value));
        }

        // Send via Resend
        const resRequest = await fetch('https://api.resend.com/emails', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${resendApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            from: 'Finishd Admin <noreply@finishd.app>',
            to: [recipientEmail],
            subject: subject,
            html: body,
          })
        });

        const resData = await resRequest.json();

        if (!resRequest.ok) {
           throw new Error(`Resend Error: ${resData.message || JSON.stringify(resData)}`);
        }

        // Mark sent & log
        await supabaseAdmin.from('email_queue').update({
           status: 'sent',
           processed_at: new Date().toISOString()
        }).eq('id', job.id);

        await supabaseAdmin.from('email_logs').insert({
           recipient: recipientEmail,
           subject: subject,
           template_id: job.payload.templateId,
           status: 'sent',
           provider_message_id: resData.id
        });

      } catch (jobError: any) {
         console.error(`Error processing email ${job.id}:`, jobError);
         const newRetryCount = (job.retry_count || 0) + 1;
         const newStatus = newRetryCount >= 3 ? 'failed' : 'pending';
         const backoffSeconds = Math.pow(2, newRetryCount) * 60;
         
         const nextRetryAt = newStatus === 'pending'
           ? new Date(Date.now() + backoffSeconds * 1000).toISOString()
           : null;

         await supabaseAdmin.from('email_queue').update({
           status: newStatus,
           retry_count: newRetryCount,
           error_message: jobError.message,
           scheduled_for: nextRetryAt,
         }).eq('id', job.id);
      }
    }

    if (jobs.length === 100) {
      supabaseAdmin.functions.invoke('process-email-queue').catch(e => console.error("Recursive trigger failed:", e));
    }

    return new Response(JSON.stringify({ processed: jobs.length }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("Worker error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
