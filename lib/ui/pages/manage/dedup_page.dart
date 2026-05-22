import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_provider.dart';

class DedupPage extends ConsumerStatefulWidget {
  const DedupPage({super.key});

  @override
  ConsumerState<DedupPage> createState() => _DedupPageState();
}

class _DedupPageState extends ConsumerState<DedupPage> {
  bool _isScanning = false;
  bool _isCleaned = false;
  dynamic _report;

  Future<void> _scanAndClean() async {
    setState(() {
      _isScanning = true;
      _report = null;
      _isCleaned = false;
    });

    try {
      final dedupService = ref.read(dedupServiceProvider);
      final report = await dedupService.deduplicate();
      setState(() {
        _report = report;
        _isCleaned = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失败: $e')));
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('题库去重清理')),
      body: _isScanning
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在扫描全库题目...'),
                ],
              ),
            )
          : _isCleaned && _report != null
              ? _buildReport(theme)
              : _buildIdle(theme),
    );
  }

  Widget _buildIdle(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cleaning_services, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text('题库去重清理', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '扫描全部8个模块的题目\n按题干+选项比对，自动清除重复题\n保留最早入库的原题，删除副本',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanAndClean,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始扫描清理'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Icon(Icons.check_circle, size: 64, color: Colors.green),
        const SizedBox(height: 16),
        Center(
          child: Text('清理完成', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        _reportRow('扫描总题数', '${_report.totalScanned}'),
        _reportRow('发现重复组', '${_report.duplicateGroupsFound}'),
        _reportRow('删除重复题', '${_report.questionsRemoved}'),
        _reportRow('耗时', '${_report.duration.inSeconds} 秒'),
        const SizedBox(height: 24),
        if (_report.questionsRemoved > 0)
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '已成功清理${_report.questionsRemoved}道重复题目，错题记录和收藏已自动转移到原题。',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          )
        else
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('题库中没有发现重复题目，无需清理。', style: TextStyle(color: Colors.blue)),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _scanAndClean,
            child: const Text('重新扫描'),
          ),
        ),
      ],
    );
  }

  Widget _reportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
