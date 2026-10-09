import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

abstract class AiProvider {
  Future<AiResponse> askQuestion({
    required String question,
    required String language,
    required List<String> relevantTopicContents,
    required List<String> topicNames,
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
  final SupabaseClient _client;

  GeminiAiProvider({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  @override
  Future<AiResponse> askQuestion({
    required String question,
    required String language,
    required List<String> relevantTopicContents,
    required List<String> topicNames,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'ask-question',
        body: {
          'question': question,
          'language': language,
          'relevant_topic_contents': relevantTopicContents,
          'topic_names': topicNames,
        },
      );

      if (response.status != 200) {
        throw Exception(
          'Failed to get response from AI assistant. Status: ${response.status}',
        );
      }

      final dynamic data = response.data;
      if (data == null) {
        throw Exception('Empty response received from AI service.');
      }

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

      final answer = parsedData['answer']?.toString() ?? '';
      final rawSources = parsedData['sources_used'] ??
          parsedData['sourcesUsed'] ??
          topicNames;
      final sources = (rawSources as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[];

      return AiResponse(
        answer: answer,
        sourcesUsed: sources,
      );
    } on FunctionException catch (e) {
      throw Exception('AI function error: ${e.details ?? e.reasonPhrase}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unexpected error querying AI assistant: $e');
    }
  }
}
