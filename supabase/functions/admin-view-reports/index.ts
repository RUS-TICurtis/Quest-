// Admin View Reports Edge Function
//
// All requests are made via POST (supabase-flutter functions.invoke always sends POST).
//
// POST /admin-view-reports  — no body (or empty body) → returns list of reports
// POST /admin-view-reports  — body: { reportId, action, notes? } → resolves/dismisses a report

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── Service-role client — used for ALL operations ─────────────────────
    // We use the service role for auth.getUser() as well, passing the raw
    // bearer token. This is more reliable than creating an anon-key client
    // with a forwarded Authorization header (which can fail on web origins).
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // ── Auth: verify caller is an admin / reviewer ─────────────────────────
    const authHeader = req.headers.get("Authorization");
    const token = authHeader?.replace("Bearer ", "").trim();

    if (!token) {
      return new Response(JSON.stringify({ error: "Unauthorized: no token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const {
      data: { user },
      error: authError,
    } = await supabaseAdmin.auth.getUser(token);

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile || !["admin", "reviewer"].includes(profile.role)) {
      return new Response(
        JSON.stringify({ error: "Forbidden: Admin or reviewer role required" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── Route: decide list vs resolve based on body content ────────────────
    // supabase-flutter always sends POST; an empty/missing body means "list".
    let body: Record<string, unknown> = {};
    try {
      const text = await req.text();
      if (text && text.trim().length > 0) {
        body = JSON.parse(text);
      }
    } catch (_) {
      // Non-JSON body — treat as list request
    }

    const { reportId, action, notes } = body as {
      reportId?: string;
      action?: string;
      notes?: string;
    };

    // ── RESOLVE / DISMISS ──────────────────────────────────────────────────
    if (reportId) {
      if (!action || !["dismiss", "resolve"].includes(action)) {
        return new Response(
          JSON.stringify({ error: "Invalid action. Must be 'dismiss' or 'resolve'." }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      const newStatus = action === "dismiss" ? "dismissed" : "resolved";
      const now = new Date().toISOString();

      const { error: updateError } = await supabaseAdmin
        .from("reports")
        .update({
          status: newStatus,
          reviewed_by: user.id,
          resolution_notes: notes ?? null,
          resolved_at: now,
          updated_at: now,
        })
        .eq("id", reportId);

      if (updateError) {
        return new Response(JSON.stringify({ error: updateError.message }), {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(
        JSON.stringify({
          success: true,
          message: `Report ${action}ed successfully`,
          reportId,
          newStatus,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // ── LIST REPORTS ───────────────────────────────────────────────────────
    const status = (body["status"] as string) || "pending";
    const limit = parseInt((body["limit"] as string) || "50") || 50;

    // Fetch universal reports from the single `reports` table.
    // We use two separate select calls to avoid brittle nested FK aliases:
    //   1. The reports themselves
    //   2. Reporter + reported-user profiles (joined in application layer)
    const { data: reports, error: reportsError } = await supabaseAdmin
      .from("reports")
      .select(
        `
        id,
        reporter_id,
        target_id,
        target_id_int,
        target_type,
        reason,
        additional_info,
        status,
        reported_user_id,
        community_id,
        chat_id,
        resolved_at,
        resolution_notes,
        created_at,
        updated_at
      `
      )
      .eq("status", status)
      .order("created_at", { ascending: true })
      .limit(limit);

    if (reportsError) {
      return new Response(JSON.stringify({ error: reportsError.message }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (!reports || reports.length === 0) {
      return new Response(JSON.stringify({ reports: [] }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // ── Resolve profile usernames in a single IN query ─────────────────────
    const profileIds = new Set<string>();
    for (const r of reports) {
      if (r.reporter_id) profileIds.add(r.reporter_id);
      if (r.reported_user_id) profileIds.add(r.reported_user_id);
    }

    const profileIdList = Array.from(profileIds);
    let profileMap: Record<string, { username: string }> = {};

    if (profileIdList.length > 0) {
      const { data: profiles } = await supabaseAdmin
        .from("profiles")
        .select("id, username")
        .in("id", profileIdList);

      if (profiles) {
        for (const p of profiles) {
          profileMap[p.id] = { username: p.username };
        }
      }
    }

    // ── Combine and return ─────────────────────────────────────────────────
    const formatted = reports.map((r: any) => ({
      id: r.id,
      reporter_id: r.reporter_id,
      reporter_username: profileMap[r.reporter_id]?.username ?? "unknown",
      target_id: r.target_id,
      target_id_int: r.target_id_int,
      target_type: r.target_type,
      reason: r.reason,
      additional_info: r.additional_info,
      status: r.status,
      reported_user_id: r.reported_user_id,
      reported_user: r.reported_user_id
        ? { username: profileMap[r.reported_user_id]?.username ?? "Unknown" }
        : null,
      community_id: r.community_id,
      chat_id: r.chat_id,
      resolved_at: r.resolved_at,
      resolution_notes: r.resolution_notes,
      created_at: r.created_at,
      updated_at: r.updated_at,
    }));

    return new Response(JSON.stringify({ reports: formatted }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Unhandled error in admin-view-reports:", err);
    return new Response(JSON.stringify({ error: err.message ?? "Internal server error" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
