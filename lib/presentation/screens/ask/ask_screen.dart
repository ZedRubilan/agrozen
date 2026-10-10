import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agrozen/config/constants.dart';
import 'package:agrozen/config/theme.dart';
import 'package:agrozen/config/supabase_config.dart';
import 'package:agrozen/core/localization/app_strings.dart';
import 'package:agrozen/data/providers/ai_provider.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/voice_input_button.dart';
import 'package:agrozen/presentation/widgets/organic_image_inspector.dart';
import 'package:agrozen/presentation/widgets/tactile_button.dart';
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
  final bool isEmbeddedInPageView;

  const AskScreen({
    super.key,
    this.startInFieldMode = false,
    this.isEmbeddedInPageView = false,
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

    final bDay = context.batchDay;
    final cCount = context.currentCount;
    final welcomeMessage = ChatMessage(
      text: AppStrings.tr(
        lang: prefs.getString('app_language') ?? 'uz',
        uz: "Assalomu alaykum, ${context.farmerName}! Men AgroZen aqlli yordamchingizman.\n"
            "Sizning partiyangiz $bDay-kunda ($cCount ta parrandalar). Harorat, yem, shamollatish yoki jo'jalar sog'lig'i bo'yicha savolingizni bering yoki surat yuboring.",
        ru: "Здравствуйте, ${context.farmerName}! Я ваш помощник AgroZen.\n"
            "Ваша партия на $bDay-м дне ($cCount голов). Задавайте любые вопросы по температуре, кормам, вентиляции или отправьте фото птичника.",
        en: "Hello, ${context.farmerName}! I am your AgroZen assistant.\n"
            "Your flock is on Day $bDay ($cCount birds). Ask any questions about temperature, feed, ventilation, or share a flock photo.",
      ),
      isUser: false,
      source: AppStrings.tr(
        lang: prefs.getString('app_language') ?? 'uz',
        uz: 'AgroZen bilimlar bazasi',
        ru: 'База знаний AgroZen',
        en: 'AgroZen Knowledge Base',
      ),
    );

    if (!mounted) return;
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _remainingQuestions = DailyCounters.getRemainingQuestions(
        prefs,
        maxDailyQuestions: AppConstants.maxDailyQuestions,
      );
      _liveContext = context;
      if (_messages.isEmpty) {
        _messages.add(welcomeMessage);
      }
    });
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
    } catch (e) {
      if (!mounted) return;
      _pulseController.stop();
      _pulseController.reset();
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  Future<void> _toggleSpeak(String text) async {
    if (_speakingText == text) {
      await _ttsService.stop();
      if (!_isRecording && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
      setState(() => _speakingText = null);
    } else {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      setState(() => _speakingText = text);
      await _ttsService.speak(
        text: text,
        lang: _lang,
        onComplete: () {
          if (mounted) {
            setState(() => _speakingText = null);
            if (!_isRecording && _pulseController.isAnimating) {
              _pulseController.stop();
              _pulseController.reset();
            }
          }
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
      en: 'Bugun qoldi: $_remainingQuestions/30',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedInPageView,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D7A4C), Color(0xFF1B5E20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A4C).withAlpha(50),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1F1D),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _remainingQuestions > 0 ? const Color(0xFF22C55E) : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        quotaText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Mode toggle: Chat vs Hands-Free Field Mode
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _isFieldMode = !_isFieldMode);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isFieldMode
                        ? const Color(0xFF2D7A4C)
                        : const Color(0xFF2D7A4C).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isFieldMode
                          ? const Color(0xFF2D7A4C)
                          : const Color(0xFF2D7A4C).withAlpha(60),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFieldMode
                            ? Icons.agriculture_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 15,
                        color: _isFieldMode ? Colors.white : const Color(0xFF2D7A4C),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isFieldMode
                            ? AppStrings.tr(
                                lang: _lang, uz: 'Dala rejimi', ru: 'Режим поля', en: 'Field Mode')
                            : AppStrings.tr(lang: _lang, uz: 'Chat', ru: 'Чат', en: 'Chat'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isFieldMode ? Colors.white : const Color(0xFF2D7A4C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isFieldMode ? _buildFieldModeBody(theme) : _buildChatModeBody(theme),
      ),
    );
  }

  /// Real-time live audio wave visualizer (equalizer effect)
  Widget _buildAudioWaveVisualizer({
    required bool isActive,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final animValue = _pulseController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final double height = isActive
                ? (6.0 + 16.0 * (0.3 + 0.7 * (sin(animValue * pi * 2 + index * 1.1).abs())))
                : 4.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }

  /// Hands-Free "Dala Rejimi": Built for dirty hands with massive touch targets,
  /// atmospheric voice chamber, and automatic read-aloud voice playback.
  Widget _buildFieldModeBody(ThemeData theme) {
    final ChatMessage lastAiMessage = _messages.isNotEmpty
        ? _messages.lastWhere(
            (m) => !m.isUser,
            orElse: () => _messages.first,
          )
        : ChatMessage(
            text: AppStrings.tr(
              lang: _lang,
              uz: "Assalomu alaykum! Savolingizni ovozli bering yoki rasm yuboring.",
              ru: "Здравствуйте! Задайте вопрос голосом или отправьте фото.",
              en: "Hello! Ask a question by voice or share a photo.",
            ),
            isUser: false,
            source: 'AgroZen',
          );

    return Column(
      children: [
        // 1. Live Flock Dossier Card
        if (_liveContext != null) _buildFlockDossierCard(),

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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 8,
                bottom: widget.isEmbeddedInPageView ? 110 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 2. Atmospheric Voice Sphere Hero Arena
                  _buildAtmosphericVoiceArena(),
                  const SizedBox(height: 16),

                  // 3. Tactile Media & Action Pill Dock
                  _buildTactileMediaDock(),
                  const SizedBox(height: 18),

                  // 4. Quick Agronomic Questions Carousel (1-Tap Voice Answers)
                  _buildQuickPromptsCarousel(),
                  const SizedBox(height: 18),

                  // 5. Premier AI Voice Response Card
                  _buildAiAnswerCard(lastAiMessage),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Live Flock Dossier Card with real chick photo and climate norm
  Widget _buildFlockDossierCard() {
    if (_liveContext == null) return const SizedBox.shrink();

    final targetTemp = _liveContext!.targetTemperatureC.round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF22C55E), width: 1.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Image.asset(
                'assets/images/chick_starter.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_liveContext!.batchDay}-kun dossier biriktirildi',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: Color(0xFF15803D),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${_liveContext!.district} • ${_liveContext!.currentCount} bosh',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.thermostat_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 3),
                Text(
                  '$targetTemp°C',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The Atmospheric Voice Sphere Hero Chamber
  Widget _buildAtmosphericVoiceArena() {
    final bool isListening = _isRecording;
    final bool isSpeaking = _speakingText != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0C2417),
            Color(0xFF133E26),
            Color(0xFF091C12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF133E26).withAlpha(100),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Voice Orb with Multi-Ring Pulse
          AnimatedBuilder(
            animation: _pulseScale,
            builder: (context, _) {
              final scaleVal = _pulseController.isAnimating ? _pulseScale.value : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Outer ripple ring
                  Transform.scale(
                    scale: isListening ? scaleVal * 1.15 : (isSpeaking ? scaleVal * 1.08 : 1.0),
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isListening
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E))
                            .withAlpha(isListening ? 45 : (isSpeaking ? 30 : 18)),
                      ),
                    ),
                  ),
                  // Secondary softer ripple
                  Transform.scale(
                    scale: isListening ? 1.0 + (scaleVal - 1.0) * 0.6 : 1.0,
                    child: Container(
                      width: 154,
                      height: 154,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isListening
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E))
                            .withAlpha(isListening ? 70 : (isSpeaking ? 50 : 30)),
                      ),
                    ),
                  ),
                  // Center Tactile Glowing Mic Button (128x128)
                  GestureDetector(
                    onTap: () {
                      if (_isRecording) {
                        _stopVoiceRecording();
                      } else {
                        _startVoiceRecording();
                      }
                    },
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isListening
                              ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                              : [const Color(0xFF22C55E), const Color(0xFF15803D)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(
                          color: Colors.white.withAlpha(220),
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isListening ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                                .withAlpha(140),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Glow Status Pill inside Arena
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              border: Border.all(
                color: (isListening ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withAlpha(140),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isListening ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? const Color(0xFFEF4444) : const Color(0xFF22C55E))
                            .withAlpha(180),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isListening
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
                    color: isListening ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  ),
                ),
                if (isListening || isSpeaking) ...[
                  const SizedBox(width: 8),
                  _buildAudioWaveVisualizer(
                    isActive: true,
                    color: isListening ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Subtle guidance prompt in ivory
          Text(
            isListening
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(200),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Tactile Media & Action Pill Dock
  Widget _buildTactileMediaDock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Camera action pill
          InkWell(
            onTap: () => _pickImage(ImageSource.camera),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFDE68A), width: 1),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFFD97706)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr(lang: _lang, uz: 'Kamera', ru: 'Камера', en: 'Camera'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: AppTheme.cardBorder,
          ),
          // Gallery action pill
          InkWell(
            onTap: () => _pickImage(ImageSource.gallery),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                    ),
                    child: const Icon(Icons.photo_library_rounded, size: 18, color: Color(0xFF059669)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.tr(lang: _lang, uz: 'Galereya', ru: 'Галерея', en: 'Gallery'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Agronomic Questions Carousel (1-Tap Voice Answers)
  Widget _buildQuickPromptsCarousel() {
    final day = _liveContext?.batchDay ?? 1;
    final prompts = [
      {
        'icon': Icons.thermostat_rounded,
        'label': '$day-kun harorat me\'yori',
        'query': "$day-kunda xona harorati qanday bo'lishi kerak?",
      },
      {
        'icon': Icons.water_drop_rounded,
        'label': 'Suv harorati qanday?',
        'query': "Jo'jalar uchun suv harorati qanday bo'lishi kerak?",
      },
      {
        'icon': Icons.grain_rounded,
        'label': 'Yem sarfi me\'yori',
        'query': "$day-kunda jo'jalar uchun yem sarfi qancha?",
      },
      {
        'icon': Icons.air_rounded,
        'label': 'Shamollatish qoidalari',
        'query': "Parrandaxonani shamollatish qoidalari qanday?",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                AppStrings.tr(
                  lang: _lang,
                  uz: "Tezkor agronomic savollar",
                  ru: "Быстрые вопросы агроному",
                  en: "Quick Agronomic Questions",
                ),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final item = prompts[idx];
              return InkWell(
                onTap: () => _sendMessage(item['query'] as String),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData, size: 14, color: const Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Simulated AI Answer Card with TTS readout & emergency call
  Widget _buildAiAnswerCard(ChatMessage lastAiMessage) {
    final bool isSpeaking = _speakingText == lastAiMessage.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        boxShadow: AppTheme.cardShadow,
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
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF5ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.psychology_rounded, size: 18, color: Color(0xFF15803D)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: 'AgroZen Maslahatchi',
                          ru: 'AgroZen Консультант',
                          en: 'AgroZen Advisor',
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (lastAiMessage.source != null)
                        Text(
                          lastAiMessage.source!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // TTS Play/Stop Button
              InkWell(
                onTap: () => _toggleSpeak(lastAiMessage.text),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSpeaking ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: isSpeaking ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.volume_up_rounded : Icons.volume_mute_rounded,
                        size: 16,
                        color: isSpeaking ? const Color(0xFF15803D) : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 6),
                      if (isSpeaking) ...[
                        _buildAudioWaveVisualizer(
                          isActive: true,
                          color: const Color(0xFF15803D),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        isSpeaking
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
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSpeaking ? const Color(0xFF15803D) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            lastAiMessage.text,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              height: 1.55,
            ),
          ),
          if (lastAiMessage.riskLevel == RiskLevel.high &&
              _liveContext?.localVet != null) ...[
            const SizedBox(height: 16),
            TactileButton(
              height: 52,
              depth: 4,
              borderRadius: 16,
              backgroundColor: const Color(0xFFDC2626),
              shadowColor: const Color(0xFF991B1B),
              onPressed: _callLocalVet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "${AppStrings.tr(lang: _lang, uz: 'Veterinar:', ru: 'Ветеринар:', en: 'Vet:')} ${_liveContext!.localVet!['name']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4C)),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.tr(
                    lang: _lang,
                    uz: 'AgroZen tahlil qilmoqda...',
                    ru: 'AgroZen думает...',
                    en: 'AgroZen is thinking...',
                  ),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Quick Suggestion Chips Carousel (shown before first query)
        if (_messages.length <= 1 && !_isLoading)
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSuggestionChip(
                  icon: Icons.thermostat_rounded,
                  text: "Issiqlik me'yori",
                  prompt: "Broylerlar uchun xona harorati qanday bo'lishi kerak?",
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.grass_rounded,
                  text: "Kunlik yem miqdori",
                  prompt: "Broylerlarga kunlik yem me'yori qancha?",
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.air_rounded,
                  text: "Shamollatish qoidalari",
                  prompt: "Parrandaxonani shamollatish qoidalari qanday?",
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.water_drop_rounded,
                  text: "Suv harorati",
                  prompt: "Jo'jalar uchun suv harorati qanday bo'lishi kerak?",
                ),
              ],
            ),
          ),

        // Image attachment preview before sending
        if (_selectedImagePath != null && !_isLoading)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_selectedImagePath!),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: "Biriktirilgan rasm",
                          ru: 'Прикреплённое фото',
                          en: 'Attached photo',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.tr(
                          lang: _lang,
                          uz: "Jo'ja yoki to'shama holati",
                          ru: 'Птица или подстилка',
                          en: 'Flock or bedding condition',
                        ),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _selectedImagePath = null),
                ),
              ],
            ),
          ),

        // Modern Floating Input Dock
        Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: widget.isEmbeddedInPageView ? 95 : 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Media Action Buttons
              _buildInputIconBtn(
                icon: Icons.camera_alt_rounded,
                tooltip: 'Camera',
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 4),
              _buildInputIconBtn(
                icon: Icons.photo_library_rounded,
                tooltip: 'Gallery',
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 4),
              VoiceInputButton(
                isRecording: _isRecording,
                language: _lang,
                onStartRecording: _startVoiceRecording,
                onStopRecording: _stopVoiceRecording,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: AppStrings.tr(
                        lang: _lang,
                        uz: 'Savol yozing...',
                        ru: 'Задайте вопрос...',
                        en: 'Type a question...',
                      ),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tactile Emerald Send Button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D7A4C), Color(0xFF1E5B37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(23),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D7A4C).withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip({
    required IconData icon,
    required String text,
    required String prompt,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF2D7A4C)),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1B5E20),
        ),
      ),
      backgroundColor: const Color(0xFFEAF5ED),
      side: BorderSide(color: const Color(0xFF2D7A4C).withAlpha(40)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _sendMessage(prompt),
    );
  }

  Widget _buildInputIconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: const Color(0xFF475569)),
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ThemeData theme) {
    final isSpeakerActive = _speakingText == msg.text;

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: msg.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF2D7A4C), Color(0xFF1E5B37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: msg.isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          border: msg.isUser
              ? null
              : Border.all(
                  color: msg.riskLevel == RiskLevel.high
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFE2E8F0),
                  width: msg.riskLevel == RiskLevel.high ? 1.5 : 1.0,
                ),
          boxShadow: [
            BoxShadow(
              color: msg.isUser
                  ? const Color(0xFF2D7A4C).withAlpha(40)
                  : Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assistant Brand Header in Bubble
            if (!msg.isUser) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D7A4C).withAlpha(25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: Color(0xFF2D7A4C),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'AgroZen AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E5B37),
                        ),
                      ),
                    ],
                  ),
                  // Audio TTS button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleSpeak(msg.text),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSpeakerActive
                              ? const Color(0xFFEAF5ED)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSpeakerActive ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                              size: 15,
                              color: isSpeakerActive
                                  ? const Color(0xFF2D7A4C)
                                  : Colors.grey.shade600,
                            ),
                            if (isSpeakerActive) ...[
                              const SizedBox(width: 4),
                              const Text(
                                '...',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D7A4C),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Risk Level Badge for AI responses
            if (!msg.isUser && msg.riskLevel != RiskLevel.low) ...[
              _buildRiskBadge(msg.riskLevel),
              const SizedBox(height: 10),
            ],

            // Attached image if present
            if (msg.imagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(msg.imagePath!),
                  width: 240,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 10),
            ],

            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : const Color(0xFF1E293B),
                fontSize: 14,
                fontWeight: msg.isUser ? FontWeight.w600 : FontWeight.w500,
                height: 1.5,
              ),
            ),

            // Source indicator
            if (!msg.isUser && msg.source != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF2D7A4C),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '${AppStrings.tr(lang: _lang, uz: 'Manba:', ru: 'Источник:', en: 'Source:')} ${msg.source}',
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1E5B37),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (msg.isUser && msg.source != null) ...[
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
    final color = isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706);
    final bgColor = isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(120), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCritical ? Icons.emergency_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isCritical
                  ? AppStrings.tr(
                      lang: _lang,
                      uz: "YUQORI XAVF: VETERINAR TALAB ETILADI",
                      ru: "ВЫСОКИЙ РИСК: ТРЕБУЕТСЯ ВЕТЕРИНАР",
                      en: "CRITICAL: VETERINARY REFERRAL",
                    )
                  : AppStrings.tr(
                      lang: _lang,
                      uz: "DIQQAT TALAB HOLAT",
                      ru: "ТРЕБУЕТСЯ ВНИМАНИЕ",
                      en: "MODERATE ATTENTION",
                    ),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

