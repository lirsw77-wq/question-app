import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/parsed_question.dart';
import '../../../data/models/question.dart';
import '../../../providers/database_provider.dart';
import '../../../domain/enums/exam_module.dart';

class EditQuestionPage extends ConsumerStatefulWidget {
  final ParsedQuestion? parsedQuestion;
  final Question? existingQuestion;

  const EditQuestionPage({super.key, this.parsedQuestion, this.existingQuestion});

  @override
  ConsumerState<EditQuestionPage> createState() => _EditQuestionPageState();
}

class _EditQuestionPageState extends ConsumerState<EditQuestionPage> {
  late TextEditingController _contentController;
  late TextEditingController _answerController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  String _selectedType = '单选题';
  String _selectedModule = '公共基础知识';
  String _selectedChapter = '法律';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final q = widget.existingQuestion;
    final pq = widget.parsedQuestion;

    _contentController = TextEditingController(text: q?.content ?? pq?.content ?? '');
    _answerController = TextEditingController(text: q?.answer ?? pq?.answer ?? '');
    _explanationController = TextEditingController(text: q?.explanation ?? pq?.explanation ?? '');

    final options = q?.optionsList ?? pq?.options ?? [];
    _optionControllers = List.generate(
      options.isEmpty ? 4 : options.length,
      (i) => TextEditingController(text: i < options.length ? options[i] : ''),
    );

    _selectedType = q?.type ?? pq?.type ?? '单选题';
    if (q != null) {
      _selectedModule = q.module;
      _selectedChapter = q.chapter;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingQuestion != null ? '编辑题目' : '修复题目'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Question content
          Text('题干内容', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请输入题目内容',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Question type
          Text('题型', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            items: const [
              DropdownMenuItem(value: '单选题', child: Text('单选题')),
              DropdownMenuItem(value: '多选题', child: Text('多选题')),
              DropdownMenuItem(value: '判断题', child: Text('判断题')),
              DropdownMenuItem(value: '填空题', child: Text('填空题')),
              DropdownMenuItem(value: '主观题', child: Text('主观题')),
            ],
            onChanged: (v) => setState(() => _selectedType = v!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // Module and chapter
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('所属模块', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedModule,
                      items: ExamModule.values.map((m) => DropdownMenuItem(value: m.label, child: Text(m.label))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedModule = v!;
                          final module = ExamModule.fromLabel(v);
                          if (!module.chapters.contains(_selectedChapter)) {
                            _selectedChapter = module.chapters.first;
                          }
                        });
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('章节', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: ExamModule.fromLabel(_selectedModule).chapters.contains(_selectedChapter)
                          ? _selectedChapter
                          : ExamModule.fromLabel(_selectedModule).chapters.first,
                      items: ExamModule.fromLabel(_selectedModule).chapters
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedChapter = v!),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Options (for choice questions)
          if (_selectedType == '单选题' || _selectedType == '多选题') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('选项', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    if (_optionControllers.length < 8)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
                      ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            _optionControllers.last.dispose();
                            _optionControllers.removeLast();
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_optionControllers.length, (i) {
              final label = String.fromCharCode(65 + i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _optionControllers[i],
                  decoration: InputDecoration(
                    labelText: '$label.',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Answer
          Text('答案', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              hintText: _selectedType == '单选题' ? '如: A' : _selectedType == '多选题' ? '如: A,B,C' : '请输入答案',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Explanation
          Text('解析', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _explanationController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '请输入答案解析（选填）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('保存题目'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入题干内容')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final options = _optionControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final optionsStr = jsonEncode(options);
      final repo = ref.read(questionRepositoryProvider);
      final exists = await repo.existsDuplicate(content, optionsStr);

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该题目已存在，无需重复保存')));
          setState(() => _isSaving = false);
        }
        return;
      }

      final question = Question(
        content: content,
        module: _selectedModule,
        chapter: _selectedChapter,
        type: _selectedType,
        options: optionsStr,
        answer: _answerController.text.trim(),
        explanation: _explanationController.text.trim(),
        difficulty: 3,
        knowledgePoints: '',
        source: 'manual',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      if (widget.existingQuestion?.id != null) {
        await repo.updateQuestion(question.copyWith(id: widget.existingQuestion!.id));
      } else {
        await repo.insertQuestion(question);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e')));
        setState(() => _isSaving = false);
      }
    }
  }
}
