import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/wrong_record_provider.dart';
import '../../../providers/favorite_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../data/services/multi_ai_service.dart';
import '../../widgets/bottom_nav_bar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: ListView(
        children: [
          // Exam settings
          _sectionHeader('考试设置'),
          _settingsCard([
            _settingsTile(
              icon: Icons.timer,
              iconColor: const Color(0xFFFF8C42),
              title: '考试时长',
              subtitle: '${settings.examDurationMinutes} 分钟',
              onTap: () => _showDurationPicker(context, ref, settings.examDurationMinutes),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _settingsTile(
              icon: Icons.flag,
              iconColor: const Color(0xFF43A047),
              title: '每日学习目标',
              subtitle: '${settings.dailyGoalCount} 题',
              onTap: () => _showGoalPicker(context, ref, settings.dailyGoalCount),
            ),
          ]),

          // AI Models section
          _sectionHeader('AI大模型'),
          _buildAiModelsCard(context),
          const SizedBox(height: 8),

          // Data management
          _sectionHeader('数据管理'),
          _settingsCard([
            _settingsTile(
              icon: Icons.backup,
              iconColor: const Color(0xFF1976D2),
              title: '一键备份数据',
              subtitle: '备份所有学习数据到本地文件',
              onTap: () => _exportBackup(context, ref),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _settingsTile(
              icon: Icons.restore,
              iconColor: const Color(0xFF26A69A),
              title: '一键恢复数据',
              subtitle: '从备份文件恢复全部数据',
              onTap: () => _importBackup(context, ref),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _settingsTile(
              icon: Icons.folder_open,
              iconColor: const Color(0xFFFF8C42),
              title: '题库管理',
              subtitle: '导入/导出题库，手动录入',
              onTap: () => context.push('/manage'),
            ),
            Divider(height: 1, indent: 56, color: Colors.grey.shade100),
            _settingsTile(
              icon: Icons.delete_outline,
              iconColor: Colors.red,
              title: '清除数据',
              subtitle: '清除所有错题、收藏和练习记录',
              titleColor: Colors.red,
              onTap: () => _showClearDataDialog(context, ref),
            ),
          ]),

          // About
          _sectionHeader('关于'),
          _settingsCard([
            _settingsTile(
              icon: Icons.info_outline,
              iconColor: const Color(0xFF5C6BC0),
              title: '上岸事考 v1.0.0',
              subtitle: '河南事业单位、省考备考必备',
              onTap: () => _showAboutDialog(context),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: titleColor)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildAiModelsCard(BuildContext context) {
    final aiService = MultiAiService();
    final models = aiService.getAvailableModels();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('内置三大AI模型，题目讲解、错题分析、申论批改均可自由切换', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          ...models.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C42).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Text(m['icon'], style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(m['desc'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('免费', style: TextStyle(fontSize: 11, color: Color(0xFF43A047), fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '免费额度用尽自动提示停用，无自动扣费',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDurationPicker(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (ctx) {
        int value = current;
        return AlertDialog(
          title: const Text('设置考试时长'),
          content: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value 分钟', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: value.toDouble(),
                  min: 30,
                  max: 240,
                  divisions: 21,
                  onChanged: (v) => setState(() => value = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).setExamDuration(value);
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showGoalPicker(BuildContext context, WidgetRef ref, int current) {
    showDialog(
      context: context,
      builder: (ctx) {
        int value = current;
        return AlertDialog(
          title: const Text('每日学习目标'),
          content: StatefulBuilder(
            builder: (ctx, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$value 题/天', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Slider(
                  value: value.toDouble(),
                  min: 10,
                  max: 200,
                  divisions: 19,
                  onChanged: (v) => setState(() => value = v.round()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).setDailyGoal(value);
                Navigator.pop(ctx);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(importExportServiceProvider);
      await service.exportBackup();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('备份完成')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e')));
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('恢复将覆盖当前所有数据，确定继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定恢复', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(importExportServiceProvider);
      final success = await service.importBackup();
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据恢复成功')));
          ref.invalidate(wrongCountProvider);
          ref.invalidate(favoriteCountProvider);
          ref.invalidate(totalPracticeCountProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('未选择备份文件')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
      }
    }
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除数据'),
        content: const Text('将清除所有错题记录、收藏和练习统计。题目数据不会被删除。\n\n此操作不可撤销！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await ref.read(wrongRecordRepositoryProvider).deleteAll();
              await ref.read(favoriteRepositoryProvider).deleteAll();
              await ref.read(statsRepositoryProvider).deleteAll();
              ref.invalidate(wrongCountProvider);
              ref.invalidate(favoriteCountProvider);
              ref.invalidate(totalPracticeCountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已清除')));
              }
            },
            child: const Text('确认清除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('上岸事考'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('版本：1.0.0'),
            SizedBox(height: 8),
            Text('河南事业单位、省考备考必备刷题APP'),
            SizedBox(height: 8),
            Text('功能特点：'),
            Text('  - 内置三大AI模型'),
            Text('  - 智能错题分析'),
            Text('  - 申论AI批改'),
            Text('  - 时政热点更新'),
            Text('  - 艾宾浩斯复习'),
            Text('  - 语音背诵'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }
}
