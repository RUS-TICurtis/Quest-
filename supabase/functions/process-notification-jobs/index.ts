import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { getFcmAccessToken, sendToTopic, sendFCMMessage } from "../_shared/fcm.ts";

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
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 1. Atomically claim jobs using RPC to prevent race conditions
    const { data: jobs, error: fetchError } = await supabaseAdmin.rpc('claim_notification_jobs', { p_limit: 50 });

    if (fetchError) throw fetchError;
    if (!jobs || jobs.length === 0) {
      return new Response(JSON.stringify({ message: "No pending jobs" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    // 2. Auth with FCM once for the batch
    const fcmAuth = await getFcmAccessToken();

    for (const job of jobs) {
      try {
        if (job.type === 'community_post') {
          await processCommunityPostJob(job, supabaseAdmin, fcmAuth);
        } else if (job.type === 'chat_message') {
          await processChatMessageJob(job, supabaseAdmin, fcmAuth);
        } else if (job.type === 'moderation_action') {
          await processModerationActionJob(job, supabaseAdmin, fcmAuth);
        }

        // Mark as completed
        await supabaseAdmin
          .from('notification_jobs')
          .update({
            status: 'completed',
            updated_at: new Date().toISOString(),
            next_retry_at: null, // clear any retry schedule
          })
          .eq('id', job.id);

      } catch (jobError: any) {
        console.error(`Error processing job ${job.id}:`, jobError);

        const newRetryCount = (job.retry_count || 0) + 1;
        const newStatus = newRetryCount >= 3 ? 'failed' : 'pending';

        // BUG 8 FIX: Exponential back-off — 2^retry minutes (2m, 4m, 8m).
        // Prevents hammering FCM/Supabase in a tight retry loop.
        // The claim_notification_jobs RPC must filter:
        //   WHERE status = 'pending'
        //     AND (next_retry_at IS NULL OR next_retry_at <= now())
        const backoffSeconds = Math.pow(2, newRetryCount) * 60;
        const nextRetryAt = newStatus === 'pending'
          ? new Date(Date.now() + backoffSeconds * 1000).toISOString()
          : null;

        await supabaseAdmin
          .from('notification_jobs')
          .update({
            status: newStatus,
            retry_count: newRetryCount,
            updated_at: new Date().toISOString(),
            next_retry_at: nextRetryAt,
          })
          .eq('id', job.id);
      }
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
async function processChatMessageJob(job: any, supabaseAdmin: any, fcmAuth: any) {
  const { chat_id, sender_id, sender_name, is_group, group_name, content, message_type } = job.payload;

  // 1. Fetch participants who need to be notified (excluding sender)
  const { data: participants, error: participantsError } = await supabaseAdmin
    .from('chat_participants')
    .select('user_id')
    .eq('chat_id', chat_id)
    .neq('user_id', sender_id);

  if (participantsError) throw participantsError;
  if (!participants || participants.length === 0) return;

  // 2. Prepare payload
  const title = is_group ? group_name : sender_name;
  let body = content;
  if (!body || body.trim() === '') {
    if (message_type === 'image') body = '📷 Image';
    else if (message_type === 'video') body = '🎥 Video';
    else if (message_type === 'gif') body = 'GIF';
    else if (message_type === 'recommendation') body = '🎬 Recommendation';
    else body = 'New Message';
  } else if (body.length > 50) {
    body = body.substring(0, 50) + '...';
  }

  // If group, prepend sender name to body
  if (is_group) {
    body = `${sender_name}: ${body}`;
  }

  // 3. For each participant, get their devices and send push notification
  for (const p of participants) {
    const { data: devices, error: devicesError } = await supabaseAdmin
      .from('user_devices')
      .select('fcm_token, platform')
      .eq('user_id', p.user_id);

    if (devicesError || !devices || devices.length === 0) continue;

    for (const device of devices) {
      const fcmPayload = {
        message: {
          token: device.fcm_token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "chat_message",
            chat_id: String(chat_id),
            sender_id: String(sender_id),
            click_action: "FLUTTER_NOTIFICATION_CLICK"
          },
          android: {
            notification: {
              icon: "notification_icon",
              color: "#1A8927",
              group: `chat_${chat_id}` // Conversation grouping key
            }
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                "thread-id": `chat_${chat_id}` // Thread Identifier for iOS
              }
            }
          }
        }
      };

      await sendFCMMessage(fcmPayload, fcmAuth.accessToken, fcmAuth.projectId);
    }
  }
}

async function processCommunityPostJob(job: any, supabaseAdmin: any, fcmAuth: any) {
  const { community_id, post_id, author_id, content } = job.payload;

  // 0. Rate Limiting Check: Max 3 notifications per community per hour
  const { data: canNotify, error: rateError } = await supabaseAdmin.rpc('check_community_notification_rate_limit', {
    p_community_id: community_id,
    p_limit: 3
  });

  if (rateError) {
    console.error("Rate limit check failed:", rateError);
    throw rateError;
  }

  if (!canNotify) {
    console.log(`Rate limit exceeded for community ${community_id}. Skipping notifications for post ${post_id}.`);
    return;
  }

  // Fetch community title from the communities table
  const { data: community, error: communityError } = await supabaseAdmin
    .from('communities')
    .select('title')
    .eq('id', community_id)
    .single();

  if (communityError) throw communityError;
  const communityTitle = community?.title || 'Community';

  // Fetch post details to get spoiler status and media properties
  const { data: post, error: postError } = await supabaseAdmin
    .from('community_posts')
    .select('content, is_spoiler, media_urls')
    .eq('id', post_id)
    .single();

  if (postError) throw postError;

  // Build the notification body based on spoiler configuration and content properties
  let body = '';
  if (post.is_spoiler) {
    body = 'Spoiler post shared';
  } else {
    const rawContent = (post.content || '').trim();
    if (rawContent.length > 0) {
      body = rawContent.length > 100 ? rawContent.substring(0, 100) + '...' : rawContent;
    } else if (post.media_urls && post.media_urls.length > 0) {
      body = '📷 Shared media';
    } else {
      body = 'New post shared';
    }
  }

  // 1. Send FCM Topic Push Notification
  const topic = `community_${community_id}`;
  const title = `New Post • ${communityTitle}`;

  const fcmPayload = {
    message: {
      topic: topic,
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: "community_post",
        community_id: String(community_id),
        post_id: String(post_id),
        community_title: communityTitle, // Added for direct linking
        ...(job.payload.show_id ? { show_id: String(job.payload.show_id) } : {}),
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      },
      android: {
        notification: {
          icon: "notification_icon",
          color: "#1A8927",
          group: `community_${community_id}` // Group key for grouping
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            "thread-id": `community_${community_id}` // Thread ID for iOS grouping
          }
        }
      }
    }
  };

  await sendToTopic(fcmPayload, fcmAuth.accessToken, fcmAuth.projectId);

  // 2. Generate In-App Notifications (Batch Insert)
  let offset = 0;
  const BATCH_SIZE = 1000;
  let hasMore = true;

  while (hasMore) {
    const { data: members, error: membersError } = await supabaseAdmin
      .from('community_members')
      .select('user_id')
      .eq('community_id', community_id)
      .eq('is_muted', false)
      .neq('user_id', author_id)
      .order('user_id')
      .range(offset, offset + BATCH_SIZE - 1);

    if (membersError) throw membersError;

    if (!members || members.length === 0) {
      hasMore = false;
      break;
    }

    // Prepare batch insert with rich titles and body
    const notificationInserts = members.map((m: any) => ({
      user_id: m.user_id,
      type: 'community_post',
      title: title,
      body: body,
      reference_id: post_id,
      metadata: { community_id }
    }));

    const { error: notifError } = await supabaseAdmin
      .from('notifications')
      .upsert(notificationInserts, { onConflict: 'user_id,reference_id,type', ignoreDuplicates: true });

    if (notifError) {
       console.error("Batch insert notifications error:", notifError);
       throw notifError;
    }

    if (members.length < BATCH_SIZE) {
      hasMore = false;
    } else {
      offset += BATCH_SIZE;
    }
  }
}

async function processModerationActionJob(job: any, supabaseAdmin: any, fcmAuth: any) {
  const { user_id, action, reason } = job.payload;

  // Ensure this is only for bans and suspensions
  if (action !== 'ban' && action !== 'suspend') return;

  const title = "Account Action Required";
  const body = action === 'ban' 
    ? "Your account has been banned due to a violation of our terms. Tap for details."
    : "Your account has been temporarily suspended. Tap for details.";

  // Fetch the user's devices
  const { data: devices, error: devicesError } = await supabaseAdmin
    .from('user_devices')
    .select('fcm_token, platform')
    .eq('user_id', user_id);

  if (devicesError) {
    console.error("Error fetching devices for moderation notification:", devicesError);
    throw devicesError;
  }

  // Send push notifications
  if (devices && devices.length > 0) {
    for (const device of devices) {
      const fcmPayload = {
        message: {
          token: device.fcm_token,
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: "moderation_action",
            action: action,
            click_action: "FLUTTER_NOTIFICATION_CLICK"
          },
          android: {
            notification: {
              icon: "notification_icon",
              color: "#D32F2F", // Red color for urgency
              group: `moderation`
            }
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1,
                "thread-id": `moderation`
              }
            }
          }
        }
      };

      await sendFCMMessage(fcmPayload, fcmAuth.accessToken, fcmAuth.projectId);
    }
  }

  // Generate an in-app notification
  const { error: notifError } = await supabaseAdmin
    .from('notifications')
    .insert({
      user_id: user_id,
      type: 'moderation_action',
      title: title,
      body: body,
      metadata: { action, reason }
    });

  if (notifError) {
    console.error("Error inserting in-app notification:", notifError);
    // Don't throw here to avoid retrying the FCM push if only the in-app insert fails
  }
}

