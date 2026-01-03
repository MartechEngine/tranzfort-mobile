import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const configuredUrl = process.env.SUPABASE_URL;
const configuredKey = process.env.SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(configuredUrl && configuredKey);

if (!isSupabaseConfigured) {
  console.warn('Supabase URL or Key is missing. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in .env');
}

// NOTE: createClient throws if URL is empty. Use a placeholder when not configured.
const supabaseUrl = configuredUrl ?? 'http://localhost:54321';
const supabaseKey = configuredKey ?? 'anon';

export const supabase = createClient(supabaseUrl, supabaseKey);
