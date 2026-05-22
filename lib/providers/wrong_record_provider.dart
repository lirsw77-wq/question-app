import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/wrong_record.dart';
import 'database_provider.dart';

final wrongCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getWrongCount();
});

final dueReviewCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getDueReviewCount();
});

final dueReviewQuestionIdsProvider = FutureProvider<List<int>>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getDueReviewQuestionIds();
});

final unmasteredRecordsProvider = FutureProvider<List<WrongRecord>>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getUnmasteredRecords();
});

final wrongQuestionIdsByModuleProvider = FutureProvider.family<List<int>, String>((ref, module) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getWrongQuestionIdsByModule(module);
});

final wrongStatsByModuleProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getWrongStatsByModule();
});

final knowledgePointStatsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(wrongRecordRepositoryProvider);
  return await repo.getKnowledgePointStats();
});

// State notifier for refreshing wrong records
final wrongRecordRefreshProvider = StateProvider<int>((ref) => 0);
