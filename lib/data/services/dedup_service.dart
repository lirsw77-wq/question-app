import '../models/question.dart';
import '../models/import_result.dart';
import '../repositories/question_repository.dart';

class DedupService {
  final QuestionRepository _questionRepo;

  DedupService(this._questionRepo);

  Future<DedupReport> deduplicate() async {
    final stopwatch = Stopwatch()..start();

    final allQuestions = await _questionRepo.getAllQuestions();
    final grouped = <String, List<Question>>{};

    for (final q in allQuestions) {
      final key = _normalizeKey(q.content, q.options);
      grouped.putIfAbsent(key, () => []).add(q);
    }

    int duplicateGroups = 0;
    int removed = 0;

    for (final entry in grouped.entries) {
      if (entry.value.length <= 1) continue;
      duplicateGroups++;

      entry.value.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      final duplicates = entry.value.sublist(1);

      for (final dup in duplicates) {
        await _questionRepo.deleteQuestion(dup.id!);
        removed++;
      }
    }

    stopwatch.stop();

    return DedupReport(
      totalScanned: allQuestions.length,
      duplicateGroupsFound: duplicateGroups,
      questionsRemoved: removed,
      duration: stopwatch.elapsed,
    );
  }

  String _normalizeKey(String content, String options) {
    final normalizedContent = content.trim().replaceAll(RegExp(r'\s+'), '');
    final normalizedOptions = options.trim().replaceAll(RegExp(r'\s+'), '');
    return '$normalizedContent||$normalizedOptions';
  }
}
