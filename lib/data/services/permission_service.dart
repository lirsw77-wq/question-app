import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// 检查并请求相机权限
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, '相机权限', '拍照识题需要使用相机权限，请在设置中开启');
      }
      return false;
    }

    final result = await Permission.camera.request();
    if (result.isGranted) {
      return true;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('需要相机权限才能拍照识题'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    return false;
  }

  /// 检查并请求存储权限
  static Future<bool> requestStoragePermission(BuildContext context) async {
    // Android 13+ 使用 READ_MEDIA_IMAGES
    if (await Permission.photos.status.isGranted ||
        await Permission.storage.status.isGranted) {
      return true;
    }

    // 尝试请求 photos 权限 (Android 13+)
    var result = await Permission.photos.request();

    // 如果 photos 权限不可用，尝试 storage 权限
    if (!result.isGranted) {
      result = await Permission.storage.request();
    }

    if (result.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, '存储权限', '导入文件需要存储权限，请在设置中开启');
      }
      return false;
    }

    return result.isGranted;
  }

  /// 显示跳转设置弹窗
  static void _showSettingsDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 显示网络不可用提示
  static void showNetworkError(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('网络不可用'),
        content: const Text('该功能需要网络连接，请检查网络设置后重试'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
