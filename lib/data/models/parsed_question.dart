import 'dart:convert';
import 'question.dart';

class ParsedQuestion {
  final String content;
  final String type;
  final List<String> options;
  final String answer;
  final String explanation;
  final bool hasError;
  final String? errorReason;

  ParsedQuestion({
    required this.content,
    required this.type,
    required this.options,
    this.answer = '',
    this.explanation = '',
    this.hasError = false,
    this.errorReason,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'type': type,
    'options': options,
    'answer': answer,
    'explanation': explanation,
    'hasError': hasError,
    'errorReason': errorReason,
  };

  factory ParsedQuestion.fromJson(Map<String, dynamic> json) => ParsedQuestion(
    content: json['content'] as String,
    type: json['type'] as String,
    options: List<String>.from(json['options'] as List),
    answer: json['answer'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    hasError: json['hasError'] as bool? ?? false,
    errorReason: json['errorReason'] as String?,
  );

  Question toQuestion({
    required String module,
    required String chapter,
    String source = 'imported',
    String? examSource,
  }) {
    return Question(
      content: content,
      module: module,
      chapter: chapter,
      type: type,
      options: jsonEncode(options),
      answer: answer,
      explanation: explanation,
      difficulty: 3,
      knowledgePoints: '[]',
      source: source,
      examSource: examSource,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
