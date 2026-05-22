import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/wrong_record_provider.dart';
import '../../../providers/recite_wrong_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/services/multi_ai_service.dart';

class WrongBookPage extends ConsumerStatefulWidget {
  const WrongBookPage({super.key});

  @override
  ConsumerState<WrongBookPage> createState() => _WrongBookPageState();
}

class _WrongBookPageState extends ConsumerState<WrongBookPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AiModel _selectedAiModel = AiModel.doubao;
  bool _isAnalyzing = false;
  String? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('错题本', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            onPressed: () => context.push('/knowledge-summary'),
            tooltip: '知识点汇总',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFF8C42),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF8C42),
          tabs: const [
            Tab(text: '刷题错题本', icon: Icon(Icons.quiz)),
            Tab(text: '背诵错题本', icon: Icon(Icons.menu_book)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizWrongBook(theme),
          _buildReciteWrongBook(theme),
        ],
      ),
    );
  }

  Widget _buildQuizWrongBook(ThemeData theme) {
    final wrongCount = ref.watch(wrongCountProvider);
    final dueReviewCount = ref.watch(dueReviewCountProvider);
    final wrongStats = ref.watch(wrongStatsByModuleProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _statCard(wrongCount, '错题总数', const Color(0xFFE53935), Icons.error_outline_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(dueReviewCount, '待复习', const Color(0xFFFF8C42), Icons.schedule_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/practice', extra: {
                  'mode': PracticeMode.wrong,
                  'module': '公共基础知识',
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('错题练习'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/review'),
                icon: const Icon(Icons.psychology_rounded),
                label: const Text('智能复习'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C6BC0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Export and AI Analysis buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportWrongQuestions(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('导出错题'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF26A69A),
                  side: const BorderSide(color: Color(0xFF26A69A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnalyzing ? null : () => _analyzeWrongQuestions(),
                icon: _isAnalyzing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 18),
                label: Text(_isAnalyzing ? '分析中...' : 'AI分析'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7B1FA2),
                  side: const BorderSide(color: Color(0xFF7B1FA2)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        // AI Model selector
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Text('AI模型:', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              ...AiModel.values.map((model) {
                final names = {AiModel.doubao: '豆包', AiModel.tongyi: '通义', AiModel.zhipu: '智谱'};
                final isSelected = _selectedAiModel == model;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(names[model]!, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey.shade600)),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFF8C42),
                    onSelected: (_) => setState(() => _selectedAiModel = model),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }),
            ],
          ),
        ),
        // AI Analysis result
        if (_aiAnalysis != null) ...[
          const SizedBox(height: 12),
          Container(
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
                    Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7B1FA2)),
                    SizedBox(width: 6),
                    Text('AI错题分析', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7B1FA2))),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_aiAnalysis!, style: const TextStyle(fontSize: 14, height: 1.7)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('按科目分类', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 10),
        wrongStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
          data: (stats) {
            if (stats.isEmpty) {
              return _emptyState('暂无错题，继续保持！');
            }
            return Column(
              children: stats.map((stat) {
                final module = stat['module'] as String;
                final chapter = stat['chapter'] as String;
                final count = stat['wrong_count'] as int;
                return _buildWrongItem(module, chapter, count, () {
                  context.push('/practice', extra: {
                    'mode': PracticeMode.wrong,
                    'module': module,
                    'chapter': chapter,
                  });
                });
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReciteWrongBook(ThemeData theme) {
    final reciteCount = ref.watch(reciteWrongCountProvider);
    final reciteDueCount = ref.watch(reciteDueReviewCountProvider);
    final reciteStats = ref.watch(reciteWrongStatsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(child: _statCard(reciteCount, '背诵错题', const Color(0xFF7B1FA2), Icons.menu_book)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(reciteDueCount, '待复习', const Color(0xFFFF8C42), Icons.schedule_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/recite-review'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('开始背诵复习'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B1FA2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _exportReciteWrong(),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('导出背诵'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF26A69A),
                  side: const BorderSide(color: Color(0xFF26A69A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('按知识点分类', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        const SizedBox(height: 10),
        reciteStats.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
          data: (stats) {
            if (stats.isEmpty) {
              return _emptyState('暂无背诵错题，继续保持！');
            }
            return Column(
              children: stats.entries.map((entry) {
                return _buildWrongItem(entry.key, '背诵', entry.value, () {
                  context.push('/recite-review');
                });
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _exportWrongQuestions() async {
    final service = ref.read(importExportServiceProvider);
    await service.shareWrongQuestions();
  }

  Future<void> _exportReciteWrong() async {
    final service = ref.read(importExportServiceProvider);
    await service.shareReciteWrong();
  }

  Future<void> _analyzeWrongQuestions() async {
    setState(() {
      _isAnalyzing = true;
      _aiAnalysis = null;
    });

    try {
      final db = await ref.read(appDatabaseProvider).database;
      final results = await db.rawQuery('''
        SELECT q.content, q.answer, q.explanation, q.module, q.chapter
        FROM wrong_records wr
        JOIN questions q ON wr.question_id = q.id
        WHERE wr.is_mastered = 0
        ORDER BY wr.wrong_count DESC
        LIMIT 20
      ''');

      if (results.isEmpty) {
        setState(() {
          _aiAnalysis = '暂无错题数据可供分析。';
          _isAnalyzing = false;
        });
        return;
      }

      final questions = results.map((r) => {
        'question': r['content']?.toString() ?? '',
        'myAnswer': '错误',
        'correctAnswer': r['answer']?.toString() ?? '',
      }).toList();

      final aiService = ref.read(multiAiServiceProvider);
      final analysis = await aiService.analyzeWrongQuestions(questions, model: _selectedAiModel);

      setState(() {
        _aiAnalysis = analysis;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _aiAnalysis = '分析失败: $e';
        _isAnalyzing = false;
      });
    }
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF43A047)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildWrongItem(String title, String subtitle, int count, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('$count', style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(AsyncValue<int> countAsync, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          countAsync.when(
            loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => Text('0', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            data: (count) => Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }
}
