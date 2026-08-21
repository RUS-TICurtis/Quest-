import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Use service-role client for auth validation — more reliable on web origins
    // than creating an anon-key client with a forwarded Authorization header.
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "").trim();

    if (!token) {
      return new Response(JSON.stringify({ error: "Unauthorized: no token" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    const { targetUid, reason, additionalInfo } = await req.json();

    if (!targetUid) {
      return new Response(JSON.stringify({ error: "Missing required parameter: targetUid" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // supabaseAdmin already created above — no need for a separate service-role client

    // 1. Insert user block
    const { error: blockError } = await supabaseAdmin
      .from("user_blocks")
      .insert({
        blocker_id: user.id,
        blocked_id: targetUid,
      });

    if (blockError) {
      // Postgres unique violation code 23505 means already blocked
      if (blockError.code === "23505") {
        return new Response(JSON.stringify({ success: true, message: "User is already blocked" }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 200,
        });
      }
      throw blockError;
    }

    // 2. Insert moderation report
    const { error: reportError } = await supabaseAdmin
      .from("reports")
      .insert({
        reporter_id: user.id,
        target_id: targetUid,
        target_type: "user_profile",
        reported_user_id: targetUid,
        reason: reason ?? "other",
        additional_info: additionalInfo ?? "Automated report: Blocked by user.",
        status: "pending",
      });

    if (reportError) {
      console.error("Failed to automatically create block report:", reportError);
      // We don't fail the entire block action if report creation fails
    }

    return new Response(JSON.stringify({ success: true, message: "User blocked successfully" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("Error in block-user function:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
