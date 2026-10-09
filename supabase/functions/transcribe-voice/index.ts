// supabase/functions/transcribe-voice/index.ts
// Voice-to-Text Transcription Edge Function for AgroZen
//
// Deployment instructions:
// 1. Ensure Supabase CLI is authenticated:
//    supabase login
// 2. Link your project:
//    supabase link --project-ref <your-project-ref>
// 3. Set secrets:
//    supabase secrets set GOOGLE_CLOUD_STT_KEY="your-google-stt-api-key"
//    # OR
//    supabase secrets set OPENAI_API_KEY="your-openai-api-key"
//    # OR
//    supabase secrets set GEMINI_API_KEY="your-gemini-api-key"
// 4. Deploy function:
//    supabase functions deploy transcribe-voice --no-verify-jwt

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

interface TranscribeResponse {
  transcribed_text: string;
  language: 'uz' | 'ru';
}

serve(async (req: Request) => {
  // Handle CORS
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
    let audioBytes: Uint8Array | null = null;
    let languageCode: 'uz' | 'ru' = 'uz';
    let mimeType = 'audio/m4a';
    let fileName = 'recording.m4a';

    const contentType = req.headers.get('content-type') || '';

    if (contentType.includes('multipart/form-data')) {
      const formData = await req.formData();
      const file = formData.get('audio') || formData.get('file');
      const langParam = formData.get('language');

      if (langParam === 'ru' || langParam === 'uz') {
        languageCode = langParam;
      }

      if (file && typeof file === 'object' && 'arrayBuffer' in file) {
        const fileObj = file as File;
        audioBytes = new Uint8Array(await fileObj.arrayBuffer());
        mimeType = fileObj.type || 'audio/m4a';
        fileName = fileObj.name || fileName;
      }
    } else if (contentType.includes('application/json')) {
      const json = await req.json();
      if (json.language === 'ru' || json.language === 'uz') {
        languageCode = json.language;
      }
      if (json.audio_base64) {
        const binaryString = atob(json.audio_base64);
        audioBytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          audioBytes[i] = binaryString.charCodeAt(i);
        }
        if (json.mime_type) mimeType = json.mime_type;
      }
    } else {
      // Direct raw binary stream
      audioBytes = new Uint8Array(await req.arrayBuffer());
      const queryLang = new URL(req.url).searchParams.get('language');
      if (queryLang === 'ru' || queryLang === 'uz') {
        languageCode = queryLang;
      }
    }

    if (!audioBytes || audioBytes.length === 0) {
      return new Response(
        JSON.stringify({
          error:
            languageCode === 'ru'
              ? 'Аудиофайл не передан или пуст'
              : 'Ovozli fayl topilmadi yoki bo\'sh',
        }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    let transcribedText = '';

    // -------------------------------------------------------------------------
    // 1. Provider: Google Cloud Speech-to-Text API
    // -------------------------------------------------------------------------
    const googleSttKey =
      Deno.env.get('GOOGLE_CLOUD_STT_KEY') ??
      Deno.env.get('GOOGLE_API_KEY');

    if (googleSttKey && !transcribedText) {
      try {
        let binary = '';
        for (let i = 0; i < audioBytes.byteLength; i++) {
          binary += String.fromCharCode(audioBytes[i]);
        }
        const base64Audio = btoa(binary);

        const sttUrl = `https://speech.googleapis.com/v1/speech:recognize?key=${googleSttKey}`;
        const sttPayload = {
          config: {
            encoding: 'ENCODING_UNSPECIFIED',
            languageCode: languageCode === 'uz' ? 'uz-UZ' : 'ru-RU',
            alternativeLanguageCodes: languageCode === 'uz' ? ['ru-RU'] : ['uz-UZ'],
            enableAutomaticPunctuation: true,
          },
          audio: {
            content: base64Audio,
          },
        };

        const gResponse = await fetch(sttUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(sttPayload),
        });

        if (gResponse.ok) {
          const gData = await gResponse.json();
          const results = gData?.results;
          if (Array.isArray(results) && results.length > 0) {
            transcribedText = results
              .map((r: any) => r.alternatives?.[0]?.transcript ?? '')
              .filter(Boolean)
              .join(' ')
              .trim();
          }
        } else {
          console.warn('Google STT error response:', await gResponse.text());
        }
      } catch (gErr) {
        console.error('Google STT exception:', gErr);
      }
    }

    // -------------------------------------------------------------------------
    // 2. Provider: OpenAI Whisper API
    // -------------------------------------------------------------------------
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY');
    if (openAiApiKey && !transcribedText) {
      try {
        const whisperFormData = new FormData();
        const blob = new Blob([audioBytes], { type: mimeType });
        whisperFormData.append('file', blob, fileName);
        whisperFormData.append('model', 'whisper-1');
        whisperFormData.append('language', languageCode);

        const whisperResponse = await fetch(
          'https://api.openai.com/v1/audio/transcriptions',
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${openAiApiKey}`,
            },
            body: whisperFormData,
          }
        );

        if (whisperResponse.ok) {
          const whisperData = await whisperResponse.json();
          if (whisperData.text) {
            transcribedText = whisperData.text.trim();
          }
        } else {
          console.warn('Whisper API error response:', await whisperResponse.text());
        }
      } catch (wErr) {
        console.error('Whisper API exception:', wErr);
      }
    }

    // -------------------------------------------------------------------------
    // 3. Provider: Google Gemini Multimodal Audio Recognition
    // -------------------------------------------------------------------------
    const geminiKey =
      Deno.env.get('GEMINI_API_KEY') ??
      Deno.env.get('GOOGLE_AI_API_KEY');

    if (geminiKey && !transcribedText) {
      try {
        let binary = '';
        for (let i = 0; i < audioBytes.byteLength; i++) {
          binary += String.fromCharCode(audioBytes[i]);
        }
        const base64Audio = btoa(binary);

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${geminiKey}`;
        const promptInstruction =
          languageCode === 'ru'
            ? 'Точно расшифруйте речь из аудиозаписи на русском языке. Верните только расшифрованный текст без лишних комментариев.'
            : 'Ovozli yozuvdagi nutqni o\'zbek tilida so\'zma-so\'z matnga aylantiring (transkripsiya qiling). Hech qanday qo\'shimcha izohlarsiz faqat nutq matnini qaytaring.';

        const geminiAudioResponse = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [
              {
                role: 'user',
                parts: [
                  { text: promptInstruction },
                  {
                    inline_data: {
                      mime_type: mimeType,
                      data: base64Audio,
                    },
                  },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.1,
            },
          }),
        });

        if (geminiAudioResponse.ok) {
          const gemData = await geminiAudioResponse.json();
          const textCandidate =
            gemData?.candidates?.[0]?.content?.parts?.[0]?.text;
          if (textCandidate) {
            transcribedText = textCandidate.trim();
          }
        } else {
          // Fallback to gemini-1.5-flash if 2.5 returns error
          const fallbackUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiKey}`;
          const fallbackResp = await fetch(fallbackUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              contents: [
                {
                  role: 'user',
                  parts: [
                    { text: promptInstruction },
                    {
                      inline_data: {
                        mime_type: mimeType,
                        data: base64Audio,
                      },
                    },
                  ],
                },
              ],
              generationConfig: {
                temperature: 0.1,
              },
            }),
          });

          if (fallbackResp.ok) {
            const fallbackData = await fallbackResp.json();
            const text = fallbackData?.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) transcribedText = text.trim();
          }
        }
      } catch (gemErr) {
        console.error('Gemini Audio STT exception:', gemErr);
      }
    }

    // Default fallback if no STT key is configured or recognition was empty
    if (!transcribedText) {
      if (
        !googleSttKey &&
        !openAiApiKey &&
        !geminiKey
      ) {
        return new Response(
          JSON.stringify({
            error:
              'STT provider is not configured. Please set GOOGLE_CLOUD_STT_KEY, OPENAI_API_KEY, or GEMINI_API_KEY in Supabase secrets.',
            transcribed_text: '',
            language: languageCode,
          }),
          {
            status: 503,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }

      transcribedText =
        languageCode === 'ru'
          ? 'Не удалось распознать речь в аудиофайле.'
          : 'Ovozli xabardagi nutqni aniqlab bo\'lmadi.';
    }

    const responsePayload: TranscribeResponse = {
      transcribed_text: transcribedText,
      language: languageCode,
    };

    return new Response(JSON.stringify(responsePayload), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Unexpected error in transcribe-voice function:', err);
    return new Response(
      JSON.stringify({
        error: 'Transkripsiya xatoligi. / Ошибка транскрипции.',
        details: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
