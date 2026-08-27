import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// Basic SHA-1 for Cloudinary signature
async function sha1(str: string) {
  const buffer = new TextEncoder().encode(str);
  const hashBuffer = await crypto.subtle.digest("SHA-1", buffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  try {
    // 1. Initialize Supabase Client with Service Role (Bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing Supabase environment variables');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 2. Query expired stories
    // Stories created more than 24 hours ago
    const { data: expiredStories, error: fetchError } = await supabase
      .from('stories')
      .select('id, media_url, mux_asset_id')
      .lt('createdAt', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

    if (fetchError) {
      throw fetchError;
    }

    if (!expiredStories || expiredStories.length === 0) {
      return new Response(JSON.stringify({ message: "No expired stories found." }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    const muxTokenId = Deno.env.get('MUX_TOKEN_ID') ?? '';
    const muxTokenSecret = Deno.env.get('MUX_TOKEN_SECRET') ?? '';
    const cloudName = Deno.env.get('CLOUDINARY_CLOUD_NAME') ?? '';
    const cloudApiKey = Deno.env.get('CLOUDINARY_API_KEY') ?? '';
    const cloudApiSecret = Deno.env.get('CLOUDINARY_API_SECRET') ?? '';

    const deletedIds = [];
    const errors = [];

    // 3. Process each story
    for (const story of expiredStories) {
      try {
        // A. Delete from Mux if video
        if (story.mux_asset_id && muxTokenId && muxTokenSecret && muxTokenSecret !== 'dummy_secret') {
          const muxAuth = btoa(`${muxTokenId}:${muxTokenSecret}`);
          const muxRes = await fetch(`https://api.mux.com/video/v1/assets/${story.mux_asset_id}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Basic ${muxAuth}` }
          });
          
          if (!muxRes.ok && muxRes.status !== 404) {
            console.error(`Mux delete failed for ${story.mux_asset_id}:`, await muxRes.text());
          }
        }

        // B. Delete from Cloudinary if image
        if (story.media_url && story.media_url.includes('cloudinary.com')) {
          // Extract public_id from URL: e.g. https://res.cloudinary.com/demo/image/upload/v1234/folder/file.jpg
          // This is a naive extraction assuming standard upload URLs
          const uploadIndex = story.media_url.indexOf('/upload/');
          if (uploadIndex !== -1) {
            const pathAfterUpload = story.media_url.substring(uploadIndex + 8);
            const pathParts = pathAfterUpload.split('/');
            // Remove the version part (e.g. v1234) if it starts with 'v' and has digits
            if (pathParts[0].match(/^v\d+$/)) {
              pathParts.shift();
            }
            const publicIdWithExt = pathParts.join('/');
            const publicId = publicIdWithExt.substring(0, publicIdWithExt.lastIndexOf('.')) || publicIdWithExt;

            if (publicId && cloudApiKey && cloudApiSecret) {
              const timestamp = Math.round(new Date().getTime() / 1000).toString();
              const strToSign = `public_id=${publicId}&timestamp=${timestamp}${cloudApiSecret}`;
              const signature = await sha1(strToSign);

              const formData = new URLSearchParams();
              formData.append('public_id', publicId);
              formData.append('api_key', cloudApiKey);
              formData.append('timestamp', timestamp);
              formData.append('signature', signature);

              const cloudRes = await fetch(`https://api.cloudinary.com/v1_1/${cloudName}/image/destroy`, {
                method: 'POST',
                body: formData
              });

              if (!cloudRes.ok && cloudRes.status !== 404) {
                console.error(`Cloudinary delete failed for ${publicId}:`, await cloudRes.text());
              }
            }
          }
        }

        // 4. Delete row from Supabase
        const { error: deleteError } = await supabase
          .from('stories')
          .delete()
          .eq('id', story.id);

        if (deleteError) throw deleteError;
        
        deletedIds.push(story.id);
      } catch (err) {
        console.error(`Failed to process story ${story.id}:`, err);
        errors.push({ id: story.id, error: String(err) });
      }
    }

    return new Response(JSON.stringify({ 
      message: "Cleanup complete", 
      deletedCount: deletedIds.length,
      deletedIds,
      errors
    }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
