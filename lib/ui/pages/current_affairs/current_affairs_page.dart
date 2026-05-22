import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';
import '../../../providers/current_affair_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/current_affair.dart';
import '../../../data/services/multi_ai_service.dart';

class CurrentAffairsPage extends ConsumerStatefulWidget {
  const CurrentAffairsPage({super.key});

  @override
  ConsumerState<CurrentAffairsPage> createState() => _CurrentAffairsPageState();
}

class _CurrentAffairsPageState extends ConsumerState<CurrentAffairsPage> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;
  double _ttsSpeed = 0.5;
  bool _isLooping = false;
  CurrentAffair? _currentSpeakingAffair;

  static const Map<String, Color> _keywordColors = {
    '政治': Color(0xFFE53935),
    '经济': Color(0xFFFF8C42),
    '法律': Color(0xFF5C6BC0),
    '科技': Color(0xFF26A69A),
    '教育': Color(0xFF43A047),
    '社会': Color(0xFF7B1FA2),
    '民生': Color(0xFF00897B),
    '改革': Color(0xFFD84315),
    '发展': Color(0xFF1565C0),
    '政策': Color(0xFF6A1B9A),
    '法规': Color(0xFF283593),
    '考试': Color(0xFFEF6C00),
    '高频考点': Color(0xFFC62828),
  };

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(_ttsSpeed);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        if (_isLooping && _currentSpeakingAffair != null) {
          _tts.speak('${_currentSpeakingAffair!.title}。${_currentSpeakingAffair!.content}');
        } else {
          setState(() {
            _isSpeaking = false;
            _currentSpeakingAffair = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCategory = ref.watch(currentAffairCategoryProvider);
    final affairs = ref.watch(currentAffairsProvider);
    final service = ref.watch(currentAffairServiceProvider);
    final categories = service.getCategories();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('时政热点', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        actions: [
          if (_isSpeaking) ...[
            IconButton(
              icon: Icon(
                _isLooping ? Icons.repeat_one : Icons.repeat,
                color: _isLooping ? const Color(0xFF26A69A) : Colors.grey,
              ),
              onPressed: () => setState(() => _isLooping = !_isLooping),
              tooltip: _isLooping ? '关闭循环' : '开启循环',
            ),
            PopupMenuButton<double>(
              icon: const Icon(Icons.speed, color: Color(0xFF26A69A)),
              onSelected: (speed) {
                setState(() {
                  _ttsSpeed = speed;
                  _tts.setSpeechRate(speed);
                });
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 0.5, child: Text('0.5x')),
                const PopupMenuItem(value: 0.75, child: Text('0.75x')),
                const PopupMenuItem(value: 1.0, child: Text('1.0x')),
                const PopupMenuItem(value: 1.25, child: Text('1.25x')),
                const PopupMenuItem(value: 1.5, child: Text('1.5x')),
              ],
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(currentAffairsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category chips
          Container(
            height: 48,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: ChoiceChip(
                    label: Text(cat, style: TextStyle(fontSize: 13, color: isSelected ? Colors.white : Colors.grey.shade700)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF26A69A),
                    backgroundColor: Colors.grey.shade100,
                    onSelected: (_) {
                      ref.read(currentAffairCategoryProvider.notifier).state = cat;
                      ref.invalidate(currentAffairsProvider);
                    },
                  ),
                );
              },
            ),
          ),
          // News list with date grouping
          Expanded(
            child: affairs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text('加载失败，请检查网络', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(currentAffairsProvider),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('暂无时政新闻', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                }
                final filtered = selectedCategory == '全部'
                    ? list
                    : list.where((a) => a.category == selectedCategory).toList();
                if (filtered.isEmpty) {
                  return Center(child: Text('该分类暂无新闻', style: TextStyle(color: Colors.grey.shade500)));
                }

                // Group by date
                final grouped = _groupByDate(filtered);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(currentAffairsProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final entry = grouped[index];
                      final dateStr = entry.key;
                      final items = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Divider(color: Colors.grey.shade200)),
                              ],
                            ),
                          ),
                          ...items.map((affair) => _buildNewsCard(context, theme, affair)),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MapEntry<String, List<CurrentAffair>>> _groupByDate(List<CurrentAffair> items) {
    final Map<String, List<CurrentAffair>> map = {};
    for (final item in items) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.publishDate);
      final key = DateFormat('yyyy-MM-dd').format(date);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map.entries.toList();
  }

  Widget _buildNewsCard(BuildContext context, ThemeData theme, CurrentAffair affair) {
    final date = DateTime.fromMillisecondsSinceEpoch(affair.publishDate);
    final dateStr = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        ref.read(currentAffairRepositoryProvider).markAsRead(affair.id!);
        _showDetail(context, affair);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _categoryColor(affair.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(affair.category, style: TextStyle(color: _categoryColor(affair.category), fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Text(affair.source, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const Spacer(),
                Text(dateStr, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            _buildHighlightedText(
              affair.title,
              TextStyle(
                fontSize: 15,
                fontWeight: affair.isRead ? FontWeight.normal : FontWeight.w600,
                color: affair.isRead ? Colors.grey.shade600 : Colors.grey.shade800,
              ),
              maxLines: 2,
            ),
            if (affair.content.isNotEmpty && affair.content != affair.title) ...[
              const SizedBox(height: 6),
              _buildHighlightedText(
                affair.content,
                TextStyle(color: Colors.grey.shade500, fontSize: 13),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, TextStyle style, {int? maxLines}) {
    final spans = _highlightKeywords(text, style);
    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  List<TextSpan> _highlightKeywords(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final entry in _keywordColors.entries) {
      final keyword = entry.key;
      final color = entry.value;
      int start = 0;
      while (true) {
        final idx = text.indexOf(keyword, start);
        if (idx == -1) break;
        if (idx > lastEnd) {
          spans.add(TextSpan(text: text.substring(lastEnd, idx), style: baseStyle));
        }
        spans.add(TextSpan(
          text: keyword,
          style: baseStyle.copyWith(color: color, fontWeight: FontWeight.bold),
        ));
        lastEnd = idx + keyword.length;
        start = idx + 1;
      }
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: baseStyle));
    }

    return spans;
  }

  void _showDetail(BuildContext context, CurrentAffair affair) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => _DetailSheet(
          affair: affair,
          scrollController: scrollController,
          tts: _tts,
          keywordColors: _keywordColors,
          categoryColor: _categoryColor(affair.category),
          onToggleSpeech: () => _toggleSpeech(affair),
          isSpeaking: _isSpeaking && _currentSpeakingAffair?.id == affair.id,
          ttsSpeed: _ttsSpeed,
          onSpeedChanged: (speed) => setState(() {
            _ttsSpeed = speed;
            _tts.setSpeechRate(speed);
          }),
          ref: ref,
        ),
      ),
    );
  }

  void _toggleSpeech(CurrentAffair affair) async {
    if (_isSpeaking && _currentSpeakingAffair?.id == affair.id) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
        _currentSpeakingAffair = null;
      });
    } else {
      if (_isSpeaking) await _tts.stop();
      setState(() {
        _isSpeaking = true;
        _currentSpeakingAffair = affair;
      });
      await _tts.setSpeechRate(_ttsSpeed);
      await _tts.speak('${affair.title}。${affair.content}');
    }
  }

  Color _categoryColor(String category) {
    return _keywordColors[category] ?? const Color(0xFF78909C);
  }
}

class _DetailSheet extends StatefulWidget {
  final CurrentAffair affair;
  final ScrollController scrollController;
  final FlutterTts tts;
  final Map<String, Color> keywordColors;
  final Color categoryColor;
  final VoidCallback onToggleSpeech;
  final bool isSpeaking;
  final double ttsSpeed;
  final ValueChanged<double> onSpeedChanged;
  final WidgetRef ref;

  const _DetailSheet({
    required this.affair,
    required this.scrollController,
    required this.tts,
    required this.keywordColors,
    required this.categoryColor,
    required this.onToggleSpeech,
    required this.isSpeaking,
    required this.ttsSpeed,
    required this.onSpeedChanged,
    required this.ref,
  });

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  String? _aiSummary;
  bool _isGeneratingSummary = false;
  Map<String, dynamic>? _examQuestion;
  bool _isGeneratingQuestion = false;

  @override
  Widget build(BuildContext context) {
    final affair = widget.affair;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Title
                Text(affair.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                // Meta
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(affair.category, style: TextStyle(color: widget.categoryColor, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Text(affair.source, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    const Spacer(),
                    Text(
                      '${DateTime.fromMillisecondsSinceEpoch(affair.publishDate).month}-${DateTime.fromMillisecondsSinceEpoch(affair.publishDate).day}',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Content with highlighting
                ..._buildHighlightedContent(affair.content),
                const SizedBox(height: 24),
                // AI Summary
                if (affair.aiSummary != null || _aiSummary != null) ...[
                  _buildAiSummaryCard(affair.aiSummary ?? _aiSummary!),
                  const SizedBox(height: 20),
                ],
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: widget.isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                      label: widget.isSpeaking ? '停止朗读' : '语音朗读',
                      color: const Color(0xFF26A69A),
                      onTap: widget.onToggleSpeech,
                    ),
                    _actionButton(
                      icon: affair.isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                      label: affair.isFavorite ? '已收藏' : '收藏',
                      color: const Color(0xFFFF8C42),
                      onTap: () async {
                        await widget.ref.read(currentAffairRepositoryProvider).toggleFavorite(affair.id!);
                        widget.ref.invalidate(currentAffairsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(affair.isFavorite ? '已取消收藏' : '已收藏')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // TTS speed control
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, size: 18, color: Color(0xFF26A69A)),
                      const SizedBox(width: 8),
                      const Text('语速', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: widget.ttsSpeed,
                          min: 0.3,
                          max: 1.5,
                          divisions: 12,
                          activeColor: const Color(0xFF26A69A),
                          label: '${widget.ttsSpeed.toStringAsFixed(1)}x',
                          onChanged: widget.onSpeedChanged,
                        ),
                      ),
                      Text('${widget.ttsSpeed.toStringAsFixed(1)}x', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // AI buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingSummary ? null : () => _generateSummary(affair),
                        icon: _isGeneratingSummary
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isGeneratingSummary ? '生成中...' : 'AI摘要'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingQuestion ? null : () => _generateExamQuestion(affair),
                        icon: _isGeneratingQuestion
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.quiz, size: 18),
                        label: Text(_isGeneratingQuestion ? '生成中...' : '生成考题'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7B1FA2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                // Generated exam question
                if (_examQuestion != null) ...[
                  const SizedBox(height: 16),
                  _buildExamQuestionCard(_examQuestion!),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildHighlightedContent(String text) {
    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final entry in widget.keywordColors.entries) {
      final keyword = entry.key;
      final color = entry.value;
      int start = 0;
      while (true) {
        final idx = text.indexOf(keyword, start);
        if (idx == -1) break;
        if (idx > lastEnd) {
          spans.add(TextSpan(text: text.substring(lastEnd, idx)));
        }
        spans.add(TextSpan(
          text: keyword,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ));
        lastEnd = idx + keyword.length;
        start = idx + 1;
      }
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }

    return [
      RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
          children: spans,
        ),
      ),
    ];
  }

  Future<void> _generateSummary(CurrentAffair affair) async {
    setState(() => _isGeneratingSummary = true);
    final aiService = widget.ref.read(multiAiServiceProvider);
    try {
      final summary = await aiService.summarizeNews(affair.title, affair.content);
      setState(() {
        _aiSummary = summary;
        _isGeneratingSummary = false;
      });
      // Save to DB
      await widget.ref.read(currentAffairRepositoryProvider).updateAiSummary(affair.id!, summary);
    } catch (e) {
      setState(() => _isGeneratingSummary = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: $e')));
      }
    }
  }

  Future<void> _generateExamQuestion(CurrentAffair affair) async {
    setState(() => _isGeneratingQuestion = true);
    final aiService = widget.ref.read(multiAiServiceProvider);
    try {
      final result = await aiService.chat(
        AiModel.doubao,
        '标题：${affair.title}\n内容：${affair.content}',
        systemPrompt: '''根据以下时政新闻，生成一道公考标准的单选题（4个选项），包含正确答案和解析。
请严格按JSON格式返回：
{
  "question": "题目内容",
  "options": ["A. 选项1", "B. 选项2", "C. 选项3", "D. 选项4"],
  "answer": "A",
  "explanation": "解析内容"
}''',
      );

      String jsonStr = result;
      final jsonStart = result.indexOf('{');
      final jsonEnd = result.lastIndexOf('}');
      if (jsonStart != -1 && jsonEnd != -1) {
        jsonStr = result.substring(jsonStart, jsonEnd + 1);
      }
      final parsed = _parseJson(jsonStr);
      setState(() {
        _examQuestion = parsed;
        _isGeneratingQuestion = false;
      });
    } catch (e) {
      setState(() => _isGeneratingQuestion = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('生成失败: $e')));
      }
    }
  }

  Map<String, dynamic> _parseJson(String jsonStr) {
    // Simple JSON parser for the exam question
    try {
      final decoded = _simpleJsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  dynamic _simpleJsonDecode(String str) {
    // Use dart:convert
    return _decodeJson(str);
  }

  dynamic _decodeJson(String str) {
    try {
      // ignore: import_dart_convert
      return _doDecode(str);
    } catch (_) {
      return {};
    }
  }

  dynamic _doDecode(String str) {
    final cleaned = str.trim();
    if (cleaned.startsWith('{')) {
      final map = <String, dynamic>{};
      final inner = cleaned.substring(1, cleaned.lastIndexOf('}')).trim();
      if (inner.isEmpty) return map;
      // Simple key-value parsing
      final pairs = _splitJsonPairs(inner);
      for (final pair in pairs) {
        final colonIdx = pair.indexOf(':');
        if (colonIdx == -1) continue;
        final key = pair.substring(0, colonIdx).trim().replaceAll('"', '');
        final value = pair.substring(colonIdx + 1).trim();
        if (value.startsWith('[')) {
          final listStr = value.substring(1, value.lastIndexOf(']'));
          map[key] = listStr.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
        } else {
          map[key] = value.replaceAll('"', '');
        }
      }
      return map;
    }
    return {};
  }

  List<String> _splitJsonPairs(String str) {
    final pairs = <String>[];
    final buffer = StringBuffer();
    int depth = 0;
    bool inQuote = false;

    for (int i = 0; i < str.length; i++) {
      final ch = str[i];
      if (ch == '"') inQuote = !inQuote;
      if (!inQuote) {
        if (ch == '{' || ch == '[') depth++;
        if (ch == '}' || ch == ']') depth--;
        if (ch == ',' && depth == 0) {
          pairs.add(buffer.toString());
          buffer.clear();
          continue;
        }
      }
      buffer.write(ch);
    }
    if (buffer.isNotEmpty) pairs.add(buffer.toString());
    return pairs;
  }

  Widget _buildAiSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: Color(0xFF1976D2)),
              SizedBox(width: 6),
              Text('AI摘要', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildExamQuestionCard(Map<String, dynamic> question) {
    final q = question['question']?.toString() ?? '';
    final options = (question['options'] as List?)?.cast<String>() ?? [];
    final answer = question['answer']?.toString() ?? '';
    final explanation = question['explanation']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.quiz, size: 16, color: Color(0xFF7B1FA2)),
              SizedBox(width: 6),
              Text('AI生成考题', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
            ],
          ),
          const SizedBox(height: 10),
          Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.6)),
          const SizedBox(height: 8),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(opt, style: const TextStyle(fontSize: 14, height: 1.5)),
          )),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('正确答案：$answer', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF43A047))),
          ],
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('解析：$explanation', style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
