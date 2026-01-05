import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Fetch pending notifications
    const { data: notifications, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('status', 'PENDING')
      .limit(50)

    if (error) throw error

    // Placeholder for FCM logic
    // In a real scenario, you'd call Firebase Admin SDK or a REST API
    for (const notification of notifications || []) {
      console.log(`Sending notification to user ${notification.user_id}: ${notification.title}`)
      
      await supabase
        .from('notifications')
        .update({ status: 'SENT', sent_at: new Date().toISOString() })
        .eq('id', notification.id)
    }

    return new Response(JSON.stringify({ 
      message: 'Notification processing completed', 
      processed: notifications?.length ?? 0 
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
