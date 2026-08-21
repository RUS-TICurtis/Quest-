import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// ─── Env helpers ─────────────────────────────────────────────────────────────
// Resolved once per function cold start; Edge Functions are single-tenant so
// these are effectively module-level constants.
const SUPABASE_URL         = () => Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY    = () => Deno.env.get("SUPABASE_ANON_KEY")!;
const SUPABASE_SERVICE_KEY = () => Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// ─── Client factories ─────────────────────────────────────────────────────────

/**
 * Returns a user-scoped anon client that forwards the caller's Authorization
 * header so RLS policies evaluate correctly.
 */
export function getSupabaseClient(req: Request): SupabaseClient {
  const authHeader = req.headers.get("Authorization");
  return createClient(SUPABASE_URL(), SUPABASE_ANON_KEY(), {
    global: {
      headers: authHeader ? { Authorization: authHeader } : undefined,
    },
  });
}

/**
 * Returns a service-role admin client that bypasses RLS.
 * Use ONLY for trusted server-side operations (inserts, RPCs that need
 * elevated access). Never use for auth token validation.
 */
export function getSupabaseAdmin(): SupabaseClient {
  return createClient(SUPABASE_URL(), SUPABASE_SERVICE_KEY());
}

/**
 * Verifies the Bearer JWT from the request and returns the authenticated user.
 *
 * Always uses an anon client for `auth.getUser` — the service-role client
 * must never be used here because it bypasses JWT signature verification.
 *
 * Pass an existing anon `client` (from `getSupabaseClient`) to avoid a second
 * instantiation. When omitted, a fresh anon client is created internally.
 */
export async function verifyAuth(
  req: Request,
  client?: SupabaseClient
): Promise<any> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing Authorization header");
  }
  const jwt = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : authHeader;

  // Use a provided anon client or spin up a minimal one.
  // NOTE: Do NOT pass the admin client here — use getSupabaseClient(req) instead.
  const anonClient = client ?? createClient(SUPABASE_URL(), SUPABASE_ANON_KEY());

  const { data: { user }, error: authError } = await anonClient.auth.getUser(jwt);
  if (authError || !user) {
    throw new Error("Unauthorized: " + (authError?.message ?? "No user found"));
  }
  return user;
}
