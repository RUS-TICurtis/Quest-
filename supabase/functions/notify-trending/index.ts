import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { getFcmAccessToken, sendFCMMessage } from '../_shared/fcm.ts';

serve(async (req) => {
  try {
    // 1. Fetch TMDB API Key from environment
    const tmdbApiKey = Deno.env.get('TMDB_API_KEY');
    if (!tmdbApiKey) {
      throw new Error('TMDB_API_KEY is not set');
    }

    // 2. Fetch Trending TV Shows from TMDB
    console.log('Fetching trending shows from TMDB...');
    const tmdbRes = await fetch(
      `https://api.themoviedb.org/3/trending/tv/day?api_key=${tmdbApiKey}`
    );

    if (!tmdbRes.ok) {
      throw new Error('Failed to fetch TMDB trending');
    }

    const tmdbData = await tmdbRes.json();
    const shows = tmdbData.results;

    if (!shows || shows.length === 0) {
      return new Response(JSON.stringify({ message: 'No trending shows found.' }), {
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Pick top trending show
    const topShow = shows[0];
    const showName = topShow.name || topShow.original_name;
    const showId = topShow.id.toString();

    console.log(`Top Trending Show: ${showName} (ID: ${showId})`);

    // 3. Authenticate with Google / FCM
    console.log('Authenticating FCM...');
    const { accessToken, projectId } = await getFcmAccessToken();

    // 4. Send Message to Global Topic
    const fcmPayload = {
      message: {
        topic: 'all_users',
        notification: {
          title: '🔥 Trending Today',
          body: `${showName} is trending! Check it out now.`,
        },
        data: {
          show_id: showId,
          type: 'trending',
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

    console.log(`Sending topic push to ${projectId}...`);
    const success = await sendFCMMessage(fcmPayload, accessToken, projectId);

    if (!success) {
      throw new Error('FCM API rejected payload.');
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Successfully pushed trending notification for ${showName}`,
      }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (err) {
    console.error('Crash in notify-trending:', err.message);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
