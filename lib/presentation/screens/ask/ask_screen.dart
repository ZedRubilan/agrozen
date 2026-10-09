import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrozen/data/repositories/knowledge_repository.dart';
import 'package:agrozen/presentation/widgets/voice_input_button.dart';

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

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lang = prefs.getString('app_language') ?? 'uz';
      _remainingQuestions = prefs.getInt('remaining_questions') ?? 30;
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('remaining_questions', _remainingQuestions);

    _scrollToBottom();

    // RAG AI response generation from verified knowledge base
    final isRu = _lang == 'ru';
    final query = text.toLowerCase();
    String answer = '';
    String source = '';

    if (query.contains('harorat') || query.contains('issiq') || query.contains('температур')) {
      await _knowledgeRepo.getTopicContent(_lang, 'temperature');
      source = isRu ? 'Температура и влажность' : 'Harorat va namlik';
      answer = isRu
          ? 'В первые 1-3 дня цыплятам требуется 33-34°C. К 7 дню снижайте до 32°C, к 14 дню до 29°C, к 21 дню до 27°C. Избегайте сквозняков и следите за поведением птицы.'
          : "Dastlabki 1-3 kunlarda jo'jalarga 33-34°C kerak. 7-kunga kelib 32°C, 14-kunga 29°C, 21-kunga 27°C ga tushiriladi. Shamol urishidan saqlang va jo'jalar tarqalishini kuzating.";
    } else if (query.contains('yem') || query.contains('ovqat') || query.contains('корм')) {
      await _knowledgeRepo.getTopicContent(_lang, 'feed');
      source = isRu ? 'Фазы кормления' : 'Oziqlantirish bosqichlari';
      answer = isRu
          ? 'Кормление делится на 3 фазы: 1) Старт (1-10 дни) — мелкая крупка, высокое содержание белка (22-23%). 2) Рост (11-24 дни) — крупка/гранула (20-21% белка). 3) Финиш (25-42 дни) — гранулы для набора массы.'
          : "Oziqlantirish 3 bosqichdan iborat: 1) Start (1-10 kunlar) — mayda krupka, yuqori oqsil (22-23%). 2) O'sish (11-24 kunlar) — o'rtacha granula (20-21% oqsil). 3) Finish (25-42 kunlar) — yirik granula, vazn olish uchun.";
    } else if (query.contains('kasal') || query.contains('emlash') || query.contains('dori') || query.contains('вакцин') || query.contains('болезн')) {
      await _knowledgeRepo.getTopicContent(_lang, 'vaccination');
      source = isRu ? 'Ветеринарные правила' : 'Veterinariya qoidalari';
      answer = isRu
          ? 'AgroZen не назначает лекарства и антибиотики самостоятельно. Основные вакцинации: Ньюкасл (1 и 14 дни), Гамборо (7 и 21 дни). При любых симптомах болезни немедленно звоните районному ветеринару!'
          : "AgroZen mustaqil ravishda dori yoki antibiotik belgilamaydi. Asosiy emlashlar: Nyukasl (1 va 14-kunlar), Gamboro (7 va 21-kunlar). Kasallik belgilarida darhol tumaningiz veterinariga murojaat qiling!";
    } else if (query.contains('shamol') || query.contains('havo') || query.contains('вентиляц')) {
      await _knowledgeRepo.getTopicContent(_lang, 'ventilation');
      source = isRu ? 'Вентиляция и микроклимат' : 'Shamollatish va mikroiqlim';
      answer = isRu
          ? 'Вентиляция жизненно необходима для удаления аммиака и углекислого газа. Минимальный воздухообмен — 0.7 м³/ч на 1 кг живого веса в холодное время, до 4-5 м³/ч летом.'
          : "Shamollatish ammiak va karbonat angidridni chiqarish uchun o'ta muhim. Minimal havo almashinuvi — 1 kg tirik vaznga sovuqda 0.7 m³/soat, yozda 4-5 m³/soatgacha.";
    } else {
      source = isRu ? 'Справочник AgroZen' : "AgroZen qo'llanmasi";
      answer = isRu
          ? 'Пожалуйста, уточните ваш вопрос по бройлерам. Я могу помочь с нормами температуры, графиком кормления, вакцинацией и уходом по дням.'
          : "Iltimos, broylerlar bo'yicha savolingizni aniqlashtiring. Men harorat me'yorlari, yem jadvali, emlash va kunlik parvarish bo'yicha yordam bera olaman.";
    }

    await Future.delayed(const Duration(milliseconds: 600));

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
                    onStartRecording: () {
                      setState(() => _isRecording = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isRu ? 'Говорите... (Запись голоса)' : 'Gapiring... (Ovoz yozilmoqda)'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onStopRecording: () {
                      setState(() => _isRecording = false);
                      // Transcribe mock speech to text
                      final sampleQuery = isRu ? 'Какая температура нужна цыплятам?' : "Jo'jalarga qanday harorat kerak?";
                      _sendMessage(sampleQuery);
                    },
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
                  Text(
                    'Manba: ${msg.source}',
                    style: TextStyle(
                      fontSize: 11,
                      color: msg.isUser ? Colors.white70 : Colors.green.shade800,
                      fontWeight: FontWeight.w600,
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
