import 'package:flutter/material.dart';
import 'package:agrozen/config/constants.dart';
import 'package:agrozen/config/supabase_config.dart';
import 'package:agrozen/data/providers/ai_provider.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/voice_input_button.dart';
import 'package:agrozen/services/daily_counters.dart';
import 'package:agrozen/services/local_rag.dart';
import 'package:agrozen/services/voice_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? source;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.source,
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

  final List<ChatMessage> _messages = [];
  String _lang = 'uz';
  int _remainingQuestions = 30;
  bool _isLoading = false;
  bool _isRecording = false;

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

    // Add initial welcome message
    final isRu = _lang == 'ru';
    _messages.add(
      ChatMessage(
        text: isRu
            ? 'Здравствуйте! Я ваш ИИ-помощник по выращиванию бройлеров AgroZen. '
              'Задавайте любые вопросы по температуре, кормам, вентиляции или вакцинации.'
            : "Assalomu alaykum! Men AgroZen broyler yetishtirish bo'yicha aqlli yordamchingizman. "
              "Harorat, yem, shamollatish yoki emlash bo'yicha istalgan savolingizni bering.",
        isUser: false,
        source: isRu ? 'База знаний AgroZen' : 'AgroZen bilimlar bazasi',
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

  /// Begins microphone capture. Permission outcome is surfaced; nothing is
  /// sent anywhere yet.
  Future<void> _startVoiceRecording() async {
    final isRu = _lang == 'ru';
    try {
      final path = await _voice.startRecording();
      _recordingPath = path;
      if (!mounted) return;
      setState(() => _isRecording = true);
      _showSnack(isRu ? 'Говорите... (Запись голоса)' : 'Gapiring... (Ovoz yozilmoqda)');
    } on VoiceUnavailable catch (e) {
      if (!mounted) return;
      if (e.reason == VoiceUnavailableReason.permissionDenied) {
        _showSnack(
          isRu
              ? 'Нет доступа к микрофону. Разрешите доступ в настройках телефона и попробуйте ещё раз.'
              : "Mikrofonga ruxsat berilmagan. Telefon sozlamalaridan ruxsat bering va qayta urining.",
          isError: true,
        );
      } else {
        _showSnack(
          isRu ? 'Запись недоступна. Напишите вопрос текстом.' : 'Yozib olish imkonsiz. Savolni matn bilan yozing.',
          isError: true,
        );
      }
    }
  }

  /// Stops capture, transcribes through the backend, and asks the transcript.
  /// NEVER fabricates text: on any failure the farmer is told to type.
  Future<void> _stopVoiceRecording() async {
    final isRu = _lang == 'ru';
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
        isRu ? 'Запись не удалась. Напишите вопрос текстом.' : 'Yozuv amalga oshmadi. Savolni matn bilan yozing.',
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
            isRu
                ? 'Голосовой ввод ещё не подключён к серверу. Пожалуйста, напишите вопрос текстом.'
                : "Ovozli kiritish hali serverga ulanmagan. Iltimos, savolni matn bilan yozing.",
            isError: true,
          );
        case VoiceUnavailableReason.noAudio:
        case VoiceUnavailableReason.transcribeFailed:
        case VoiceUnavailableReason.permissionDenied:
          _showSnack(
            isRu ? 'Не удалось распознать речь. Напишите вопрос текстом.' : "Nutqni aniqlab bo'lmadi. Savolni matn bilan yozing.",
            isError: true,
          );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _voiceService?.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? overrideText]) async {
    final text = (overrideText ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    if (_remainingQuestions <= 0) {
      final isRu = _lang == 'ru';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRu
                ? 'Дневной лимит вопросов (30) исчерпан. Попробуйте завтра!'
                : "Kunlik savollar limiti (30) tugadi. Ertaga davom ettiring!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
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

    // RAG: server-side Gemini when configured, offline knowledge base
    // otherwise. Never invents — if nothing matches, we say so.
    final isRu = _lang == 'ru';
    late final String answer;
    late final String source;

    final rag = LocalRag(_knowledgeRepo);

    if (rag.wantsMedicine(text)) {
      // Safety rule #2: never prescribe drugs or dosages, always refer.
      answer = rag.medicineRefusal(_lang);
      source = isRu ? 'Ветеринарные правила' : 'Veterinariya qoidalari';
    } else if (rag.looksLikeEmergency(text)) {
      // Emergency phrasing gets the safety script + a vet, not a generic answer.
      answer = isRu
          ? 'Похоже на экстренную ситуацию. Не ждите и не лечите птицу самостоятельно:\n\n'
              '1. Изолируйте заболевших птиц от здоровых.\n'
              '2. Прекратите вывоз и продажу птицы.\n'
              '3. Немедленно позвоните ветеринару вашего района — контакты на экране Дневника.\n\n'
              'AgroZen не ставит диагнозы и не назначает лекарства.'
          : "Shoshilinch holatga o'xshaydi. Kutmang va parrandani o'zingiz davolamang:\n\n"
              "1. Kasal parrandani sog'lomlaridan ajrating.\n"
              "2. Parrandani tashqariga chiqarishni to'xtating.\n"
              "3. Darhol tumaningiz veterinariiga qo'ng'iroq qiling — kontaktlar Kundalik ekranida.\n\n"
              "AgroZen tashxis qo'ymaydi va dori buyurmadi.";
      source = isRu ? 'Экстренная помощь' : 'Favqulodda yordam';
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
        // Cloud model only when there is no local hit AND the backend exists.
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
          answer = _noAnswerMessage(isRu);
          source = isRu ? 'АгроЗен: нет данных' : "AgroZen: ma'lumot yo'q";
        }
      } else {
        // Honest "I don't know" per the safety rule.
        answer = _noAnswerMessage(isRu);
        source = isRu ? 'АгроЗен: нет данных' : "AgroZen: ma'lumot yo'q";
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

  static String _noAnswerMessage(bool isRu) => isRu
      ? 'Я не нашёл ответа на этот вопрос в проверенной базе знаний. '
          'Пожалуйста, обратитесь к ветеринару вашего района — я не буду придумывать.'
      : "Bu savol bo'yicha tekshirilgan bazada javob topa olmadim. "
          "Iltimos, tumaningiz veterinariiga murojaat qiling — men o'ylab topmayman.";

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
    final isRu = _lang == 'ru';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isRu ? 'ИИ Помощник AgroZen' : 'AgroZen AI Yordamchi', style: const TextStyle(fontSize: 16)),
            Text(
              isRu ? 'Осталось: $_remainingQuestions/30 сегодня' : 'Bugun qoldi: $_remainingQuestions/30',
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
                      isRu ? 'AgroZen думает...' : 'AgroZen javob tayyorlamoqda...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),

            // Input Bar with Voice & Text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                  VoiceInputButton(
                    isRecording: _isRecording,
                    language: _lang,
                    onStartRecording: _startVoiceRecording,
                    onStopRecording: _stopVoiceRecording,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: isRu ? 'Задайте вопрос...' : 'Savol yozing...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const SizedBox(width: 6),
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
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            if (msg.source != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: msg.isUser ? Colors.white70 : Colors.green.shade800,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Manba: ${msg.source}',
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 11,
                        color: msg.isUser ? Colors.white70 : Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
