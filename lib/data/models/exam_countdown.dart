class ExamCountdown {
  final int? id;
  final String name;
  final int examDate; // 毫秒时间戳
  final bool isVisible;
  final int createdAt;

  ExamCountdown({
    this.id,
    required this.name,
    required this.examDate,
    this.isVisible = true,
    required this.createdAt,
  });

  int get daysRemaining {
    final now = DateTime.now();
    final exam = DateTime.fromMillisecondsSinceEpoch(examDate);
    return exam.difference(now).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'exam_date': examDate,
      'is_visible': isVisible ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ExamCountdown.fromMap(Map<String, dynamic> map) {
    return ExamCountdown(
      id: map['id'] as int?,
      name: map['name'] as String,
      examDate: map['exam_date'] as int,
      isVisible: (map['is_visible'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  ExamCountdown copyWith({
    int? id,
    String? name,
    int? examDate,
    bool? isVisible,
    int? createdAt,
  }) {
    return ExamCountdown(
      id: id ?? this.id,
      name: name ?? this.name,
      examDate: examDate ?? this.examDate,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
