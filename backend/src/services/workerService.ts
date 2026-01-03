import cron from 'node-cron';
import { supabase } from '../config/supabase.js';

/**
 * Background workers for automated system tasks.
 * Scheduled using node-cron.
 */

export const initWorkers = () => {
  // 1. Every hour: Mark loads as EXPIRED if loading_date + 24h has passed
  cron.schedule('0 * * * *', async () => {
    console.log('[Worker] Checking for expired loads...');
    try {
      const now = new Date();
      const cutoff = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
      
      const { data, error } = await supabase
        .from('loads')
        .update({ status: 'EXPIRED' })
        .lt('loading_date', cutoff)
        .eq('status', 'ACTIVE')
        .select();

      if (error) throw error;
      const count = data ? (data as any[]).length : 0;
      console.log(`[Worker] Expired loads updated: ${count}`);
    } catch (err) {
      console.error('[Worker] Error in load expiry worker:', err);
    }
  });

  // 2. Every midnight: Close chat threads older than 72 hours
  cron.schedule('0 0 * * *', async () => {
    console.log('[Worker] Cleaning up old chat threads...');
    try {
      const seventyTwoHoursAgo = new Date(Date.now() - 72 * 60 * 60 * 1000).toISOString();
      const { data, error } = await supabase
        .from('chats')
        .update({ status: 'EXPIRED' })
        .lt('created_at', seventyTwoHoursAgo)
        .eq('status', 'ACTIVE')
        .select();

      if (error) throw error;
      const count = data ? (data as any[]).length : 0;
      console.log(`[Worker] Old chats closed: ${count}`);
    } catch (err) {
      console.error('[Worker] Error in chat cleanup worker:', err);
    }
  });

  // 3. Every 30 seconds: Poll for pending notifications and "send" them via FCM
  cron.schedule('*/30 * * * * *', async () => {
    try {
      const { data: notifications, error } = await supabase
        .from('notifications')
        .select('*')
        .eq('fcm_status', 'PENDING')
        .limit(50);

      if (error) throw error;
      if (!notifications || notifications.length === 0) return;

      console.log(`[Worker] Processing ${notifications.length} pending notifications...`);

      for (const notification of notifications) {
        // Here you would integrate with firebase-admin SDK
        // try {
        //   await admin.messaging().send({ ... });
        //   await supabase.from('notifications').update({ fcm_status: 'SENT' }).eq('id', notification.id);
        // } catch (fcmErr) {
        //   await supabase.from('notifications').update({ fcm_status: 'FAILED' }).eq('id', notification.id);
        // }
        
        // Mock success for now
        await supabase
          .from('notifications')
          .update({ fcm_status: 'SENT' })
          .eq('id', notification.id);
      }
    } catch (err) {
      console.error('[Worker] Error in notification worker:', err);
    }
  });

  console.log('[Workers] All background workers initialized.');
};
