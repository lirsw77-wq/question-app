import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BaiduOcrService {
  static const String _apiKey = 'uykDtzg0M64BpcrC7IvCvrZ5';
  static const String _secretKey = 'vIofK1QsyjcPtigC0BC6N6NMVtWBN9Qw';
  static const String _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _ocrUrl = 'https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic';

  // 免费额度限制
  static const int _dailyFreeLimit = 50000;

  final Dio _dio = Dio();

  String? _accessToken;
  int _todayUsedCount = 0;
  String _todayDate = '';

  BaiduOcrService() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _loadUsageCount();
  }

  /// 加载今日已使用次数
  Future<void> _loadUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    if (_todayDate != today) {
      _todayDate = today;
      _todayUsedCount = prefs.getInt('ocr_used_$today') ?? 0;
    }
  }

  /// 获取今日日期标识
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  /// 保存使用次数
  Future<void> _saveUsageCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ocr_used_${_getTodayKey()}', _todayUsedCount);
  }

  /// 检查是否还有免费额度
  Future<bool> hasFreeQuota() async {
    await _loadUsageCount();
    return _todayUsedCount < _dailyFreeLimit;
  }

  /// 获取剩余免费次数
  Future<int> getRemainingQuota() async {
    await _loadUsageCount();
    return _dailyFreeLimit - _todayUsedCount;
  }

  /// 获取今日已使用次数
  Future<int> getTodayUsedCount() async {
    await _loadUsageCount();
    return _todayUsedCount;
  }

  /// 获取Access Token
  Future<String> _getAccessToken() async {
    if (_accessToken != null) {
      return _accessToken!;
    }

    try {
      final response = await _dio.post(
        _tokenUrl,
        queryParameters: {
          'grant_type': 'client_credentials',
          'client_id': _apiKey,
          'client_secret': _secretKey,
        },
      );

      if (response.statusCode == 200) {
        _accessToken = response.data['access_token'];
        return _accessToken!;
      } else {
        throw Exception('获取Token失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络请求失败: ${e.message}');
    }
  }

  /// 识别图片文字
  /// 返回识别结果列表
  /// 如果返回null表示额度已用完
  Future<List<String>?> recognizeText(String imagePath) async {
    // 检查额度
    if (!await hasFreeQuota()) {
      return null;
    }

    try {
      final token = await _getAccessToken();

      // 读取并压缩图片
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 调用通用文字识别标准版
      final response = await _dio.post(
        _ocrUrl,
        queryParameters: {'access_token': token},
        data: {
          'image': base64Image,
          'language_type': 'CHN_ENG',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // 检查错误码
        if (data['error_code'] != null) {
          final errorCode = data['error_code'];
          if (errorCode == 18) {
            // 额度用尽
            _todayUsedCount = _dailyFreeLimit;
            await _saveUsageCount();
            return null;
          }
          throw Exception('OCR识别失败: ${data['error_msg']}');
        }

        // 更新使用次数
        final wordsResult = data['words_result'] as List? ?? [];
        _todayUsedCount += 1;
        await _saveUsageCount();

        // 提取文字
        return wordsResult.map((item) => item['words'] as String).toList();
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('网络超时，请检查网络连接');
      }
      throw Exception('网络请求失败: ${e.message}');
    }
  }

  /// 批量识别图片（用于PDF导入）
  /// 返回每页识别结果
  /// 如果返回null表示额度已用完
  Future<List<List<String>>?> batchRecognize(
    List<String> imagePaths, {
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <List<String>>[];

    for (int i = 0; i < imagePaths.length; i++) {
      if (!await hasFreeQuota()) {
        return null;
      }

      final result = await recognizeText(imagePaths[i]);
      if (result == null) {
        return null;
      }

      results.add(result);
      onProgress?.call(i + 1, imagePaths.length);

      // 避免请求过快
      if (i < imagePaths.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }
}
