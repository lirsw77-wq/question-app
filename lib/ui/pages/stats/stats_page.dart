import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/stats_provider.dart';
import '../../widgets/bottom_nav_bar.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalPractice = ref.watch(totalPracticeCountProvider);
    final learningDays = ref.watch(learningDaysProvider);
    final consecutiveDays = ref.watch(consecutiveDaysProvider);
    final accuracyByModule = ref.watch(accuracyByModuleProvider);
    final dailyStats = ref.watch(dailyStatsProvider(30));
    final weakChapters = ref.watch(weakChaptersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('学习统计')),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalPracticeCountProvider);
          ref.invalidate(totalCorrectCountProvider);
          ref.invalidate(learningDaysProvider);
          ref.invalidate(consecutiveDaysProvider);
          ref.invalidate(accuracyByModuleProvider);
          ref.invalidate(dailyStatsProvider);
          ref.invalidate(weakChaptersProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Overall stats
            Row(
              children: [
                _statCard(context, '总做题', totalPractice, Icons.quiz, Colors.blue),
                const SizedBox(width: 8),
                _statCard(context, '学习天数', learningDays, Icons.calendar_today, Colors.green),
                const SizedBox(width: 8),
                _statCard(context, '连续天数', consecutiveDays, Icons.local_fire_department, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),

            // Accuracy by module
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('各科目正确率', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: accuracyByModule.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('加载失败: $e')),
                        data: (data) {
                          if (data.isEmpty) return const Center(child: Text('暂无数据'));
                          return BarChart(
                            BarChartData(
                              barGroups: data.asMap().entries.map((entry) {
                                final accuracy = (entry.value['accuracy'] as double? ?? 0) * 100;
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: accuracy,
                                      color: accuracy >= 80 ? Colors.green : accuracy >= 60 ? Colors.orange : Colors.red,
                                      width: 30,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }).toList(),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < data.length) {
                                        final name = data[idx]['module'] as String;
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(name.length > 4 ? '${name.substring(0, 4)}...' : name, style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                                    getTitlesWidget: (value, meta) => Text('${value.toInt()}%', style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                              maxY: 100,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Daily trend
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('近30天做题趋势', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: dailyStats.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('加载失败: $e')),
                        data: (data) {
                          if (data.isEmpty) return const Center(child: Text('暂无数据'));
                          final spots = data.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), (entry.value['total'] as int? ?? 0).toDouble());
                          }).toList();
                          return LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 2,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
                                ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                                    getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: true, drawVerticalLine: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Weak chapters
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('薄弱知识点', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    weakChapters.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('加载失败: $e'),
                      data: (data) {
                        if (data.isEmpty) return const Text('暂无数据', style: TextStyle(color: Colors.grey));
                        return Column(
                          children: data.map((w) {
                            final accuracy = (w['accuracy'] as double? ?? 0) * 100;
                            return ListTile(
                              leading: _accuracyCircle(accuracy),
                              title: Text('${w['chapter']}'),
                              subtitle: Text('${w['module']} | ${w['correct']}/${w['total']}'),
                              dense: true,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, AsyncValue<int> value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              value.when(
                loading: () => const Text('...'),
                error: (_, _) => const Text('0'),
                data: (v) => Text('$v', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accuracyCircle(double accuracy) {
    final color = accuracy >= 80 ? Colors.green : accuracy >= 60 ? Colors.orange : Colors.red;
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: accuracy / 100,
            strokeWidth: 3,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text('${accuracy.round()}%', style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
