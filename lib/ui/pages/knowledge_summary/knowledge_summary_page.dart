import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../../providers/wrong_record_provider.dart';

class KnowledgeSummaryPage extends ConsumerWidget {
  const KnowledgeSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(knowledgePointStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('错题知识点汇总', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C42))),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (data) {
          if (data.isEmpty) {
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
                  const Text('暂无薄弱知识点', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('继续努力，保持好状态！', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final stat = data[index];
              final knowledgePoint = stat['knowledge_point'] as String? ?? stat['chapter'] as String;
              final module = stat['module'] as String;
              final total = stat['total_questions'] as int;
              final wrong = stat['wrong_count'] as int;
              final questionCount = stat['question_count'] as int? ?? 0;
              final accuracy = total > 0 ? ((total - wrong) / total * 100) : 100.0;
              final isWeak = accuracy < 60;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isWeak ? Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3), width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: EdgeInsets.zero,
                    leading: _accuracyIndicator(accuracy),
                    title: Text(
                      knowledgePoint,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isWeak ? const Color(0xFFE53935) : Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(module, style: const TextStyle(fontSize: 11, color: Color(0xFFFF8C42))),
                          ),
                          const SizedBox(width: 8),
                          Text('错题$wrong/$questionCount题', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Accuracy bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: accuracy / 100,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(
                                  accuracy >= 80 ? const Color(0xFF43A047)
                                      : accuracy >= 60 ? const Color(0xFFFFA000)
                                      : const Color(0xFFE53935),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '正确率 ${accuracy.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: accuracy >= 80 ? const Color(0xFF43A047)
                                    : accuracy >= 60 ? const Color(0xFFFFA000)
                                    : const Color(0xFFE53935),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isWeak)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFCC80)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, size: 16, color: Color(0xFFE65100)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '该知识点正确率较低，建议重点复习',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/practice', extra: {
                                  'mode': PracticeMode.wrong,
                                  'module': module,
                                  'chapter': knowledgePoint,
                                }),
                                icon: const Icon(Icons.fitness_center_rounded, size: 18),
                                label: const Text('专项练习'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8C42),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _accuracyIndicator(double accuracy) {
    final color = accuracy >= 80 ? const Color(0xFF43A047)
        : accuracy >= 60 ? const Color(0xFFFFA000)
        : const Color(0xFFE53935);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: accuracy / 100,
            strokeWidth: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text('${accuracy.round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
