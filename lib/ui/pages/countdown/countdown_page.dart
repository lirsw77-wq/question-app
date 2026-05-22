import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/exam_countdown_provider.dart';
import '../../../data/models/exam_countdown.dart';

class CountdownPage extends ConsumerStatefulWidget {
  const CountdownPage({super.key});

  @override
  ConsumerState<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends ConsumerState<CountdownPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countdowns = ref.watch(allCountdownsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('考试倒计时', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFE53935),
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: countdowns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('还没有考试倒计时', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('点击右下角 + 添加考试', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) => _buildCountdownCard(context, theme, list[index]),
          );
        },
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, ThemeData theme, ExamCountdown countdown) {
    final days = countdown.daysRemaining;
    final isExpired = days < 0;
    final dateStr = '${DateTime.fromMillisecondsSinceEpoch(countdown.examDate).year}-'
        '${DateTime.fromMillisecondsSinceEpoch(countdown.examDate).month.toString().padLeft(2, '0')}-'
        '${DateTime.fromMillisecondsSinceEpoch(countdown.examDate).day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : days <= 7
                  ? [const Color(0xFFE53935), const Color(0xFFFF7043)]
                  : days <= 30
                      ? [const Color(0xFFFF8C42), const Color(0xFFFFB07C)]
                      : [const Color(0xFF43A047), const Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isExpired ? Colors.grey : const Color(0xFFE53935)).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          countdown.name,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (!countdown.isVisible)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('已隐藏', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '考试日期: $dateStr',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isExpired ? '已结束' : '$days',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
                      ),
                      Text(
                        isExpired ? '' : '天',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleVisibility(countdown),
                      child: Icon(
                        countdown.isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showEditDialog(context, countdown),
                      child: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, countdown),
                      child: Icon(Icons.delete_outline, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVisibility(ExamCountdown countdown) async {
    final repo = ref.read(examCountdownRepositoryProvider);
    await repo.toggleVisibility(countdown.id!, !countdown.isVisible);
    ref.invalidate(allCountdownsProvider);
    ref.invalidate(examCountdownsProvider);
  }

  void _confirmDelete(BuildContext context, ExamCountdown countdown) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${countdown.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final repo = ref.read(examCountdownRepositoryProvider);
              await repo.deleteCountdown(countdown.id!);
              ref.invalidate(allCountdownsProvider);
              ref.invalidate(examCountdownsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    _showFormDialog(context, null);
  }

  void _showEditDialog(BuildContext context, ExamCountdown countdown) {
    _showFormDialog(context, countdown);
  }

  void _showFormDialog(BuildContext context, ExamCountdown? existing) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.fromMillisecondsSinceEpoch(existing.examDate)
        : DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? '添加考试倒计时' : '编辑考试倒计时'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '考试名称',
                  hintText: '如：河南省考、事业编联考',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('考试日期'),
                subtitle: Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final repo = ref.read(examCountdownRepositoryProvider);
                if (existing == null) {
                  await repo.addCountdown(ExamCountdown(
                    name: nameController.text,
                    examDate: selectedDate.millisecondsSinceEpoch,
                    createdAt: DateTime.now().millisecondsSinceEpoch,
                  ));
                } else {
                  await repo.updateCountdown(existing.copyWith(
                    name: nameController.text,
                    examDate: selectedDate.millisecondsSinceEpoch,
                  ));
                }
                ref.invalidate(allCountdownsProvider);
                ref.invalidate(examCountdownsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? '添加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}
