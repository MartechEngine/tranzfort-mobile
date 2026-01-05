import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 1. Expire Loads (loading_date + 24h)
    const { data: expiredLoads, error: loadError } = await supabase
      .from('loads')
      .update({ status: 'EXPIRED' })
      .lt('loading_date', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
      .eq('status', 'ACTIVE')
      .select()

    if (loadError) throw loadError

    // 2. Expire Chats (72h of inactivity)
    const { data: expiredChats, error: chatError } = await supabase
      .from('chats')
      .update({ status: 'EXPIRED' })
      .lt('updated_at', new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString())
      .eq('status', 'ACTIVE')
      .select()

    if (chatError) throw chatError

    return new Response(JSON.stringify({ 
      message: 'Expiry process completed', 
      expiredLoads: expiredLoads?.length ?? 0,
      expiredChats: expiredChats?.length ?? 0
    }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    })
  }
})
