import 'dart:convert';
import 'package:dio/dio.dart';

enum AiModel { doubao, tongyi, zhipu }

class MultiAiService {
  final Dio _dio = Dio();

  static const Map<AiModel, String> _apiKeys = {
    AiModel.doubao: 'ark-0e369a80-e6ef-46f1-9577-2ace0e041e7d-3e895',
    AiModel.tongyi: 'sk-ee33093874774df58474eb80c945bcc2',
    AiModel.zhipu: 'aca5c15657a04dbb89fdbbc8f6540874.jXcGFGuSCWTrU7v6',
  };

  static const Map<AiModel, String> _endpoints = {
    AiModel.doubao: 'https://ark.cn-beijing.volces.com/api/v3/chat/completions',
    AiModel.tongyi: 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
    AiModel.zhipu: 'https://open.bigmodel.cn/api/paas/v4/chat/completions',
  };

  static const Map<AiModel, String> _models = {
    AiModel.doubao: 'doubao-1.5-pro-32k',
    AiModel.tongyi: 'qwen-plus',
    AiModel.zhipu: 'glm-4-flash',
  };

  /// 通用AI对话
  Future<String> chat(AiModel model, String prompt, {String? systemPrompt}) async {
    try {
      final messages = <Map<String, String>>[];
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      }
      messages.add({'role': 'user', 'content': prompt});

      final response = await _dio.post(
        _endpoints[model]!,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_apiKeys[model]}',
          },
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: {
          'model': _models[model],
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2000,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content']?.toString() ?? '无响应内容';
      }
      return '请求失败: ${response.statusCode}';
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '网络超时，请检查网络后重试';
      }
      return '网络错误: ${e.message}';
    } catch (e) {
      return '未知错误: $e';
    }
  }

  /// 题目解析
  Future<String> explainQuestion(String question, String answer, {AiModel? model}) async {
    final selectedModel = model ?? AiModel.doubao;
    final systemPrompt = '你是一位专业的事业单位考试辅导老师。请详细解析以下题目，包括考点分析、解题思路和知识点拓展。使用通俗易懂的语言。';
    return await chat(selectedModel, '题目：$question\n正确答案：$answer', systemPrompt: systemPrompt);
  }

  /// 申论批改
  Future<Map<String, dynamic>> gradeEssay(String title, String content, {AiModel? model}) async {
    final selectedModel = model ?? AiModel.tongyi;
    final systemPrompt = '''你是一位资深的申论阅卷专家。请对以下申论文章进行评分和批改。

评分维度（每项满分20分，总分100分）：
1. 观点立意：观点是否明确、立意是否深刻
2. 论证分析：论证是否充分、分析是否透彻
3. 结构逻辑：结构是否完整、逻辑是否清晰
4. 语言表达：语言是否规范、表达是否流畅
5. 素材运用：素材是否恰当、引用是否准确

请严格按照以下JSON格式返回：
{
  "score": 总分,
  "dimensionScores": {
    "观点立意": 分数,
    "论证分析": 分数,
    "结构逻辑": 分数,
    "语言表达": 分数,
    "素材运用": 分数
  },
  "comment": "总体评价",
  "strengths": ["优点1", "优点2"],
  "improvements": ["改进建议1", "改进建议2"],
  "rewrite": "修改后的段落示例（取文章开头一段进行示范修改）"
}''';

    final result = await chat(selectedModel, '申论题目：$title\n\n考生作答：\n$content', systemPrompt: systemPrompt);

    try {
      // 尝试解析JSON
      String jsonStr = result;
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        jsonStr = result.substring(jsonStart, jsonEnd + 1);
      }
      return jsonDecode(jsonStr);
    } catch (e) {
      return {
        'score': 0,
        'dimensionScores': {},
        'comment': result,
        'strengths': [],
        'improvements': [],
        'rewrite': '',
      };
    }
  }

  /// 错题分析
  Future<String> analyzeWrongQuestions(List<Map<String, String>> questions, {AiModel? model}) async {
    final selectedModel = model ?? AiModel.zhipu;
    final systemPrompt = '你是一位专业的考试辅导老师。请分析以下错题，找出学生的薄弱知识点，并给出针对性的学习建议。';

    final buffer = StringBuffer('以下是我做错的题目，请帮我分析：\n\n');
    for (int i = 0; i < questions.length; i++) {
      buffer.writeln('${i + 1}. ${questions[i]['question']}');
      buffer.writeln('   我的答案：${questions[i]['myAnswer']}');
      buffer.writeln('   正确答案：${questions[i]['correctAnswer']}');
      buffer.writeln();
    }

    return await chat(selectedModel, buffer.toString(), systemPrompt: systemPrompt);
  }

  /// 时政摘要
  Future<String> summarizeNews(String title, String content, {AiModel? model}) async {
    final selectedModel = model ?? AiModel.doubao;
    final systemPrompt = '请用3-5句话概括以下时政新闻的核心要点，突出考试可能考查的知识点。语言简洁明了。';
    return await chat(selectedModel, '标题：$title\n内容：$content', systemPrompt: systemPrompt);
  }

  /// 获取可用模型列表
  List<Map<String, dynamic>> getAvailableModels() {
    return [
      {'id': AiModel.doubao, 'name': '豆包', 'desc': '字节跳动，适合中文理解', 'icon': '🤖'},
      {'id': AiModel.tongyi, 'name': '通义千问', 'desc': '阿里云，擅长分析推理', 'icon': '🧠'},
      {'id': AiModel.zhipu, 'name': '智谱清言', 'desc': '智谱AI，知识渊博', 'icon': '📚'},
    ];
  }
}
