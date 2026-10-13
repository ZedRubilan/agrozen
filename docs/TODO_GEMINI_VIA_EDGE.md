# TODO: stop shipping the Gemini key inside the app

Written 2026-10-13, when the repository was made public for the poster QR code.

## Problem

The release workflow builds the APK with `--dart-define=GEMINI_API_KEY=...`
(`.github/workflows/android-release.yml:59`). That bakes the key into the APK,
and anyone who downloads it can pull the key out. The key is currently on the
Gemini free tier (no billing), so the risk is quota abuse rather than cost.
If billing is ever enabled on that Google Cloud project, fix this first.

## Where the app calls Gemini directly

| File | What | Server route that already exists |
|---|---|---|
| `lib/data/providers/ai_provider.dart:142–191` | Chat answers (fallback after `ask-question`) | `ask-question` |
| `lib/services/poultry_vision_analyzer.dart:227` | Photo check | `ask-question` with `image_base64` (already the secondary engine) |
| `lib/services/voice_service.dart:345` | Speech-to-text fallback | `transcribe-voice` |
| `lib/services/tts_service.dart:232` | Read-aloud (`gemini-2.5-flash-preview-tts`) | **none yet**: add a `text-to-speech` Edge Function |

## Plan

1. Add a `text-to-speech` Supabase Edge Function that calls Gemini TTS with the
   server-side `GEMINI_API_KEY` secret (`supabase secrets set GEMINI_API_KEY=...`).
2. Point all four call sites at their Edge Function and delete the direct
   `generativelanguage.googleapis.com` calls. Keep the existing offline
   fallbacks (`LocalRag`, local photo inspector, device TTS).
3. Remove `GEMINI_API_KEY` from `SupabaseConfig` (`lib/config/supabase_config.dart`)
   and from the `--dart-define` list in the release workflow.
4. Rotate the Gemini key in Google AI Studio, because the old one is in every
   APK released so far (v1.0.3 and earlier).
5. Check: `flutter analyze`, `flutter test`, and confirm that
   `strings build/app/outputs/flutter-apk/app-release.apk | grep AIza` finds nothing.

Until then: in Google Cloud Console → Credentials, restrict the key to the
Generative Language API and set a daily request quota.
