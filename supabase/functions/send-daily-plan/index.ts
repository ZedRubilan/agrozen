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
  const fcmProjectId = Deno.env.get('FCM_PROJECT_ID');
  const fcmServiceAccountToken = Deno.env.get('FCM_SERVICE_ACCOUNT_TOKEN');
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

    // Compute today's date in Uzbekistan local time (Asia/Tashkent, UTC+5)
    const uzNow = new Date(Date.now() + 5 * 3600_000);
    const todayMidnight = new Date(
      Date.UTC(uzNow.getUTCFullYear(), uzNow.getUTCMonth(), uzNow.getUTCDate())
    );

    const results: SendNotificationResult[] = [];
    let sentCount = 0;

    for (const batch of batches) {
      try {
        const arrival = new Date(batch.arrival_date);
        const arrivalMidnight = new Date(
          Date.UTC(arrival.getUTCFullYear(), arrival.getUTCMonth(), arrival.getUTCDate())
        );

        // Calculate cycle day: (CURRENT_DATE_UZ - arrival_date) + 1
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

        // Idempotency check: prevent duplicate notification for same (batch_id, batch_day)
        const { data: existingLog, error: existingErr } = await supabase
          .from('notification_logs')
          .select('id')
          .eq('batch_id', batch.id)
          .eq('batch_day', batchDay)
          .limit(1)
          .maybeSingle();

        if (existingErr) {
          console.warn(
            `Error checking existing notification_logs for batch ${batch.id} day ${batchDay}:`,
            existingErr.message
          );
        } else if (existingLog) {
          results.push({
            batch_id: batch.id,
            farmer_id: batch.farmer_id,
            batch_day: batchDay,
            fcm_sent: false,
            status: 'skipped',
            message: `Notification already sent for batch ${batch.id} on day ${batchDay}.`,
          });
          continue;
        }

        // Retrieve today's tasks
        const dayPlan = BROILER_PLAN_DATA.find((p) => p.day === batchDay);
        const farmer: any = Array.isArray(batch.farmers)
          ? batch.farmers[0]
          : batch.farmers;
        const lang: 'uz' | 'ru' | 'en' =
          farmer?.language === 'ru'
            ? 'ru'
            : farmer?.language === 'en'
              ? 'en'
              : 'uz';

        const title =
          lang === 'en'
            ? `AgroZen: Day ${batchDay} — Today's Tasks`
            : lang === 'ru'
              ? `AgroZen: День ${batchDay} — Задачи на сегодня`
              : `AgroZen: ${batchDay}-kun — Bugungi reja`;

        const enTasksText = Array.isArray(dayPlan?.tasks_en)
          ? dayPlan.tasks_en.join(' ')
          : dayPlan?.tasks_en;

        const body =
          lang === 'en'
            ? (enTasksText ||
                'Check house temperature, ventilation, feed intake, and drinker lines.')
            : lang === 'ru'
              ? (dayPlan?.tasks_ru ??
                  'Проверьте температуру, вентиляцию, расход корма и поилки.')
              : (dayPlan?.tasks_uz ??
                  "Harorat, shamollatish, yem sarfi va suv ta'minotini tekshiring.");

        let fcmSent = false;

        // Dispatch FCM Push Notification if configured (prefer HTTP v1, fallback to legacy key)
        if (farmer?.fcm_token) {
          if (fcmProjectId && fcmServiceAccountToken) {
            try {
              const fcmV1Url = `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`;
              const fcmResponse = await fetch(fcmV1Url, {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                  Authorization: `Bearer ${fcmServiceAccountToken}`,
                },
                body: JSON.stringify({
                  message: {
                    token: farmer.fcm_token,
                    notification: {
                      title,
                      body,
                    },
                    data: {
                      type: 'daily_plan',
                      batch_id: String(batch.id),
                      batch_day: String(batchDay),
                      video_url: dayPlan?.video_url ?? '',
                    },
                  },
                }),
              });

              if (fcmResponse.ok) {
                fcmSent = true;
              } else {
                console.warn(
                  `FCM v1 dispatch failed for farmer ${batch.farmer_id}:`,
                  await fcmResponse.text()
                );
              }
            } catch (fcmErr) {
              console.error('FCM v1 dispatch error:', fcmErr);
            }
          } else if (fcmServerKey) {
            try {
              const fcmResponse = await fetch(
                'https://fcm.googleapis.com/fcm/send',
                {
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
                }
              );

              if (fcmResponse.ok) {
                fcmSent = true;
              } else {
                console.warn(
                  `FCM legacy dispatch failed for farmer ${batch.farmer_id}:`,
                  await fcmResponse.text()
                );
              }
            } catch (fcmErr) {
              console.error('FCM legacy dispatch error:', fcmErr);
            }
          }
        }

        // Record entry in notification_logs table
        let logSucceeded = false;
        try {
          const { error: logError } = await supabase
            .from('notification_logs')
            .insert({
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

          if (logError) {
            console.error('Failed to log notification in DB:', logError);
          } else {
            logSucceeded = true;
            sentCount++;
          }
        } catch (logErr) {
          console.error('Exception logging notification in DB:', logErr);
        }

        results.push({
          batch_id: batch.id,
          farmer_id: batch.farmer_id,
          batch_day: batchDay,
          fcm_sent: fcmSent,
          status: logSucceeded || fcmSent ? 'sent' : 'failed',
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
