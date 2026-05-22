import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';

class ExamResultPage extends StatelessWidget {
  final int totalCount;
  final int correctCount;
  final Duration duration;
  final List<int> wrongQuestionIds;

  const ExamResultPage({
    super.key,
    required this.totalCount,
    required this.correctCount,
    required this.duration,
    required this.wrongQuestionIds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = totalCount > 0 ? correctCount / totalCount : 0.0;
    final accuracyPercent = (accuracy * 100).toStringAsFixed(1);
    final score = (accuracy * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('考试结果'), automaticallyImplyLeading: false),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: accuracy,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$score', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('分', style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                score >= 80 ? '优秀!' : score >= 60 ? '及格' : '继续努力',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('总题数', '$totalCount', theme),
                  _stat('正确', '$correctCount', theme),
                  _stat('错误', '${totalCount - correctCount}', theme),
                  _stat('正确率', '%$accuracyPercent', theme),
                  _stat('用时', '${duration.inMinutes}分钟', theme),
                ],
              ),
              const SizedBox(height: 32),
              if (wrongQuestionIds.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/practice', extra: {
                      'mode': PracticeMode.wrong,
                      'module': '',
                      'questionIds': wrongQuestionIds,
                    }),
                    icon: const Icon(Icons.refresh),
                    label: Text('练习错题 (${wrongQuestionIds.length}题)'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('返回首页'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
