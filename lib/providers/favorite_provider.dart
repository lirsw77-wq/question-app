import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';

final favoriteCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return await repo.getFavoriteCount();
});

final favoriteQuestionIdsProvider = FutureProvider.family<List<int>, String?>((ref, module) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return await repo.getFavoriteQuestionIds(module: module);
});

final isFavoriteProvider = FutureProvider.family<bool, int>((ref, questionId) async {
  final repo = ref.watch(favoriteRepositoryProvider);
  return await repo.isFavorite(questionId);
});

final favoriteRefreshProvider = StateProvider<int>((ref) => 0);
