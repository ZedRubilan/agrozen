import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agrozen/config/constants.dart';
import 'package:agrozen/config/supabase_config.dart';
import 'package:agrozen/core/localization/app_strings.dart';
import 'package:agrozen/data/providers/ai_provider.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/voice_input_button.dart';
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:agrozen/services/poultry_vision_analyzer.dart';
import 'package:agrozen/services/tts_service.dart';
import 'package:agrozen/services/voice_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? source;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
    this.imagePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _knowledgeRepo = KnowledgeRepository();
  final _picker = ImagePicker();
  final _visionAnalyzer = PoultryVisionAnalyzer();
  final _ttsService = TtsService();

  final List<ChatMessage> _messages = [];
  String _lang = 'uz';
  int _remainingQuestions = 30;
  bool _isLoading = false;
  bool _isRecording = false;
  String? _selectedImagePath;
  String? _speakingText;

  /// Returned by the recorder when capture starts; null when the user never
  /// actually began (e.g. immediate permission denial UX).
  String? _recordingPath;
  VoiceService? _voiceService;

  VoiceService get _voice => _voiceService ??= VoiceService();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _remainingQuestions = DailyCounters.getRemainingQuestions(
        prefs,
        maxDailyQuestions: AppConstants.maxDailyQuestions,
      );
    });

    // Add initial welcome message in active language
    _messages.add(
      ChatMessage(
        text: AppStrings.tr(
          lang: _lang,
          uz: "Assalomu alaykum! Men AgroZen broyler yetishtirish bo'yicha aqlli yordamchingizman. "
              "Harorat, yem, shamollatish yoki emlash bo'yicha istalgan savolingizni bering yoki jo'jalar rasmini yuboring.",
          ru: 'Здравствуйте! Я ваш ИИ-помощник по выращиванию бройлеров AgroZen. '
              'Задавайте любые вопросы по температуре, кормам, вентиляции или вакцинации, либо отправьте фото птичника.',
          en: 'Hello! I am your AgroZen broiler farming AI assistant. '
              'Ask any questions regarding temperature, feed, ventilation, or vaccination, or share a photo for visual analysis.',
        ),
        isUser: false,
        source: AppStrings.tr(
          lang: _lang,
          uz: 'AgroZen bilimlar bazasi',
          ru: 'База знаний AgroZen',
          en: 'AgroZen Knowledge Base',
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        setState(() {
          _selectedImagePath = picked.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  /// Begins microphone capture. Permission outcome is surfaced.
  Future<void> _startVoiceRecording() async {
    try {
      final path = await _voice.startRecording();
      _recordingPath = path;
      if (!mounted) return;
      setState(() => _isRecording = true);
      _showSnack(
        AppStrings.tr(
          lang: _lang,
          uz: 'Gapiring... (Ovoz yozilmoqda)',
          ru: 'Говорите... (Запись голоса)',
          en: 'Speak now... (Recording audio)',
        ),
      );
    } on VoiceUnavailable catch (e) {
      if (!mounted) return;
      if (e.reason == VoiceUnavailableReason.permissionDenied) {
        _showSnack(
          AppStrings.tr(
            lang: _lang,
            uz: "Mikrofonga ruxsat berilmagan. Telefon sozlamalaridan ruxsat bering va qayta urining.",
            ru: 'Нет доступа к микрофону. Разрешите доступ в настройках телефона и попробуйте ещё раз.',
            en: 'Microphone permission denied. Please grant access in device settings.',
          ),
          isError: true,
        );
      } else {
        _showSnack(
          AppStrings.tr(
            lang: _lang,
            uz: 'Yozib olish imkonsiz. Savolni matn bilan yozing.',
            ru: 'Запись недоступна. Напишите вопрос текстом.',
            en: 'Voice recording unavailable. Please type your question.',
          ),
          isError: true,
        );
      }
    }
  }

  /// Stops capture, transcribes through the backend, and asks the transcript.
  Future<void> _stopVoiceRecording() async {
    setState(() => _isRecording = false);

    final path = _recordingPath;
    _recordingPath = null;

    String? stoppedPath;
    try {
      stoppedPath = await _voice.stopRecording();
    } catch (_) {
      stoppedPath = null;
    }

    final audioPath = stoppedPath ?? path;
    if (audioPath == null) {
      _showSnack(
        AppStrings.tr(
          lang: _lang,
          uz: 'Yozuv amalga oshmadi. Savolni matn bilan yozing.',
          ru: 'Запись не удалась. Напишите вопрос текстом.',
          en: 'Recording failed. Please type your question.',
        ),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final transcript = await _voice.transcribe(audioPath, language: _lang);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _sendMessage(transcript);
    } on VoiceUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      switch (e.reason) {
        case VoiceUnavailableReason.notConfigured:
          _showSnack(
            AppStrings.tr(
              lang: _lang,
              uz: "Ovozli kiritish hali serverga ulanmagan. Iltimos, savolni matn bilan yozing.",
              ru: 'Голосовой ввод ещё не подключён к серверу. Пожалуйста, напишите вопрос текстом.',
              en: 'Voice service not configured yet. Please type your question.',
            ),
            isError: true,
          );
        case VoiceUnavailableReason.noAudio:
        case VoiceUnavailableReason.transcribeFailed:
        case VoiceUnavailableReason.permissionDenied:
          _showSnack(
            AppStrings.tr(
              lang: _lang,
              uz: "Nutqni aniqlab bo'lmadi. Savolni matn bilan yozing.",
              ru: 'Не удалось распознать речь. Напишите вопрос текстом.',
              en: 'Could not recognize speech. Please type your question.',
            ),
            isError: true,
          );
      }
    }
  }

  Future<void> _toggleSpeak(String text) async {
    if (_speakingText == text) {
      await _ttsService.stop();
      setState(() => _speakingText = null);
    } else {
      setState(() => _speakingText = text);
      await _ttsService.speak(
        text: text,
        lang: _lang,
        onComplete: () {
          if (mounted) setState(() => _speakingText = null);
        },
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _voiceService?.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    final attachedImage = _selectedImagePath;

    if (text.isEmpty && attachedImage == null) return;
    if (_isLoading) return;

    if (_remainingQuestions <= 0) {
      _showSnack(
        AppStrings.tr(
          lang: _lang,
          uz: "Kunlik savollar limiti (30) tugadi. Ertaga davom ettiring!",
          ru: 'Дневной лимит вопросов (30) исчерпан. Попробуйте завтра!',
          en: 'Daily limit of 30 questions reached. Please continue tomorrow!',
        ),
        isError: true,
      );
      return;
    }

    _controller.clear();
    setState(() {
      _selectedImagePath = null;
      _messages.add(
        ChatMessage(
          text: text.isEmpty
              ? AppStrings.tr(
                  lang: _lang,
                  uz: "Parranda yoki to'shama fotosurati tahlil qilinsin",
                  ru: 'Анализ фото птицы или подстилки',
                  en: 'Analyze flock or bedding photo',
                )
              : text,
          isUser: true,
          imagePath: attachedImage,
        ),
      );
      _isLoading = true;
      _remainingQuestions--;
    });

    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    await DailyCounters.setRemainingQuestions(
      prefs,
      _remainingQuestions,
    );

    _scrollToBottom();

    late final String answer;
    late final String source;

    final rag = LocalRag(_knowledgeRepo);

    // If an image is attached, run poultry vision analysis
    if (attachedImage != null) {
      final visionResult = await _visionAnalyzer.analyzeFlockImage(
        imagePath: attachedImage,
        userQuery: text.isNotEmpty ? text : null,
        language: _lang,
      );
      answer = visionResult.analysisText;
      source = visionResult.source;
    } else if (rag.wantsMedicine(text)) {
      // Safety rule #2: never prescribe drugs or dosages, always refer.
      answer = rag.medicineRefusal(_lang);
      source = AppStrings.tr(
        lang: _lang,
        uz: 'Veterinariya qoidalari',
        ru: 'Ветеринарные правила',
        en: 'Veterinary Rules',
      );
    } else if (rag.looksLikeEmergency(text)) {
      // Emergency phrasing gets safety script + vet referral
      answer = AppStrings.tr(
        lang: _lang,
        uz: "Shoshilinch holatga o'xshaydi. Kutmang va parrandani o'zingiz davolamang:\n\n"
            "1. Kasal parrandani sog'lomlaridan ajrating.\n"
            "2. Parrandani tashqariga chiqarishni to'xtating.\n"
            "3. Darhol tumaningiz veterinariiga qo'ng'iroq qiling — kontaktlar Kundalik ekranida.\n\n"
            "AgroZen tashxis qo'ymaydi va dori buyurmadi.",
        ru: 'Похоже на экстренную ситуацию. Не ждите и не лечите птицу самостоятельно:\n\n'
            '1. Изолируйте заболевших птиц от здоровых.\n'
            '2. Прекратите вывоз и продажу птицы.\n'
            '3. Немедленно позвоните ветеринару вашего района — контакты на экране Дневника.\n\n'
            'AgroZen не ставит диагнозы и не назначает лекарства.',
        en: 'This appears to be an urgent situation. Do not wait or self-treat the flock:\n\n'
            '1. Isolate symptomatic birds from healthy ones.\n'
            '2. Suspend poultry transfer and sales immediately.\n'
            '3. Call your district veterinarian immediately — contact info is on the Diary screen.\n\n'
            'AgroZen does not provide diagnoses or prescribe medication.',
      );
      source = AppStrings.tr(
        lang: _lang,
        uz: 'Favqulodda yordam',
        ru: 'Экстренная помощь',
        en: 'Emergency Response',
      );
    } else {
      RagResult? ragResult;
      try {
        ragResult = await rag.answer(question: text, language: _lang);
      } catch (_) {
        ragResult = null;
      }

      if (ragResult != null) {
        answer = ragResult.answer;
        source = ragResult.sources.join(', ');
      } else if (SupabaseConfig.isConfigured) {
        try {
          final ai = GeminiAiProvider();
          final response = await ai.askQuestion(
            question: text,
            language: _lang,
            relevantTopicContents: const [],
            topicNames: const [],
          );
          answer = response.answer;
          source = response.sourcesUsed.join(', ');
        } catch (_) {
          answer = _noAnswerMessage(_lang);
          source = AppStrings.tr(
            lang: _lang,
            uz: "AgroZen: ma'lumot yo'q",
            ru: 'АгроЗен: нет данных',
            en: 'AgroZen: No Data',
          );
        }
      } else {
        answer = _noAnswerMessage(_lang);
        source = AppStrings.tr(
          lang: _lang,
          uz: "AgroZen: ma'lumot yo'q",
          ru: 'АгроЗен: нет данных',
          en: 'AgroZen: No Data',
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: answer,
          isUser: false,
          source: source,
        ),
      );
      _isLoading = false;
    });

    _scrollToBottom();
  }

  static String _noAnswerMessage(String lang) => AppStrings.tr(
        lang: lang,
        uz: "Bu savol bo'yicha tekshirilgan bazada javob topa olmadim. "
            "Iltimos, tumaningiz veterinariiga murojaat qiling — men o'ylab topmayman.",
        ru: 'Я не нашёл ответа на этот вопрос в проверенной базе знаний. '
            'Пожалуйста, обратитесь к ветеринару вашего района — я не буду придумывать.',
        en: 'I could not find an answer in the verified knowledge base. '
            'Please consult your district veterinarian — I will not fabricate answers.',
      );

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleText = AppStrings.tr(
      lang: _lang,
      uz: 'AgroZen AI Yordamchi',
      ru: 'ИИ Помощник AgroZen',
      en: 'AgroZen AI Assistant',
    );

    final quotaText = AppStrings.tr(
      lang: _lang,
      uz: 'Bugun qoldi: $_remainingQuestions/30',
      ru: 'Осталось: $_remainingQuestions/30 сегодня',
      en: 'Remaining today: $_remainingQuestions/30',
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titleText, style: const TextStyle(fontSize: 16)),
            Text(
              quotaText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, theme);
                },
              ),
            ),

            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'AgroZen javob tayyorlamoqda...',
                        ru: 'AgroZen думает...',
                        en: 'AgroZen is thinking...',
                      ),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Image attachment preview before sending
            if (_selectedImagePath != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_selectedImagePath!),
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: "Biriktirilgan rasm (jo'ja yoki to'shama)",
                          ru: 'Прикреплённое фото (птицы / подстилка)',
                          en: 'Attached photo (birds / litter)',
                        ),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => setState(() => _selectedImagePath = null),
                    ),
                  ],
                ),
              ),

            // Input Bar with Camera, Voice & Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Camera Icon
                  IconButton(
                    tooltip: AppStrings.tr(
                      lang: _lang,
                      uz: 'Kamera',
                      ru: 'Камера',
                      en: 'Camera',
                    ),
                    icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade700),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  // Gallery Icon
                  IconButton(
                    tooltip: AppStrings.tr(
                      lang: _lang,
                      uz: 'Galereya',
                      ru: 'Галерея',
                      en: 'Gallery',
                    ),
                    icon: Icon(Icons.photo_library_outlined, color: Colors.grey.shade700),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                  // Voice Recording
                  VoiceInputButton(
                    isRecording: _isRecording,
                    language: _lang,
                    onStartRecording: _startVoiceRecording,
                    onStopRecording: _stopVoiceRecording,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: AppStrings.tr(
                          lang: _lang,
                          uz: 'Savol yozing...',
                          ru: 'Задайте вопрос...',
                          en: 'Type a question...',
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: Icon(Icons.send_rounded, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isSpeakerActive = _speakingText == msg.text;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? theme.colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If image is attached to message
            if (msg.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(msg.imagePath!),
                  width: 220,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 8),
            ],

            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),

            // Footer with source and TTS audio playback
            if (!msg.isUser) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (msg.source != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            size: 14,
                            color: Colors.green.shade800,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${AppStrings.tr(lang: _lang, uz: 'Manba:', ru: 'Источник:', en: 'Source:')} ${msg.source}',
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isSpeakerActive ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      size: 20,
                      color: isSpeakerActive ? theme.colorScheme.primary : Colors.grey.shade600,
                    ),
                    tooltip: AppStrings.tr(
                      lang: _lang,
                      uz: 'Ovozli o\'qish',
                      ru: 'Озвучить ответ',
                      en: 'Read aloud',
                    ),
                    onPressed: () => _toggleSpeak(msg.text),
                  ),
                ],
              ),
            ] else if (msg.source != null) ...[
              const SizedBox(height: 6),
              Text(
                'Manba: ${msg.source}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
