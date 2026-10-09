// supabase/functions/_shared/supabaseClient.ts
// Supabase client helper for Edge Functions

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

export function getSupabaseClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const supabaseServiceKey =
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ??
    Deno.env.get('SUPABASE_ANON_KEY') ??
    '';

  if (!supabaseUrl || !supabaseServiceKey) {
    console.warn('Warning: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not defined in environment.');
  }

  return createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}
