import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';
import '../../services/local_rag.dart';

abstract class AiProvider {
  Future<AiResponse> askQuestion({
    required String question,
    required String language,
    required List<String> relevantTopicContents,
    required List<String> topicNames,
    String? farmerId,
  });
}

class AiResponse extends Equatable {
  final String answer;
  final List<String> sourcesUsed;

  const AiResponse({
    required this.answer,
    required this.sourcesUsed,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final rawSources = json['sources_used'] ?? json['sourcesUsed'] ?? [];
    final sources = (rawSources as List<dynamic>).map((e) => e.toString()).toList();
    final ans = json['answer'] as String? ?? '';
    return AiResponse(answer: ans, sourcesUsed: sources);
  }

  Map<String, dynamic> toJson() => {
        'answer': answer,
        'sources_used': sourcesUsed,
      };

  @override
  List<Object?> get props => [answer, sourcesUsed];
}

class GeminiAiProvider implements AiProvider {
  final SupabaseClient? _customClient;
  final http.Client? httpClient;

  GeminiAiProvider({SupabaseClient? client, this.httpClient})
      : _customClient = client;

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  static const List<String> _staticServerFallbackPrefixes = [
    'based on the agrozen broiler handbook:',
    'на основе регламента бройлеров agrozen:',
    'agrozen broyler reglamentiga muvofiq:',
  ];

  static bool isStaticServerFallback(String answer) {
    final norm = answer.trim().toLowerCase();
    if (norm.isEmpty) return true;
    return _staticServerFallbackPrefixes.any(norm.startsWith);
  }

  static List<String> _humanizeSources(List<String> rawSources, String language) {
    if (rawSources.isEmpty) return const [];
    final mapped = <String>{};
    for (final src in rawSources) {
      final clean = src.trim().replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
      if (clean.isEmpty) continue;
      if (clean == 'norms.json') {
        mapped.add(
          language == 'en'
              ? 'Ross-308 / Cobb-500 Norms'
              : (language == 'ru' ? 'Нормативы Ross-308 / Cobb-500' : "Ross-308 / Cobb-500 me'yorlari"),
        );
      } else {
        mapped.add(LocalRag.titleFor(clean, language));
      }
    }
    return mapped.toList();
  }

  @override
  Future<AiResponse> askQuestion({
    required String question,
    required String language,
    required List<String> relevantTopicContents,
    required List<String> topicNames,
    String? farmerId,
  }) async {
    // 1. Try Supabase Edge Function if configured
    if (_customClient != null || SupabaseConfig.isConfigured) {
      try {
        final response = await _client.functions.invoke(
          'ask-question',
          body: {
            'question': question,
            'language': language,
            'relevant_topic_contents': relevantTopicContents,
            'topic_names': topicNames,
            if (farmerId != null) 'farmer_id': farmerId,
          },
        );

        if (response.status == 200 && response.data != null) {
          final dynamic data = response.data;
          Map<String, dynamic> parsedData;
          if (data is Map<String, dynamic>) {
            parsedData = data;
          } else if (data is String) {
            parsedData = jsonDecode(data) as Map<String, dynamic>;
          } else if (data is Map) {
            parsedData = Map<String, dynamic>.from(data);
          } else {
            throw Exception('Unexpected response format from AI service.');
          }

          final answer = parsedData['answer']?.toString().trim() ?? '';
          final isFallback = parsedData['is_fallback'] == true ||
              isStaticServerFallback(answer);

          if (!isFallback && answer.isNotEmpty) {
            final rawSources = parsedData['sources_used'] ??
                parsedData['sourcesUsed'] ??
                topicNames;
            final sources = (rawSources as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                <String>[];

            return AiResponse(
              answer: answer,
              sourcesUsed: _humanizeSources(sources, language),
            );
          }
        }
      } catch (_) {
        // Fall through to direct Gemini or caller's local RAG fallback
      }
    }

    // 2. Try direct Gemini API if GEMINI_API_KEY is available
    if (SupabaseConfig.hasGeminiKey) {
      final directResponse = await _askDirectGemini(
        question: question,
        language: language,
        relevantTopicContents: relevantTopicContents,
        topicNames: topicNames,
      );
      if (directResponse != null) {
        return directResponse;
      }
    }

    throw Exception('Cloud AI unavailable; falling back to local assistant.');
  }

  Future<AiResponse?> _askDirectGemini({
    required String question,
    required String language,
    required List<String> relevantTopicContents,
    required List<String> topicNames,
  }) async {
    final apiKey = SupabaseConfig.geminiApiKey;
    if (apiKey.isEmpty) return null;

    final lang = language.toLowerCase();
    final systemPrompt = lang == 'en'
        ? 'You are AgroZen, a warm, knowledgeable AI poultry mentor for broiler farmers in Uzbekistan (Ross-308 / Cobb-500). '
            'Respond naturally to greetings, small talk, and questions about the farmer\'s live flock dossier. '
            'For poultry management questions, provide clear, practical, spoken-friendly advice in 2-3 concise paragraphs grounded in the provided guidelines. '
            'Never prescribe antibiotics or medical dosages; always refer disease treatment to the district veterinarian.'
        : (lang == 'ru'
            ? 'Вы AgroZen — дружелюбный и опытный ИИ-наставник по бройлерному птицеводству в Узбекистане (Ross-308 / Cobb-500). '
                'Естественно отвечайте на приветствия, общение и вопросы по текущему досье партии фермера. '
                'По вопросам содержания птицы давайте четкие, практичные ответы в 2-3 абзацах на основе регламента. '
                'Никогда не назначайте антибиотики и дозировки лекарств — направляйте к районному ветеринару.'
            : 'Siz AgroZen — O\'zbekistondagi broyler fermerlari uchun samimiy va tajribali parrandachilik AI maslahatchisisiz (Ross-308 / Cobb-500). '
                'Salomlashish, suhbat va fermerning joriy partiya dosyesi bo\'yicha savollarga tabiiy hamda do\'stona javob bering. '
                'Parrandachilik savollariga berilgan yo\'riqnoma asosida 2-3 ta lo\'nda, amaliy abzasda javob yozing. '
                'Hech qachon mustaqil dori yoki antibiotik dozasini yozmang — veterinarga yo\'naltiring.');

    final contextText = relevantTopicContents.isNotEmpty
        ? 'GUIDELINES CONTEXT:\n${relevantTopicContents.join('\n\n---\n\n')}\n\n'
        : '';

    final client = httpClient ?? http.Client();
    try {
      for (final model in const ['gemini-2.5-flash', 'gemini-2.0-flash']) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        );
        final res = await client
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'system_instruction': {
                  'parts': [
                    {'text': systemPrompt}
                  ],
                },
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': '$contextText$question'}
                    ],
                  }
                ],
                'generationConfig': {
                  'temperature': 0.25,
                  'maxOutputTokens': 900,
                },
              }),
            )
            .timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List<dynamic>?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates.first['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List<dynamic>?;
            final text = parts?.firstOrNull?['text']?.toString().trim() ?? '';
            if (text.isNotEmpty) {
              return AiResponse(
                answer: text,
                sourcesUsed: topicNames.isNotEmpty
                    ? _humanizeSources(topicNames, lang)
                    : [
                        lang == 'en'
                            ? 'AgroZen AI Assistant'
                            : (lang == 'ru' ? 'ИИ Помощник AgroZen' : 'AgroZen AI Maslahatchi')
                      ],
              );
            }
          }
        }
      }
    } catch (_) {
      return null;
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
    return null;
  }
}

