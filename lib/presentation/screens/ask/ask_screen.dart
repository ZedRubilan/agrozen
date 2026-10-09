import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agrozen/config/constants.dart';
import 'package:agrozen/config/supabase_config.dart';
import 'package:agrozen/core/localization/app_strings.dart';
import 'package:agrozen/data/providers/ai_provider.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/voice_input_button.dart';
import 'package:agrozen/presentation/widgets/organic_image_inspector.dart';
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:agrozen/services/poultry_vision_analyzer.dart';
import 'package:agrozen/services/tts_service.dart';
import 'package:agrozen/services/voice_service.dart';
import 'package:agrozen/services/flock_context_service.dart';

enum RiskLevel { low, medium, high }

class ChatMessage {
  final String text;
  final bool isUser;
  final String? source;
  final String? imagePath;
  final RiskLevel riskLevel;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
    this.imagePath,
    this.riskLevel = RiskLevel.low,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AskScreen extends StatefulWidget {
  final bool startInFieldMode;

  const AskScreen({
    super.key,
    this.startInFieldMode = false,
  });

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _knowledgeRepo = KnowledgeRepository();
  final _picker = ImagePicker();
  final _visionAnalyzer = PoultryVisionAnalyzer();
  final _ttsService = TtsService();
  final _flockContextService = FlockContextService();

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  final List<ChatMessage> _messages = [];
  String _lang = 'uz';
  int _remainingQuestions = 30;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isFieldMode = false; // Hands-Free "Dala Rejimi"
  String? _selectedImagePath;
  String? _speakingText;
  LiveFlockContext? _liveContext;

  String? _recordingPath;
  VoiceService? _voiceService;

  VoiceService get _voice => _voiceService ??= VoiceService();

  @override
  void initState() {
    super.initState();
    _isFieldMode = widget.startInFieldMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    final context = await _flockContextService.getLiveContext();

    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _remainingQuestions = DailyCounters.getRemainingQuestions(
        prefs,
        maxDailyQuestions: AppConstants.maxDailyQuestions,
      );
      _liveContext = context;
    });

    // Add initial welcome message with live flock context
    final bDay = context.batchDay;
    final cCount = context.currentCount;
    _messages.add(
      ChatMessage(
        text: AppStrings.tr(
          lang: _lang,
          uz: "Assalomu alaykum, ${context.farmerName}! Men AgroZen aqlli yordamchingizman.\n"
              "Sizning partiyangiz $bDay-kunda ($cCount ta parrandalar). Harorat, yem, shamollatish yoki jo'jalar sog'lig'i bo'yicha savolingizni bering yoki surat yuboring.",
          ru: "Здравствуйте, ${context.farmerName}! Я ваш помощник AgroZen.\n"
              "Ваша партия на $bDay-м дне ($cCount голов). Задавайте любые вопросы по температуре, кормам, вентиляции или отправьте фото птичника.",
          en: "Hello, ${context.farmerName}! I am your AgroZen assistant.\n"
              "Your flock is on Day $bDay ($cCount birds). Ask any questions about temperature, feed, ventilation, or share a flock photo.",
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
        // If in Field Mode, auto-trigger analysis immediately on image capture
        if (_isFieldMode) {
          _sendMessage();
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _startVoiceRecording() async {
    try {
      final path = await _voice.startRecording();
      _recordingPath = path;
      if (!mounted) return;
      _pulseController.repeat(reverse: true);
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
      _pulseController.stop();
      _pulseController.reset();
      if (e.reason == VoiceUnavailableReason.permissionDenied) {
        _showSnack(
          AppStrings.tr(
            lang: _lang,
            uz: "Mikrofonga ruxsat berilmagan. Telefon sozlamalaridan ruxsat bering.",
            ru: 'Нет доступа к микрофону. Разрешите доступ в настройках.',
            en: 'Microphone permission denied. Grant access in device settings.',
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

  Future<void> _stopVoiceRecording() async {
    _pulseController.stop();
    _pulseController.reset();
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
      if (e.reason == VoiceUnavailableReason.notConfigured) {
        _showSnack(
          AppStrings.tr(
            lang: _lang,
            uz: "Ovozli kiritish serverga ulanmagan. Iltimos, matn yozing.",
            ru: 'Голосовой ввод не подключён к серверу. Напишите текстом.',
            en: 'Voice service not configured yet. Please type your question.',
          ),
          isError: true,
        );
      } else {
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
    _pulseController.dispose();
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

    _flockContextService.recordTurn(role: 'user', text: text.isNotEmpty ? text : '[SURAT]');
    _scrollToBottom();

    late final String answer;
    late final String source;
    RiskLevel risk = RiskLevel.low;

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
      risk = visionResult.requiresImmediateVet ? RiskLevel.high : RiskLevel.medium;
    } else if (rag.wantsMedicine(text)) {
      // Safety rule #2: never prescribe drugs or dosages, always refer.
      answer = rag.medicineRefusal(_lang);
      source = AppStrings.tr(
        lang: _lang,
        uz: 'Veterinariya qoidalari',
        ru: 'Ветеринарные правила',
        en: 'Veterinary Rules',
      );
      risk = RiskLevel.high;
    } else if (rag.looksLikeEmergency(text)) {
      // Emergency phrasing gets safety script + vet referral
      answer = AppStrings.tr(
        lang: _lang,
        uz: "Shoshilinch holatga o'xshaydi. Kutmang va parrandani o'zingiz davolamang:\n\n"
            "1. Kasal parrandani sog'lomlaridan ajrating.\n"
            "2. Parrandani tashqariga chiqarishni to'xtating.\n"
            "3. Darhol tumaningiz veterinariga qo'ng'iroq qiling — kontaktlar Kundalik ekranida.\n\n"
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
      risk = RiskLevel.high;
    } else {
      RagResult? ragResult;
      try {
        ragResult = await rag.answer(
          question: text,
          language: _lang,
          context: _liveContext,
        );
      } catch (_) {
        ragResult = null;
      }

      if (ragResult != null) {
        answer = ragResult.answer;
        source = ragResult.sources.join(', ');
        risk = RiskLevel.low;
      } else if (SupabaseConfig.isConfigured) {
        try {
          final ai = GeminiAiProvider();
          final promptWithContext = _liveContext != null
              ? '${_liveContext!.toPromptContextBlock(_lang)}\n${_flockContextService.getConversationHistorySnippet(_lang)}\nSavol: $text'
              : text;

          final response = await ai.askQuestion(
            question: promptWithContext,
            language: _lang,
            relevantTopicContents: const [],
            topicNames: const [],
          );
          answer = response.answer;
          source = response.sourcesUsed.join(', ');
          risk = RiskLevel.low;
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

    _flockContextService.recordTurn(role: 'assistant', text: answer);

    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text: answer,
          isUser: false,
          source: source,
          riskLevel: risk,
        ),
      );
      _isLoading = false;
    });

    _scrollToBottom();

    // In Hands-Free Field Mode: auto-speak the answer out loud so dirty hands never touch the screen!
    if (_isFieldMode) {
      _toggleSpeak(answer);
    }
  }

  static String _noAnswerMessage(String lang) => AppStrings.tr(
        lang: lang,
        uz: "Bu savol bo'yicha tekshirilgan bazada javob topa olmadim. "
            "Iltimos, tumaningiz veterinariga murojaat qiling — men o'ylab topmayman.",
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

  void _callLocalVet() async {
    final vetPhone = _liveContext?.localVet?['phone']?.toString();
    if (vetPhone != null && vetPhone.isNotEmpty) {
      final uri = Uri.parse('tel:$vetPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleText = AppStrings.tr(
      lang: _lang,
      uz: 'AgroZen AI Maslahatchi',
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
        actions: [
          // Mode toggle: Chat vs Hands-Free Field Mode
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(
                _isFieldMode ? Icons.agriculture_rounded : Icons.chat_bubble_outline_rounded,
                size: 16,
                color: _isFieldMode ? Colors.white : theme.colorScheme.primary,
              ),
              label: Text(
                _isFieldMode
                    ? AppStrings.tr(lang: _lang, uz: 'Dala rejimi', ru: 'Режим поля', en: 'Field Mode')
                    : AppStrings.tr(lang: _lang, uz: 'Chat', ru: 'Чат', en: 'Chat'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isFieldMode ? Colors.white : theme.colorScheme.primary,
                ),
              ),
              backgroundColor: _isFieldMode ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
              onPressed: () {
                setState(() => _isFieldMode = !_isFieldMode);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isFieldMode ? _buildFieldModeBody(theme) : _buildChatModeBody(theme),
      ),
    );
  }

  /// Hands-Free "Dala Rejimi": Built for dirty hands with massive touch targets
  /// and automatic read-aloud voice playback.
  Widget _buildFieldModeBody(ThemeData theme) {
    final lastAiMessage = _messages.lastWhere(
      (m) => !m.isUser,
      orElse: () => _messages.first,
    );

    return Column(
      children: [
        // Live Flock Dossier Banner
        if (_liveContext != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              border: Border(
                bottom: BorderSide(color: const Color(0xFF2D7A4C).withAlpha(50), width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D7A4C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_liveContext!.batchDay}-kun dossier biriktirildi',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_liveContext!.district} • ${_liveContext!.currentCount} bosh',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

        // Live Organic Image Inspector if analyzing
        if (_selectedImagePath != null && _isLoading)
          Expanded(
            child: Center(
              child: OrganicImageInspector(
                imagePath: _selectedImagePath!,
                language: _lang,
                isAnalyzing: true,
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Giant Center Voice Circle with Outer Pulsing Ripple Rings
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer animated ripple ring
                          Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 172,
                              height: 172,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_isRecording ? Colors.red : const Color(0xFF2D7A4C))
                                    .withAlpha(_isRecording ? 45 : 30),
                              ),
                            ),
                          ),
                          // Secondary softer ripple
                          Transform.scale(
                            scale: 1.0 + (_pulseScale.value - 1.0) * 0.5,
                            child: Container(
                              width: 154,
                              height: 154,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_isRecording ? Colors.red : const Color(0xFF2D7A4C))
                                    .withAlpha(_isRecording ? 60 : 40),
                              ),
                            ),
                          ),
                          // Giant Tactile Mic Button (136x136)
                          GestureDetector(
                            onTap: () {
                              if (_isRecording) {
                                _stopVoiceRecording();
                              } else {
                                _startVoiceRecording();
                              }
                            },
                            child: Container(
                              width: 136,
                              height: 136,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: _isRecording
                                      ? [const Color(0xFFE53935), const Color(0xFFB71C1C)]
                                      : [const Color(0xFF2D7A4C), const Color(0xFF1B5E20)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isRecording ? Colors.red : const Color(0xFF1B5E20))
                                        .withAlpha(120),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Clean Status Pill Badge (Outside circle - Zero font collision)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _isRecording ? Colors.red.shade700 : const Color(0xFF1B5E20),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red.shade700 : const Color(0xFF1B5E20),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecording
                              ? AppStrings.tr(
                                  lang: _lang,
                                  uz: "ESHITILMOQDA...",
                                  ru: "СЛУШАЮ...",
                                  en: "LISTENING...",
                                )
                              : AppStrings.tr(
                                  lang: _lang,
                                  uz: "TUGMANI BOSING",
                                  ru: "НАЖМИТЕ ДЛЯ ЗАПИСИ",
                                  en: "TAP TO SPEAK",
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: _isRecording ? Colors.red.shade800 : const Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Helpful Guidance Subtext
                  Text(
                    _isRecording
                        ? AppStrings.tr(
                            lang: _lang,
                            uz: "Gapiring, to'xtatish uchun yana bosing",
                            ru: "Говорите, для завершения нажмите снова",
                            en: "Speak now, tap again to finish",
                          )
                        : AppStrings.tr(
                            lang: _lang,
                            uz: "Bosing va savolingizni ayting.\nJavob ovozli o'qib beriladi.",
                            ru: "Нажмите и задайте вопрос голосом.\nОтвет будет озвучен.",
                            en: "Tap and ask hands-free.\nAnswer will be read aloud.",
                          ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Tactile Action Controls (Camera & Gallery)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickActionBtn(
                        icon: Icons.camera_alt_rounded,
                        label: AppStrings.tr(lang: _lang, uz: 'Kamera', ru: 'Камера', en: 'Camera'),
                        color: const Color(0xFFB8781B),
                        bgColor: const Color(0xFFFFF7E6),
                        borderColor: const Color(0xFFE5A338),
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      const SizedBox(width: 24),
                      _buildQuickActionBtn(
                        icon: Icons.photo_library_rounded,
                        label: AppStrings.tr(lang: _lang, uz: 'Galereya', ru: 'Галерея', en: 'Gallery'),
                        color: const Color(0xFF2D7A4C),
                        bgColor: const Color(0xFFEAF5ED),
                        borderColor: const Color(0xFF2D7A4C),
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Simulated AI Answer Card with TTS readout & emergency call
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2D7A4C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  AppStrings.tr(
                                    lang: _lang,
                                    uz: 'AgroZen Maslahatchi',
                                    ru: 'AgroZen Консультант',
                                    en: 'AgroZen Advisor',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1B5E20),
                                  ),
                                ),
                              ],
                            ),
                            // TTS Play/Stop Button
                            InkWell(
                              onTap: () => _toggleSpeak(lastAiMessage.text),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _speakingText == lastAiMessage.text
                                      ? const Color(0xFFEAF5ED)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _speakingText == lastAiMessage.text
                                          ? Icons.volume_up_rounded
                                          : Icons.volume_mute_rounded,
                                      size: 16,
                                      color: _speakingText == lastAiMessage.text
                                          ? const Color(0xFF1B5E20)
                                          : Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _speakingText == lastAiMessage.text
                                          ? AppStrings.tr(
                                              lang: _lang,
                                              uz: 'Ovozli...',
                                              ru: 'Озвучивается...',
                                              en: 'Speaking...',
                                            )
                                          : AppStrings.tr(
                                              lang: _lang,
                                              uz: 'Ovoz',
                                              ru: 'Озвучить',
                                              en: 'Listen',
                                            ),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: _speakingText == lastAiMessage.text
                                            ? const Color(0xFF1B5E20)
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          lastAiMessage.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.45,
                          ),
                        ),
                        if (lastAiMessage.riskLevel == RiskLevel.high &&
                            _liveContext?.localVet != null) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _callLocalVet,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC84B31),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.phone_in_talk, size: 20),
                            label: Text(
                              "${AppStrings.tr(lang: _lang, uz: 'Veterinar:', ru: 'Ветеринар:', en: 'Vet:')} ${_liveContext!.localVet!['name']}",
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Standard Chat Mode Body
  Widget _buildChatModeBody(ThemeData theme) {
    return Column(
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

        // Live Organic Image Inspector if analyzing
        if (_selectedImagePath != null && _isLoading)
          OrganicImageInspector(
            imagePath: _selectedImagePath!,
            language: _lang,
            isAnalyzing: true,
          ),

        if (_isLoading && _selectedImagePath == null)
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
                    uz: 'AgroZen tahlil qilmoqda...',
                    ru: 'AgroZen думает...',
                    en: 'AgroZen is thinking...',
                  ),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

        // Image attachment preview before sending
        if (_selectedImagePath != null && !_isLoading)
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

        // Input Bar
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
              IconButton(
                tooltip: 'Camera',
                icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade700),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              IconButton(
                tooltip: 'Gallery',
                icon: Icon(Icons.photo_library_outlined, color: Colors.grey.shade700),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
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
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isSpeakerActive = _speakingText == msg.text;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? theme.colorScheme.primary : Colors.grey.shade50,
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
            // Risk Level Badge for AI responses
            if (!msg.isUser && msg.riskLevel != RiskLevel.low) ...[
              _buildRiskBadge(msg.riskLevel),
              const SizedBox(height: 8),
            ],

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
                height: 1.45,
              ),
            ),

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
                      size: 22,
                      color: isSpeakerActive ? theme.colorScheme.primary : Colors.grey.shade600,
                    ),
                    tooltip: 'Speak',
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

  Widget _buildRiskBadge(RiskLevel level) {
    final isCritical = level == RiskLevel.high;
    final color = isCritical ? const Color(0xFFC84B31) : const Color(0xFFE5A338);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCritical ? Icons.emergency : Icons.warning_amber_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isCritical
                ? AppStrings.tr(lang: _lang, uz: "YUQORI XAVF: VETERINAR TALAB ETILADI", ru: "ВЫСОКИЙ РИСК: ТРЕБУЕТСЯ ВЕТЕРИНАР", en: "CRITICAL: VETERINARY REFERRAL")
                : AppStrings.tr(lang: _lang, uz: "DIQQAT TALAB HOLAT", ru: "ТРЕБУЕТСЯ ВНИМАНИЕ", en: "MODERATE ATTENTION"),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
