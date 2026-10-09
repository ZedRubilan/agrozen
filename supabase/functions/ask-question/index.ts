// supabase/functions/ask-question/index.ts
// AgroZen AI Assistant Edge Function
//
// Deployment instructions:
// 1. Ensure Supabase CLI is authenticated:
//    supabase login
// 2. Link your project:
//    supabase link --project-ref <your-project-ref>
// 3. Set secrets:
//    supabase secrets set GEMINI_API_KEY="your-gemini-api-key"
//    supabase secrets set GEMINI_MODEL="gemini-2.5-flash" # optional, defaults to gemini-2.5-flash
// 4. Deploy function:
//    supabase functions deploy ask-question --no-verify-jwt

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getSupabaseClient } from '../_shared/supabaseClient.ts';
import { retrieveRelevantKnowledge } from '../_shared/knowledge.ts';

interface AskQuestionRequest {
  question: string;
  language?: 'uz' | 'ru';
  farmer_id?: string;
  relevant_topic_contents?: string[];
  topic_names?: string[];
}

interface AskQuestionResponse {
  answer: string;
  sources_used: string[];
  remaining_questions: number;
}

const MAX_DAILY_QUESTIONS = 30;

serve(async (req: Request) => {
  // Handle CORS Preflight
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed. Use POST.' }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }

  try {
    const body: AskQuestionRequest = await req.json();
    const { question, language = 'uz', farmer_id } = body;

    // Validate inputs
    if (!question || typeof question !== 'string' || question.trim().length === 0) {
      return new Response(
        JSON.stringify({
          error:
            language === 'ru'
              ? 'Вопрос не может быть пустым'
              : 'Savol bo\'sh bo\'lishi mumkin emas',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const lang: 'uz' | 'ru' = language === 'ru' ? 'ru' : 'uz';
    const supabase = getSupabaseClient();
    const today = new Date().toISOString().split('T')[0];

    let remainingQuestions = MAX_DAILY_QUESTIONS;

    // Check & update daily question count if farmer_id is provided
    if (farmer_id) {
      const { data: farmer, error: farmerError } = await supabase
        .from('farmers')
        .select('id, daily_question_count, last_question_date')
        .eq('id', farmer_id)
        .maybeSingle();

      if (farmerError) {
        console.error('Error fetching farmer profile:', farmerError);
      } else if (farmer) {
        let currentCount = farmer.daily_question_count || 0;
        const lastDate = farmer.last_question_date;

        if (lastDate !== today) {
          currentCount = 0;
        }

        if (currentCount >= MAX_DAILY_QUESTIONS) {
          const limitMsg =
            lang === 'ru'
              ? 'Вы достигли дневного лимита вопросов (30 в день). Пожалуйста, вернитесь завтра или обратитесь напрямую к ветеринару.'
              : 'Siz kunlik savollar limitiga (30 ta) yetdingiz. Iltimos, ertaga davom eting yoki zudlik bilan veterinarga murojaat qiling.';

          return new Response(
            JSON.stringify({
              error: limitMsg,
              answer: limitMsg,
              sources_used: [],
              remaining_questions: 0,
            }),
            {
              status: 429,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        remainingQuestions = MAX_DAILY_QUESTIONS - (currentCount + 1);

        // Update farmer daily count
        await supabase
          .from('farmers')
          .update({
            daily_question_count: currentCount + 1,
            last_question_date: today,
            updated_at: new Date().toISOString(),
          })
          .eq('id', farmer_id);
      }
    }

    // 1. RAG Knowledge Retrieval
    const retrieved = retrieveRelevantKnowledge(question, lang, 3);
    const combinedTopics: string[] = Array.from(
      new Set([...(body.topic_names ?? []), ...retrieved.topics])
    );

    let ragContext = retrieved.contextText;
    if (
      body.relevant_topic_contents &&
      body.relevant_topic_contents.length > 0
    ) {
      ragContext =
        body.relevant_topic_contents.join('\n\n---\n\n') +
        '\n\n---\n\n' +
        ragContext;
    }

    // 2. Build Safe System Prompt
    const systemPromptUz = `Siz "AgroZen" loyihasining O'zbekistondagi broyler yetishtiruvchi fermerlar uchun AI yordamchisisiz.
QAT'IY QOIDALAR VA CHEKLOVLAR:
1. FAQAT va FAQAT quyida berilgan "Parrandachilik Yo'riqnomasi va Me'yorlari" bo'yicha javob bering.
2. TIBBIY VA VETERINARIYA CHEKLOVI: HECH QACHON dori vositalari, antibiotiklar yoki aniq dozalarni tayinlamang (masalan, "5 ml enrofloksatsin bering" deb yozish MUTLAQO TAQIQLANADI). Dori berishdan oldin doimo hududiy veterinarga murojaat qilishni tayinlang.
3. KASALLIK TASHXISI CHEKLOVI: Hech qachon qushlarga aniq tibbiy tashxis qo'ymang. Agar kasallik alomatlari so'ralsa, mikroiqlim (harorat, namlik, to'shama, shamollatish) va gigiyena bo'yicha maslahat bering hamda veterinarga zudlik bilan uchrashishni tavsiya qiling.
4. Agar berilgan yo'riqnomada javob bo'lmasa, uni to'qib chiqarmang. Ochiq tan oling va mutaxassis-veterinarga murojaat qilishni maslahat bering.
5. Javobni sodda, lo'nda, o'zbek tilida, hurmat bilan va amaliy tavsiyalar shaklida bering. Kerakli o'rinlarda Ross-308/Cobb-500 normativ ko'rsatkichlarini keltiring.`;

    const systemPromptRu = `Вы AI-помощник платформы "AgroZen" для фермеров-бройлероводов Узбекистана.
СТРОГИЕ ПРАВИЛА И ОГРАНИЧЕНИЯ:
1. Отвечайте ТОЛЬКО на основе приведенного ниже "Регламента и норм птицеводства".
2. ВЕТЕРИНАРНОЕ ОГРАНИЧЕНИЕ: СТРОГО ЗАПРЕЩЕНО назначать лекарственные препараты, антибиотики или указывать точные дозировки медикаментов. Всегда рекомендуйте консультацию с ветеринаром перед применением любых лекарств.
3. ОГРАНИЧЕНИЕ ПО ДИАГНОСТИКЕ: НИКОГДА не ставьте окончательные диагнозы заболеваний. При тревожных симптомах укажите на параметры содержания (температура, вентиляция, подстилка) и призовите незамедлительно вызвать ветеринара.
4. Если ответа нет в предоставленных данных регламента, не придумывайте. Честно укажите это и направьте к местному специалисту.
5. Давайте практичные, ясные, лаконичные ответы на русском языке с уважением к фермеру. При необходимости приводите технологические нормы Ross-308/Cobb-500.`;

    const systemInstruction = lang === 'ru' ? systemPromptRu : systemPromptUz;

    const userPrompt = `KONTEKST (Регламент и нормативы):
${ragContext}

---------------------------
SAVOL / ВОПРОС ФЕРМЕРА:
${question}

Javobingizni qat'iy yo'riqnomaga muvofiq, sodda va amaliy shaklda yozing.`;

    // 3. Call Google Gemini API
    const geminiApiKey =
      Deno.env.get('GEMINI_API_KEY') ??
      Deno.env.get('GOOGLE_AI_API_KEY') ??
      '';

    const preferredModel =
      Deno.env.get('GEMINI_MODEL') ?? 'gemini-2.5-flash';

    let generatedAnswer = '';

    if (geminiApiKey) {
      try {
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${preferredModel}:generateContent?key=${geminiApiKey}`;

        const geminiResponse = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            system_instruction: {
              parts: [{ text: systemInstruction }],
            },
            contents: [
              {
                role: 'user',
                parts: [{ text: userPrompt }],
              },
            ],
            generationConfig: {
              temperature: 0.2,
              maxOutputTokens: 1024,
            },
          }),
        });

        if (geminiResponse.ok) {
          const geminiData = await geminiResponse.json();
          const textCandidate =
            geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (textCandidate) {
            generatedAnswer = textCandidate.trim();
          }
        } else {
          // If gemini-2.5-flash returns 404/error, fallback to gemini-1.5-flash
          console.warn(
            `Gemini API returned status ${geminiResponse.status}. Attempting fallback to gemini-1.5-flash...`
          );
          const fallbackUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;
          const fallbackResponse = await fetch(fallbackUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              system_instruction: {
                parts: [{ text: systemInstruction }],
              },
              contents: [
                {
                  role: 'user',
                  parts: [{ text: userPrompt }],
                },
              ],
              generationConfig: {
                temperature: 0.2,
                maxOutputTokens: 1024,
              },
            }),
          });

          if (fallbackResponse.ok) {
            const fallbackData = await fallbackResponse.json();
            const textCandidate =
              fallbackData?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (textCandidate) {
              generatedAnswer = textCandidate.trim();
            }
          } else {
            const errBody = await fallbackResponse.text();
            console.error('Gemini fallback error:', errBody);
          }
        }
      } catch (geminiError) {
        console.error('Gemini fetch exception:', geminiError);
      }
    }

    // Graceful offline / template fallback if Gemini API is unavailable
    if (!generatedAnswer) {
      if (lang === 'ru') {
        generatedAnswer = `На основе регламента бройлеров AgroZen:\n\nПожалуйста, убедитесь в соблюдении параметров микроклимата и чистоты в птичнике. При первых признаках вялости или респираторных симптомах незамедлительно свяжитесь с ветеринарной службой вашего района. Самостоятельное применение антибиотиков без предписания ветеринара запрещено.`;
      } else {
        generatedAnswer = `AgroZen broyler reglamentiga muvofiq:\n\nIltimos, tovuqxonadagi harorat, namlik va tozalik ko'rsatkichlarini me'yorga keltiring. Kasallik alomatlari yoki jo'jalarning holsizlanishi kuzatilsa, zudlik bilan tumaningizdagi malakali veterinarga murojaat qiling. Mutaxassis ko'rigisiz o'zboshimchalik bilan dori va antibiotik qo'llash qat'iyan taqiqlanadi.`;
      }
    }

    // 4. Save interaction to question_logs table
    try {
      await supabase.from('question_logs').insert({
        farmer_id: farmer_id ?? null,
        question: question.trim(),
        answer: generatedAnswer,
        topics_used: combinedTopics,
        language: lang,
        source: 'text',
        created_at: new Date().toISOString(),
      });
    } catch (logErr) {
      console.error('Error saving to question_logs:', logErr);
    }

    // 5. Send Response
    const responsePayload: AskQuestionResponse = {
      answer: generatedAnswer,
      sources_used: combinedTopics,
      remaining_questions: remainingQuestions,
    };

    return new Response(JSON.stringify(responsePayload), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Unexpected error in ask-question function:', err);
    return new Response(
      JSON.stringify({
        error: 'Ichki server xatoligi yuz berdi. / Внутренняя ошибка сервера.',
        details: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
