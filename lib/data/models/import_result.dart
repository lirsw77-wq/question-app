import 'parsed_question.dart';

class ImportResult {
  final int totalParsed;
  final int imported;
  final int duplicates;
  final int failed;
  final List<ParsedQuestion> failedQuestions;
  final List<ParsedQuestion> unclassifiedQuestions;
  final Duration duration;
  final bool isOcr; // true if OCR was used (scanned PDF)

  ImportResult({
    required this.totalParsed,
    required this.imported,
    required this.duplicates,
    required this.failed,
    this.failedQuestions = const [],
    this.unclassifiedQuestions = const [],
    required this.duration,
    this.isOcr = false,
  });
}

class DedupReport {
  final int totalScanned;
  final int duplicateGroupsFound;
  final int questionsRemoved;
  final Duration duration;

  DedupReport({
    required this.totalScanned,
    required this.duplicateGroupsFound,
    required this.questionsRemoved,
    required this.duration,
  });
}
