import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/exam_countdown.dart';
import 'database_provider.dart';

final examCountdownsProvider = FutureProvider<List<ExamCountdown>>((ref) async {
  final repo = ref.watch(examCountdownRepositoryProvider);
  return await repo.getVisibleCountdowns();
});

final allCountdownsProvider = FutureProvider<List<ExamCountdown>>((ref) async {
  final repo = ref.watch(examCountdownRepositoryProvider);
  return await repo.getAllCountdowns();
});

final countdownRefreshProvider = StateProvider<int>((ref) => 0);
