import 'dart:io';

class NetworkService {
  /// 检查网络是否可用
  static Future<bool> isNetworkAvailable() async {
    try {
      final result = await InternetAddress.lookup('baidu.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 检查是否为WiFi连接
  static Future<bool> isWifiConnected() async {
    try {
      final result = await InternetAddress.lookup('baidu.com');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
