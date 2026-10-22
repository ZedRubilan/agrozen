import 'dart:io';
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
import 'package:agrozen/presentation/ui/broiler_photos.dart';
import 'package:agrozen/presentation/ui/components.dart';
import 'package:agrozen/presentation/widgets/agro_icons.dart';
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

class _AskScreenState extends State<AskScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _knowledgeRepo = KnowledgeRepository();
  final _picker = ImagePicker();
  final _visionAnalyzer = PoultryVisionAnalyzer();
  final _ttsService = TtsService();
  final _flockContextService = FlockContextService();
  final _aiProvider = GeminiAiProvider();

  late AnimationController _pulseController;

  final List<ChatMessage> _messages = [];
  String _lang = 'uz';
  int _remainingQuestions = 30;
  bool _isLoading = false;
  bool _isRecording = false;

  /// Read every answer aloud (hands-free use in the barn).
  bool _readAloud = false;
  String _livePartialTranscript = '';
  String? _selectedImagePath;
  String? _analyzingImagePath;
  String _selectedPhotoCategory =
      'chick'; // 'chick', 'droppings', 'litter', 'clustering'
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
    _readAloud = widget.startInFieldMode;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.initialPrompt != null &&
        widget.initialPrompt!.trim().isNotEmpty) {
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
    final resolvedLang =
        prefs.getString('app_language') ?? localeOverride ?? 'uz';
    final context = await _flockContextService.getLiveContext();

    if (!mounted) return;
    setState(() {
      _lang = resolvedLang;
      _remainingQuestions = DailyCounters.getRemainingQuestions(
        prefs,
        maxDailyQuestions: AppConstants.maxDailyQuestions,
      );
      _liveContext = context;
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
    await DailyCounters.setRemainingQuestions(prefs, _remainingQuestions);

    _flockContextService.recordTurn(
      role: 'user',
      text: attachedImage != null
          ? '[SURAT] $effectiveUserText'
          : effectiveUserText,
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
          final historySnippet = _flockContextService
              .getConversationHistorySnippet(effectiveLang);
          final dossierBlock =
              _liveContext?.toPromptContextBlock(effectiveLang) ?? '';
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

    // Hands-free: read the answer aloud when enabled.
    if (_readAloud) {
      _toggleSpeak(answer, effectiveLang);
    }
  }

  static String _noAnswerMessage(String lang) => AppStrings.tr(
    lang: lang,
    uz:
        "Bu savol bo'yicha tekshirilgan bazada aniq javob topa olmadim. "
        "Iltimos, parrandachilik bo'yicha savolingizni biroz aniqlashtirib yozing yoki tumaningiz veterinariga murojaat qiling.",
    ru:
        'Я не нашёл точного ответа на этот вопрос в проверенной базе знаний. '
        'Пожалуйста, уточните ваш вопрос по птицеводству или обратитесь к ветеринару вашего района.',
    en:
        'I could not find a specific answer for that in the verified knowledge base. '
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

  String _t(String uz, String ru, String en) =>
      AppStrings.tr(lang: _lang, uz: uz, ru: ru, en: en);

  void _toggleReadAloud() {
    setState(() => _readAloud = !_readAloud);
    _showSnack(
      _readAloud
          ? _t(
              "Javoblar ovoz bilan o'qiladi",
              'Ответы будут озвучиваться',
              'Answers will be read aloud',
            )
          : _t(
              "Ovozli o'qish o'chirildi",
              'Озвучивание выключено',
              'Reading aloud is off',
            ),
    );
  }

  Future<void> _choosePhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.screen,
            0,
            AppSpace.screen,
            AppSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _t(
                  "Jo'jalar, axlat yoki to'shamani suratga oling",
                  'Сфотографируйте птицу, помёт или подстилку',
                  'Take a photo of birds, droppings or litter',
                ),
                style: AppText.section,
              ),
              const Gap(),
              ListGroup(
                children: [
                  ListRow(
                    icon: Icons.photo_camera_outlined,
                    title: _t('Kamera', 'Камера', 'Camera'),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  ListRow(
                    icon: Icons.photo_library_outlined,
                    tone: Tone.info,
                    title: _t('Galereya', 'Галерея', 'Gallery'),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEmbeddedInPageView ? null : AppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.lg,
                  AppSpace.screen,
                  AppSpace.lg,
                ),
                children: [
                  PageHeader(
                    title: _t(
                      'AgroZen yordamchisi',
                      'Помощник AgroZen',
                      'AgroZen assistant',
                    ),
                    subtitle: _liveContext == null
                        ? null
                        : _t(
                            '${_liveContext!.batchDay}-kun · ${_liveContext!.currentCount} ta parranda',
                            'День ${_liveContext!.batchDay} · ${_liveContext!.currentCount} птиц',
                            'Day ${_liveContext!.batchDay} · ${_liveContext!.currentCount} birds',
                          ),
                    trailing: IconButton(
                      tooltip: _t(
                        "Javoblarni ovoz bilan o'qish",
                        'Озвучивать ответы',
                        'Read answers aloud',
                      ),
                      onPressed: _toggleReadAloud,
                      isSelected: _readAloud,
                      icon: const Icon(
                        Icons.volume_off_outlined,
                        color: AppColors.inkSecondary,
                      ),
                      selectedIcon: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_messages.isEmpty) ...[
                    Text(
                      _t(
                        'Sizga qanday yordam beray?',
                        'Чем вам помочь?',
                        'What would you like help with?',
                      ),
                      style: AppText.section,
                    ),
                    const Gap(AppSpace.sm),
                  ],
                  for (final msg in _messages) _buildMessage(msg),
                  if (_messages.isEmpty && !_isLoading) _buildSuggestions(),
                  if (_isLoading) _buildThinking(),
                ],
              ),
            ),
            if (_selectedImagePath != null && !_isLoading) _buildAttachment(),
            if (_isRecording) _buildRecordingBar(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    final items = <(IconData, String, String)>[
      (
        Icons.thermostat_rounded,
        _t('Bugungi harorat', 'Температура сегодня', "Today's temperature"),
        _t(
          "Bugun binoda harorat qanday bo'lishi kerak?",
          'Какая сегодня должна быть температура в птичнике?',
          'What should the house temperature be today?',
        ),
      ),
      (
        Icons.grain_rounded,
        _t('Yem miqdori', 'Норма корма', 'How much feed'),
        _t(
          'Bugun qancha yem berishim kerak?',
          'Сколько корма давать сегодня?',
          'How much feed should I give today?',
        ),
      ),
      (
        Icons.air_rounded,
        _t('Shamollatish', 'Вентиляция', 'Ventilation'),
        _t(
          'Parrandaxonani qanday shamollatish kerak?',
          'Как правильно проветривать птичник?',
          'How should I ventilate the poultry house?',
        ),
      ),
      (
        Icons.water_drop_outlined,
        _t('Suv', 'Вода', 'Water'),
        _t(
          "Jo'jalar uchun suv harorati qanday bo'lishi kerak?",
          'Какой температуры должна быть вода для цыплят?',
          'What should the drinking water temperature be?',
        ),
      ),
    ];
    final tones = [Tone.warning, Tone.warning, Tone.neutral, Tone.info];
    final tiles = <Widget>[
      for (var i = 0; i < items.length; i++)
        _QuickQuestionTile(
          icon: items[i].$1,
          tone: tones[i % tones.length],
          label: items[i].$2,
          onTap: () => _sendMessage(items[i].$3),
        ),
    ];
    return Reveal(
      index: 1,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpace.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoCheckCard(
              title: _t(
                'Rasmni tekshirish',
                'Проверить по фото',
                'Check a photo',
              ),
              subtitle: _t(
                "Jo'jalar, axlat yoki to'shama",
                'Птица, помёт или подстилка',
                'Birds, droppings or litter',
              ),
              onTap: _choosePhoto,
            ),
            const SizedBox(height: AppSpace.lg),
            Text(
              _t('Tez savollar', 'Быстрые вопросы', 'Quick questions'),
              style: AppText.section,
            ),
            const SizedBox(height: AppSpace.sm),
            ListGroup(children: tiles),
          ],
        ),
      ),
    );
  }

  Widget _buildThinking() {
    final analyzingPhoto = _analyzingImagePath != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          const SizedBox(width: AppSpace.md),
          Text(
            analyzingPhoto
                ? _t(
                    'Rasm tekshirilmoqda…',
                    'Проверяю фото…',
                    'Checking the photo…',
                  )
                : _t(
                    'Javob tayyorlanmoqda…',
                    'Готовлю ответ…',
                    'Preparing an answer…',
                  ),
            style: AppText.bodyMuted,
          ),
        ],
      ),
    );
  }

  Widget _imagePreview(String path, {double size = 64}) {
    final image = kIsWeb
        ? Image.network(
            path,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
          )
        : Image.file(
            File(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: image,
    );
  }

  Widget _buildAttachment() {
    final categories = <String, String>{
      'chick': _t("Jo'ja holati", 'Состояние птицы', 'Bird health'),
      'droppings': _t('Axlat', 'Помёт', 'Droppings'),
      'litter': _t("To'shama", 'Подстилка', 'Litter'),
      'clustering': _t('Joylashuvi', 'Распределение', 'Spread in house'),
    };
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.screen,
        AppSpace.md,
        AppSpace.screen,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _imagePreview(_selectedImagePath!),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    'Nimani tekshiramiz?',
                    'Что проверить?',
                    'What should I check?',
                  ),
                  style: AppText.label,
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in categories.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _selectedPhotoCategory == entry.key,
                        onSelected: (_) =>
                            setState(() => _selectedPhotoCategory = entry.key),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _t("Olib tashlash", 'Убрать', 'Remove'),
            onPressed: () => setState(() => _selectedImagePath = null),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      width: double.infinity,
      color: AppColors.dangerSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.screen,
        vertical: AppSpace.md,
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 0.3,
              end: 1,
            ).animate(_pulseController),
            child: const Icon(
              Icons.fiber_manual_record,
              color: AppColors.danger,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              _livePartialTranscript.isNotEmpty
                  ? _livePartialTranscript
                  : _t(
                      'Gapiring… tugatgach to\'xtatish tugmasini bosing',
                      'Говорите… затем нажмите «стоп»',
                      'Speak… then tap stop',
                    ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final quotaText = AppStrings.tr(
      lang: _lang,
      uz: 'Bugun qoldi: $_remainingQuestions/30',
      ru: 'Осталось: $_remainingQuestions/30 сегодня',
      en: 'Remaining today: $_remainingQuestions/30',
    );
    final hasText = _controller.text.trim().isNotEmpty;
    final canSend = hasText || _selectedImagePath != null;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
        AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            tooltip: _t('Rasm yuborish', 'Отправить фото', 'Send a photo'),
            onPressed: _isLoading || _isRecording ? null : _choosePhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isRecording,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: _t(
                  'Savolingizni yozing…',
                  'Напишите вопрос…',
                  'Type your question…',
                ),
                helperText: quotaText,
                helperStyle: AppText.caption.copyWith(
                  color: _remainingQuestions > 0
                      ? AppColors.inkMuted
                      : AppColors.danger,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          SizedBox(
            width: 48,
            height: 48,
            child: canSend && !_isRecording
                ? IconButton.filled(
                    tooltip: _t('Yuborish', 'Отправить', 'Send'),
                    onPressed: _isLoading ? null : () => _sendMessage(),
                    icon: const Icon(Icons.send_rounded),
                  )
                : IconButton.filled(
                    tooltip: _isRecording
                        ? _t("To'xtatish", 'Стоп', 'Stop')
                        : _t(
                            'Ovoz bilan so\'rash',
                            'Спросить голосом',
                            'Ask by voice',
                          ),
                    style: IconButton.styleFrom(
                      backgroundColor: _isRecording
                          ? AppColors.danger
                          : AppColors.primary,
                    ),
                    onPressed: _isLoading
                        ? null
                        : (_isRecording
                              ? _stopVoiceRecording
                              : _startVoiceRecording),
                    icon: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    final maxWidth = MediaQuery.of(context).size.width * 0.86;
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(
            bottom: AppSpace.md,
            left: AppSpace.xxl,
          ),
          constraints: BoxConstraints(maxWidth: maxWidth),
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.lg),
              topRight: Radius.circular(AppRadius.lg),
              bottomLeft: Radius.circular(AppRadius.lg),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.imagePath != null) ...[
                _imagePreview(msg.imagePath!, size: 160),
                const SizedBox(height: AppSpace.sm),
              ],
              Text(msg.text, style: AppText.body.copyWith(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    final speaking = _speakingText == msg.text;
    final vetPhone = _liveContext?.localVet?['phone']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md, right: AppSpace.lg),
      child: AppCard(
        borderColor: msg.riskLevel == RiskLevel.high ? AppColors.danger : null,
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AgroChickIcon(size: 26),
                const SizedBox(width: AppSpace.sm),
                const Expanded(child: Text('AgroZen', style: AppText.label)),
                TextButton.icon(
                  onPressed: () => _toggleSpeak(msg.text),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                    ),
                  ),
                  icon: Icon(
                    speaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                    size: 18,
                  ),
                  label: Text(
                    speaking
                        ? _t("To'xtatish", 'Стоп', 'Stop')
                        : _t('Tinglash', 'Слушать', 'Listen'),
                  ),
                ),
              ],
            ),
            if (msg.riskLevel != RiskLevel.low) ...[
              const SizedBox(height: AppSpace.xs),
              StatusPill(
                tone: msg.riskLevel == RiskLevel.high
                    ? Tone.danger
                    : Tone.warning,
                icon: msg.riskLevel == RiskLevel.high
                    ? Icons.local_hospital_outlined
                    : Icons.warning_amber_rounded,
                label: msg.riskLevel == RiskLevel.high
                    ? _t('Veterinar kerak', 'Нужен ветеринар', 'See a vet')
                    : _t(
                        "E'tibor bering",
                        'Обратите внимание',
                        'Needs attention',
                      ),
              ),
            ],
            const SizedBox(height: AppSpace.sm),
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.sm),
              child: Text(
                _formatMarkdownForDisplay(msg.text),
                style: AppText.body,
              ),
            ),
            if (msg.source != null && msg.source!.isNotEmpty) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                '${_t('Manba:', 'Источник:', 'Source:')} ${msg.source}',
                style: AppText.caption,
              ),
            ],
            if (msg.riskLevel == RiskLevel.high && vetPhone != null) ...[
              const SizedBox(height: AppSpace.md),
              FilledButton.icon(
                onPressed: _callLocalVet,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(0, 44),
                ),
                icon: const Icon(Icons.phone_in_talk, size: 18),
                label: Text(
                  _t(
                    "Veterinarga qo'ng'iroq",
                    'Позвонить ветеринару',
                    'Call the vet',
                  ),
                ),
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
    text = text.replaceAllMapped(RegExp(r'^\s*\|(.+)\|\s*$', multiLine: true), (
      m,
    ) {
      final cells = m
          .group(1)!
          .split('|')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
      return cells.isEmpty ? '' : '• ${cells.join(' — ')}';
    });
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
}

/// Full-width question row; long translations can wrap.
class _QuickQuestionTile extends StatelessWidget {
  final IconData icon;
  final Tone tone;
  final String label;
  final VoidCallback onTap;
  const _QuickQuestionTile({
    required this.icon,
    required this.tone,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) =>
      ListRow(icon: icon, tone: tone, title: label, onTap: onTap);
}

/// Compact photo entry that opens the camera / gallery sheet.
class _PhotoCheckCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PhotoCheckCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpace.md),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Image.asset(
            BroilerPhotos.chicksCloseup,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                const IconBadge(icon: Icons.photo_camera_outlined, size: 64),
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.cardTitle),
              const Gap(AppSpace.xs),
              Text(subtitle, style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
      ],
    ),
  );
}
