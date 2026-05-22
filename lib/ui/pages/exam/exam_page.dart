import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/settings_provider.dart';

class ExamPage extends ConsumerStatefulWidget {
  final String module;
  const ExamPage({super.key, required this.module});

  @override
  ConsumerState<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends ConsumerState<ExamPage> {
  int _questionCount = 100;
  String? _selectedChapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('模拟考试')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('考试设置', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    // Question count
                    Text('题目数量: $_questionCount 题'),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 20,
                      max: 200,
                      divisions: 18,
                      label: '$_questionCount',
                      onChanged: (v) => setState(() => _questionCount = v.round()),
                    ),
                    const SizedBox(height: 8),
                    // Duration info
                    Text('考试时长: ${settings.examDurationMinutes} 分钟'),
                    const SizedBox(height: 16),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          context.push('/practice', extra: {
                            'mode': PracticeMode.exam,
                            'module': widget.module,
                            'chapter': _selectedChapter,
                            'questionCount': _questionCount,
                            'examDuration': settings.examDurationMinutes,
                          });
                        },
                        icon: const Icon(Icons.timer),
                        label: const Text('开始考试'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
