import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface EvidenceItem {
  mediaUrl: string;
  mediaType: 'image' | 'video' | 'text';
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const {
      firebaseUid,
      targetId,
      targetType,
      reported_user_id,
      reason,
      additionalInfo,
      community_id,
      chatId,
      contentSnapshot,
      evidence, // Array of { mediaUrl, mediaType }
    } = await req.json();

    // Validate required fields
    if (!firebaseUid || !targetType || !reason) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // 1. Lookup the Supabase UUID from the firebase_uid OR direct id match (UUID)
    let reporterId: string | null = null;
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    
    if (uuidRegex.test(firebaseUid)) {
      // Direct UUID match attempt
      const { data: directProfile } = await supabase
        .from("profiles")
        .select("id")
        .eq("id", firebaseUid)
        .maybeSingle();
      if (directProfile) {
        reporterId = directProfile.id;
      }
    }

    if (!reporterId) {
      // Try treating as firebase_uid string lookup
      const { data: mappedProfile } = await supabase
        .from("profiles")
        .select("id")
        .eq("firebase_uid", firebaseUid)
        .maybeSingle();
      if (mappedProfile) {
        reporterId = mappedProfile.id;
      }
    }

    if (!reporterId) {
      console.error("Reporter profile not found for identifier", firebaseUid);
      return new Response(JSON.stringify({ error: "User profile not found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 404,
      });
    }

    // 2. Resolve reportedUserId: support direct UUID match OR firebase_uid lookup
    let resolvedReportedUserId: string | null = null;
    if (reported_user_id) {
      if (uuidRegex.test(reported_user_id)) {
        const { data: directReported } = await supabase
          .from("profiles")
          .select("id")
          .eq("id", reported_user_id)
          .maybeSingle();
        if (directReported) {
          resolvedReportedUserId = directReported.id;
        }
      }
      
      if (!resolvedReportedUserId) {
        const { data: mappedReported } = await supabase
          .from("profiles")
          .select("id")
          .eq("firebase_uid", reported_user_id)
          .maybeSingle();
        if (mappedReported) {
          resolvedReportedUserId = mappedReported.id;
        }
      }
    }

    // 2.5 Resolve communityId if it's passed but might be a showId
    let resolvedCommunityId: number | null = null;
    if (community_id !== undefined && community_id !== null) {
      const { data: directComm } = await supabase
        .from("communities")
        .select("id")
        .eq("id", community_id)
        .maybeSingle();

      if (directComm) {
        resolvedCommunityId = directComm.id;
      } else {
        const { data: showComm } = await supabase
          .from("communities")
          .select("id")
          .eq("show_id", community_id)
          .maybeSingle();
        if (showComm) {
          resolvedCommunityId = showComm.id;
        }
      }
    }

    // 3. Duplicate check: prevent same reporter from reporting same content twice
    let duplicateQuery = supabase
      .from("reports")
      .select("id")
      .eq("reporter_id", reporterId)
      .eq("target_type", targetType);
      
    if (targetId) duplicateQuery = duplicateQuery.eq("target_id", targetId);
    else if (targetType === 'user' && resolvedReportedUserId) duplicateQuery = duplicateQuery.eq("reported_user_id", resolvedReportedUserId);
    else if (targetType === 'community' && resolvedCommunityId) duplicateQuery = duplicateQuery.eq("target_id_int", resolvedCommunityId);

    const { data: existing } = await duplicateQuery.maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({ error: "You have already reported this content" }),
        {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 409,
        }
      );
    }

    // 4. Insert the report
    const { data: report, error: reportError } = await supabase
      .from("reports")
      .insert({
        reporter_id: reporterId,
        target_id: targetId ?? null,
        target_id_int: targetType === 'community' ? resolvedCommunityId : null,
        target_type: targetType,
        reported_user_id: resolvedReportedUserId ?? null,
        reason: reason,
        additional_info: additionalInfo ?? null,
        content_snapshot: contentSnapshot ?? null,
        community_id: resolvedCommunityId ?? null,
        chat_id: chatId ?? null,
        status: "pending",
      })
      .select()
      .single();

    if (reportError) {
      // Catch rate-limiting trigger exception
      if (reportError.message.includes("Rate limit exceeded")) {
        return new Response(JSON.stringify({ error: reportError.message }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: 429,
        });
      }
      return new Response(JSON.stringify({ error: reportError.message }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    // 5. Insert evidence if provided
    if (evidence && Array.isArray(evidence) && evidence.length > 0) {
      const evidenceRows = evidence.map((item: EvidenceItem) => ({
        report_id: report.id,
        media_url: item.mediaUrl,
        media_type: item.mediaType,
      }));

      const { error: evidenceError } = await supabase
        .from("report_evidence")
        .insert(evidenceRows);

      if (evidenceError) {
        console.error("Error inserting report evidence:", evidenceError);
        // We do not throw to avoid failing the report itself, but log it
      }
    }

    return new Response(JSON.stringify({ success: true, report }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (err) {
    console.error("Error submitting report:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 400,
    });
  }
});
