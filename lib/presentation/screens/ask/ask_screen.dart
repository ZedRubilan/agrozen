import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'package:agrozen/domain/broiler/broiler_grower_library.dart';
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
  final String? initialPrompt;

  const AskScreen({
    super.key,
    this.startInFieldMode = false,
    this.isEmbeddedInPageView = false,
    this.initialPrompt,
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
  final _aiProvider = GeminiAiProvider();

  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  final List<ChatMessage> _messages = [];
  String _lang = 'uz';
  int _remainingQuestions = 30;
  bool _isLoading = false;
  bool _isRecording = false;
  bool _isFieldMode = false; // Hands-Free "Dala Rejimi"
  bool _autoSpeakInFieldMode = true;
  String _livePartialTranscript = '';
  String? _selectedImagePath;
  String? _analyzingImagePath;
  String _selectedPhotoCategory = 'chick'; // 'chick', 'droppings', 'litter', 'clustering'
  String? _speakingText;
  LiveFlockContext? _liveContext;
  Locale? _observedLocale;
  String? _lastHandledInitialPrompt;

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
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      _lastHandledInitialPrompt = widget.initialPrompt;
      _controller.text = widget.initialPrompt!;
    }
    _loadState();
  }

  @override
  void didUpdateWidget(covariant AskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.initialPrompt?.trim();
    if (incoming != null &&
        incoming.isNotEmpty &&
        incoming != _lastHandledInitialPrompt) {
      _lastHandledInitialPrompt = incoming;
      _controller.text = incoming;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _sendMessage(incoming);
        }
      });
    }
  }

  void _enhanceCurrentInput() {
    final enhanced = FarmerPromptEnhancer.enhanceFarmerPrompt(
      rawInput: _controller.text,
      lang: _lang,
      batchDay: _liveContext?.batchDay ?? 1,
      birdCount: _liveContext?.currentCount ?? 500,
      outsideTempC: _liveContext?.outsideTemp,
    );
    setState(() {
      _controller.text = enhanced;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
    _showSnack(
      AppStrings.tr(
        lang: _lang,
        uz: "✨ Savol Ross-308 partiya ko'rsatkichlari bilan boyitildi!",
        ru: '✨ Вопрос обогащён параметрами вашей партии Ross-308!',
        en: '✨ Prompt enhanced with your Ross-308 flock parameters!',
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.maybeLocaleOf(context);
    if (_observedLocale != null &&
        currentLocale != null &&
        currentLocale != _observedLocale) {
      _observedLocale = currentLocale;
      _loadState(localeOverride: currentLocale.languageCode);
    } else {
      _observedLocale = currentLocale;
    }
  }

  Future<void> _loadState({String? localeOverride}) async {
    final prefs = await DailyCounters.rolled(
      maxDailyQuestions: AppConstants.maxDailyQuestions,
    );
    final resolvedLang = prefs.getString('app_language') ?? localeOverride ?? 'uz';
    final context = await _flockContextService.getLiveContext();

    final bDay = context.batchDay;
    final cCount = context.currentCount;
    final welcomeMessage = ChatMessage(
      text: AppStrings.tr(
        lang: resolvedLang,
        uz: "Assalomu alaykum, ${context.farmerName}! Men AgroZen aqlli yordamchingizman.\n"
            "Sizning partiyangiz $bDay-kunda ($cCount ta parrandalar). Harorat, yem, shamollatish yoki jo'jalar sog'lig'i bo'yicha savolingizni bering yoki surat yuboring.",
        ru: "Здравствуйте, ${context.farmerName}! Я ваш помощник AgroZen.\n"
            "Ваша партия на $bDay-м дне ($cCount голов). Задавайте любые вопросы по температуре, кормам, вентиляции или отправьте фото птичника.",
        en: "Hello, ${context.farmerName}! I am your AgroZen assistant.\n"
            "Your flock is on Day $bDay ($cCount birds). Ask any questions about temperature, feed, ventilation, or share a flock photo.",
      ),
      isUser: false,
      source: AppStrings.tr(
        lang: resolvedLang,
        uz: 'AgroZen bilimlar bazasi',
        ru: 'База знаний AgroZen',
        en: 'AgroZen Knowledge Base',
      ),
    );

    if (!mounted) return;
    setState(() {
      _lang = resolvedLang;
      _remainingQuestions = DailyCounters.getRemainingQuestions(
        prefs,
        maxDailyQuestions: AppConstants.maxDailyQuestions,
      );
      _liveContext = context;
      if (_messages.isEmpty) {
        _messages.add(welcomeMessage);
      } else if (_messages.length == 1 && !_messages.first.isUser) {
        _messages[0] = welcomeMessage;
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
      if (_speakingText != null || _ttsService.isPlaying) {
        await _ttsService.stop();
        if (mounted) {
          setState(() => _speakingText = null);
        }
      }
      if (mounted) {
        setState(() => _livePartialTranscript = '');
      }
      final path = await _voice.startRecording(
        language: _lang,
        onPartialResult: (partial) {
          if (mounted) {
            setState(() => _livePartialTranscript = partial);
          }
        },
      );
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
    final partialFallback = _livePartialTranscript.trim();
    setState(() {
      _isRecording = false;
      _livePartialTranscript = '';
    });

    final path = _recordingPath;
    _recordingPath = null;

    String? stoppedPath;
    try {
      stoppedPath = await _voice.stopRecording();
    } catch (_) {
      stoppedPath = null;
    }

    final audioPath = stoppedPath ?? path;
    if (audioPath == null && partialFallback.isEmpty) {
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
      final transcript = audioPath != null
          ? await _voice.transcribe(audioPath, language: _lang)
          : partialFallback;
      if (!mounted) return;
      setState(() => _isLoading = false);
      _sendMessage(transcript.isNotEmpty ? transcript : partialFallback);
    } on VoiceUnavailable catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (partialFallback.isNotEmpty) {
        _sendMessage(partialFallback);
        return;
      }
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
      if (partialFallback.isNotEmpty) {
        _sendMessage(partialFallback);
        return;
      }
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

  Future<void> _toggleSpeak(String text, [String? langOverride]) async {
    if (_speakingText == text) {
      await _ttsService.stop();
      if (!_isRecording && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
      setState(() => _speakingText = null);
    } else {
      final speakLang =
          langOverride ?? LocalRag.detectLanguage(text, fallback: _lang);
      setState(() => _speakingText = text);
      await _ttsService.speak(
        text: text,
        lang: speakLang,
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
      if (mounted && _ttsService.isPlaying && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
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

  String _photoCategoryDefaultQuery(String category, String lang) {
    switch (category) {
      case 'droppings':
        return AppStrings.tr(
          lang: lang,
          uz: "Jo'ja axlati va hazm qilish holatini tekshiring (qon, shilliq yoki oq ich ketishi bormi?)",
          ru: 'Проверьте состояние помёта и пищеварения (есть ли кровь, слизь или белый понос?)',
          en: 'Inspect droppings and digestion condition (check for blood, mucus, or white diarrhea)',
        );
      case 'litter':
        return AppStrings.tr(
          lang: lang,
          uz: "To'shama (qipiq) quruqligi, namligi va ammiak xavfini tekshiring",
          ru: 'Проверьте сухость, влажность подстилки и риск аммиака',
          en: 'Inspect bedding/litter dryness, moisture, and ammonia hazard',
        );
      case 'clustering':
        return AppStrings.tr(
          lang: lang,
          uz: "Jo'jalarning bino bo'ylab joylashishi, issiq yoki sovuq stressi alomatlarini tekshiring",
          ru: 'Проверьте распределение цыплят по птичнику, признаки жары или холода',
          en: 'Inspect flock distribution, clustering, and heat or cold stress signs',
        );
      case 'chick':
      default:
        return AppStrings.tr(
          lang: lang,
          uz: "Suratdagi jo'ja yoki to'daning umumiy sog'lig'i, patlari, ko'zi va oyoqlari yaxshimi?",
          ru: 'В норме ли общее здоровье цыплёнка или стада, оперение, глаза и лапы на фото?',
          en: 'Is the chicken or flock in the photo fine and healthy (feathers, posture, eyes, legs)?',
        );
    }
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

    final effectiveUserText = (text.isEmpty && attachedImage != null)
        ? _photoCategoryDefaultQuery(_selectedPhotoCategory, _lang)
        : text;

    _controller.clear();
    setState(() {
      _selectedImagePath = null;
      _analyzingImagePath = attachedImage;
      _messages.add(
        ChatMessage(
          text: effectiveUserText,
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

    _flockContextService.recordTurn(
      role: 'user',
      text: attachedImage != null ? '[SURAT] $effectiveUserText' : effectiveUserText,
    );
    _scrollToBottom();

    late final String answer;
    late final String source;
    RiskLevel risk = RiskLevel.low;

    final rag = LocalRag(_knowledgeRepo);
    final effectiveLang = text.isNotEmpty
        ? LocalRag.detectLanguage(text, fallback: _lang)
        : _lang;

    // If an image is attached, run Gemini Multimodal poultry vision analysis
    if (attachedImage != null) {
      final visionResult = await _visionAnalyzer.analyzeFlockImage(
        imagePath: attachedImage,
        userQuery: effectiveUserText,
        language: effectiveLang,
        flockContext: _liveContext,
      );
      answer = visionResult.analysisText;
      source = visionResult.source;
      if (visionResult.requiresImmediateVet) {
        risk = RiskLevel.high;
      } else if (answer.contains('⚠️')) {
        risk = RiskLevel.medium;
      } else {
        risk = RiskLevel.low;
      }
    } else if (rag.wantsMedicine(text)) {
      // Safety rule #2: never prescribe drugs or dosages, always refer.
      answer = rag.medicineRefusal(effectiveLang);
      source = AppStrings.tr(
        lang: effectiveLang,
        uz: 'Veterinariya qoidalari',
        ru: 'Ветеринарные правила',
        en: 'Veterinary Rules',
      );
      risk = RiskLevel.high;
    } else if (rag.looksLikeEmergency(text)) {
      // Emergency phrasing gets safety script + vet referral
      answer = rag.emergencyMessage(effectiveLang, context: _liveContext);
      source = AppStrings.tr(
        lang: effectiveLang,
        uz: 'Favqulodda yordam',
        ru: 'Экстренная помощь',
        en: 'Emergency Response',
      );
      risk = RiskLevel.high;
    } else {
      String? resolvedAnswer;
      String? resolvedSource;

      // 1. Primary Brain: Live AI (Gemini / Supabase Edge Function) grounded with flock dossier & local knowledge
      if (SupabaseConfig.isConfigured || SupabaseConfig.hasGeminiKey) {
        try {
          final localTopics = await rag.getRelevantTopicContext(
            question: text,
            language: effectiveLang,
          );
          final questionLabel = effectiveLang == 'en'
              ? 'Question'
              : (effectiveLang == 'ru' ? 'Вопрос' : 'Savol');
          final historySnippet =
              _flockContextService.getConversationHistorySnippet(effectiveLang);
          final dossierBlock = _liveContext?.toPromptContextBlock(effectiveLang) ?? '';
          final promptParts = <String>[
            if (dossierBlock.isNotEmpty) dossierBlock,
            if (historySnippet.isNotEmpty) historySnippet,
            '$questionLabel: $text',
          ];
          final promptWithContext = promptParts.length > 1
              ? promptParts.join('\n')
              : text;

          final response = await _aiProvider.askQuestion(
            question: promptWithContext,
            language: effectiveLang,
            relevantTopicContents: localTopics.contents,
            topicNames: localTopics.titles,
          );
          if (response.answer.trim().isNotEmpty) {
            resolvedAnswer = response.answer.trim();
            resolvedSource = response.sourcesUsed.join(', ');
          }
        } catch (aiErr) {
          debugPrint('Live AI call failed, using LocalRag fallback: $aiErr');
        }
      }

      // 2. Smart Local Conversational + RAG Fallback (offline or if cloud AI unavailable)
      if (resolvedAnswer == null || resolvedAnswer.isEmpty) {
        try {
          final ragResult = await rag.answer(
            question: text,
            language: effectiveLang,
            context: _liveContext,
          );
          if (ragResult != null) {
            resolvedAnswer = ragResult.answer;
            resolvedSource = ragResult.sources.join(', ');
          }
        } catch (ragErr) {
          debugPrint('LocalRag fallback error: $ragErr');
        }
      }

      if (resolvedAnswer != null && resolvedAnswer.isNotEmpty) {
        answer = resolvedAnswer;
        source = (resolvedSource != null && resolvedSource.isNotEmpty)
            ? resolvedSource
            : AppStrings.tr(
                lang: effectiveLang,
                uz: 'AgroZen AI Maslahatchi',
                ru: 'ИИ Консультант AgroZen',
                en: 'AgroZen AI Advisor',
              );
        risk = RiskLevel.low;
      } else {
        answer = _noAnswerMessage(effectiveLang);
        source = AppStrings.tr(
          lang: effectiveLang,
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
      _analyzingImagePath = null;
    });

    _scrollToBottom();

    // In Hands-Free Field Mode: auto-speak the answer out loud when enabled
    if (_isFieldMode && _autoSpeakInFieldMode) {
      _toggleSpeak(answer, effectiveLang);
    }
  }

  static String _noAnswerMessage(String lang) => AppStrings.tr(
        lang: lang,
        uz: "Bu savol bo'yicha tekshirilgan bazada aniq javob topa olmadim. "
            "Iltimos, parrandachilik bo'yicha savolingizni biroz aniqlashtirib yozing yoki tumaningiz veterinariga murojaat qiling.",
        ru: 'Я не нашёл точного ответа на этот вопрос в проверенной базе знаний. '
            'Пожалуйста, уточните ваш вопрос по птицеводству или обратитесь к ветеринару вашего района.',
        en: 'I could not find a specific answer for that in the verified knowledge base. '
            'Please clarify your poultry question or consult your district veterinarian.',
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
  /// atmospheric voice chamber, automatic read-aloud voice playback, and quick text input.
  Widget _buildFieldModeBody(ThemeData theme) {
    final ChatMessage lastAiMessage = _messages.isNotEmpty
        ? _messages.lastWhere(
            (m) => !m.isUser,
            orElse: () => _messages.first,
          )
        : ChatMessage(
            text: AppStrings.tr(
              lang: _lang,
              uz: "Assalomu alaykum! Savolingizni ovozli bering, yozing yoki rasm yuboring.",
              ru: "Здравствуйте! Задайте вопрос голосом, текстом или отправьте фото.",
              en: "Hello! Ask a question by voice, text, or share a photo.",
            ),
            isUser: false,
            source: 'AgroZen',
          );

    ChatMessage? lastUserMessage;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUserMessage = _messages[i];
        break;
      }
    }

    return Column(
      children: [
        // 1. Live Flock Dossier Card
        if (_liveContext != null) _buildFlockDossierCard(),

        // Live Organic Image Inspector if analyzing
        if (_analyzingImagePath != null && _isLoading)
          Expanded(
            child: Center(
              child: OrganicImageInspector(
                imagePath: _analyzingImagePath!,
                language: _lang,
                isAnalyzing: true,
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                left: 18,
                right: 18,
                top: 8,
                bottom: 16,
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

                  // 5. User's Last Question / Spoken Transcript Pill
                  if (lastUserMessage != null) ...[
                    _buildFieldModeUserQuestionBanner(lastUserMessage),
                    const SizedBox(height: 12),
                  ],

                  // 6. Thinking / Processing Indicator in Field Mode
                  if (_isLoading && _analyzingImagePath == null) ...[
                    _buildThinkingBanner(),
                    const SizedBox(height: 12),
                  ],

                  // 7. Premier AI Voice Response Card (Full untruncated response)
                  _buildAiAnswerCard(lastAiMessage),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

        // 8. Quick Text Input Bar in Field Mode so typing also works seamlessly
        _buildFieldModeQuickInputBar(),
      ],
    );
  }

  Widget _buildFieldModeUserQuestionBanner(ChatMessage userMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7A4C), Color(0xFF1E5B37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D7A4C).withAlpha(35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userMsg.imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: kIsWeb
                  ? Image.network(
                      userMsg.imagePath!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                    )
                  : Image.file(
                      File(userMsg.imagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                    ),
            ),
            const SizedBox(width: 10),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userMsg.imagePath != null
                      ? AppStrings.tr(
                          lang: _lang,
                          uz: 'Skanerlangan fotosurat:',
                          ru: 'Просканированное фото:',
                          en: 'Scanned photo:',
                        )
                      : AppStrings.tr(
                          lang: _lang,
                          uz: 'Sizning savolingiz:',
                          ru: 'Ваш вопрос:',
                          en: 'Your question:',
                        ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userMsg.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D7A4C)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.tr(
                lang: _lang,
                uz: 'AgroZen javob tayyorlamoqda...',
                ru: 'AgroZen готовит ответ...',
                en: 'AgroZen is preparing your answer...',
              ),
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldModeQuickInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 8,
        bottom: widget.isEmbeddedInPageView ? 95 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✨ Smart Prompt Enhancer Button
          Tooltip(
            message: AppStrings.tr(
              lang: _lang,
              uz: 'Savolni boyitish (Prompt Enhancer)',
              ru: 'Улучшить вопрос (Prompt Enhancer)',
              en: 'Enhance Prompt',
            ),
            child: GestureDetector(
              onTap: _enhanceCurrentInput,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFD97706),
                    size: 19,
                  ),
                ),
              ),
            ),
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
                    uz: 'Savol yozing yoki ✨ bosing...',
                    ru: 'Напишите вопрос или нажмите ✨...',
                    en: 'Type a question or tap ✨ to enhance...',
                  ),
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D7A4C), Color(0xFF1E5B37)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D7A4C).withAlpha(75),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.send_rounded, color: Colors.white, size: 19),
              ),
            ),
          ),
        ],
      ),
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
                      _lang == 'en'
                          ? 'Day ${_liveContext!.batchDay} dossier attached'
                          : (_lang == 'ru'
                              ? 'День ${_liveContext!.batchDay}: досье подключено'
                              : '${_liveContext!.batchDay}-kun dossier biriktirildi'),
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
                  _lang == 'en'
                      ? '${_liveContext!.district} • ${_liveContext!.currentCount} birds'
                      : (_lang == 'ru'
                          ? '${_liveContext!.district} • ${_liveContext!.currentCount} голов'
                          : '${_liveContext!.district} • ${_liveContext!.currentCount} bosh'),
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

          if (isListening && _livePartialTranscript.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withAlpha(50)),
              ),
              child: Text(
                '"$_livePartialTranscript"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
            ),
          ],

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.tr(lang: _lang, uz: 'Kamera', ru: 'Камера', en: 'Camera'),
                    style: const TextStyle(
                      fontSize: 12.5,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.tr(lang: _lang, uz: 'Galereya', ru: 'Галерея', en: 'Gallery'),
                    style: const TextStyle(
                      fontSize: 12.5,
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
          // Auto-speak toggle pill
          InkWell(
            onTap: () async {
              final next = !_autoSpeakInFieldMode;
              setState(() => _autoSpeakInFieldMode = next);
              if (!next && (_speakingText != null || _ttsService.isPlaying)) {
                await _ttsService.stop();
                if (mounted) setState(() => _speakingText = null);
              }
            },
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _autoSpeakInFieldMode
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _autoSpeakInFieldMode
                            ? const Color(0xFF86EFAC)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _autoSpeakInFieldMode
                          ? Icons.record_voice_over_rounded
                          : Icons.voice_over_off_rounded,
                      size: 17,
                      color: _autoSpeakInFieldMode
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppStrings.tr(
                      lang: _lang,
                      uz: 'Avto-ovoz',
                      ru: 'Авто-речь',
                      en: 'Auto-Voice',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _autoSpeakInFieldMode
                          ? const Color(0xFF15803D)
                          : AppTheme.textSecondary,
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
        'label': AppStrings.tr(
          lang: _lang,
          uz: '$day-kun harorat me\'yori',
          ru: 'Норма тепла на $day-й день',
          en: 'Day $day temp norm',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: "$day-kunda xona harorati qanday bo'lishi kerak?",
          ru: 'Какая должна быть температура в птичнике на $day-й день?',
          en: 'What should the barn temperature be on day $day?',
        ),
      },
      {
        'icon': Icons.trending_up_rounded,
        'label': AppStrings.tr(
          lang: _lang,
          uz: 'Vazn va FCR me\'yori',
          ru: 'Вес и конверсия FCR',
          en: 'Weight & FCR norm',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: "$day-kunda broyler etalon vazni va FCR yem konversiyasi qanday bo'lishi kerak?",
          ru: 'Какой эталонный вес бройлеров и конверсия корма FCR на $day-й день?',
          en: 'What is the target broiler weight and FCR feed conversion on day $day?',
        ),
      },
      {
        'icon': Icons.wb_incandescent_rounded,
        'label': AppStrings.tr(
          lang: _lang,
          uz: 'Yorug\'lik va zichlik',
          ru: 'Свет и плотность',
          en: 'Lighting & density',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: "$day-kunda yorug'lik rejimi va 1 kvadrat metrga joylashtirish zichligi qanday?",
          ru: 'Какой режим освещения и плотность посадки на 1 квадратный метр на $day-й день?',
          en: 'What is the lighting schedule and stocking density per square meter on day $day?',
        ),
      },
      {
        'icon': Icons.water_drop_rounded,
        'label': AppStrings.tr(
          lang: _lang,
          uz: 'Suv harorati qanday?',
          ru: 'Температура воды',
          en: 'Water temperature',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: "Jo'jalar uchun suv harorati qanday bo'lishi kerak?",
          ru: 'Какой температуры должна быть вода для цыплят?',
          en: 'What should the drinking water temperature be for chicks?',
        ),
      },
      {
        'icon': Icons.grain_rounded,
        'label': AppStrings.tr(
          lang: _lang,
          uz: 'Yem sarfi me\'yori',
          ru: 'Норма расхода корма',
          en: 'Daily feed norm',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: "$day-kunda jo'jalar uchun yem sarfi qancha?",
          ru: 'Какова суточная норма корма для цыплят на $day-й день?',
          en: 'What is the daily feed requirement for chicks on day $day?',
        ),
      },
      {
        'icon': Icons.air_rounded,
        'label': AppStrings.tr(
          lang: _lang,
          uz: 'Shamollatish qoidalari',
          ru: 'Правила вентиляции',
          en: 'Ventilation rules',
        ),
        'query': AppStrings.tr(
          lang: _lang,
          uz: 'Parrandaxonani shamollatish qoidalari qanday?',
          ru: 'Каковы правила вентиляции птичника?',
          en: 'What are the ventilation rules for the poultry house?',
        ),
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

  /// Premier AI Answer Card with TTS readout & emergency call (full untruncated text)
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
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: 'AgroZen Maslahatchi',
                              ru: 'AgroZen Консультант',
                              en: 'AgroZen Advisor',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
          if (lastAiMessage.riskLevel != RiskLevel.low) ...[
            _buildRiskBadge(lastAiMessage.riskLevel),
            const SizedBox(height: 12),
          ],
          Text(
            _formatMarkdownForDisplay(lastAiMessage.text),
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
                  Flexible(
                    child: Text(
                      "${AppStrings.tr(lang: _lang, uz: 'Veterinar:', ru: 'Ветеринар:', en: 'Vet:')} ${_liveContext!.localVet!['name']}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
        if (_analyzingImagePath != null && _isLoading)
          OrganicImageInspector(
            imagePath: _analyzingImagePath!,
            language: _lang,
            isAnalyzing: true,
          ),

        if (_isLoading && _analyzingImagePath == null)
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
                  text: AppStrings.tr(
                    lang: _lang,
                    uz: "Issiqlik me'yori",
                    ru: 'Норма тепла',
                    en: 'Temperature norm',
                  ),
                  prompt: AppStrings.tr(
                    lang: _lang,
                    uz: "Broylerlar uchun xona harorati qanday bo'lishi kerak?",
                    ru: 'Какая должна быть температура в птичнике для бройлеров?',
                    en: 'What should the barn temperature be for broilers?',
                  ),
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.grass_rounded,
                  text: AppStrings.tr(
                    lang: _lang,
                    uz: 'Kunlik yem miqdori',
                    ru: 'Суточная норма корма',
                    en: 'Daily feed amount',
                  ),
                  prompt: AppStrings.tr(
                    lang: _lang,
                    uz: "Broylerlarga kunlik yem me'yori qancha?",
                    ru: 'Какова суточная норма корма для бройлеров?',
                    en: 'What is the daily feed requirement for broilers?',
                  ),
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.air_rounded,
                  text: AppStrings.tr(
                    lang: _lang,
                    uz: 'Shamollatish qoidalari',
                    ru: 'Правила вентиляции',
                    en: 'Ventilation rules',
                  ),
                  prompt: AppStrings.tr(
                    lang: _lang,
                    uz: 'Parrandaxonani shamollatish qoidalari qanday?',
                    ru: 'Каковы правила вентиляции птичника?',
                    en: 'What are the ventilation rules for the poultry house?',
                  ),
                ),
                const SizedBox(width: 8),
                _buildSuggestionChip(
                  icon: Icons.water_drop_rounded,
                  text: AppStrings.tr(
                    lang: _lang,
                    uz: 'Suv harorati',
                    ru: 'Температура воды',
                    en: 'Water temperature',
                  ),
                  prompt: AppStrings.tr(
                    lang: _lang,
                    uz: "Jo'jalar uchun suv harorati qanday bo'lishi kerak?",
                    ru: 'Какой температуры должна быть вода для цыплят?',
                    en: 'What should the drinking water temperature be for chicks?',
                  ),
                ),
              ],
            ),
          ),

        // Image attachment preview + 1-tap Gemini Vision Scanner before sending
        if (_selectedImagePath != null && !_isLoading)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF86EFAC), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF15803D).withAlpha(18),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImagePath!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 56, height: 56),
                            )
                          : Image.file(
                              File(_selectedImagePath!),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox(width: 56, height: 56),
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
                              uz: 'Gemini Vision AI Skaneri tayyor',
                              ru: 'Сканер Gemini Vision AI готов',
                              en: 'Gemini Vision AI Scanner Ready',
                            ),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.tr(
                              lang: _lang,
                              uz: "Nimani tekshiramiz? Yo'nalishni tanlang:",
                              ru: 'Что проверяем? Выберите категорию:',
                              en: 'What are we checking? Pick a focus:',
                            ),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _selectedImagePath = null),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPhotoFocusChip(
                        id: 'chick',
                        label: AppStrings.tr(
                          lang: _lang,
                          uz: "🐥 Jo'ja sog'lommi?",
                          ru: '🐥 Здоровье цыплёнка',
                          en: '🐥 Chick Health',
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildPhotoFocusChip(
                        id: 'droppings',
                        label: AppStrings.tr(
                          lang: _lang,
                          uz: '💩 Axlat / Ich ketish',
                          ru: '💩 Помёт / Диарея',
                          en: '💩 Droppings',
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildPhotoFocusChip(
                        id: 'litter',
                        label: AppStrings.tr(
                          lang: _lang,
                          uz: "🌾 To'shama namligi",
                          ru: '🌾 Подстилка',
                          en: '🌾 Bedding',
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildPhotoFocusChip(
                        id: 'clustering',
                        label: AppStrings.tr(
                          lang: _lang,
                          uz: "🌡️ Issiq / Sovuq",
                          ru: '🌡️ Тепло / Холод',
                          en: '🌡️ Clustering',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.document_scanner_rounded, size: 18),
                    label: Text(
                      AppStrings.tr(
                        lang: _lang,
                        uz: 'Gemini AI bilan suratni tekshirish',
                        ru: 'Сканировать фото через Gemini AI',
                        en: 'Scan Photo with Gemini AI',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
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
                tooltip: AppStrings.tr(lang: _lang, uz: 'Kamera', ru: 'Камера', en: 'Camera'),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 4),
              _buildInputIconBtn(
                icon: Icons.photo_library_rounded,
                tooltip: AppStrings.tr(lang: _lang, uz: 'Galereya', ru: 'Галерея', en: 'Gallery'),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(width: 4),
              VoiceInputButton(
                isRecording: _isRecording,
                language: _lang,
                onStartRecording: _startVoiceRecording,
                onStopRecording: _stopVoiceRecording,
              ),
              const SizedBox(width: 4),
              _buildInputIconBtn(
                icon: Icons.auto_awesome_rounded,
                tooltip: AppStrings.tr(
                  lang: _lang,
                  uz: 'Savolni boyitish (Prompt Enhancer)',
                  ru: 'Улучшить вопрос (Prompt Enhancer)',
                  en: 'Enhance Prompt',
                ),
                onPressed: _enhanceCurrentInput,
              ),
              const SizedBox(width: 6),
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

  Widget _buildPhotoFocusChip({
    required String id,
    required String label,
  }) {
    final isSelected = _selectedPhotoCategory == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPhotoCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF15803D)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF15803D)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
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
                child: kIsWeb
                    ? Image.network(
                        msg.imagePath!,
                        width: 240,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      )
                    : Image.file(
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
              msg.isUser ? msg.text : _formatMarkdownForDisplay(msg.text),
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
                '${AppStrings.tr(lang: _lang, uz: 'Manba:', ru: 'Источник:', en: 'Source:')} ${msg.source}',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Cleans raw Markdown symbols (`**`, `###`, `---`, `<!-- -->`, and raw table pipes)
  /// into readable structured text while keeping standard `Text` widgets for accessibility and tests.
  String _formatMarkdownForDisplay(String raw) {
    if (raw.isEmpty) return raw;
    var text = raw;
    // Strip HTML comments
    text = text.replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    // Strip horizontal rules
    text = text.replaceAll(RegExp(r'^\s*---+\s*$', multiLine: true), '');
    // Convert markdown headers into clean section titles
    text = text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s+(.+)$', multiLine: true),
      (m) => '▸ ${m.group(1)!.trim()}',
    );
    // Remove markdown table separator rows (e.g., |---|---|)
    text = text.replaceAll(
      RegExp(r'^\s*\|[\s\-:|]+\|\s*$', multiLine: true),
      '',
    );
    // Format markdown table rows into readable dash-separated lines
    text = text.replaceAllMapped(
      RegExp(r'^\s*\|(.+)\|\s*$', multiLine: true),
      (m) {
        final cells = m
            .group(1)!
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        return cells.isEmpty ? '' : '• ${cells.join(' — ')}';
      },
    );
    // Convert markdown bullet points (* or -) into clean bullets
    text = text.replaceAllMapped(
      RegExp(r'^(\s*)[-*]\s+', multiLine: true),
      (m) => '${m.group(1)}• ',
    );
    // Strip bold/italic/code markers
    text = text.replaceAll('**', '');
    text = text.replaceAll('__', '');
    text = text.replaceAll('`', '');
    // Collapse excessive blank lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
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


