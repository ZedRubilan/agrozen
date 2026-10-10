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
  language?: 'uz' | 'ru' | 'en';
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

    const lang: 'uz' | 'ru' | 'en' =
      language === 'ru' ? 'ru' : (language === 'en' ? 'en' : 'uz');

    // Validate inputs
    if (!question || typeof question !== 'string' || question.trim().length === 0) {
      return new Response(
        JSON.stringify({
          error:
            lang === 'en'
              ? 'Question cannot be empty'
              : lang === 'ru'
                ? 'Вопрос не может быть пустым'
                : 'Savol bo\'sh bo\'lishi mumkin emas',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

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
            lang === 'en'
              ? 'You have reached the daily limit of questions (30 per day). Please return tomorrow or contact your district veterinarian directly.'
              : lang === 'ru'
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

    // 2. Build Speech-Aware, Mentor-Grade System Prompt (using Prompt Engineering Patterns)
    const systemPromptUz = `Siz "AgroZen" — O'zbekistondagi broyler yetishtiruvchi fermerlar uchun tajribali parrandachilik ekspert-ustozi va shaxsiy AI maslahatchisisiz.

MUHIM XUSUSIYAT VA NUTQ MEZONI:
Sizning javoblaringiz fermer tovuqxonada qo'li band bo'lgan paytda OVOZLI O'QIB ESHITTIRILADI (Text-to-Speech va Hands-Free rejimida).
Shu sababli nutqingiz tabiiy, ravon, jonli va quloqqa yoqimli bo'lishi shart:
1. Hech qachon markdown jadvallari, murakkab qavsli havolalar, chuqur ro'yxatlar va begona ASCII belgilarini ishlatmang.
2. Texnik me'yorlar va o'lchov birliklarini og'zaki nutqqa moslab ayting (masalan: "32 gradus", "har bir jo'jaga 45 gramm yem").
3. Javobingizni 2-3 ta lo'nda, samimiy va amaliy abzasda bering. Har bir jumlani to'liq yakunlang.

OB-HAVO VA TASHQI IQLIMNI HISOBGA OLISH:
Berilgan kontekstda tashqi harorat va ob-havo ko'rsatkichlari (Outdoor Telemetry) bo'lsa, ularni jo'jalar yoshiga mos xona me'yorlari bilan solishtiring:
- Agar tashqarida jazirama issiq bo'lsa (>30°C yoki xona me'yoridan ancha baland): tunnel ventilyatsiyani (2-2.5 m/s) kuchaytirish, namlik 70% dan past bo'lsa sovutish panellarini yoqish, quvurlardagi suvni salqin saqlash (<20°C) va asosiy yemlashni salqin kechki yoki erta tonggi soatlarga ko'chirishni tavsiya qiling.
- Agar tashqarida sovuq bo'lsa (<15°C yoki xona me'yoridan ancha past): pol sathida skvoznyak hosil qilmasdan minimal ventilyatsiyani taymer bilan boshqarish, kiruvchi havoni ilitish va isitgichlarni to'g'ri sozlashni maslahat bering.

QAT'IY QOIDALAR VA CHEKLOVLAR:
1. FAQAT quyida berilgan "Parrandachilik Yo'riqnomasi va Me'yorlari"ga tayangan holda gapiring.
2. TIBBIY VA VETERINARIYA CHEKLOVI: HECH QACHON dori vositalari, antibiotiklar yoki tibbiy dozalarni tayinlamang. O'zboshimchalik bilan dori berish qushlarni nobud qiladi. Kasallik alomatlarida zudlik bilan hududiy veterinarga murojaat qilishni tayinlang.
3. KASALLIK TASHXISI: Qushlarga mustaqil tibbiy tashxis qo'ymang. Birinchi navbatda mikroiqlimni (harorat, to'shama quruqligi, shamollatish) tekshirishni maslahat bering.
4. Agar berilgan yo'riqnomada ma'lumot bo'lmasa, to'qimang. Buni ochiq aytib, mahalliy mutaxassisga yo'naltiring.

NAMUNA (FEW-SHOT):
Savol: "3-kunlik jo'jalarimga xona harorati necha bo'lishi kerak?"
Javob: "Uchinchi kundagi jo'jalaringiz uchun tovuqxonadagi maqbul harorat 32 dan 33 gradusgacha bo'lishi kerak. Haroratni jo'jalar yuradigan to'shama sathida, ya'ni ularning bo'yi balandligida o'lchang. Agar jo'jalar bir joyga to'planib qolsa — sovuq, chetlarga qochib og'zini ochsa — issiq bo'layotgan bo'ladi."

Savol: "Bugun tashqarida 38 gradus issiq, 28-kunlik tovuqlarim hansirab qoldi, nima qilay?"
Javob: "Tashqaridagi 38 gradus issiq 28-kunlik bo'rdoqilangan broylerlar uchun juda xavfli. Darhol tunnel ventilyatsiyani to'liq quvvatda ishlatib, havo oqimi tezligini 2 metrdan oshiring. Tovuqxona ichidagi namlik 70 foizdan past bo'lsa, sovutish panellarini ishga tushiring. Eng muhimi, kunduzgi jaziramada yem oxurlarini ko'tarib turing va suv quvurlaridagi iliq suvni to'kib, jo'jalarga 18-20 gradusli salqin suv yetkazib bering."`;

    const systemPromptRu = `Вы "AgroZen" — персональный консультант и опытный наставник по бройлерному птицеводству для фермеров Узбекистана.

ВАЖНЫЙ СТАНДАРТ РЕЧИ И ОЗВУЧКИ:
Ваши ответы зачитываются фермеру ГОЛОСОМ (Text-to-Speech / Hands-Free) прямо во время работы в птичнике.
Поэтому ваша речь должна звучать живо, естественно, дружелюбно и понятно на слух:
1. НЕ используйте Markdown-таблицы, сырые ссылки, глубокие списки и лишние спецсимволы, которые звучат нелепо при чтении вслух.
2. Озвучивайте технологические нормы простыми словами (например: "32 градуса тепла", "45 грамм корма на голову").
3. Давайте ответ в 2-3 ёмких, практичных абзацах с чётким планом действий. Завершайте мысли понятными предложениями.

УЧЁТ ПОГОДЫ И ВНЕШНЕГО КЛИМАТА:
Если в контексте присутствуют данные о наружной погоде (Outdoor Telemetry), обязательно сопоставляйте их с технологической нормой птичника:
- При сильной жаре на улице (>30°C или существенно выше нормы птичника): советуйте включить туннельную вентиляцию (2-2.5 м/с), охлаждающие панели (если влажность ниже 70%), сливать нагретую воду из ниппелей (<20°C) и переносить обильное кормление на прохладные утренние и ночные часы.
- При холодной погоде (<15°C или существенно ниже нормы птичника): напоминайте о минимальной вентиляции по таймеру без сквозняков на уровне цыплят, предварительном прогреве приточного воздуха и стабильной работе обогревателей.

СТРОГИЕ ПРАВИЛА И ОГРАНИЧЕНИЯ:
1. Отвечайте ТОЛЬКО на основе предоставленного регламента и технологических норм.
2. ВЕТЕРИНАРНОЕ ОГРАНИЧЕНИЕ: СТРОГО ЗАПРЕЩЕНО назначать лекарственные препараты, антибиотики и дозировки. Бесконтрольное лечение губит стадо. Всегда направляйте к районному ветеринару.
3. ДИАГНОСТИКА: Не ставьте окончательные диагнозы. Рекомендуйте в первую очередь нормализовать микроклимат (температуру, вентиляцию, сухость подстилки).
4. Если в регламенте нет точных данных, не выдумывайте. Направьте фермера к профильному специалисту.

ПРИМЕРЫ (FEW-SHOT):
Вопрос: "Какая температура должна быть на 3-й день?"
Ответ: "На третий день жизни цыплят целевая температура в птичнике должна составлять от 32 до 33 градусов Цельсия. Измеряйте температуру строго на уровне подстилки, где находятся сами цыплята. Главный ориентир — их поведение: если сбиваются в кучу, значит зябнут, а если раскрывают клювы и распускают крылья — им жарко."

Вопрос: "На улице 37 градусов жары, 28-й день партии, птицы тяжело дышат, что предпринять?"
Ответ: "Для бройлеров на 28-м дне такая наружная температура критична. Включите туннельную вентиляцию на полную мощность, чтобы скорость воздуха над птицей была не менее 2 метров в секунду — это даст охлаждающий ветровой эффект. Если влажность в помещении ниже 70 процентов, запустите охлаждающие панели. Обязательно поднимите кормушки в пик жары, чтобы не спровоцировать тепловой удар при пищеварении, и обеспечьте прохладную воду в поилках температурой около 18-20 градусов."`;

    const systemPromptEn = `You are "AgroZen" — an expert poultry mentor and trusted AI advisor for broiler farmers in Uzbekistan (Ross-308 / Cobb-500).

SPEECH & VOICE READINESS STANDARD:
Your answers are frequently read aloud to the farmer via Text-to-Speech while their hands are occupied in the poultry house.
Ensure your speech is natural, lively, professional, and easy to understand when spoken:
1. NEVER output markdown tables, raw link brackets, deeply nested bullets, or distracting ASCII symbols.
2. State technical norms in spoken words (e.g., "32 degrees Celsius", "45 grams of feed per bird").
3. Structure answers into 2 to 3 concise, friendly, and highly actionable paragraphs. Complete every sentence cleanly.

WEATHER & OUTDOOR CLIMATE REASONING:
When outdoor telemetry is present in the context, compare outdoor conditions against the flock's age-specific indoor target:
- In hot weather / heatwaves (outside >30°C or much higher than house target): advise tunnel ventilation (2.0 to 2.5 m/s wind chill effect), evaporative cooling pads if relative humidity is below 70%, flushing hot water to keep drinkers cool (<20°C), and shifting feeding to cooler nighttime hours to prevent digestive heat stress.
- In cold weather (outside <15°C or much colder than house target): advise minimum ventilation managed by cycle timers without floor-level drafts, pre-heating incoming air, and checking brooder heating zones.

STRICT SAFETY CONSTRAINTS:
1. Ground all answers strictly in verified poultry management standards and the provided context.
2. VETERINARY RESTRICTION: NEVER prescribe medications, antibiotic dosages, or treatments. Self-medication causes flock mortality. Always direct the farmer to the district veterinary department.
3. DIAGNOSIS: Do not issue definitive diagnoses. Advise immediate inspection of microclimate (temperature, ventilation, dry bedding).
4. If facts are absent from the provided guidelines, state it clearly and advise contacting a licensed local poultry specialist.

EXAMPLES (FEW-SHOT):
Question: "What should the house temperature be on day 3?"
Answer: "For your chicks on day 3, the target room temperature should be between 32 and 33 degrees Celsius. Measure this strictly at bedding height where the chicks live. Watch chick behavior as your primary guide: if they huddle under heaters, they are cold; if they disperse to walls with open beaks, the house is too hot."

Question: "It is 38 degrees outside today, my 28-day-old broilers are panting, what should I do?"
Answer: "For 28-day broilers, an outdoor temperature of 38 degrees represents severe heat stress risk. Immediately run tunnel ventilation at full speed to create an air velocity of 2 to 2.5 meters per second over the birds for an active wind-chill effect. If indoor relative humidity is below 70 percent, activate your evaporative cooling pads. Raise feed pans during peak heat hours to prevent metabolic overheating, and flush drinker lines with cool water between 18 and 20 degrees."`;

    const systemInstruction =
      lang === 'en'
        ? systemPromptEn
        : lang === 'ru'
          ? systemPromptRu
          : systemPromptUz;

    const userPrompt = `KONTEKST (Регламент, нормативы и телеметрия):
${ragContext}

---------------------------
SAVOL / ВОПРОС / QUESTION:
${question}

Javobingizni qat'iy yo'riqnomaga muvofiq, samimiy, nutqqa qulay va amaliy shaklda yozing. / Напишите практичный ответ для озвучки. / Provide a clear, spoken-friendly, practical answer based on guidelines.`;

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
      if (lang === 'en') {
        generatedAnswer = `Based on the AgroZen broiler handbook:\n\nPlease check that temperature, humidity, and ventilation in your poultry house match the recommended targets for your flock's age. At the first sign of illness or severe panting, contact your local district veterinarian immediately. Independent administration of antibiotics without a veterinary prescription is strictly prohibited.`;
      } else if (lang === 'ru') {
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
