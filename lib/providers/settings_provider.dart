import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final int examDurationMinutes;
  final int dailyGoalCount;
  final bool aiEnabled;
  final String aiApiKey;
  final String aiApiUrl;
  final String aiProvider;

  SettingsState({
    this.examDurationMinutes = 120,
    this.dailyGoalCount = 50,
    this.aiEnabled = false,
    this.aiApiKey = '',
    this.aiApiUrl = 'https://api.deepseek.com/v1/chat/completions',
    this.aiProvider = 'deepseek',
  });

  SettingsState copyWith({
    int? examDurationMinutes,
    int? dailyGoalCount,
    bool? aiEnabled,
    String? aiApiKey,
    String? aiApiUrl,
    String? aiProvider,
  }) {
    return SettingsState(
      examDurationMinutes: examDurationMinutes ?? this.examDurationMinutes,
      dailyGoalCount: dailyGoalCount ?? this.dailyGoalCount,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiApiUrl: aiApiUrl ?? this.aiApiUrl,
      aiProvider: aiProvider ?? this.aiProvider,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      examDurationMinutes: prefs.getInt('exam_duration') ?? 120,
      dailyGoalCount: prefs.getInt('daily_goal') ?? 50,
      aiEnabled: prefs.getBool('ai_enabled') ?? false,
      aiApiKey: prefs.getString('ai_api_key') ?? '',
      aiApiUrl: prefs.getString('ai_api_url') ?? 'https://api.deepseek.com/v1/chat/completions',
      aiProvider: prefs.getString('ai_provider') ?? 'deepseek',
    );
  }

  Future<void> setExamDuration(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('exam_duration', minutes);
    state = state.copyWith(examDurationMinutes: minutes);
  }

  Future<void> setDailyGoal(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', count);
    state = state.copyWith(dailyGoalCount: count);
  }

  Future<void> setAiEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ai_enabled', enabled);
    state = state.copyWith(aiEnabled: enabled);
  }

  Future<void> setAiApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', key);
    state = state.copyWith(aiApiKey: key);
  }

  Future<void> setAiApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_url', url);
    state = state.copyWith(aiApiUrl: url);
  }

  Future<void> setAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_provider', provider);
    state = state.copyWith(aiProvider: provider);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
