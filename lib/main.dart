import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'app.dart';

String? _pendingPdfPath;
String? _pendingPdfName;

String? get pendingPdfPath => _pendingPdfPath;
String? get pendingPdfName => _pendingPdfName;

void clearPendingPdf() {
  _pendingPdfPath = null;
  _pendingPdfName = null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 全局错误捕获：Flutter框架错误
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // Release模式下记录日志而非崩溃
      debugPrint('Flutter Error: ${details.exceptionAsString()}');
    }
  };

  // 全局错误捕获：Dart异步异常
  runZonedGuarded<Future<void>>(() async {
    // 自定义 ErrorWidget，防止构建阶段出错显示红屏
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('页面加载出错，请重试',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    };

    tz.initializeTimeZones();

    // Check for sharing intent on Android (wrapped in try-catch for release safety)
    try {
      final files = await ReceiveSharingIntent.instance.getInitialMedia();
      if (files.isNotEmpty) {
        final file = files.first;
        if (file.path.toLowerCase().endsWith('.pdf')) {
          _pendingPdfPath = file.path;
          _pendingPdfName = file.path.split('/').last;
        }
      }
    } catch (_) {
      // Ignore sharing intent errors in release mode
    }

    runApp(const ProviderScope(child: HenanExamApp()));
  }, (error, stackTrace) {
    debugPrint('Uncaught Error: $error');
    debugPrint('Stack Trace: $stackTrace');
  });
}
