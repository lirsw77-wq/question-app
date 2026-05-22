import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final notificationInitializedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  await service.init();
  return true;
});
