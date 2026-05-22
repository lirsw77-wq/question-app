import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/current_affair.dart';
import '../data/services/current_affair_service.dart';
import 'database_provider.dart';

final currentAffairServiceProvider = Provider<CurrentAffairService>((ref) {
  final repo = ref.watch(currentAffairRepositoryProvider);
  return CurrentAffairService(repo);
});

final currentAffairCategoryProvider = StateProvider<String>((ref) => '全部');

final currentAffairsProvider = FutureProvider<List<CurrentAffair>>((ref) async {
  final service = ref.watch(currentAffairServiceProvider);
  ref.watch(currentAffairCategoryProvider);
  return await service.fetchHotNews();
});

final favoriteAffairsProvider = FutureProvider<List<CurrentAffair>>((ref) async {
  final repo = ref.watch(currentAffairRepositoryProvider);
  return await repo.getFavorites();
});
