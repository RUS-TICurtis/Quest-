import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0";

// Ensure CORS headers for Flutter client requests (although this function is now cron-only, it's good practice)
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const YOUTUBE_API_KEY = Deno.env.get("YOUTUBE_API_KEY");
    if (!YOUTUBE_API_KEY) {
      throw new Error("Missing YOUTUBE_API_KEY environment variable");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase configuration");
    }

    // Use service role key to bypass RLS for inserting records
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const currentYear = new Date().getFullYear();

    const categories = [
      { id: "trending", query: `official movie trailer ${currentYear}` },
      { id: "action", query: `action movie trailer ${currentYear}` },
      { id: "horror", query: `horror movie trailer ${currentYear}` },
      { id: "comedy", query: `comedy movie trailer ${currentYear}` },
      { id: "bts", query: "behind the scenes movie|movie cast interview" },
    ];

    const results: Record<string, any[]> = {
      trending: [],
      action: [],
      horror: [],
      comedy: [],
      bts: [],
    };

    const allVideosToUpsertMap: Map<string, any> = new Map();

    // Helper for mandatory filtering
    const isValidVideo = (title: string) => {
      const lowerTitle = title.toLowerCase();

      // Blacklist
      if (
        lowerTitle.includes("reaction") ||
        lowerTitle.includes("fan made") ||
        lowerTitle.includes("fan-made") ||
        lowerTitle.includes("fanmade") ||
        lowerTitle.includes("explained")
      ) {
        return false;
      }

      // Whitelist (must contain at least one)
      const hasWhitelistTerm =
        lowerTitle.includes("official") ||
        lowerTitle.includes("trailer") ||
        lowerTitle.includes("teaser") ||
        lowerTitle.includes("behind the scenes") ||
        lowerTitle.includes("interview");

      return hasWhitelistTerm;
    };

    for (const cat of categories) {
      // Split by pipe if multiple queries were combined
      const queries = cat.query.split("|");

      for (const q of queries) {
        // Fetch up to 15 items per query to account for items filtered out
        const ytUrl = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(q)}&type=video&maxResults=15&key=${YOUTUBE_API_KEY}`;

        const response = await fetch(ytUrl);
        if (!response.ok) {
          console.error(`Failed to fetch YouTube API for query: ${q}`);
          continue;
        }

        const data = await response.json();
        const items = data.items || [];

        for (const item of items) {
          const title = item.snippet.title;

          if (!isValidVideo(title)) {
            continue;
          }

          const videoData = {
            id: item.id.videoId,
            title: title,
            thumbnail_url: item.snippet.thumbnails?.high?.url || item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url || "",
            video_url: `https://www.youtube.com/watch?v=${item.id.videoId}`,
            category: cat.id,
            source: "youtube",
            published_at: item.snippet.publishedAt,
            // created_at will default to now()
          };

          // Check if video already exists in our result map to prevent duplicates
          if (!results[cat.id].some(v => v.id === videoData.id)) {
             results[cat.id].push(videoData);

             // Deduplicate globally by video ID to prevent PostgreSQL upsert errors
             if (!allVideosToUpsertMap.has(videoData.id)) {
               allVideosToUpsertMap.set(videoData.id, videoData);
             }
          }
        }
      }
    }

    const allVideosToUpsert = Array.from(allVideosToUpsertMap.values());

    // Upsert to Supabase cache
    if (allVideosToUpsert.length > 0) {
      // Supabase UPSERT based on the 'id' primary key
      const { error } = await supabase
        .from("external_videos")
        .upsert(allVideosToUpsert, { onConflict: "id" });

      if (error) {
        console.error("Error upserting to Supabase:", error);
      }
    }

    // Return the categorized data directly to match request format requirements
    return new Response(JSON.stringify(results), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
