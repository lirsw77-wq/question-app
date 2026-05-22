import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/question.dart';
import 'database_provider.dart';

final questionsByModuleProvider = FutureProvider.family<List<Question>, String>((ref, module) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getQuestionsByModule(module);
});

final questionsByChapterProvider = FutureProvider.family<List<Question>, ({String module, String chapter})>((ref, params) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getQuestionsByChapter(params.module, params.chapter);
});

final randomQuestionsProvider = FutureProvider.family<List<Question>, ({String module, int count, String? chapter})>((ref, params) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getRandomQuestions(params.module, params.count, chapter: params.chapter);
});

final questionByIdProvider = FutureProvider.family<Question?, int>((ref, id) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getQuestionById(id);
});

final similarQuestionsProvider = FutureProvider.family<List<Question>, ({Question question, int count})>((ref, params) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getSimilarQuestions(params.question, params.count);
});

final questionCountProvider = FutureProvider.family<int, ({String module, String? chapter})>((ref, params) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getQuestionCount(params.module, chapter: params.chapter);
});

final chapterStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, module) async {
  final repo = ref.watch(questionRepositoryProvider);
  return await repo.getChapterStats(module);
});
