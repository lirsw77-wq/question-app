import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:go_router/go_router.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/recite_wrong_record.dart';
import '../../../data/services/multi_ai_service.dart';

class ReciteReviewPage extends ConsumerStatefulWidget {
  const ReciteReviewPage({super.key});

  @override
  ConsumerState<ReciteReviewPage> createState() => _ReciteReviewPageState();
}

class _ReciteReviewPageState extends ConsumerState<ReciteReviewPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _textController = TextEditingController();

  List<ReciteWrongRecord> _records = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isListening = false;
  bool _sttAvailable = false;
  bool _useTextMode = false;
  String _userAnswer = '';
  bool _isEvaluating = false;
  Map<String, dynamic>? _evalResult;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initStt();
    _loadRecords();
  }

  void _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  void _initStt() async {
    try {
      _sttAvailable = await _speech.initialize(
        onError: (error) {
          if (mounted) {
            setState(() => _isListening = false);
            if (!_useTextMode) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('语音识别出错: ${error.errorMsg}，已切换到文字输入')),
              );
              setState(() => _useTextMode = true);
            }
          }
        },
      );
    } catch (e) {
      _sttAvailable = false;
      _useTextMode = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadRecords() async {
    final repo = ref.read(reciteWrongRepositoryProvider);
    final records = await repo.getDueReviewRecords();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _textController.dispose();
    super.dispose();
  }

  void _speakCurrent() {
    if (_records.isEmpty || _currentIndex >= _records.length) return;
    final record = _records[_currentIndex];
    _tts.speak('${record.knowledgePoint}。${record.content}');
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (!_sttAvailable) {
        setState(() => _useTextMode = true);
        return;
      }
      setState(() => _userAnswer = '');
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() => _userAnswer = result.recognizedWords);
          }
        },
        localeId: 'zh_CN',
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _evaluateAnswer() async {
    final answer = _useTextMode ? _textController.text.trim() : _userAnswer.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先作答')),
      );
      return;
    }

    setState(() {
      _isEvaluating = true;
      _evalResult = null;
    });

    final record = _records[_currentIndex];
    final aiService = ref.read(multiAiServiceProvider);

    try {
      final prompt = '''知识点：${record.knowledgePoint}
内容：${record.content}
用户回答：$answer

请判断用户的回答是否正确掌握了这个知识点。请严格按以下JSON格式返回：
{"correct": true或false, "comment": "简短评价和纠正说明"}''';

      final result = await aiService.chat(AiModel.doubao, prompt,
          systemPrompt: '你是一位严格的考试辅导老师。判断学生对知识点的掌握程度。只返回JSON，不要其他内容。');

      String jsonStr = result;
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        jsonStr = result.substring(jsonStart, jsonEnd + 1);
      }
      final parsed = jsonDecode(jsonStr);

      setState(() {
        _evalResult = {
          'correct': parsed['correct'] == true,
          'comment': parsed['comment']?.toString() ?? '',
        };
        _isEvaluating = false;
      });
    } catch (e) {
      setState(() {
        _evalResult = {
          'correct': false,
          'comment': 'AI评估失败: $e',
        };
        _isEvaluating = false;
      });
    }
  }

  void _markCorrect() async {
    final record = _records[_currentIndex];
    await ref.read(reciteWrongRepositoryProvider).markCorrect(record.id!);
    setState(() => _correctCount++);
    _showResultAnimation(true);
  }

  void _markWrong() async {
    final record = _records[_currentIndex];
    await ref.read(reciteWrongRepositoryProvider).markWrongAgain(record.id!);
    setState(() => _wrongCount++);
    _showResultAnimation(false);
  }

  void _showResultAnimation(bool isCorrect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: isCorrect ? const Color(0xFF43A047) : const Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 48,
              ),
              Text(
                isCorrect ? '正确' : '错误',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).pop();
        _nextRecord();
      }
    });
  }

  void _nextRecord() {
    if (_currentIndex + 1 >= _records.length) {
      setState(() => _isCompleted = true);
    } else {
      setState(() {
        _currentIndex++;
        _userAnswer = '';
        _evalResult = null;
        _textController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: Text(
          _isCompleted ? '复习完成' : '背诵复习',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        actions: [
          if (!_isCompleted && _records.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_records.length}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42)))
          : _isCompleted
              ? _buildSummary(theme)
              : _records.isEmpty
                  ? _buildEmpty(theme)
                  : _buildReviewContent(theme),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF43A047)),
          ),
          const SizedBox(height: 16),
          const Text('暂无待复习的背诵内容', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('所有背诵内容已掌握！', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C42),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme) {
    final total = _correctCount + _wrongCount;
    final rate = total > 0 ? (_correctCount / total * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: rate >= 80
                      ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                      : rate >= 60
                          ? [const Color(0xFFFF8C42), const Color(0xFFFFB07C)]
                          : [const Color(0xFFE53935), const Color(0xFFFF7043)],
                ),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$rate%', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('正确率', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('本次复习完成', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _summaryItem('总计', '$total', Colors.grey.shade700),
                const SizedBox(width: 32),
                _summaryItem('正确', '$_correctCount', const Color(0xFF43A047)),
                const SizedBox(width: 32),
                _summaryItem('错误', '$_wrongCount', const Color(0xFFE53935)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('返回错题本', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _buildReviewContent(ThemeData theme) {
    final record = _records[_currentIndex];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _records.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFFF8C42)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),

        // Knowledge point card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7B1FA2).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      record.knowledgePoint,
                      style: const TextStyle(color: Color(0xFF7B1FA2), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _speakCurrent,
                    icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF26A69A)),
                    tooltip: '朗读',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                record.content,
                style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                '已错${record.wrongCount}次  |  复习阶段 ${record.reviewStage}/6',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Answer input section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('口头作答', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  // Toggle voice/text mode
                  GestureDetector(
                    onTap: () => setState(() => _useTextMode = !_useTextMode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _useTextMode ? Icons.keyboard : Icons.mic,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _useTextMode ? '文字模式' : '语音模式',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (_useTextMode) ...[
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: '请输入你对这个知识点的理解...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 4,
                  minLines: 3,
                ),
              ] else ...[
                // Voice input
                GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _isListening
                          ? const Color(0xFFE53935).withValues(alpha: 0.1)
                          : const Color(0xFF26A69A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isListening
                            ? const Color(0xFFE53935).withValues(alpha: 0.3)
                            : const Color(0xFF26A69A).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _isListening ? Icons.stop_circle : Icons.mic,
                          size: 40,
                          color: _isListening ? const Color(0xFFE53935) : const Color(0xFF26A69A),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isListening ? '点击停止' : '点击开始语音作答',
                          style: TextStyle(
                            color: _isListening ? const Color(0xFFE53935) : const Color(0xFF26A69A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_userAnswer.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '识别结果: $_userAnswer',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Evaluate button
        if (_evalResult == null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isEvaluating ? null : _evaluateAnswer,
              icon: _isEvaluating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_awesome),
              label: Text(_isEvaluating ? 'AI评估中...' : 'AI评估答案'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C6BC0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],

        // Evaluation result
        if (_evalResult != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (_evalResult!['correct'] as bool)
                  ? const Color(0xFF43A047).withValues(alpha: 0.08)
                  : const Color(0xFFE53935).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (_evalResult!['correct'] as bool)
                    ? const Color(0xFF43A047).withValues(alpha: 0.3)
                    : const Color(0xFFE53935).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      (_evalResult!['correct'] as bool) ? Icons.check_circle : Icons.cancel,
                      color: (_evalResult!['correct'] as bool) ? const Color(0xFF43A047) : const Color(0xFFE53935),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (_evalResult!['correct'] as bool) ? '回答正确' : '回答有误',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (_evalResult!['correct'] as bool) ? const Color(0xFF43A047) : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _evalResult!['comment']?.toString() ?? '',
                  style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Manual override buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markCorrect,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('答对了'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _markWrong,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('答错了'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
