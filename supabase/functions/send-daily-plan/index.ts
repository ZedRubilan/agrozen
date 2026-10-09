// supabase/functions/send-daily-plan/index.ts
// AgroZen Daily Morning Plan Dispatcher
//
// Deployment & pg_cron instructions:
// 1. Deploy function:
//    supabase functions deploy send-daily-plan --no-verify-jwt
//
// 2. Set optional FCM secret for push notifications:
//    supabase secrets set FCM_SERVER_KEY="your-fcm-server-key"
//
// 3. Schedule via pg_cron in Supabase Dashboard SQL Editor (07:00 Tashkent time = 02:00 UTC):
//    CREATE EXTENSION IF NOT EXISTS pg_cron;
//    CREATE EXTENSION IF NOT EXISTS pg_net;
//
//    SELECT cron.schedule(
//      'send-daily-plan-morning-job',
//      '0 2 * * *', -- Every day at 02:00 UTC (07:00 Tashkent time UTC+5)
//      $$
//      SELECT net.http_post(
//        url := 'https://<your-project-ref>.supabase.co/functions/v1/send-daily-plan',
//        headers := jsonb_build_object(
//          'Content-Type', 'application/json',
//          'Authorization', 'Bearer <SUPABASE_SERVICE_ROLE_KEY>'
//        ),
//        body := '{}'::jsonb
//      ) as request_id;
//      $$
//    );

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getSupabaseClient } from '../_shared/supabaseClient.ts';
import { BROILER_PLAN_DATA } from '../_shared/knowledge.ts';

interface SendNotificationResult {
  batch_id: string;
  farmer_id: string;
  batch_day: number;
  fcm_sent: boolean;
  status: 'sent' | 'skipped' | 'failed';
  message?: string;
}

serve(async (req: Request) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST' && req.method !== 'GET') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed. Use POST or GET.' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  const startTime = Date.now();
  const supabase = getSupabaseClient();
  const fcmServerKey = Deno.env.get('FCM_SERVER_KEY');

  try {
    // 1. Fetch all active batches and associated farmer details
    const { data: batches, error: batchError } = await supabase
      .from('batches')
      .select(`
        id,
        farmer_id,
        arrival_date,
        initial_count,
        current_count,
        status,
        farmers (
          id,
          name,
          phone,
          language,
          district,
          fcm_token
        )
      `)
      .eq('status', 'active');

    if (batchError) {
      console.error('Failed to query active batches:', batchError);
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch active batches',
          details: batchError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (!batches || batches.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No active batches found.',
          processed_batches: 0,
          notifications_sent: 0,
          results: [],
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const today = new Date();
    // Normalize to midnight UTC
    const todayMidnight = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()));

    const results: SendNotificationResult[] = [];
    let sentCount = 0;

    for (const batch of batches) {
      try {
        const arrival = new Date(batch.arrival_date);
        const arrivalMidnight = new Date(Date.UTC(arrival.getUTCFullYear(), arrival.getUTCMonth(), arrival.getUTCDate()));

        // Calculate cycle day: (CURRENT_DATE - arrival_date) + 1
        const diffMs = todayMidnight.getTime() - arrivalMidnight.getTime();
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
        const batchDay = diffDays + 1;

        // Skip if outside 1-42 day range
        if (batchDay < 1 || batchDay > 42) {
          results.push({
            batch_id: batch.id,
            farmer_id: batch.farmer_id,
            batch_day: batchDay,
            fcm_sent: false,
            status: 'skipped',
            message: `Batch day ${batchDay} is out of standard 1-42 range.`,
          });
          continue;
        }

        // Retrieve today's tasks
        const dayPlan = BROILER_PLAN_DATA.find((p) => p.day === batchDay);
        const farmer: any = Array.isArray(batch.farmers) ? batch.farmers[0] : batch.farmers;
        const isRu = farmer?.language === 'ru';

        const title = isRu
          ? `AgroZen: День ${batchDay} — Задачи на сегодня`
          : `AgroZen: ${batchDay}-kun — Bugungi reja`;

        const body = isRu
          ? (dayPlan?.tasks_ru ?? 'Проверьте температуру, вентиляцию, расход корма и поилки.')
          : (dayPlan?.tasks_uz ?? 'Harorat, shamollatish, yem sarfi va suv ta\'minotini tekshiring.');

        let fcmSent = false;

        // Dispatch FCM Push Notification if configured
        if (fcmServerKey && farmer?.fcm_token) {
          try {
            const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                Authorization: `key=${fcmServerKey}`,
              },
              body: JSON.stringify({
                to: farmer.fcm_token,
                notification: {
                  title,
                  body,
                  sound: 'default',
                },
                data: {
                  type: 'daily_plan',
                  batch_id: batch.id,
                  batch_day: String(batchDay),
                  video_url: dayPlan?.video_url ?? '',
                },
              }),
            });

            if (fcmResponse.ok) {
              fcmSent = true;
            } else {
              console.warn(
                `FCM dispatch failed for farmer ${batch.farmer_id}:`,
                await fcmResponse.text()
              );
            }
          } catch (fcmErr) {
            console.error('FCM dispatch error:', fcmErr);
          }
        }

        // Record entry in notification_logs table
        try {
          await supabase.from('notification_logs').insert({
            farmer_id: batch.farmer_id,
            batch_id: batch.id,
            batch_day: batchDay,
            title,
            body,
            status: 'sent',
            metadata: {
              video_url: dayPlan?.video_url ?? null,
              fcm_sent: fcmSent,
              has_fcm_token: Boolean(farmer?.fcm_token),
            },
            sent_at: new Date().toISOString(),
          });
          sentCount++;
        } catch (logErr) {
          console.error('Failed to log notification in DB:', logErr);
        }

        results.push({
          batch_id: batch.id,
          farmer_id: batch.farmer_id,
          batch_day: batchDay,
          fcm_sent: fcmSent,
          status: 'sent',
        });
      } catch (itemErr) {
        console.error(`Error processing batch ${batch.id}:`, itemErr);
        results.push({
          batch_id: batch.id,
          farmer_id: batch.farmer_id,
          batch_day: 0,
          fcm_sent: false,
          status: 'failed',
          message: itemErr instanceof Error ? itemErr.message : String(itemErr),
        });
      }
    }

    const durationMs = Date.now() - startTime;

    return new Response(
      JSON.stringify({
        success: true,
        processed_batches: batches.length,
        notifications_sent: sentCount,
        duration_ms: durationMs,
        results,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  } catch (err) {
    console.error('Unhandled error in send-daily-plan:', err);
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Unhandled server error during daily plan broadcast',
        details: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
