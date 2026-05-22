class ImportJob {
  final int? id;
  final String filePath;
  final String fileName;
  final String status; // pending, parsing, importing, completed, failed
  final int totalQuestions;
  final int importedCount;
  final int duplicateCount;
  final int failedCount;
  final String? parsedJson;
  final String? examSource;
  final int createdAt;
  final int updatedAt;

  ImportJob({
    this.id,
    required this.filePath,
    required this.fileName,
    this.status = 'pending',
    this.totalQuestions = 0,
    this.importedCount = 0,
    this.duplicateCount = 0,
    this.failedCount = 0,
    this.parsedJson,
    this.examSource,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'file_path': filePath,
    'file_name': fileName,
    'status': status,
    'total_questions': totalQuestions,
    'imported_count': importedCount,
    'duplicate_count': duplicateCount,
    'failed_count': failedCount,
    'parsed_json': parsedJson,
    'exam_source': examSource,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  factory ImportJob.fromMap(Map<String, dynamic> map) => ImportJob(
    id: map['id'] as int?,
    filePath: map['file_path'] as String,
    fileName: map['file_name'] as String,
    status: map['status'] as String? ?? 'pending',
    totalQuestions: map['total_questions'] as int? ?? 0,
    importedCount: map['imported_count'] as int? ?? 0,
    duplicateCount: map['duplicate_count'] as int? ?? 0,
    failedCount: map['failed_count'] as int? ?? 0,
    parsedJson: map['parsed_json'] as String?,
    examSource: map['exam_source'] as String?,
    createdAt: map['created_at'] as int,
    updatedAt: map['updated_at'] as int,
  );

  ImportJob copyWith({
    int? id,
    String? status,
    int? totalQuestions,
    int? importedCount,
    int? duplicateCount,
    int? failedCount,
    String? parsedJson,
    String? examSource,
  }) => ImportJob(
    id: id ?? this.id,
    filePath: filePath,
    fileName: fileName,
    status: status ?? this.status,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    importedCount: importedCount ?? this.importedCount,
    duplicateCount: duplicateCount ?? this.duplicateCount,
    failedCount: failedCount ?? this.failedCount,
    parsedJson: parsedJson ?? this.parsedJson,
    examSource: examSource ?? this.examSource,
    createdAt: createdAt,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
}
