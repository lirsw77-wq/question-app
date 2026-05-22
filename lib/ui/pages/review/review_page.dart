import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/wrong_record_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/question.dart';
import '../../widgets/question_type_badge.dart';

class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dueCount = ref.watch(dueReviewCountProvider);
    final wrongCount = ref.watch(wrongCountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('智能复习')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header card
          Card(
            color: Colors.orange.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.psychology, size: 48, color: Colors.orange),
                  const SizedBox(height: 12),
                  Text('基于艾宾浩斯遗忘曲线', style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          dueCount.when(
                            loading: () => const Text('...'),
                            error: (_, _) => const Text('0'),
                            data: (c) => Text('$c', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                          const Text('今日待复习'),
                        ],
                      ),
                      Column(
                        children: [
                          wrongCount.when(
                            loading: () => const Text('...'),
                            error: (_, _) => const Text('0'),
                            data: (c) => Text('$c', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                          const Text('总错题数'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Start review button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/practice', extra: {
                'mode': PracticeMode.review,
                'module': '',
              }),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始今日复习'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Ebbinghaus stages explanation
          Text('复习计划说明', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _stageRow('第1轮', '1天后', '答对进入下一轮，答错重置', Colors.red),
                  _stageRow('第2轮', '2天后', '', Colors.orange),
                  _stageRow('第3轮', '4天后', '', Colors.amber),
                  _stageRow('第4轮', '7天后', '', Colors.lime),
                  _stageRow('第5轮', '15天后', '', Colors.lightGreen),
                  _stageRow('第6轮', '30天后', '通过后标记为已掌握', Colors.green),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Due review questions list
          Text('待复习题目', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _DueReviewList(),
        ],
      ),
    );
  }

  Widget _stageRow(String stage, String interval, String note, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(stage, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Text(interval, style: const TextStyle(fontWeight: FontWeight.w500)),
          if (note.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(note, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _DueReviewList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueIds = ref.watch(dueReviewQuestionIdsProvider);

    return dueIds.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败: $e'),
      data: (ids) {
        if (ids.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('今日无需复习的题目', style: TextStyle(color: Colors.grey))),
            ),
          );
        }
        return FutureBuilder<List<Question>>(
          future: ref.read(questionRepositoryProvider).getQuestionsByIds(ids),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final questions = snapshot.data!;
            return Column(
              children: questions.map((q) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: QuestionTypeBadge(type: q.type),
                  title: Text(q.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${q.module} - ${q.chapter}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/practice', extra: {
                    'mode': PracticeMode.review,
                    'module': q.module,
                    'questionIds': [q.id],
                  }),
                ),
              )).toList(),
            );
          },
        );
      },
    );
  }
}
