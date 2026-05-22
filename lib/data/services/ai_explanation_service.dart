import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';

class AiExplanationService {
  static const String _apiKeyPref = 'ai_api_key';
  static const String _apiUrlPref = 'ai_api_url';
  static const String _apiProviderPref = 'ai_api_provider';
  static const String _enabledPref = 'ai_enabled';

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledPref) ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledPref, enabled);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, key);
  }

  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlPref) ?? 'https://api.deepseek.com/v1/chat/completions';
  }

  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlPref, url);
  }

  Future<String> getApiProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiProviderPref) ?? 'deepseek';
  }

  Future<void> setApiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiProviderPref, provider);
  }

  Future<String?> getAiExplanation(Question question) async {
    // Try local prebuilt explanation first
    if (question.aiExplanation != null && question.aiExplanation!.isNotEmpty) {
      return question.aiExplanation;
    }

    // Check if AI is enabled and configured
    final enabled = await isEnabled();
    if (!enabled) return null;

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final apiUrl = await getApiUrl();
      final prompt = _buildPrompt(question);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '你是一名事业单位考试辅导老师，擅长清晰地讲解题目。请用中文回答，格式清晰，包含：1.解题思路 2.正确答案分析 3.错误选项分析 4.相关知识点。',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
    } catch (_) {
      // Network error, return null
    }
    return null;
  }

  String _buildPrompt(Question question) {
    final buffer = StringBuffer();
    buffer.writeln('题型：${_getTypeLabel(question.type)}');
    buffer.writeln('题目：${question.content}');
    final options = question.optionsList;
    if (options.isNotEmpty) {
      buffer.writeln('选项：${options.join(' | ')}');
    }
    buffer.writeln('正确答案：${question.answer}');
    if (question.explanation.isNotEmpty) {
      buffer.writeln('已有解析：${question.explanation}');
    }
    buffer.writeln('\n请给出详细的解题思路讲解。');
    return buffer.toString();
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'single_choice': return '单选题';
      case 'multiple_choice': return '多选题';
      case 'true_false': return '判断题';
      case 'fill_blank': return '填空题';
      case 'essay': return '主观题';
      default: return '未知题型';
    }
  }
}
