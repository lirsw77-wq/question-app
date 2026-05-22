class CheckInRecord {
  final int? id;
  final String date; // YYYY-MM-DD格式
  final int studyDuration; // 学习时长（秒）
  final int practiceCount; // 刷题数量
  final int reciteCount; // 背诵数量
  final bool isChecked;
  final int createdAt;

  CheckInRecord({
    this.id,
    required this.date,
    this.studyDuration = 0,
    this.practiceCount = 0,
    this.reciteCount = 0,
    this.isChecked = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'study_duration': studyDuration,
      'practice_count': practiceCount,
      'recite_count': reciteCount,
      'is_checked': isChecked ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory CheckInRecord.fromMap(Map<String, dynamic> map) {
    return CheckInRecord(
      id: map['id'] as int?,
      date: map['date'] as String,
      studyDuration: map['study_duration'] as int? ?? 0,
      practiceCount: map['practice_count'] as int? ?? 0,
      reciteCount: map['recite_count'] as int? ?? 0,
      isChecked: (map['is_checked'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  CheckInRecord copyWith({
    int? id,
    String? date,
    int? studyDuration,
    int? practiceCount,
    int? reciteCount,
    bool? isChecked,
    int? createdAt,
  }) {
    return CheckInRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      studyDuration: studyDuration ?? this.studyDuration,
      practiceCount: practiceCount ?? this.practiceCount,
      reciteCount: reciteCount ?? this.reciteCount,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
