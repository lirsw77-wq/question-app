import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

final totalPracticeCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getTotalPracticeCount();
});

final totalCorrectCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getTotalCorrectCount();
});

final learningDaysProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getLearningDays();
});

final consecutiveDaysProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getConsecutiveDays();
});

final todayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getTodayStats();
});

final accuracyByModuleProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getAccuracyByModule();
});

final dailyStatsProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getDailyStats(days);
});

final weakChaptersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  return await repo.getWeakChapters();
});

final statsRefreshProvider = StateProvider<int>((ref) => 0);
