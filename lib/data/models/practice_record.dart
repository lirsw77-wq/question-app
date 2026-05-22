class PracticeRecord {
  final int? id;
  final String mode; // sequential, random, exam, wrong, favorite, review
  final String module;
  final String? chapter;
  final int totalCount;
  final int correctCount;
  final int duration; // seconds
  final int timestamp;

  PracticeRecord({
    this.id,
    required this.mode,
    required this.module,
    this.chapter,
    required this.totalCount,
    required this.correctCount,
    required this.duration,
    required this.timestamp,
  });

  double get accuracy => totalCount > 0 ? correctCount / totalCount : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mode': mode,
      'module': module,
      'chapter': chapter,
      'total_count': totalCount,
      'correct_count': correctCount,
      'duration': duration,
      'timestamp': timestamp,
    };
  }

  factory PracticeRecord.fromMap(Map<String, dynamic> map) {
    return PracticeRecord(
      id: map['id'] as int?,
      mode: map['mode'] as String,
      module: map['module'] as String,
      chapter: map['chapter'] as String?,
      totalCount: map['total_count'] as int,
      correctCount: map['correct_count'] as int,
      duration: map['duration'] as int,
      timestamp: map['timestamp'] as int,
    );
  }
}
