import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/question.dart';
import '../../../../domain/enums/practice_mode.dart';
import '../../../../providers/question_provider.dart';
import '../../../widgets/question_type_badge.dart';

class SimilarQuestionsSheet extends ConsumerWidget {
  final Question question;
  const SimilarQuestionsSheet({super.key, required this.question});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final similar = ref.watch(similarQuestionsProvider((question: question, count: 5)));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text('举一反三 - 相似题目', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: similar.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('加载失败: $e')),
                  data: (questions) {
                    if (questions.isEmpty) {
                      return const Center(child: Text('暂无相似题目'));
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final q = questions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: QuestionTypeBadge(type: q.type),
                            title: Text(q.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${q.module} - ${q.chapter}', style: const TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.play_arrow),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/practice', extra: {
                                'mode': PracticeMode.sequential,
                                'module': q.module,
                                'questionIds': [q.id],
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
