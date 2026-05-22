import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/recite_wrong_record.dart';
import 'database_provider.dart';

final reciteWrongCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(reciteWrongRepositoryProvider);
  return await repo.getUnmasteredCount();
});

final reciteDueReviewCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(reciteWrongRepositoryProvider);
  return await repo.getDueReviewCount();
});

final reciteWrongRecordsProvider = FutureProvider<List<ReciteWrongRecord>>((ref) async {
  final repo = ref.watch(reciteWrongRepositoryProvider);
  return await repo.getUnmasteredRecords();
});

final reciteDueReviewRecordsProvider = FutureProvider<List<ReciteWrongRecord>>((ref) async {
  final repo = ref.watch(reciteWrongRepositoryProvider);
  return await repo.getDueReviewRecords();
});

final reciteWrongStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(reciteWrongRepositoryProvider);
  return await repo.getStatsByKnowledgePoint();
});
