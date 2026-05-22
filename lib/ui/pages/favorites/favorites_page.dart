import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/question.dart';
import '../../widgets/question_type_badge.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favCount = ref.watch(favoriteCountProvider);
    final favIds = ref.watch(favoriteQuestionIdsProvider(null));

    return Scaffold(
      appBar: AppBar(title: const Text('收藏夹')),
      body: Column(
        children: [
          // Header
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bookmark, color: Colors.amber, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      favCount.when(
                        loading: () => const Text('加载中...'),
                        error: (_, _) => const Text('收藏题目: 0'),
                        data: (count) => Text('收藏题目: $count', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      final ids = ref.read(favoriteQuestionIdsProvider(null)).valueOrNull;
                      if (ids != null && ids.isNotEmpty) {
                        context.push('/practice', extra: {
                          'mode': PracticeMode.favorite,
                          'module': '',
                          'questionIds': ids,
                        });
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('练习收藏'),
                  ),
                ],
              ),
            ),
          ),
          // Favorites list
          Expanded(
            child: favIds.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (ids) {
                if (ids.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无收藏', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return _FavoriteList(questionIds: ids);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteList extends ConsumerWidget {
  final List<int> questionIds;
  const _FavoriteList({required this.questionIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionRepositoryProvider);

    return FutureBuilder<List<Question>>(
      future: questionsAsync.getQuestionsByIds(questionIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final questions = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: QuestionTypeBadge(type: q.type),
                title: Text(q.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${q.module} - ${q.chapter}'),
                trailing: IconButton(
                  icon: const Icon(Icons.bookmark, color: Colors.amber),
                  onPressed: () async {
                    await ref.read(favoriteRepositoryProvider).removeFavorite(q.id!);
                    ref.invalidate(favoriteQuestionIdsProvider);
                    ref.invalidate(favoriteCountProvider);
                  },
                ),
                onTap: () => context.push('/practice', extra: {
                  'mode': PracticeMode.favorite,
                  'module': q.module,
                  'questionIds': [q.id],
                }),
              ),
            );
          },
        );
      },
    );
  }
}
