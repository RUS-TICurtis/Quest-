import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { corsHeaders } from "../_shared/cors.ts";
import { verifyAuth } from "../_shared/supabase.ts";

/**
 * sign-media-upload
 *
 * Secure server-side credential gate for media uploads.
 * Replaces client-side secrets (Mux, Cloudinary, ImageKit).
 *
 * All requests require a valid Supabase user JWT in the Authorization header.
 *
 * Actions / Providers:
 * - provider: "mux" -> Returns pre-signed direct upload URL + ID
 * - provider: "mux", action: "check_mux" -> Queries Mux upload status / asset readiness
 * - provider: "cloudinary" -> Signs upload params server-side with CLOUDINARY_API_SECRET
 * - provider: "imagekit" -> Signs auth params server-side with IMAGEKIT_PRIVATE_KEY
 */

// SHA-1 helper using Web Crypto API
async function sha1Hex(str: string): Promise<string> {
  const data = new TextEncoder().encode(str);
  const hashBuffer = await crypto.subtle.digest("SHA-1", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

// HMAC-SHA1 helper using Web Crypto API
async function hmacSha1Hex(keyStr: string, dataStr: string): Promise<string> {
  const keyData = new TextEncoder().encode(keyStr);
  const msgData = new TextEncoder().encode(dataStr);
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-1" },
    false,
    ["sign"],
  );
  const sigBuffer = await crypto.subtle.sign("HMAC", cryptoKey, msgData);
  return Array.from(new Uint8Array(sigBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    // 1. Authenticate user
    const user = await verifyAuth(req);
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const provider = (body.provider as string || "").toLowerCase();
    const action = (body.action as string || "create_upload").toLowerCase();

    // ── MUX HANDLER ──────────────────────────────────────────────────────────
    if (provider === "mux") {
      const tokenId = Deno.env.get("MUX_TOKEN_ID");
      const tokenSecret = Deno.env.get("MUX_TOKEN_SECRET");

      if (!tokenId || !tokenSecret) {
        return new Response(
          JSON.stringify({ error: "Mux server credentials not configured" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      const basicAuth = btoa(`${tokenId}:${tokenSecret}`);

      if (action === "check_mux") {
        const uploadId = body.upload_id as string;
        if (!uploadId) {
          return new Response(
            JSON.stringify({ error: "Missing upload_id for check_mux" }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
          );
        }

        // 1. Check upload
        const uploadResp = await fetch(`https://api.mux.com/video/v1/uploads/${uploadId}`, {
          headers: { Authorization: `Basic ${basicAuth}` },
        });
        const uploadJson = await uploadResp.json();
        const uploadData = uploadJson.data;

        if (!uploadData) {
          return new Response(
            JSON.stringify({ error: "Upload not found", detail: uploadJson }),
            { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
          );
        }

        const uploadStatus = uploadData.status;
        const assetId = uploadData.asset_id;

        if (uploadStatus === "asset_created" && assetId) {
          // 2. Check asset readiness
          const assetResp = await fetch(`https://api.mux.com/video/v1/assets/${assetId}`, {
            headers: { Authorization: `Basic ${basicAuth}` },
          });
          const assetJson = await assetResp.json();
          const assetData = assetJson.data;

          if (assetData?.status === "ready" && assetData?.playback_ids?.length > 0) {
            const playbackId = assetData.playback_ids[0].id;
            return new Response(
              JSON.stringify({
                status: "ready",
                asset_id: assetId,
                playback_id: playbackId,
              }),
              { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
            );
          } else if (assetData?.status === "errored") {
            return new Response(
              JSON.stringify({ status: "errored", error: "Mux asset processing failed" }),
              { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
            );
          }

          return new Response(
            JSON.stringify({ status: "processing", asset_id: assetId }),
            { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
          );
        }

        return new Response(
          JSON.stringify({ status: uploadStatus }),
          { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // Default: create direct upload
      const createResp = await fetch("https://api.mux.com/video/v1/uploads", {
        method: "POST",
        headers: {
          Authorization: `Basic ${basicAuth}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          new_asset_settings: {
            playback_policy: ["public"],
            passthrough: user.id,
          },
          cors_origin: "*",
        }),
      });

      const createJson = await createResp.json();
      if (!createResp.ok || !createJson.data) {
        console.error("[sign-media-upload] Mux create error:", createJson);
        return new Response(
          JSON.stringify({ error: "Failed to create Mux direct upload", detail: createJson }),
          { status: createResp.status, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      return new Response(
        JSON.stringify({
          provider: "mux",
          upload_url: createJson.data.url,
          upload_id: createJson.data.id,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── CLOUDINARY HANDLER ───────────────────────────────────────────────────
    if (provider === "cloudinary") {
      const cloudName = Deno.env.get("CLOUDINARY_CLOUD_NAME") || "wmjg4pug";
      const apiKey = Deno.env.get("CLOUDINARY_API_KEY");
      const apiSecret = Deno.env.get("CLOUDINARY_API_SECRET");

      if (!apiKey || !apiSecret) {
        return new Response(
          JSON.stringify({ error: "Cloudinary server credentials not configured" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      const isVideo = Boolean(body.is_video);
      const timestamp = Math.round(Date.now() / 1000).toString();
      const paramsToSign = `timestamp=${timestamp}${apiSecret}`;
      const signature = await sha1Hex(paramsToSign);

      const resourceType = isVideo ? "video" : "image";
      const uploadUrl = `https://api.cloudinary.com/v1_1/${cloudName}/${resourceType}/upload`;

      return new Response(
        JSON.stringify({
          provider: "cloudinary",
          upload_url: uploadUrl,
          api_key: apiKey,
          timestamp,
          signature,
          cloud_name: cloudName,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── IMAGEKIT HANDLER ─────────────────────────────────────────────────────
    if (provider === "imagekit") {
      const publicKey = Deno.env.get("IMAGEKIT_PUBLIC_KEY");
      const privateKey = Deno.env.get("IMAGEKIT_PRIVATE_KEY");

      if (!publicKey || !privateKey) {
        return new Response(
          JSON.stringify({ error: "ImageKit server credentials not configured" }),
          { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      const token = crypto.randomUUID();
      const expire = (Math.round(Date.now() / 1000) + 1800).toString(); // 30 minutes
      const dataToSign = `${token}${expire}`;
      const signature = await hmacSha1Hex(privateKey, dataToSign);

      return new Response(
        JSON.stringify({
          provider: "imagekit",
          upload_url: "https://upload.imagekit.io/api/v1/files/upload",
          public_key: publicKey,
          token,
          expire,
          signature,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ error: "Unknown provider. Supported: mux, cloudinary, imagekit" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    console.error("[sign-media-upload] Exception:", error);
    return new Response(
      JSON.stringify({ error: (error as Error).message || "Internal Server Error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
