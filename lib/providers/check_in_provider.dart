import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/check_in_record.dart';
import 'database_provider.dart';

final todayCheckInProvider = FutureProvider<CheckInRecord?>((ref) async {
  final repo = ref.watch(checkInRepositoryProvider);
  return await repo.getTodayRecord();
});


final checkInTodayStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(checkInRepositoryProvider);
  return await repo.getTodayStats();
});

final checkInConsecutiveDaysProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(checkInRepositoryProvider);
  return await repo.getConsecutiveDays();
});

final monthCheckInProvider = FutureProvider.family<List<CheckInRecord>, ({int year, int month})>((ref, params) async {
  final repo = ref.watch(checkInRepositoryProvider);
  return await repo.getMonthRecords(params.year, params.month);
});

final checkInRefreshProvider = StateProvider<int>((ref) => 0);
