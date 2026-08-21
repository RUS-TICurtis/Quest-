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

export async function verifyAuth(req: Request): Promise<any> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing Authorization header");
  }
  const jwt = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : authHeader;
  
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const supabaseClient = createClient(supabaseUrl, supabaseAnonKey);

  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(jwt);
  if (authError || !user) {
    throw new Error("Unauthorized: " + (authError?.message || "No user found"));
  }
  return user;
}
