import 'dart:convert';

class Question {
  final int? id;
  final String content;
  final String type; // single_choice, multiple_choice, true_false, fill_blank, essay
  final String options; // JSON array string, e.g. '["A. xxx","B. yyy"]'
  final String answer;
  final String explanation;
  final String? aiExplanation;
  final String knowledgePoints; // JSON array string
  final String module;
  final String chapter;
  final int difficulty; // 1-5
  final String source; // builtin, manual, imported
  final String? examSource; // e.g. "2024年 河南省直事业单位真题"
  final int? createdAt;

  Question({
    this.id,
    required this.content,
    required this.type,
    required this.options,
    required this.answer,
    required this.explanation,
    this.aiExplanation,
    this.knowledgePoints = '[]',
    required this.module,
    required this.chapter,
    this.difficulty = 3,
    this.source = 'builtin',
    this.examSource,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type,
      'options': options,
      'answer': answer,
      'explanation': explanation,
      'ai_explanation': aiExplanation,
      'knowledge_points': knowledgePoints,
      'module': module,
      'chapter': chapter,
      'difficulty': difficulty,
      'source': source,
      'exam_source': examSource,
      'created_at': createdAt,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      content: map['content'] as String,
      type: map['type'] as String,
      options: map['options'] as String,
      answer: map['answer'] as String,
      explanation: map['explanation'] as String? ?? '',
      aiExplanation: map['ai_explanation'] as String?,
      knowledgePoints: map['knowledge_points'] as String? ?? '[]',
      module: map['module'] as String,
      chapter: map['chapter'] as String,
      difficulty: map['difficulty'] as int? ?? 3,
      source: map['source'] as String? ?? 'builtin',
      examSource: map['exam_source'] as String?,
      createdAt: map['created_at'] as int?,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json, String module, String chapter, {String? examSource}) {
    final optionsList = (json['options'] as List).map((e) => e.toString()).toList();
    final kpList = json['knowledge_points'] != null
        ? (json['knowledge_points'] as List).map((e) => e.toString()).toList()
        : [chapter];
    return Question(
      content: json['content'] as String,
      type: json['type'] as String,
      options: jsonEncode(optionsList),
      answer: json['answer'] as String,
      explanation: json['explanation'] as String? ?? '',
      aiExplanation: json['ai_explanation'] as String?,
      knowledgePoints: jsonEncode(kpList),
      module: module,
      chapter: chapter,
      difficulty: json['difficulty'] as int? ?? 3,
      source: 'builtin',
      examSource: examSource,
    );
  }

  List<String> get optionsList {
    try {
      if (options.isEmpty) return [];
      // Try JSON decode first (new format)
      if (options.startsWith('[')) {
        final decoded = jsonDecode(options);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      }
      // Fallback: newline-separated format
      if (options.contains('\n')) {
        return options.split('\n').where((s) => s.trim().isNotEmpty).toList();
      }
      return [options];
    } catch (_) {
      // Fallback for legacy format like "[A. x, B. y]"
      final cleaned = options.replaceAll('[', '').replaceAll(']', '');
      if (cleaned.isEmpty) return [];
      return cleaned.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
    }
  }

  List<String> get knowledgePointsList {
    try {
      if (knowledgePoints.isEmpty) return [];
      if (knowledgePoints.startsWith('[')) {
        final decoded = jsonDecode(knowledgePoints);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      }
      if (knowledgePoints.contains(',')) {
        return knowledgePoints.split(',').where((s) => s.trim().isNotEmpty).toList();
      }
      return knowledgePoints.isEmpty ? [] : [knowledgePoints];
    } catch (_) {
      return [];
    }
  }

  Question copyWith({int? id, String? content, String? module, String? chapter, String? type, String? options, String? answer, String? explanation, String? source, String? examSource}) {
    return Question(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      explanation: explanation ?? this.explanation,
      aiExplanation: aiExplanation,
      knowledgePoints: knowledgePoints,
      module: module ?? this.module,
      chapter: chapter ?? this.chapter,
      difficulty: difficulty,
      source: source ?? this.source,
      examSource: examSource ?? this.examSource,
      createdAt: createdAt,
    );
  }
}
