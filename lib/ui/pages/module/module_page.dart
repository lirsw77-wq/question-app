import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/exam_module.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/question_provider.dart';
import '../../../providers/database_provider.dart';

class ModulePage extends ConsumerStatefulWidget {
  final String module;
  const ModulePage({super.key, required this.module});

  @override
  ConsumerState<ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends ConsumerState<ModulePage> {
  String? _selectedExamSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final examModule = ExamModule.fromLabel(widget.module);
    final chapterStats = ref.watch(chapterStatsProvider(widget.module));
    final examSourcesAsync = ref.watch(_examSourcesProvider(widget.module));

    return Scaffold(
      appBar: AppBar(title: Text(widget.module)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Module overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_moduleIcon(examModule), size: 48, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.module, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${examModule.chapters.length}个章节', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Exam source filter
          examSourcesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (sources) {
              if (sources.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('按来源筛选', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('全部', _selectedExamSource == null, () {
                          setState(() => _selectedExamSource = null);
                          ref.invalidate(_filteredQuestionsProvider);
                        }),
                        ...sources.map((s) => _filterChip(s, _selectedExamSource == s, () {
                          setState(() => _selectedExamSource = s);
                          ref.invalidate(_filteredQuestionsProvider);
                        })),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Quick start buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/practice', extra: {
                    'mode': PracticeMode.sequential,
                    'module': widget.module,
                    'examSource': _selectedExamSource,
                  }),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('顺序练习'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/practice', extra: {
                    'mode': PracticeMode.random,
                    'module': widget.module,
                    'questionCount': 20,
                    'examSource': _selectedExamSource,
                  }),
                  icon: const Icon(Icons.shuffle),
                  label: const Text('随机20题'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chapter list
          Text('章节列表', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          chapterStats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
            data: (stats) {
              final statMap = {for (var s in stats) s['chapter'] as String: s};
              return Column(
                children: examModule.chapters.map((chapter) {
                  final stat = statMap[chapter];
                  final total = stat?['total'] as int? ?? 0;
                  final wrongCount = stat?['wrong_count'] as int? ?? 0;
                  return Card(
                    child: ListTile(
                      title: Text(chapter),
                      subtitle: total > 0
                          ? Text('共$total题 | 错题$wrongCount题')
                          : const Text('暂无题目'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/practice', extra: {
                        'mode': PracticeMode.sequential,
                        'module': widget.module,
                        'chapter': chapter,
                        'examSource': _selectedExamSource,
                      }),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  IconData _moduleIcon(ExamModule module) {
    switch (module) {
      case ExamModule.gongji: return Icons.menu_book;
      case ExamModule.zhiCe: return Icons.calculate;
      case ExamModule.shenLun: return Icons.edit_note;
    }
  }
}

final _examSourcesProvider = FutureProvider.family<List<String>, String>((ref, module) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getDistinctExamSources(module);
});

final _filteredQuestionsProvider = FutureProvider.family<int, ({String module, String? source})>((ref, params) async {
  final repo = ref.watch(questionRepositoryProvider);
  final questions = await repo.getFilteredQuestions(params.module, examSource: params.source);
  return questions.length;
});
