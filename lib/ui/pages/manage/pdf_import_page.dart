import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/import_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../data/services/permission_service.dart';
import '../../../data/services/network_service.dart';

class PdfImportPage extends ConsumerStatefulWidget {
  final String? initialFilePath;
  final String? initialFileName;

  const PdfImportPage({super.key, this.initialFilePath, this.initialFileName});

  @override
  ConsumerState<PdfImportPage> createState() => _PdfImportPageState();
}

class _PdfImportPageState extends ConsumerState<PdfImportPage> {
  bool _quotaExhausted = false;
  int _remainingQuota = 50000;

  @override
  void initState() {
    super.initState();
    _checkQuota();
    if (widget.initialFilePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startImport(widget.initialFilePath!, widget.initialFileName ?? 'imported.pdf');
      });
    }
  }

  Future<void> _checkQuota() async {
    final baiduOcr = ref.read(baiduOcrServiceProvider);
    final hasQuota = await baiduOcr.hasFreeQuota();
    final remaining = await baiduOcr.getRemainingQuota();
    if (mounted) {
      setState(() {
        _quotaExhausted = !hasQuota;
        _remainingQuota = remaining;
      });
    }
  }

  Future<void> _pickAndImport() async {
    // 检查网络
    if (!await NetworkService.isNetworkAvailable()) {
      if (mounted) {
        PermissionService.showNetworkError(context);
      }
      return;
    }

    // 检查额度
    if (_quotaExhausted) {
      if (mounted) {
        _showQuotaExhaustedDialog();
      }
      return;
    }

    // 检查存储权限
    if (!mounted) return;
    if (!await PermissionService.requestStoragePermission(context)) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    _startImport(file.path!, file.name);
  }

  void _startImport(String filePath, String fileName) {
    ref.read(importProvider.notifier).importPdf(filePath, fileName);
  }

  void _showQuotaExhaustedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('今日免费额度已用完'),
        content: const Text('今日免费识别额度已用完，次日零点自动恢复可用。\n\n全程禁止开启按量付费，绝不会产生任何费用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importState = ref.watch(importProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF真题导入'),
        actions: [
          if (importState.phase == ImportPhase.completed || importState.phase == ImportPhase.error)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新导入',
              onPressed: () {
                ref.read(importProvider.notifier).reset();
                _checkQuota();
              },
            ),
        ],
      ),
      body: _buildBody(context, theme, importState),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme, ImportState state) {
    if (state.phase == ImportPhase.idle) {
      return _buildIdleState(context, theme);
    }

    if (state.phase == ImportPhase.error) {
      return _buildErrorState(context, theme, state);
    }

    if (state.phase == ImportPhase.completed && state.result != null) {
      return _buildResultState(context, theme, state);
    }

    return _buildProgressState(theme, state);
  }

  Widget _buildIdleState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('导入PDF真题', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '支持带答案解析版和纯题干版PDF\n支持扫描版PDF（云端OCR识别）\n自动识别题目、选项、答案\n自动分类到对应模块',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 剩余次数显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _quotaExhausted ? Colors.red.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _quotaExhausted ? Icons.block : Icons.cloud_queue,
                    size: 16,
                    color: _quotaExhausted ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _quotaExhausted ? '今日额度已用完' : '今日剩余 $_remainingQuota 次',
                    style: TextStyle(
                      fontSize: 12,
                      color: _quotaExhausted ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _quotaExhausted ? null : _pickAndImport,
                icon: const Icon(Icons.file_open),
                label: const Text('选择PDF文件'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '也可以从文件管理器或网盘中直接选择PDF文件用本APP打开',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressState(ThemeData theme, ImportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            const SizedBox(height: 24),
            Text(state.phaseText, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 8),
            Text('${(state.progress * 100).toInt()}%', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ThemeData theme, ImportState state) {
    final isImageOnly = state.error?.contains('纯图片') ?? false;
    final isQuotaExhausted = state.error?.contains('额度') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isQuotaExhausted ? Icons.block : Icons.error_outline,
              size: 80,
              color: isQuotaExhausted ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isQuotaExhausted ? '今日免费额度已用完' : (isImageOnly ? '无法解析此PDF' : '导入失败'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              isQuotaExhausted
                  ? '今日免费识别额度已用完\n次日零点自动恢复可用'
                  : (isImageOnly
                      ? '该PDF为纯图片文件，无法自动识别文字内容\n请尝试使用包含文字层的PDF文件'
                      : state.error ?? '未知错误'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(importProvider.notifier).reset();
                  _checkQuota();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重新选择PDF'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState(BuildContext context, ThemeData theme, ImportState state) {
    final result = state.result!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Success icon
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Center(
          child: Text('导入完成', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('耗时 ${result.duration.inSeconds} 秒', style: theme.textTheme.bodySmall),
        ),
        if (result.isOcr) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.orange.shade50,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.cloud_queue, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '本次使用云端OCR识别导入扫描版PDF',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Stats cards
        Row(
          children: [
            _statCard('总解析', '${result.totalParsed}', Colors.blue, theme),
            const SizedBox(width: 8),
            _statCard('新导入', '${result.imported}', Colors.green, theme),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _statCard('重复跳过', '${result.duplicates}', Colors.orange, theme),
            const SizedBox(width: 8),
            _statCard('识别失败', '${result.failed}', Colors.red, theme),
          ],
        ),
        const SizedBox(height: 24),

        // Failed questions
        if (result.failedQuestions.isNotEmpty) ...[
          Text('识别失败的题目 (${result.failedQuestions.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...result.failedQuestions.take(10).map((q) => Card(
            child: ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: Text(q.content.length > 60 ? '${q.content.substring(0, 60)}...' : q.content),
              subtitle: Text(q.errorReason ?? '解析异常', style: const TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.edit),
              onTap: () {
                context.push('/manage/edit-question', extra: q);
              },
            ),
          )),
          if (result.failedQuestions.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('还有${result.failedQuestions.length - 10}道题未显示', style: theme.textTheme.bodySmall),
            ),
          const SizedBox(height: 16),
        ],

        // Unclassified questions
        if (result.unclassifiedQuestions.isNotEmpty) ...[
          Text('未分类题目 (${result.unclassifiedQuestions.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...result.unclassifiedQuestions.take(10).map((q) => Card(
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: Text(q.content.length > 60 ? '${q.content.substring(0, 60)}...' : q.content),
              trailing: const Icon(Icons.category),
              onTap: () {
                context.push('/manage/edit-question', extra: q);
              },
            ),
          )),
          const SizedBox(height: 16),
        ],

        // Action buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('返回题库管理'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _pickAndImport,
            icon: const Icon(Icons.add),
            label: const Text('继续导入'),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
