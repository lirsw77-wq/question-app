class Favorite {
  final int? id;
  final int questionId;
  final int createdAt;

  Favorite({
    this.id,
    required this.questionId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question_id': questionId,
      'created_at': createdAt,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      questionId: map['question_id'] as int,
      createdAt: map['created_at'] as int,
    );
  }
}
