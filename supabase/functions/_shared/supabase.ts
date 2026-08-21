import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

export function getSupabaseClient(req: Request): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const authHeader = req.headers.get("Authorization");

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: authHeader ? { Authorization: authHeader } : undefined,
    },
  });
  return client;
}

export function getSupabaseAdmin(): SupabaseClient {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  return createClient(supabaseUrl, supabaseServiceRoleKey);
}

/**
 * Verifies the Bearer JWT from the request.
 *
 * Pass an existing `client` to avoid a redundant 3rd Supabase instantiation
 * (callers that already called getSupabaseClient / getSupabaseAdmin can reuse).
 * When `client` is omitted a temporary anon client is created internally.
 */
export async function verifyAuth(
  req: Request,
  client?: SupabaseClient
): Promise<any> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing Authorization header");
  }
  const jwt = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;

  // Reuse a provided client or create a minimal one for auth verification.
  const supabaseClient = client ?? (() => {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    return createClient(supabaseUrl, supabaseAnonKey);
  })();

  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(jwt);
  if (authError || !user) {
    throw new Error("Unauthorized: " + (authError?.message || "No user found"));
  }
  return user;
}
