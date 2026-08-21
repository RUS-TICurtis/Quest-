import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.39.0";

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
    // 1. Validate secrets
    const tmdbApiKey = Deno.env.get("TMDB_API_KEY");
    if (!tmdbApiKey) {
      throw new Error("TMDB_API_KEY is not set in Edge Function secrets.");
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase auto-injected environment variables.");
    }

    // 2. Initialize privileged client
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 3. Fetch data from TMDB
    const tmdbRes = await fetch(
      `https://api.themoviedb.org/3/trending/all/day?api_key=${tmdbApiKey}`
    );

    if (!tmdbRes.ok) {
      const errText = await tmdbRes.text();
      throw new Error(`TMDB error (${tmdbRes.status}): ${errText}`);
    }

    const tmdbData = await tmdbRes.json();
    const movies = tmdbData.results || [];

    // 4. Normalize TMDB items (movie 'title' vs tv 'name')
    const normalizedMovies = movies.map((m: any) => ({
      id: m.id,
      title: m.title || m.name,
      poster_path: m.poster_path,
      overview: m.overview,
      media_type: m.media_type,
    }));

    const dateToday = new Date().toISOString().split("T")[0];

    // 5. Upsert into database
    const { error: dbError } = await supabase
      .from("daily_trending")
      .upsert(
        {
          date: dateToday,
          movies: normalizedMovies,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "date" }
      );

    if (dbError) {
      throw new Error(`Supabase Upsert Error: ${dbError.message}`);
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: "Trending movies updated successfully.",
        date: dateToday, 
        count: normalizedMovies.length 
      }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error: any) {
    console.error("[fetch-daily-trending] Error:", error.message);
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500,
      }
    );
  }
});
