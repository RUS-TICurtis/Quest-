import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3';
import { getFcmAccessToken, sendFCMMessage } from '../_shared/fcm.ts';

serve(async (req) => {
  try {
    const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!tmdbApiKey || !supabaseUrl || !supabaseKey) {
      throw new Error('Missing environment configuration.');
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // 1. O(1) External API Call: Fetch all TV shows airing today globally
    console.log('Fetching tmdb airing_today...');
    const tmdbRes = await fetch(
      `https://api.themoviedb.org/3/tv/airing_today?api_key=${tmdbApiKey}&timezone=America%2FNew_York`
    );

    if (!tmdbRes.ok) {
      throw new Error('Failed to fetch TMDB airing_today');
    }

    const tmdbData = await tmdbRes.json();
    const airingShows = tmdbData.results || [];
    
    if (airingShows.length === 0) {
      return new Response(JSON.stringify({ message: 'No shows airing today.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Hash the airing shows for O(1) lookup
    const airingShowMap = new Map<string, any>();
    for (const show of airingShows) {
      airingShowMap.set(show.id.toString(), show);
    }

    // 2. Fetch User Watchlists efficiently
    console.log('Fetching user watchlists from DB...');
    // We only fetch 'tv' that are in 'watchlist' and paginate if needed. But edge functions handle up to 50mb RAM easily.
    // We'll fetch all using a looped query if over 1000, but for now standard fetch limits apply (default 1000). 
    // We explicitly set a high limit since it's a backend cron.
    const { data: watchlists, error: dbError } = await supabase
      .from('user_titles')
      .select('title_id, user_id')
      .eq('media_type', 'tv')
      .in('status', ['watchlist', 'watching'])
      .limit(100000);

    if (dbError) {
      throw new Error(`DB Error: ${dbError.message}`);
    }

    // 3. Map Shows to Users
    const notifyMap = new Map<string, Set<string>>(); // show_id -> Set<user_id>
    const userIdsToFetchTokens = new Set<string>();

    for (const entry of watchlists || []) {
      const showId = entry.title_id;
      if (airingShowMap.has(showId)) {
        const userId = entry.user_id;
        if (!notifyMap.has(showId)) {
          notifyMap.set(showId, new Set());
        }
        notifyMap.get(showId)!.add(userId);
        userIdsToFetchTokens.add(userId);
      }
    }

    if (userIdsToFetchTokens.size === 0) {
      return new Response(JSON.stringify({ message: 'No users tracking airing shows today.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // 4. Batch Resolve FCM Tokens
    console.log(`Fetching tokens for ${userIdsToFetchTokens.size} users...`);
    const userIdsArray = Array.from(userIdsToFetchTokens);
    const tokenMap = new Map<string, string[]>(); // user_id -> [tokens]

    // Chunk DB queries to avoid URL length issues or PostgREST limits
    const chunkSize = 500;
    for (let i = 0; i < userIdsArray.length; i += chunkSize) {
      const chunk = userIdsArray.slice(i, i + chunkSize);
      
      const { data: devices, error: devError } = await supabase
        .from('user_devices')
        .select('user_id, fcm_token')
        .in('user_id', chunk);

      if (!devError && devices) {
        for (const dev of devices) {
          if (!tokenMap.has(dev.user_id)) {
            tokenMap.set(dev.user_id, []);
          }
          tokenMap.get(dev.user_id)!.push(dev.fcm_token);
        }
      }
    }

    // 5. Authenticate FCM
    console.log('Authenticating FCM...');
    const { accessToken, projectId } = await getFcmAccessToken();
    let sentCount = 0;
    
    // 6. Dispatch Notifications Concurrently safely via Batching
    const fcmPromises: Promise<any>[] = [];

    for (const [showId, usersSet] of notifyMap.entries()) {
      const showInfo = airingShowMap.get(showId)!;
      const showName = showInfo.name || showInfo.original_name;

      for (const userId of usersSet) {
        const tokens = tokenMap.get(userId) || [];
        
        for (const token of tokens) {
          const payload = {
            message: {
              token: token,
              notification: {
                title: '📺 Airing Today',
                body: `${showName} is airing today!`,
              },
              data: {
                show_id: showId.toString(),
                type: 'airing_today',
              },
              android: {
                notification: {
                  icon: "notification_icon",
                  color: "#1A8927"
                }
              },
              apns: {
                payload: {
                  aps: { sound: "default", badge: 1 }
                }
              }
            },
          };

          const p = sendFCMMessage(payload, accessToken, projectId).then(success => {
            if (success) sentCount++;
          });
          
          fcmPromises.push(p);

          // prevent overwhelming Node/Deno thread queue by chunking Promise.all
          if (fcmPromises.length >= 200) {
            await Promise.all(fcmPromises);
            fcmPromises.length = 0; // reset
          }
        }
      }
    }

    // flush remaining
    if (fcmPromises.length > 0) {
      await Promise.all(fcmPromises);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Processed. Sent ${sentCount} notifications across ${notifyMap.size} unique shows.`,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Crash in notify-airing-today:', err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
