import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/database_provider.dart';
import '../../../data/services/multi_ai_service.dart';

class EssayGradingPage extends ConsumerStatefulWidget {
  const EssayGradingPage({super.key});

  @override
  ConsumerState<EssayGradingPage> createState() => _EssayGradingPageState();
}

class _EssayGradingPageState extends ConsumerState<EssayGradingPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  AiModel _selectedModel = AiModel.tongyi;
  bool _isGrading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aiService = ref.read(multiAiServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5EB),
      appBar: AppBar(
        title: const Text('申论AI批改', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // AI模型选择
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择AI模型', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: aiService.getAvailableModels().map((m) {
                      final isSelected = _selectedModel == m['id'];
                      return ChoiceChip(
                        label: Text('${m['icon']} ${m['name']}', style: TextStyle(fontSize: 13)),
                        selected: isSelected,
                        selectedColor: const Color(0xFFFF8C42).withValues(alpha: 0.2),
                        onSelected: (_) => setState(() => _selectedModel = m['id']),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 题目输入
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('申论题目', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: '请输入申论题目...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 作答内容
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('我的作答', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      Text(
                        '${_contentController.text.length}字',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      hintText: '请在此输入您的申论作答内容...\n\n建议输入800-1200字',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 15,
                    minLines: 10,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 提交按钮
            ElevatedButton(
              onPressed: _isGrading ? null : _submitForGrading,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C42),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isGrading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('AI批改中...', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    )
                  : const Text('提交批改', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 20),

            // 批改结果
            if (_result != null) _buildResultCard(theme),
          ],
        ),
      ),
    );
  }

  void _submitForGrading() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写题目和作答内容')),
      );
      return;
    }

    setState(() {
      _isGrading = true;
      _result = null;
    });

    final aiService = ref.read(multiAiServiceProvider);
    final result = await aiService.gradeEssay(
      _titleController.text,
      _contentController.text,
      model: _selectedModel,
    );

    setState(() {
      _isGrading = false;
      _result = result;
    });
  }

  Widget _buildResultCard(ThemeData theme) {
    final score = _result!['score'] as int? ?? 0;
    final comment = _result!['comment'] as String? ?? '';
    final strengths = (_result!['strengths'] as List?)?.cast<String>() ?? [];
    final improvements = (_result!['improvements'] as List?)?.cast<String>() ?? [];
    final rewrite = _result!['rewrite'] as String? ?? '';
    final dimensionScores = (_result!['dimensionScores'] as Map?)?.cast<String, dynamic>() ?? {};

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总分
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: score >= 80
                      ? [const Color(0xFF43A047), const Color(0xFF66BB6A)]
                      : score >= 60
                          ? [const Color(0xFFFF8C42), const Color(0xFFFFB07C)]
                          : [const Color(0xFFE53935), const Color(0xFFFF7043)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$score', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('分', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 维度评分
          if (dimensionScores.isNotEmpty) ...[
            const Text('分项评分', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            ...dimensionScores.entries.map((e) => _buildDimensionBar(e.key, (e.value as num).toInt())),
            const SizedBox(height: 20),
          ],

          // 总体评价
          if (comment.isNotEmpty) ...[
            const Text('总体评价', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(comment, style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
            const SizedBox(height: 16),
          ],

          // 优点
          if (strengths.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.thumb_up, color: Color(0xFF43A047), size: 18),
                const SizedBox(width: 6),
                const Text('优点', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF43A047))),
              ],
            ),
            const SizedBox(height: 8),
            ...strengths.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  ', style: TextStyle(color: Color(0xFF43A047))),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // 改进建议
          if (improvements.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Color(0xFFFF8C42), size: 18),
                const SizedBox(width: 6),
                const Text('改进建议', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFFF8C42))),
              ],
            ),
            const SizedBox(height: 8),
            ...improvements.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  ', style: TextStyle(color: Color(0xFFFF8C42))),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // 修改示范
          if (rewrite.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFF5C6BC0), size: 18),
                const SizedBox(width: 6),
                const Text('修改示范', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5C6BC0))),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(rewrite, style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDimensionBar(String label, int score) {
    final ratio = score / 20.0;
    final color = score >= 16
        ? const Color(0xFF43A047)
        : score >= 12
            ? const Color(0xFFFF8C42)
            : const Color(0xFFE53935);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 40, child: Text('$score/20', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
