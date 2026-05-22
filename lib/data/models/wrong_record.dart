class WrongRecord {
  final int? id;
  final int questionId;
  final int wrongCount;
  final int lastWrongTime; // timestamp ms
  final int nextReviewTime; // timestamp ms
  final int reviewStage; // 0-5
  final bool isMastered;

  WrongRecord({
    this.id,
    required this.questionId,
    this.wrongCount = 1,
    required this.lastWrongTime,
    required this.nextReviewTime,
    this.reviewStage = 0,
    this.isMastered = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'wrong_count': wrongCount,
      'last_wrong_time': lastWrongTime,
      'next_review_time': nextReviewTime,
      'review_stage': reviewStage,
      'is_mastered': isMastered ? 1 : 0,
    };
  }

  factory WrongRecord.fromMap(Map<String, dynamic> map) {
    return WrongRecord(
      id: map['id'] as int?,
      questionId: map['question_id'] as int,
      wrongCount: map['wrong_count'] as int? ?? 1,
      lastWrongTime: map['last_wrong_time'] as int,
      nextReviewTime: map['next_review_time'] as int,
      reviewStage: map['review_stage'] as int? ?? 0,
      isMastered: (map['is_mastered'] as int? ?? 0) == 1,
    );
  }

  WrongRecord copyWith({
    int? wrongCount,
    int? lastWrongTime,
    int? nextReviewTime,
    int? reviewStage,
    bool? isMastered,
  }) {
    return WrongRecord(
      id: id,
      questionId: questionId,
      wrongCount: wrongCount ?? this.wrongCount,
      lastWrongTime: lastWrongTime ?? this.lastWrongTime,
      nextReviewTime: nextReviewTime ?? this.nextReviewTime,
      reviewStage: reviewStage ?? this.reviewStage,
      isMastered: isMastered ?? this.isMastered,
    );
  }
}
