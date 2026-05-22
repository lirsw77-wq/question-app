import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/question_provider.dart';
import '../../../domain/enums/exam_module.dart';

class ManagePage extends ConsumerWidget {
  const ManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final importExport = ref.watch(importExportServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('题库管理')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PDF import
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.red.shade50, child: const Icon(Icons.picture_as_pdf, color: Colors.red)),
              title: const Text('PDF真题导入'),
              subtitle: const Text('从PDF文件自动解析并导入真题'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/manage/pdf-import'),
            ),
          ),
          const SizedBox(height: 12),

          // OCR scan
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.document_scanner, color: Colors.blue)),
              title: const Text('拍照识题'),
              subtitle: const Text('拍照或选择图片，OCR识别题目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/manage/ocr-scan'),
            ),
          ),
          const SizedBox(height: 12),

          // Add question
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.add)),
              title: const Text('手动添加题目'),
              subtitle: const Text('在APP内录入新题目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/manage/add'),
            ),
          ),
          const SizedBox(height: 16),

          // Import questions
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.upload_file)),
              title: const Text('导入题库'),
              subtitle: const Text('从JSON文件导入题目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final count = await importExport.importQuestionsFromJson();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(count > 0 ? '成功导入$count道题目' : '未找到可导入的题目')),
                  );
                  ref.invalidate(questionCountProvider);
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Export backup
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.backup)),
              title: const Text('备份数据'),
              subtitle: const Text('导出用户数据（错题/收藏/记录）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                try {
                  await importExport.exportBackup();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('备份失败: $e')));
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Import backup
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.restore)),
              title: const Text('恢复数据'),
              subtitle: const Text('从备份文件恢复用户数据'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认恢复'),
                    content: const Text('恢复数据将覆盖当前的错题、收藏和练习记录，确定继续吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('确定')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final success = await importExport.importBackup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? '数据恢复成功' : '恢复失败')),
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 16),

          // Dedup cleanup
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.orange.shade50, child: const Icon(Icons.cleaning_services, color: Colors.orange)),
              title: const Text('题库去重清理'),
              subtitle: const Text('扫描并清除重复题目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/manage/dedup'),
            ),
          ),
          const SizedBox(height: 16),

          // Module reset
          Card(
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.restart_alt, color: Colors.grey)),
              title: const Text('模块重置'),
              subtitle: const Text('清空指定模块的所有题目'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showModuleResetDialog(context, ref),
            ),
          ),
          const SizedBox(height: 24),

          // Module stats
          Text('题库统计', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...ExamModule.values.map((module) {
            final countAsync = ref.watch(questionCountProvider((module: module.label, chapter: null)));
            return Card(
              child: ListTile(
                leading: Icon(_moduleIcon(module), color: theme.colorScheme.primary),
                title: Text(module.label),
                trailing: countAsync.when(
                  loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, _) => const Text('0'),
                  data: (count) => Text('$count题', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            );
          }),
        ],
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

  void _showModuleResetDialog(BuildContext context, WidgetRef ref) {
    String? selectedModule;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('模块重置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择要清空的模块，该模块下所有题目将被删除，此操作不可撤销。'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedModule,
                items: ExamModule.values.map((m) => DropdownMenuItem(value: m.label, child: Text(m.label))).toList(),
                onChanged: (v) => setDialogState(() => selectedModule = v),
                decoration: const InputDecoration(labelText: '选择模块', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: selectedModule == null ? null : () async {
                final repo = ref.read(questionRepositoryProvider);
                await repo.deleteQuestionsByModule(selectedModule!);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已清空"$selectedModule"模块')),
                  );
                  ref.invalidate(questionCountProvider);
                }
              },
              child: const Text('确认清空', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
