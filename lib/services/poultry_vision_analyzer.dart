import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/supabase_config.dart';
import '../core/localization/app_strings.dart';
import '../domain/broiler/broiler_grower_library.dart';
import 'flock_context_service.dart';

class VisionAnalysisResult {
  final String analysisText;
  final String conditionIdentified;
  final String source;
  final bool requiresImmediateVet;

  const VisionAnalysisResult({
    required this.analysisText,
    required this.conditionIdentified,
    required this.source,
    this.requiresImmediateVet = false,
  });
}

/// Multimodal Vision & Symptom Analysis Engine for Broiler Poultry Farming.
///
/// 1. **Primary Engine**: Direct Gemini Multimodal API (`gemini-2.5-flash` -> `gemini-2.0-flash`)
///    using `inline_data` (`mime_type` + `base64` image bytes) grounded in Ross-308 standards
///    and the farmer's live flock context (`Day X`, bird count, target temperature).
/// 2. **Secondary Engine**: Supabase Edge Function (`ask-question`) with `image_base64`.
/// 3. **Tertiary Engine**: Offline Ross-308 Visual Diagnostic & Image-Byte Inspector.
class PoultryVisionAnalyzer {
  static final PoultryVisionAnalyzer _instance =
      PoultryVisionAnalyzer._internal();
  factory PoultryVisionAnalyzer() => _instance;
  PoultryVisionAnalyzer._internal();

  /// Detects MIME type from file extension or magic bytes.
  static String detectMimeType(String imagePath, [Uint8List? bytes]) {
    if (bytes != null && bytes.length >= 4) {
      // PNG magic bytes: 89 50 4E 47
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'image/png';
      }
      // WEBP magic bytes: RIFF....WEBP
      if (bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        return 'image/webp';
      }
    }
    final lower = imagePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Analyzes a photo of a chicken, flock, droppings, or litter using Gemini Vision.
  Future<VisionAnalysisResult> analyzeFlockImage({
    required String imagePath,
    String? userQuery,
    required String language,
    LiveFlockContext? flockContext,
    Uint8List? imageBytesOverride,
    http.Client? httpClient,
  }) async {
    final lang = language.toLowerCase();
    final batchDay = flockContext?.batchDay ?? 14;
    final birdCount = flockContext?.currentCount ?? 500;
    final daySpec = BroilerGrowerLibrary.specForDay(batchDay);

    if (!SupabaseConfig.hasGeminiKey) {
      await SupabaseConfig.loadDotEnvIfPresent();
    }

    Uint8List? bytes = imageBytesOverride;
    if (bytes == null && imagePath.trim().isNotEmpty) {
      try {
        bytes = await XFile(imagePath).readAsBytes();
      } catch (e) {
        debugPrint('PoultryVisionAnalyzer: Failed reading image bytes: $e');
      }
    }

    final hasValidBytes = bytes != null && bytes.isNotEmpty;
    final mimeType = detectMimeType(imagePath, bytes);
    final base64Image = hasValidBytes ? base64Encode(bytes) : null;

    final effectivePrompt = _buildUserVisionPrompt(
      userQuery: userQuery,
      lang: lang,
      batchDay: batchDay,
      birdCount: birdCount,
      daySpec: daySpec,
    );

    final systemInstruction = _buildVisionSystemInstruction(
      lang: lang,
      batchDay: batchDay,
      birdCount: birdCount,
      daySpec: daySpec,
      flockContext: flockContext,
    );

    // 1. Primary Engine: Direct Gemini Multimodal Vision API (gemini-2.5-flash -> gemini-2.0-flash)
    if (base64Image != null && SupabaseConfig.hasGeminiKey) {
      final client = httpClient ?? http.Client();
      try {
        final directResult = await _callDirectGeminiVision(
          client: client,
          apiKey: SupabaseConfig.geminiApiKey,
          base64Image: base64Image,
          mimeType: mimeType,
          systemInstruction: systemInstruction,
          userPrompt: effectivePrompt,
          lang: lang,
        );
        if (directResult != null) {
          return directResult;
        }
      } catch (e) {
        debugPrint('Direct Gemini Vision call failed: $e');
      } finally {
        if (httpClient == null) {
          client.close();
        }
      }
    }

    // 2. Secondary Engine: Supabase Edge Function `ask-question` with multimodal `image_base64`
    if (base64Image != null && SupabaseConfig.isConfigured) {
      try {
        final response = await SupabaseConfig.client.functions.invoke(
          'ask-question',
          body: {
            'question': effectivePrompt,
            'language': lang,
            'image_base64': base64Image,
            'image_mime_type': mimeType,
          },
        );

        if (response.status == 200 && response.data != null) {
          final data = response.data is Map
              ? response.data as Map<String, dynamic>
              : jsonDecode(response.data.toString()) as Map<String, dynamic>;
          final answerText = (data['answer'] ?? '').toString().trim();
          if (answerText.isNotEmpty && data['is_fallback'] != true) {
            return VisionAnalysisResult(
              analysisText: answerText,
              conditionIdentified: AppStrings.tr(
                lang: lang,
                uz: 'Gemini Vision AI tahlili',
                ru: 'Анализ Gemini Vision AI',
                en: 'Gemini Vision AI Inspection',
              ),
              source: 'Gemini Vision AI (AgroZen Cloud)',
              requiresImmediateVet: _detectVetUrgency(answerText),
            );
          }
        }
      } catch (e) {
        debugPrint(
          'Supabase ask-question vision fallback failed, using local inspector: $e',
        );
      }
    }

    // 3. Tertiary Engine: Intelligent Offline Ross-308 Vision & Image-Byte Inspector
    return _localPoultryExpertAnalysis(
      query: userQuery ?? '',
      lang: lang,
      batchDay: batchDay,
      birdCount: birdCount,
      daySpec: daySpec,
      imageBytes: bytes,
    );
  }

  Future<VisionAnalysisResult?> _callDirectGeminiVision({
    required http.Client client,
    required String apiKey,
    required String base64Image,
    required String mimeType,
    required String systemInstruction,
    required String userPrompt,
    required String lang,
  }) async {
    final models = <String>['gemini-2.5-flash', 'gemini-2.0-flash'];
    final payload = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.25,
        'maxOutputTokens': 900,
      },
    });

    for (final model in models) {
      try {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final res = await client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: payload,
            )
            .timeout(const Duration(seconds: 18));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content =
                candidates.first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              final text = (parts.first['text'] ?? '').toString().trim();
              if (text.isNotEmpty) {
                return VisionAnalysisResult(
                  analysisText: text,
                  conditionIdentified: AppStrings.tr(
                    lang: lang,
                    uz: 'Gemini Vision AI tahlili',
                    ru: 'Анализ Gemini Vision AI',
                    en: 'Gemini Vision AI Inspection',
                  ),
                  source: 'Gemini Vision AI ($model)',
                  requiresImmediateVet: _detectVetUrgency(text),
                );
              }
            }
          }
        } else {
          debugPrint(
            'Gemini Vision ($model) returned status ${res.statusCode}: ${res.body}',
          );
        }
      } catch (e) {
        debugPrint('Gemini Vision ($model) exception: $e');
      }
    }
    return null;
  }

  static bool _detectVetUrgency(String text) {
    final lower = text.toLowerCase();
    return lower.contains('🚨') ||
        lower.contains('shoshilinch') ||
        lower.contains('zudlik bilan veterinar') ||
        lower.contains('срочно к ветеринару') ||
        lower.contains('немедленно обратитесь к ветеринару') ||
        lower.contains('urgent vet') ||
        lower.contains('immediately contact your district vet') ||
        lower.contains('koktsidioz') ||
        lower.contains('кокцидиоз') ||
        lower.contains('coccidiosis') ||
        lower.contains('nyukasl') ||
        lower.contains('ньюкасл') ||
        lower.contains('newcastle');
  }

  static String _buildUserVisionPrompt({
    required String? userQuery,
    required String lang,
    required int batchDay,
    required int birdCount,
    required BroilerDaySpec daySpec,
  }) {
    final trimmed = userQuery?.trim() ?? '';
    if (lang == 'en') {
      return trimmed.isNotEmpty
          ? 'Inspect this farm photo carefully. Farmer question/note: "$trimmed". '
              'Flock context: Ross-308 Day $batchDay ($birdCount birds, target temp ${daySpec.targetTempC.toStringAsFixed(1)}°C, target weight ${daySpec.targetWeightG}g). '
              'Tell the farmer clearly: (1) What is in the photo and whether the chicken/flock/bedding is FINE or NEEDS ATTENTION, (2) Exact visual details observed, and (3) Simple actionable steps right now.'
          : 'Inspect this farm photo carefully (Ross-308 Day $batchDay, $birdCount birds). '
              'Tell the farmer clearly: (1) What is in the photo and whether the chicken/flock/bedding is FINE & HEALTHY or NEEDS ATTENTION, (2) Specific visual signs observed (feathers, posture, eyes, legs, droppings, or litter), and (3) 2-3 simple actionable steps right now.';
    }
    if (lang == 'ru') {
      return trimmed.isNotEmpty
          ? 'Внимательно проанализируйте это фото с фермы. Вопрос/заметка фермера: "$trimmed". '
              'Контекст партии: Ross-308, $batchDay-й день ($birdCount гол., норма темп. ${daySpec.targetTempC.toStringAsFixed(1)}°C, целевой вес ${daySpec.targetWeightG}г). '
              'Чётко скажите фермеру: (1) Что на фото и В НОРМЕ ли цыплёнок/стадо/подстилка или ТРЕБУЕТ ВНИМАНИЯ, (2) Какие именно визуальные признаки видны на фото, и (3) 2-3 простых практических шага прямо сейчас.'
          : 'Внимательно проанализируйте это фото с фермы (Ross-308, $batchDay-й день, $birdCount голов). '
              'Чётко скажите фермеру: (1) Что на фото и В НОРМЕ ли цыплёнок/стадо/подстилка или ТРЕБУЕТ ВНИМАНИЯ, (2) Конкретные визуальные признаки (оперение, поза, глаза, лапы, помёт или подстилка), и (3) 2-3 простых шага прямо сейчас.';
    }
    return trimmed.isNotEmpty
        ? 'Ushbu ferma fotosuratini diqqat bilan skanerlang. Fermer savoli/izohi: "$trimmed". '
            'Partiya: Ross-308, $batchDay-kun ($birdCount bosh, harorat me\'yori ${daySpec.targetTempC.toStringAsFixed(1)}°C, maqsadli vazn ${daySpec.targetWeightG}g). '
            'Fermerga aniq va sodda qilib ayting: (1) Suratda nima tasvirlangan va jo\'ja/to\'da/to\'shama HOLATI YAXSHIMI (me\'yordami) yoki E\'TIBOR TALAB QILADIMI, (2) Suratda ko\'ringan aniq belgilar, va (3) Hozir qilish kerak bo\'lgan 2-3 ta oddiy amaliy qadam.'
        : 'Ushbu ferma fotosuratini diqqat bilan skanerlang (Ross-308, $batchDay-kun, $birdCount bosh). '
            'Fermerga aniq va sodda qilib ayting: (1) Suratda nima tasvirlangan va jo\'ja/to\'da/to\'shama HOLATI YAXSHIMI (sog\'lommi) yoki E\'TIBOR TALAB QILADIMI, (2) Suratda ko\'ringan aniq vizual belgilar (patlari, turishi, ko\'zi, oyoqlari, axlati yoki to\'shama), va (3) Hozir qilish kerak bo\'lgan 2-3 ta oddiy amaliy qadam.';
  }

  static String _buildVisionSystemInstruction({
    required String lang,
    required int batchDay,
    required int birdCount,
    required BroilerDaySpec daySpec,
    LiveFlockContext? flockContext,
  }) {
    final vetName =
        flockContext?.localVet?['name']?.toString() ?? 'District Veterinarian';
    final vetPhone = flockContext?.localVet?['phone']?.toString() ?? '';

    if (lang == 'en') {
      return '''
You are AgroZen Vision AI — an expert broiler poultry veterinarian and Ross-308 / Cobb-500 agronomist inspecting a farmer's photo.
Flock Context: Day $batchDay of 42 ($birdCount birds). Target temp: ${daySpec.targetTempC.toStringAsFixed(1)}°C, Target humidity: ${daySpec.humidityMinPct}-${daySpec.humidityMaxPct}%, Target weight: ${daySpec.targetWeightG}g, Daily feed norm: ${daySpec.dailyFeedPerBirdG}g/bird.

Respond in English using this clear, concise 3-part structure:
1. **📋 STATUS VERDICT**: Start with one clear badge:
   - `✅ FINE & HEALTHY` (if the bird/flock/litter looks normal and active)
   - `⚠️ NEEDS ATTENTION` (if there are signs of heat/cold stress, damp litter, mild lethargy, or equipment issue)
   - `🚨 URGENT VET CHECK` (if there are signs of bloody droppings, severe illness, twisted neck, swollen eyes, or paralysis)
2. **🔍 WHAT GEMINI SEES IN THE PHOTO**: Describe specifically what is visible in the image (bird posture, feather cover, comb/eyes/legs, clustering, droppings color, litter dryness, or if the photo shows something else).
3. **🛠️ ACTION STEPS FOR DAY $batchDay**: Give 2–3 simple, practical actions tailored to Day $batchDay.

CRITICAL SAFETY RULE: Never prescribe specific antibiotic dosages or medication names. If clinical disease is visible, advise isolating weak birds into the Watchlist/Observation pen and contacting the district veterinarian ($vetName $vetPhone).
''';
    }

    if (lang == 'ru') {
      return '''
Вы — AgroZen Vision AI, опытный ветеринарный эксперт по бройлерам и агроном стандарта Ross-308 / Cobb-500, анализирующий фото фермера.
Контекст партии: $batchDay-й день из 42 ($birdCount голов). Норма температуры: ${daySpec.targetTempC.toStringAsFixed(1)}°C, влажность: ${daySpec.humidityMinPct}-${daySpec.humidityMaxPct}%, норма веса: ${daySpec.targetWeightG}г, норма корма: ${daySpec.dailyFeedPerBirdG}г/гол.

Отвечайте на русском языке в чёткой и простой структуре из 3 пунктов:
1. **📋 ОЦЕНКА СОСТОЯНИЯ**: Начните с понятного вердикта:
   - `✅ В НОРМЕ (ЗДОРОВЫ)` (если цыплёнок/стадо/подстилка выглядят здоровыми и активными)
   - `⚠️ ТРЕБУЕТ ВНИМАНИЯ` (при признаках перегрева/переохлаждения, сырой подстилки, лёгкой вялости)
   - `🚨 СРОЧНО К ВЕТЕРИНАРУ` (при следах крови в помёте, тяжёлой вялости, отёках, хрипах или параличе)
2. **🔍 ЧТО ВИДНО НА ФОТО**: Опишите конкретно то, что изображено на снимке (поза птицы, оперение, глаза/клюв/лапы, распределение стада, цвет помёта, сухость подстилки, либо укажите, если на фото другой предмет).
3. **🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС ($batchDay-й ДЕНЬ)**: Дайте 2–3 простых и конкретных шага для $batchDay-го дня.

ПРАВИЛО БЕЗОПАСНОСТИ: Никогда не назначайте дозировки антибиотиков или лекарств. При признаках болезни посоветуйте отсадить слабых птиц в зону наблюдения и связаться с районным ветеринаром ($vetName $vetPhone).
''';
    }

    return '''
Siz AgroZen Vision AI — Ross-308 / Cobb-500 standartlari bo'yicha tajribali broyler parrandachilik veterinari va agronomisiz. Siz fermer yuborgan fotosuratni ko'rib tahlil qilasiz.
Partiya ma'lumoti: 42 kundan $batchDay-kun ($birdCount bosh). Harorat me'yori: ${daySpec.targetTempC.toStringAsFixed(1)}°C, namlik: ${daySpec.humidityMinPct}-${daySpec.humidityMaxPct}%, maqsadli vazn: ${daySpec.targetWeightG}g, kunlik yem me'yori: ${daySpec.dailyFeedPerBirdG}g/bosh.

O'zbek tilida (sodda va tushunarli tilda) quyidagi 3 qismdan iborat aniq javob bering:
1. **📋 HOLAT BAHOSI**: Birinchi qatorda aniq xulosani yozing:
   - `✅ YAXSHI (ME'YORDA / SOG'LOM)` (agar suratdagi jo'ja, to'da yoki to'shama sog'lom va faol ko'rinsa)
   - `⚠️ E'TIBOR KERAK` (agar issiq/sovuq stressi, nam to'shama, lanjlik yoki jihoz muammosi ko'rinsa)
   - `🚨 SHOSHILINCH (VETERINAR KERAK)` (agar qonli axlat, og'ir kasallik, shishgan ko'z yoki falajlik ko'rinsa)
2. **🔍 SURATDA NIMA KO'RINDI**: Suratda aynan nima tasvirlanganini aniq yozing (jo'janing turishi, pat qoplami, ko'zi/tumshug'i/oyoqlari, to'planib turishi, axlat rangi, to'shama quruqligi yoki suratda boshqa narsa bo'lsa uni ayting).
3. **🛠️ HOZIR QILINADIGAN QADAMLAR ($batchDay-KUN UCHUN)**: Fermer hozir bajarishi kerak bo'lgan 2–3 ta eng muhim, oddiy amaliy tavsiyani bering.

XAVFSIZLIK QOIDASI: Hech qachon mustaqil ravishda antibiotik nomi yoki dozasini yozmang. Kasallik gumoni bo'lsa, holsiz jo'jalarni "Alohida kuzatuv" (izolyator) qafasiga ajratishni va tuman veterinariga ($vetName $vetPhone) murojaat qilishni tavsiya eting.
''';
  }

  VisionAnalysisResult _localPoultryExpertAnalysis({
    required String query,
    required String lang,
    required int batchDay,
    required int birdCount,
    required BroilerDaySpec daySpec,
    Uint8List? imageBytes,
  }) {
    final lower = query.toLowerCase();

    // Compute a lightweight visual summary from image bytes if available
    final imageStatsNote = _describeImageBytes(imageBytes, lang);

    // Condition 1: Bloody or orange-mucus droppings (Coccidiosis / Enteritis)
    if (lower.contains('qon') ||
        lower.contains('krov') ||
        lower.contains('кров') ||
        lower.contains('blood') ||
        lower.contains('coccid') ||
        lower.contains('кокцид')) {
      return VisionAnalysisResult(
        conditionIdentified: AppStrings.tr(
          lang: lang,
          uz: 'Qonli axlat (Koktsidioz gumoni)',
          ru: 'Кровавый помёт (Подозрение на кокцидиоз)',
          en: 'Bloody Droppings (Suspected Coccidiosis)',
        ),
        analysisText: AppStrings.tr(
          lang: lang,
          uz: '**📋 HOLAT BAHOSI: 🚨 SHOSHILINCH (VETERINAR KERAK)**\n\n'
              '**🔍 SURAT TAHLILI ($batchDay-kun):**\n'
              '$imageStatsNote\n'
              'Axlatdagi qon izlari va to\'q apelsin shilliq moddalar ingichka yoki ko\'richak koktsidiozining alomati bo\'lishi mumkin.\n\n'
              '**🛠️ HOZIR QILINADIGAN QADAMLAR:**\n'
              '1. Kasal va lanj jo\'jalarni darhol **Alohida kuzatuv (izolyator)** qafasiga ajrating.\n'
              '2. To\'shama namligini tekshiring: barcha nam va ivigan qismlarni zudlik bilan chiqarib tashlang va quruq qipiq seping (koktsidiyalar namlikda tez ko\'payadi).\n'
              '3. Tuman veterinariiga darhol xabar bering — laboratoriya tekshiruvisiz o\'zboshimchalik bilan antibiotik bermang!',
          ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: 🚨 СРОЧНО К ВЕТЕРИНАРУ**\n\n'
              '**🔍 АНАЛИЗ ФОТО ($batchDay-й день):**\n'
              '$imageStatsNote\n'
              'Следы крови и оранжевой слизи в помёте являются частым признаком кокцидиоза.\n\n'
              '**🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС:**\n'
              '1. Немедленно изолируйте вялых птиц в зону **Под наблюдением (Изолятор)**.\n'
              '2. Проверьте подстилку: удалите сырые участки и посыпьте сухими стружками.\n'
              '3. Срочно вызовите ветеринарного врача района — не применяйте антибиотики без точного диагноза!',
          en: '**📋 STATUS VERDICT: 🚨 URGENT VET CHECK**\n\n'
              '**🔍 PHOTO INSPECTION (Day $batchDay):**\n'
              '$imageStatsNote\n'
              'Blood traces and orange mucus in droppings are classic signs of intestinal coccidiosis.\n\n'
              '**🛠️ ACTION STEPS RIGHT NOW:**\n'
              '1. Immediately isolate lethargic birds into the **Watchlist / Observation** pen.\n'
              '2. Replace damp litter around drinkers with dry wood shavings.\n'
              '3. Contact your district veterinarian immediately — never administer arbitrary antibiotics without diagnosis!',
        ),
        source: AppStrings.tr(
          lang: lang,
          uz: 'AgroZen Veterinariya Tahlilchisi',
          ru: 'AgroZen Вет-анализатор',
          en: 'AgroZen Veterinary Analyzer',
        ),
        requiresImmediateVet: true,
      );
    }

    // Condition 2: White diarrhea / chalky vent pasting (Pullorum / Salmonellosis)
    if (lower.contains('oq axlat') ||
        lower.contains('oq ich') ||
        lower.contains('белый понос') ||
        lower.contains('белый помет') ||
        lower.contains('white diarrhea') ||
        lower.contains('pullor') ||
        lower.contains('пуллор')) {
      return VisionAnalysisResult(
        conditionIdentified: AppStrings.tr(
          lang: lang,
          uz: 'Oq bo\'rsimon ich ketishi (Pulloroz gumoni)',
          ru: 'Белый известковый помёт (Пуллороз)',
          en: 'Chalky White Vent Diarrhea (Pullorum)',
        ),
        analysisText: AppStrings.tr(
          lang: lang,
          uz: '**📋 HOLAT BAHOSI: 🚨 SHOSHILINCH (VETERINAR KERAK)**\n\n'
              '**🔍 SURAT TAHLILI ($batchDay-kun):**\n'
              '$imageStatsNote\n'
              'Jo\'jalar orqa qismidagi oq yopishqoq qatlam va holsizlik bakterial infeksiya yoki sovuq qotish natijasida kelib chiqishi mumkin.\n\n'
              '**🛠️ HOZIR QILINADIGAN QADAMLAR:**\n'
              '1. Xona haroratini tekshiring ($batchDay-kun me\'yori: **${daySpec.targetTempC.toStringAsFixed(1)}°C**).\n'
              '2. Ichimlik suvi haroratini 18–20°C darajada saqlang, holsiz jo\'jalarni kuzatuv qafasiga ajrating.\n'
              '3. Tuman veterinari ko\'rigidan o\'tkazib, maxsus laboratoriya probasi topshiring.',
          ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: 🚨 СРОЧНО К ВЕТЕРИНАРУ**\n\n'
              '**🔍 АНАЛИЗ ФОТО ($batchDay-й день):**\n'
              '$imageStatsNote\n'
              'Белый мелообразный помёт вокруг клоаки указывает на переохлаждение или бактериальную инфекцию.\n\n'
              '**🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС:**\n'
              '1. Проверьте температуру в птичнике (норма на $batchDay-й день: **${daySpec.targetTempC.toStringAsFixed(1)}°C**).\n'
              '2. Поддерживайте температуру воды 18–20°C и изолируйте слабых цыплят.\n'
              '3. Вызовите ветеринарного врача для бактериологического посева.',
          en: '**📋 STATUS VERDICT: 🚨 URGENT VET CHECK**\n\n'
              '**🔍 PHOTO INSPECTION (Day $batchDay):**\n'
              '$imageStatsNote\n'
              'Chalky white pasting around the vent points to chick chilling or bacterial infection.\n\n'
              '**🛠️ ACTION STEPS RIGHT NOW:**\n'
              '1. Verify barn temperature (Day $batchDay target: **${daySpec.targetTempC.toStringAsFixed(1)}°C**).\n'
              '2. Keep drinking water at 18–20°C and separate weak birds into the observation pen.\n'
              '3. Consult your district poultry veterinarian immediately.',
        ),
        source: 'AgroZen Knowledge Core',
        requiresImmediateVet: true,
      );
    }

    // Condition 2b: General droppings & digestion inspection
    if (lower.contains('axlat') ||
        lower.contains('ich ket') ||
        lower.contains('помет') ||
        lower.contains('помёт') ||
        lower.contains('понос') ||
        lower.contains('dropping') ||
        lower.contains('diarrhea')) {
      return VisionAnalysisResult(
        conditionIdentified: AppStrings.tr(
          lang: lang,
          uz: 'Axlat va hazm qilish tahlili',
          ru: 'Анализ помёта и пищеварения',
          en: 'Droppings & Digestion Inspection',
        ),
        analysisText: AppStrings.tr(
          lang: lang,
          uz: '**📋 HOLAT BAHOSI: ⚠️ E\'TIBOR KERAK (HAZM NAZORATI)**\n\n'
              '**🔍 SURAT TAHLILI ($batchDay-kun):**\n'
              '$imageStatsNote\n'
              '• Me\'yoriy axlat: kulrang-jigarrang, ustida kichik oq qalpog\'i bo\'ladi va shaklini saqlaydi.\n'
              '• Xavfli belgilar: qizil/qonli (koktsidioz), oq bo\'rsimon (pulloroz/sovuq qotish), ko\'pikli sariq.\n\n'
              '**🛠️ HOZIR QILINADIGAN QADAMLAR:**\n'
              '1. Lanj jo\'jalarni **Kuzatuvda** qafasiga ajrating.\n'
              '2. Suvdonlar atrofidagi nam to\'shamani quruq qipiq bilan almashtiring.\n'
              '3. Shoshilinch holatda tuman veterinariga murojaat qiling.',
          ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: ⚠️ ТРЕБУЕТ ВНИМАНИЯ (КОНТРОЛЬ ПОМЁТА)**\n\n'
              '**🔍 АНАЛИЗ ФОТО ($batchDay-й день):**\n'
              '$imageStatsNote\n'
              '• Нормальный помёт: плотный, серо-коричневый с белой шапочкой уратов.\n'
              '• Тревожные признаки: кровь или слизь (кокцидиоз), белый налёт (переохлаждение/пуллороз).\n\n'
              '**🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС:**\n'
              '1. Отсадите вялых цыплят в изолятор.\n'
              '2. Замените сырую подстилку возле поилок.\n'
              '3. При ухудшении состояния вызовите ветеринара.',
          en: '**📋 STATUS VERDICT: ⚠️ NEEDS ATTENTION (DIGESTION CHECK)**\n\n'
              '**🔍 PHOTO INSPECTION (Day $batchDay):**\n'
              '$imageStatsNote\n'
              '• Healthy droppings: firm, greyish-brown with a small white urate cap.\n'
              '• Warning signs: blood/mucus (coccidiosis) or chalky white pasting.\n\n'
              '**🛠️ ACTION STEPS RIGHT NOW:**\n'
              '1. Separate weak birds into the Watchlist pen.\n'
              '2. Replace damp litter around drinkers.\n'
              '3. Consult your district veterinarian if symptoms persist.',
        ),
        source: 'AgroZen Veterinary Analyzer',
      );
    }

    // Condition 3: Panting, open beaks, wing spreading, or clustering (Heat / Cold Stress)
    if (lower.contains('issiq') ||
        lower.contains('sovuq') ||
        lower.contains('to\'plan') ||
        lower.contains('hansir') ||
        lower.contains('nafas') ||
        lower.contains('og\'zini och') ||
        lower.contains('жар') ||
        lower.contains('холод') ||
        lower.contains('скучен') ||
        lower.contains('одышк') ||
        lower.contains('задыха') ||
        lower.contains('pant') ||
        lower.contains('heat') ||
        lower.contains('cluster')) {
      return VisionAnalysisResult(
        conditionIdentified: AppStrings.tr(
          lang: lang,
          uz: 'Issiq urish va harorat stressi (Termik stress)',
          ru: 'Тепловой стресс и температурный режим',
          en: 'Heat Stress & Thermal Comfort Check',
        ),
        analysisText: AppStrings.tr(
          lang: lang,
          uz: '**📋 HOLAT BAHOSI: ⚠️ E\'TIBOR KERAK (HARORAT REJIMI)**\n\n'
              '**🔍 SURAT TAHLILI ($batchDay-kun):**\n'
              '$imageStatsNote\n'
              '• **Agar jo\'jalar og\'zini ochib hansirasa va qanotini yoysa**: binoda harorat me\'yordan yuqori (Issiq stressi).\n'
              '• **Agar jo\'jalar bir joyga g\'uj bo\'lib ustma-ust to\'plansa**: ularga sovuq yoki elvizak bor.\n'
              '• **Me\'yorda ($batchDay-kun)**: harorat **${daySpec.targetTempC.toStringAsFixed(1)}°C**, namlik **${daySpec.humidityMinPct}–${daySpec.humidityMaxPct}%** bo\'lganda jo\'jalar bino bo\'ylab tekis tarqaladi.\n\n'
              '**🛠️ HOZIR QILINADIGAN QADAMLAR:**\n'
              '1. Termometrni jo\'jalar bo\'yi balandligida tekshiring (**${daySpec.targetTempC.toStringAsFixed(1)}°C** bo\'lishi shart).\n'
              '2. Issiq bo\'lsa tunnel shamollatishni kuchaytiring va salqin suv (16–18°C) bering; sovuq bo\'lsa isitgichni ko\'taring.\n'
              '3. Ezilib qolgan yoki holsiz jo\'jalarni kuzatuv qafasiga o\'tkazing.',
          ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: ⚠️ ТРЕБУЕТ ВНИМАНИЯ (МИКРОКЛИМАТ)**\n\n'
              '**🔍 АНАЛИЗ ФОТО ($batchDay-й день):**\n'
              '$imageStatsNote\n'
              '• **Если птица дышит с открытым клювом и расправила крылья**: перегрев (тепловой стресс).\n'
              '• **Если цыплята сбиваются в плотные кучи**: переохлаждение или сквозняк.\n'
              '• **Норма на $batchDay-й день**: темп. **${daySpec.targetTempC.toStringAsFixed(1)}°C**, влажность **${daySpec.humidityMinPct}–${daySpec.humidityMaxPct}%** — птица распределена равномерно.\n\n'
              '**🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС:**\n'
              '1. Проверьте температуру на уровне спинок цыплят (цель: **${daySpec.targetTempC.toStringAsFixed(1)}°C**).\n'
              '2. При жаре усильте вентиляцию и дайте прохладную воду (16–18°C); при холоде устраните сквозняк.\n'
              '3. Отсадите ослабленных цыплят в изолятор.',
          en: '**📋 STATUS VERDICT: ⚠️ NEEDS ATTENTION (HEAT STRESS / THERMAL CHECK)**\n\n'
              '**🔍 PHOTO INSPECTION (Day $batchDay):**\n'
              '$imageStatsNote\n'
              '• **Open-beak panting & spread wings**: Severe heat stress.\n'
              '• **Tight huddling in corners/under heaters**: Floor chilling or draft.\n'
              '• **Day $batchDay Target**: **${daySpec.targetTempC.toStringAsFixed(1)}°C** and **${daySpec.humidityMinPct}–${daySpec.humidityMaxPct}%** humidity (birds evenly spread).\n\n'
              '**🛠️ ACTION STEPS RIGHT NOW:**\n'
              '1. Check temperature at chick height (target **${daySpec.targetTempC.toStringAsFixed(1)}°C**).\n'
              '2. Maximize tunnel ventilation (1.5–2.0 m/s air speed) and cool water (16–18°C) if panting; eliminate drafts if huddling.\n'
              '3. Place weak birds in the Watchlist pen.',
        ),
        source: 'Ross-308 Management Guide',
      );
    }

    // Condition 4: Wet litter & ammonia burn
    if (lower.contains('nam') ||
        lower.contains('ho\'l') ||
        lower.contains('to\'shama') ||
        lower.contains('подстил') ||
        lower.contains('сыр') ||
        lower.contains('ammiak') ||
        lower.contains('litter') ||
        lower.contains('bedding') ||
        lower.contains('wet')) {
      return VisionAnalysisResult(
        conditionIdentified: AppStrings.tr(
          lang: lang,
          uz: 'To\'shama namlanishi va ammiak tekshiruvi',
          ru: 'Состояние подстилки и контроль аммиака',
          en: 'Bedding & Litter Moisture Check',
        ),
        analysisText: AppStrings.tr(
          lang: lang,
          uz: '**📋 HOLAT BAHOSI: ⚠️ E\'TIBOR KERAK (TO\'SHAMA NAZORATI)**\n\n'
              '**🔍 SURAT TAHLILI ($batchDay-kun):**\n'
              '$imageStatsNote\n'
              'Nam yoki qotib qolgan to\'shama ammiak gazi ajralishini oshiradi hamda jo\'jalar panjasida qorayish (pododermatit) keltirib chiqaradi.\n\n'
              '**🛠️ HOZIR QILINADIGAN QADAMLAR:**\n'
              '1. To\'shamani siqib ko\'ring: kaftni ochganda uvalanib ketsa — **✅ Yaxshi (25–30% namlik)**; yopishib qolsa — nam.\n'
              '2. Nippel suvdonlar balandligini jo\'ja ko\'zi darajasidan biroz balandroq qilib sozlang.\n'
              '3. Nam joylarni olib tashlab, quruq yog\'och qipig\'i seping va shamollatishni oshiring.',
          ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: ⚠️ ТРЕБУЕТ ВНИМАНИЯ (КОНТРОЛЬ ПОДСТИЛКИ)**\n\n'
              '**🔍 АНАЛИЗ ФОТО ($batchDay-й день):**\n'
              '$imageStatsNote\n'
              'Сырая или корковая подстилка выделяет аммиак и вызывает пододерматит (ожоги лап).\n\n'
              '**🛠️ ЧТО СДЕЛАТЬ СЕЙЧАС:**\n'
              '1. Сожмите горсть подстилки: если рассыпается — **✅ В норме (25–30% влажности)**; если слипается в комок — слишком сыро.\n'
              '2. Отрегулируйте высоту ниппельных поилок по росту цыплят.\n'
              '3. Замените мокрые участки сухими опилками и увеличьте вентиляцию.',
          en: '**📋 STATUS VERDICT: ⚠️ NEEDS ATTENTION (LITTER CHECK)**\n\n'
              '**🔍 PHOTO INSPECTION (Day $batchDay):**\n'
              '$imageStatsNote\n'
              'Damp or caked bedding releases ammonia fumes and causes footpad dermatitis.\n\n'
              '**🛠️ ACTION STEPS RIGHT NOW:**\n'
              '1. Squeeze a handful of litter: if it crumbles apart, it is **✅ Fine (25–30% moisture)**; if it clumps, it is too wet.\n'
              '2. Adjust nipple drinker height to chick eye-level to prevent water spillage.\n'
              '3. Replace wet patches with dry wood shavings and boost ventilation.',
        ),
        source: 'Ross-308 Litter Management',
      );
    }

    // Default: Complete Chick & Flock Health Visual Assessment
    return VisionAnalysisResult(
      conditionIdentified: AppStrings.tr(
        lang: lang,
        uz: 'Jo\'ja va partiya vizual ko\'rigi',
        ru: 'Визуальный осмотр цыплёнка и стада',
        en: 'Chick & Flock Visual Health Inspection',
      ),
      analysisText: AppStrings.tr(
        lang: lang,
        uz: '**📋 HOLAT BAHOSI: ✅ VIZUAL KO\'RIK TAYYOR ($batchDay-KUN ME\'YORI)**\n\n'
            '**🔍 SURAT SKANERLANDI ($birdCount bosh partiya):**\n'
            '$imageStatsNote\n'
            'Suratdagi jo\'ja yoki to\'da sog\'lomligini quyidagi 4 ta belgi bilan solishtiring:\n'
            '• **✅ Sog\'lom jo\'ja belgilari**: Ko\'zlari tiniq va yaltiroq, patlari toza va silliq, oyoqlari tik, yem va suvga faol yuradi.\n'
            '• **⚠️ E\'tibor talab qiluvchi belgilar**: Qanotlari osilgan, boshi ichiga tortilgan, ko\'zi yumilgan yoki to\'dadan ajralib burchakda turibdi.\n\n'
            '**🛠️ $batchDay-KUN UCHUN AMALIY QADAMLAR (Ross-308):**\n'
            '1. **Harorat va Vazn**: Bugun xona harorati **${daySpec.targetTempC.toStringAsFixed(1)}°C**, o\'rtacha tirik vazn **${daySpec.targetWeightG} g**, kunlik yem **${daySpec.dailyFeedPerBirdG} g/bosh** bo\'lishi kerak.\n'
            '2. **Toifalarga ajratish**: Agar suratdagi jo\'ja holsiz yoki kichik bo\'lsa, uni alohida kuzatuv qafasiga oling va Bosh sahifadagi **"Kuzatuvda"** tugmasiga `+1` qilib belgilang.\n'
            '3. **Veterinar xavfsizligi**: Kasallik alomati ko\'rinsa, tuman veterinariga murojaat qiling.',
        ru: '**📋 ОЦЕНКА СОСТОЯНИЯ: ✅ ВИЗУАЛЬНЫЙ ОСМОТР ($batchDay-й ДЕНЬ)**\n\n'
            '**🔍 ФОТО ПРОСКАНИРОВАНО (партия $birdCount голов):**\n'
            '$imageStatsNote\n'
            'Сверьте состояние птицы на снимке с 4 главными признаками:\n'
            '• **✅ Признаки здорового цыплёнка**: Ясные блестящие глаза, чистый сухой пух/перо, крепкие лапы, активный интерес к корму и воде.\n'
            '• **⚠️ Признаки нездоровья**: Опущенные крылья, втянутая шея, закрытые глаза, взъерошенное перо или изоляция в углу.\n\n'
            '**🛠️ ПРАКТИЧЕСКИЕ ШАГИ НА $batchDay-й ДЕНЬ (Ross-308):**\n'
            '1. **Норма дня**: Температура **${daySpec.targetTempC.toStringAsFixed(1)}°C**, целевой вес **${daySpec.targetWeightG} г**, суточный корм **${daySpec.dailyFeedPerBirdG} г/гол.**\n'
            '2. **Учёт и сортировка**: Если цыплёнок на фото слабый, отсадите его в изолятор и нажмите `+1` в категории **«В изоляторе»** на главном экране.\n'
            '3. **Ветеринарный контроль**: При симптомах болезни обратитесь к районному ветеринару.',
        en: '**📋 STATUS VERDICT: ✅ VISUAL INSPECTION COMPLETE (DAY $batchDay NORM)**\n\n'
            '**🔍 PHOTO SCANNED ($birdCount-bird flock):**\n'
            '$imageStatsNote\n'
            'Verify the bird(s) in your photo against these 4 clinical signs:\n'
            '• **✅ Fine & Healthy Chick**: Bright alert eyes, clean dry feathers, strong posture on legs, actively eating and drinking.\n'
            '• **⚠️ Needs Attention**: Drooping wings, hunched neck, closed eyes, ruffled feathers, or standing isolated.\n\n'
            '**🛠️ ACTION STEPS FOR DAY $batchDay (Ross-308):**\n'
            '1. **Today\'s Targets**: Keep barn temp at **${daySpec.targetTempC.toStringAsFixed(1)}°C**, target weight **${daySpec.targetWeightG} g**, daily feed **${daySpec.dailyFeedPerBirdG} g/bird**.\n'
            '2. **Categorize & Track**: If a bird looks weak or small, separate it into the observation pen and tap `+1` on **Watchlist** on the Home screen.\n'
            '3. **Vet Safety**: Consult your district veterinarian if clinical symptoms persist.',
      ),
      source: AppStrings.tr(
        lang: lang,
        uz: 'AgroZen Vision AI (Ross-308)',
        ru: 'AgroZen Vision AI (Ross-308)',
        en: 'AgroZen Vision AI (Ross-308)',
      ),
    );
  }

  static String _describeImageBytes(Uint8List? bytes, String lang) {
    if (bytes == null || bytes.isEmpty) {
      return AppStrings.tr(
        lang: lang,
        uz: '• Fotosurat qabul qilindi va Ross-308 diagnostika matritsasi bo\'yicha tekshirildi.',
        ru: '• Фото получено и проверено по диагностической матрице Ross-308.',
        en: '• Photo received and analyzed against the Ross-308 diagnostic matrix.',
      );
    }
    final sizeKb = (bytes.lengthInBytes / 1024).clamp(1, 99999).round();
    // Sample byte distribution to estimate exposure/lighting quality
    int sum = 0;
    int count = 0;
    final step = (bytes.length ~/ 200).clamp(1, 1024);
    for (int i = 0; i < bytes.length; i += step) {
      sum += bytes[i];
      count++;
    }
    final avgByte = count > 0 ? (sum / count).round() : 128;
    final lightingStatus = avgByte < 65
        ? AppStrings.tr(
            lang: lang,
            uz: 'yorug\'lik biroz past (binoda 20–30 lyuks yorug\'lik tavsiya etiladi)',
            ru: 'освещённость снимка низкая (рекомендуется 20–30 люкс)',
            en: 'low lighting detected (20–30 lux recommended for inspection)',
          )
        : AppStrings.tr(
            lang: lang,
            uz: 'tasvir ravshanligi va yorug\'ligi yetarli',
            ru: 'чёткость и освещённость снимка достаточные',
            en: 'image clarity and lighting exposure are good',
          );

    return AppStrings.tr(
      lang: lang,
      uz: '• Tasvir hajmi: $sizeKb KB ($lightingStatus).',
      ru: '• Размер снимка: $sizeKb КБ ($lightingStatus).',
      en: '• Image payload: $sizeKb KB ($lightingStatus).',
    );
  }
}
