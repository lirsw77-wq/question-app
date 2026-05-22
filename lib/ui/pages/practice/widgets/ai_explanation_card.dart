import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/question.dart';
import '../../../../providers/database_provider.dart';
import '../../../../data/services/multi_ai_service.dart';

class AiExplanationCard extends ConsumerStatefulWidget {
  final Question question;
  const AiExplanationCard({super.key, required this.question});

  @override
  ConsumerState<AiExplanationCard> createState() => _AiExplanationCardState();
}

class _AiExplanationCardState extends ConsumerState<AiExplanationCard> {
  String? _explanation;
  bool _isLoading = false;
  bool _expanded = false;
  AiModel _selectedModel = AiModel.doubao;

  @override
  void initState() {
    super.initState();
    if (widget.question.aiExplanation != null && widget.question.aiExplanation!.isNotEmpty) {
      _explanation = widget.question.aiExplanation;
    }
  }

  Future<void> _loadExplanation() async {
    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(multiAiServiceProvider);
      final result = await aiService.explainQuestion(
        widget.question.content,
        widget.question.answer,
        model: _selectedModel,
      );
      if (mounted) {
        setState(() {
          _explanation = result;
          _isLoading = false;
          _expanded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _explanation = '获取AI讲解失败: $e';
          _isLoading = false;
          _expanded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modelNames = {AiModel.doubao: '豆包', AiModel.tongyi: '通义', AiModel.zhipu: '智谱'};

    return Card(
      color: Colors.blue.withValues(alpha: 0.05),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
            title: Row(
              children: [
                const Text('AI讲解'),
                const SizedBox(width: 8),
                // Model selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AiModel>(
                      value: _selectedModel,
                      isDense: true,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                      items: AiModel.values.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(modelNames[m]!),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedModel = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            subtitle: _explanation != null ? const Text('点击查看详细讲解') : const Text('获取解题思路分析'),
            trailing: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_expanded ? Icons.expand_less : Icons.expand_more),
            onTap: () {
              if (_explanation == null) {
                _loadExplanation();
              } else {
                setState(() => _expanded = !_expanded);
              }
            },
          ),
          if (_expanded && _explanation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_explanation!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
                  const SizedBox(height: 8),
                  // Re-generate with different model
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _explanation = null);
                        _loadExplanation();
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('换模型重新生成', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
