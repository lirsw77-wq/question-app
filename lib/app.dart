import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/database_provider.dart';
import 'providers/notification_provider.dart';
import 'main.dart' as main_app;

class HenanExamApp extends ConsumerStatefulWidget {
  const HenanExamApp({super.key});

  @override
  ConsumerState<HenanExamApp> createState() => _HenanExamAppState();
}

class _HenanExamAppState extends ConsumerState<HenanExamApp> {
  bool _intentHandled = false;

  @override
  void initState() {
    super.initState();
    // Initialize notifications and schedule daily reminders
    _initNotifications();
  }

  void _initNotifications() async {
    try {
      await ref.read(notificationInitializedProvider.future);
      final service = ref.read(notificationServiceProvider);
      await service.scheduleDailyReciteReminder();
      await service.scheduleDailyCurrentAffairsReminder();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final dbInit = ref.watch(databaseInitializedProvider);

    return dbInit.when(
      loading: () => MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在初始化题库...'),
              ],
            ),
          ),
        ),
      ),
      error: (e, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(child: Text('初始化失败: $e')),
        ),
      ),
      data: (_) {
        // Navigate to PDF import if opened via intent
        if (!_intentHandled) {
          _intentHandled = true;
          final pdfPath = main_app.pendingPdfPath;
          if (pdfPath != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final fileName = main_app.pendingPdfName ?? 'imported.pdf';
              main_app.clearPendingPdf();
              goRouter.push('/manage/pdf-import', extra: {'filePath': pdfPath, 'fileName': fileName});
            });
          }
        }

        return MaterialApp.router(
          title: '河南事业单位刷题',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          routerConfig: goRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
