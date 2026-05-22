import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../providers/stats_provider.dart';
import '../../../providers/wrong_record_provider.dart';
import '../../../providers/check_in_provider.dart';
import '../../../providers/exam_countdown_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/exam_countdown.dart';
import '../../../domain/enums/exam_module.dart';
import '../../../domain/enums/practice_mode.dart';
import '../../widgets/bottom_nav_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    _checkIn();
  }

  void _checkIn() {
    ref.read(checkInRepositoryProvider).checkIn();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayStats = ref.watch(checkInTodayStatsProvider);
    final consecutiveDays = ref.watch(checkInConsecutiveDaysProvider);
    final wrongCount = ref.watch(wrongCountProvider);
    final dueReviewCount = ref.watch(dueReviewCountProvider);
    final countdowns = ref.watch(examCountdownsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('上岸事考', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: RefreshIndicator(
        color: const Color(0xFFFF8C42),
        onRefresh: () async {
          ref.invalidate(checkInTodayStatsProvider);
          ref.invalidate(checkInConsecutiveDaysProvider);
          ref.invalidate(wrongCountProvider);
          ref.invalidate(dueReviewCountProvider);
          ref.invalidate(totalPracticeCountProvider);
          ref.invalidate(examCountdownsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 考试倒计时
            _buildCountdownSection(context, theme, countdowns),
            const SizedBox(height: 16),

            // 打卡区域
            _buildCheckInSection(context, theme, todayStats, consecutiveDays),
            const SizedBox(height: 16),

            // 统计卡片
            _buildStatsCard(context, theme, todayStats, consecutiveDays),
            const SizedBox(height: 20),

            // 快捷入口
            _buildQuickActions(context, theme, wrongCount, dueReviewCount),
            const SizedBox(height: 24),

            // 考试科目
            Text('考试科目', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            ...ExamModule.values.map((module) => _buildModuleCard(context, module, theme)),
            const SizedBox(height: 20),

            // 更多功能
            Text('更多功能', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            const SizedBox(height: 12),
            _buildMoreFeatures(context, theme),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownSection(BuildContext context, ThemeData theme, AsyncValue countdowns) {
    return countdowns.when(
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
      data: (list) {
        if (list.isEmpty) return const SizedBox();
        return GestureDetector(
          onTap: () => context.push('/countdown'),
          child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE53935), Color(0xFFFF7043)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE53935).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('考试倒计时', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddCountdownDialog(context),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...list.take(3).map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${c.daysRemaining}天',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        );
      },
    );
  }

  void _showAddCountdownDialog(BuildContext context) {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加考试倒计时'),
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
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await ref.read(examCountdownRepositoryProvider).addCountdown(
                    ExamCountdown(
                      name: nameController.text,
                      examDate: selectedDate.millisecondsSinceEpoch,
                      createdAt: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                  ref.invalidate(examCountdownsProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInSection(BuildContext context, ThemeData theme, AsyncValue todayStats, AsyncValue consecutiveDays) {
    return todayStats.when(
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
      data: (stats) {
        final isChecked = stats['isChecked'] as bool;
        final studyDuration = stats['studyDuration'] as int;
        final practiceCount = stats['practiceCount'] as int;

        return consecutiveDays.when(
          loading: () => const SizedBox(),
          error: (_, _) => const SizedBox(),
          data: (days) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 打卡按钮
                GestureDetector(
                  onTap: isChecked ? null : () async {
                    await ref.read(checkInRepositoryProvider).checkIn();
                    ref.invalidate(checkInTodayStatsProvider);
                    ref.invalidate(checkInConsecutiveDaysProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('打卡成功！继续加油！')),
                      );
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: isChecked
                          ? const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF66BB6A)])
                          : const LinearGradient(colors: [Color(0xFFFF8C42), Color(0xFFFFB07C)]),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isChecked ? Colors.green : Colors.orange).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isChecked ? Icons.check : Icons.touch_app, color: Colors.white, size: 24),
                        Text(isChecked ? '已打卡' : '打卡', style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 今日统计
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('连续打卡 $days 天', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _miniStat('学习', _formatDuration(studyDuration), Icons.access_time),
                          const SizedBox(width: 16),
                          _miniStat('刷题', '$practiceCount题', Icons.quiz),
                        ],
                      ),
                    ],
                  ),
                ),
                // 日历入口
                IconButton(
                  onPressed: () => _showCalendarDialog(context),
                  icon: const Icon(Icons.calendar_month, color: Color(0xFFFF8C42)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds秒';
    if (seconds < 3600) return '${seconds ~/ 60}分钟';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '$hours时$minutes分';
  }

  void _showCalendarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TableCalendar(
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: DateTime.now(),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(formatButtonVisible: false),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color(0xFFFF8C42),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ThemeData theme, AsyncValue<Map<String, dynamic>> todayStats, AsyncValue<int> consecutiveDays) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C42), Color(0xFFFFB07C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C42).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: todayStats.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
          error: (e, _) => Text('加载失败: $e', style: const TextStyle(color: Colors.white)),
          data: (stats) {
            final total = stats['practiceCount'] as int? ?? 0;
            final duration = stats['studyDuration'] as int? ?? 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem('今日做题', '$total', Icons.edit_note),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                _statItem('学习时长', _formatDuration(duration), Icons.access_time),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                consecutiveDays.when(
                  loading: () => _statItem('连续天数', '...', Icons.local_fire_department),
                  error: (_, _) => _statItem('连续天数', '0', Icons.local_fire_department),
                  data: (days) => _statItem('连续天数', '$days', Icons.local_fire_department),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme, AsyncValue<int> wrongCount, AsyncValue<int> dueReviewCount) {
    return Row(
      children: [
        Expanded(child: _quickAction(context, '继续练习', Icons.play_arrow_rounded, const Color(0xFFFF8C42), () {
          context.push('/practice', extra: {
            'mode': PracticeMode.sequential,
            'module': '公共基础知识',
          });
        })),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(context, '错题本', Icons.error_outline_rounded, const Color(0xFFE53935), () {
          context.push('/wrongbook');
        }, badge: wrongCount)),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(context, '收藏夹', Icons.bookmark_rounded, const Color(0xFFFFA726), () {
          context.push('/favorites');
        })),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(context, '智能复习', Icons.psychology_rounded, const Color(0xFF43A047), () {
          context.push('/review');
        }, badge: dueReviewCount)),
      ],
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {AsyncValue<int>? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            badge != null
                ? badge.when(
                    loading: () => Icon(icon, size: 26, color: color),
                    error: (_, _) => Icon(icon, size: 26, color: color),
                    data: (count) => count > 0
                        ? Badge(
                            backgroundColor: const Color(0xFFE53935),
                            label: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
                            child: Icon(icon, size: 26, color: color),
                          )
                        : Icon(icon, size: 26, color: color),
                  )
                : Icon(icon, size: 26, color: color),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, ExamModule module, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/module/${module.label}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _moduleColor(module).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_moduleIcon(module), color: _moduleColor(module), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('${module.chapters.length}个章节', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFeatures(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _featureTile(context, Icons.quiz_rounded, '模拟考试', '限时模拟真实考试', const Color(0xFFFF8C42), () {
            context.push('/exam', extra: {'module': '公共基础知识'});
          }),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _featureTile(context, Icons.analytics_rounded, '错题知识点汇总', '分析薄弱知识点', const Color(0xFF5C6BC0), () {
            context.push('/knowledge-summary');
          }),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _featureTile(context, Icons.newspaper_rounded, '时政热点', '每日时政更新', const Color(0xFF26A69A), () {
            context.push('/current-affairs');
          }),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _featureTile(context, Icons.rate_review_rounded, '申论AI批改', '智能评分与建议', const Color(0xFF7B1FA2), () {
            context.push('/essay-grading');
          }),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _featureTile(context, Icons.record_voice_over_rounded, '背诵复习', '语音互动背诵', const Color(0xFF7B1FA2), () {
            context.push('/recite-review');
          }),
          Divider(height: 1, indent: 56, color: Colors.grey.shade100),
          _featureTile(context, Icons.folder_open_rounded, '题库管理', '导入/导出/拍照录入', const Color(0xFF26A69A), () {
            context.push('/manage');
          }),
        ],
      ),
    );
  }

  Widget _featureTile(BuildContext context, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Color _moduleColor(ExamModule module) {
    switch (module) {
      case ExamModule.gongji: return const Color(0xFFFF8C42);
      case ExamModule.zhiCe: return const Color(0xFF5C6BC0);
      case ExamModule.shenLun: return const Color(0xFF26A69A);
    }
  }

  IconData _moduleIcon(ExamModule module) {
    switch (module) {
      case ExamModule.gongji: return Icons.menu_book_rounded;
      case ExamModule.zhiCe: return Icons.calculate_rounded;
      case ExamModule.shenLun: return Icons.edit_note_rounded;
    }
  }
}
