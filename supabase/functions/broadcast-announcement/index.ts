import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getFcmAccessToken, sendFCMMessage } from "../_shared/fcm.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error("Missing environment configuration.");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing Authorization header.");
    }
    const token = authHeader.replace("Bearer ", "");

    // Create client with the user's JWT so auth.uid() works in the database RPC
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: authHeader,
        },
      },
    });

    // Verify user manually
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      throw new Error(`Unauthorized: ${authError?.message || 'Invalid user'}`);
    }

    // Check if user is admin
    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile || profile.role !== "admin") {
      throw new Error("Forbidden: You do not have permission to broadcast announcements.");
    }

    // 1. Get request body
    const { title, body, type, image_url, metadata = {} } = await req.json();

    if (!title || !body) {
      throw new Error("Title and Body are required for a broadcast.");
    }

    console.log(`Starting broadcast: ${title}`);

    // 2. Call the Database RPC to record history in the 'notifications' table for all users
    // This handles the "In-App" part of the announcement.
    const { data: userCount, error: rpcError } = await supabase.rpc("send_global_notification", {
      p_title: title,
      p_body: body,
      p_type: type ?? "announcement",
      p_image_url: image_url ?? null,
      p_metadata: metadata,
    });

    if (rpcError) {
      console.error("RPC Error:", rpcError);
      throw new Error(`Failed to record notification history: ${rpcError.message}`);
    }

    // 3. Trigger FCM Push Notification via the 'global_announcements' topic
    // This handles the "Push" part (outside the app).
    console.log("Authenticating with Firebase...");
    const { accessToken, projectId } = await getFcmAccessToken();

    const fcmPayload = {
      message: {
        topic: "all_users",
        notification: {
          title: title,
          body: body,
          image: image_url,
        },
        data: {
          ...metadata,
          type: type ?? "announcement",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          notification: {
            icon: "notification_icon",
            color: "#1A8927", // Branding green
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    console.log("Dispatching FCM topic message...");
    const success = await sendFCMMessage(fcmPayload, accessToken, projectId);

    return new Response(
      JSON.stringify({
        success,
        message: `Broadcast processed. History created for ${userCount} users. FCM Topic: global_announcements`,
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (err) {
    console.error("Broadcast Failure:", err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
