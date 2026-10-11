import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/supabase_config.dart';
import '../../../core/localization/app_strings.dart';
import '../../../data/providers/ai_provider.dart';
import '../../../data/repositories/knowledge_repository.dart';
import '../../../services/daily_counters.dart';
import '../../../services/flock_context_service.dart';
import '../../../services/local_rag.dart';
import '../../../services/voice_service.dart';
import 'ask_event.dart';
import 'ask_state.dart';

class AskBloc extends Bloc<AskEvent, AskState> {
  final LocalRag _rag;
  final VoiceService _voiceService;
  final AiProvider _aiProvider;
  final List<Map<String, dynamic>> _messages = [];

  AskBloc({
    KnowledgeRepository? knowledgeRepository,
    LocalRag? rag,
    VoiceService? voiceService,
    AiProvider? aiProvider,
  })  : _rag = rag ?? LocalRag(knowledgeRepository ?? KnowledgeRepository()),
        _voiceService = voiceService ?? VoiceService(),
        _aiProvider = aiProvider ?? GeminiAiProvider(),
        super(const AskInitial()) {
    on<LoadChatHistory>(_onLoadChatHistory);
    on<SendQuestion>(_onSendQuestion);
    on<StartVoiceRecording>(_onStartVoiceRecording);
    on<StopVoiceRecordingAndSend>(_onStopVoiceRecordingAndSend);
  }

  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<AskState> emit,
  ) async {
    try {
      final prefs = await DailyCounters.rolled();
      final remaining = DailyCounters.getRemainingQuestions(prefs);
      emit(AskLoaded(List.unmodifiable(_messages), remaining));
    } catch (e) {
      emit(AskError(e.toString()));
    }
  }

  Future<void> _onSendQuestion(
    SendQuestion event,
    Emitter<AskState> emit,
  ) async {
    final question = event.text.trim();
    if (question.isEmpty) return;

    try {
      final prefs = await DailyCounters.rolled();
      final uiLang = prefs.getString('app_language') ?? 'uz';
      final effectiveLang = LocalRag.detectLanguage(question, fallback: uiLang);
      var remaining = DailyCounters.getRemainingQuestions(prefs);

      if (remaining <= 0) {
        emit(AskError(AppStrings.tr(
          lang: effectiveLang,
          uz: 'Bugungi savollar limiti tugadi (30/30). Ertaga davom etamiz.',
          ru: 'Дневной лимит вопросов исчерпан (30/30). Продолжим завтра.',
          en: 'Daily question limit reached (30/30). Please try again tomorrow.',
        )));
        return;
      }

      _messages.add({
        'role': 'user',
        'text': question,
        'timestamp': DateTime.now().toIso8601String(),
      });
      emit(const AskLoading());

      LiveFlockContext? liveContext;
      try {
        liveContext = await FlockContextService().getLiveContext();
      } catch (_) {}

      String answerText = '';
      List<String> sources = const [];

      if (_rag.wantsMedicine(question)) {
        answerText = _rag.medicineRefusal(effectiveLang);
      } else if (_rag.looksLikeEmergency(question)) {
        answerText = _rag.emergencyMessage(effectiveLang, context: liveContext);
      } else {
        if (SupabaseConfig.isConfigured || SupabaseConfig.hasGeminiKey) {
          try {
            final localTopics = await _rag.getRelevantTopicContext(
              question: question,
              language: effectiveLang,
            );
            final promptWithContext = liveContext != null
                ? '${liveContext.toPromptContextBlock(effectiveLang)}\n$question'
                : question;
            final aiResponse = await _aiProvider.askQuestion(
              question: promptWithContext,
              language: effectiveLang,
              relevantTopicContents: localTopics.contents,
              topicNames: localTopics.titles,
            );
            answerText = aiResponse.answer;
            sources = aiResponse.sourcesUsed;
          } catch (_) {
            // Fall back to LocalRag below
          }
        }

        if (answerText.isEmpty) {
          final ragResult = await _rag.answer(
            question: question,
            language: effectiveLang,
            context: liveContext,
          );
          if (ragResult != null) {
            answerText = ragResult.answer;
            sources = ragResult.sources;
          } else {
            answerText = AppStrings.tr(
              lang: effectiveLang,
              uz: "Ushbu savol bo'yicha bilimlar bazasida aniq ma'lumot topilmadi. Iltimos, parrandachilik bo'yicha savolingizni biroz aniqlashtirib yozing yoki tuman veterinariiga murojaat qiling.",
              ru: 'В проверенной базе знаний нет точного ответа на этот вопрос. Пожалуйста, уточните ваш вопрос по птицеводству или обратитесь к ветеринару вашего района.',
              en: 'No verified answer was found in the knowledge base for this question. Please clarify your poultry question or consult your district veterinarian.',
            );
          }
        }
      }

      remaining = (remaining - 1).clamp(0, 30);
      await DailyCounters.setRemainingQuestions(prefs, remaining);

      _messages.add({
        'role': 'assistant',
        'text': answerText,
        'sources': sources,
        'timestamp': DateTime.now().toIso8601String(),
      });

      emit(AskLoaded(List.unmodifiable(_messages), remaining));
    } catch (e) {
      emit(AskError(e.toString()));
    }
  }

  Future<void> _onStartVoiceRecording(
    StartVoiceRecording event,
    Emitter<AskState> emit,
  ) async {
    try {
      final prefs = await DailyCounters.rolled();
      final lang = prefs.getString('app_language') ?? 'uz';
      await _voiceService.startRecording(language: lang);
      emit(const AskRecording());
    } catch (e) {
      emit(AskError(e.toString()));
    }
  }

  Future<void> _onStopVoiceRecordingAndSend(
    StopVoiceRecordingAndSend event,
    Emitter<AskState> emit,
  ) async {
    emit(const AskTranscribing());
    try {
      final prefs = await DailyCounters.rolled();
      final lang = prefs.getString('app_language') ?? 'uz';
      final transcript = await _voiceService.stopAndTranscribe(language: lang);
      add(SendQuestion(transcript));
    } catch (e) {
      emit(AskError(e.toString()));
    }
  }
}
