class ReciteWrongRecord {
  final int? id;
  final String knowledgePoint;
  final String content;
  final int wrongCount;
  final int lastWrongTime;
  final int nextReviewTime;
  final int reviewStage;
  final bool isMastered;

  ReciteWrongRecord({
    this.id,
    required this.knowledgePoint,
    required this.content,
    this.wrongCount = 1,
    required this.lastWrongTime,
    required this.nextReviewTime,
    this.reviewStage = 0,
    this.isMastered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'knowledge_point': knowledgePoint,
      'content': content,
      'wrong_count': wrongCount,
      'last_wrong_time': lastWrongTime,
      'next_review_time': nextReviewTime,
      'review_stage': reviewStage,
      'is_mastered': isMastered ? 1 : 0,
    };
  }

  factory ReciteWrongRecord.fromMap(Map<String, dynamic> map) {
    return ReciteWrongRecord(
      id: map['id'] as int?,
      knowledgePoint: map['knowledge_point'] as String,
      content: map['content'] as String,
      wrongCount: map['wrong_count'] as int? ?? 1,
      lastWrongTime: map['last_wrong_time'] as int,
      nextReviewTime: map['next_review_time'] as int,
      reviewStage: map['review_stage'] as int? ?? 0,
      isMastered: (map['is_mastered'] as int? ?? 0) == 1,
    );
  }

  ReciteWrongRecord copyWith({
    String? knowledgePoint,
    String? content,
    int? wrongCount,
    int? lastWrongTime,
    int? nextReviewTime,
    int? reviewStage,
    bool? isMastered,
  }) {
    return ReciteWrongRecord(
      id: id,
      knowledgePoint: knowledgePoint ?? this.knowledgePoint,
      content: content ?? this.content,
      wrongCount: wrongCount ?? this.wrongCount,
      lastWrongTime: lastWrongTime ?? this.lastWrongTime,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      reviewStage: reviewStage ?? this.reviewStage,
      isMastered: isMastered ?? this.isMastered,
    );
  }
}
