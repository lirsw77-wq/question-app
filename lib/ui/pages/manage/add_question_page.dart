import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/exam_module.dart';
import '../../../domain/enums/question_type.dart';
import '../../../providers/database_provider.dart';
import '../../../data/models/question.dart';

class AddQuestionPage extends ConsumerStatefulWidget {
  const AddQuestionPage({super.key});

  @override
  ConsumerState<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends ConsumerState<AddQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  ExamModule _selectedModule = ExamModule.gongji;
  String _selectedChapter = '';
  QuestionType _selectedType = QuestionType.singleChoice;
  final _contentController = TextEditingController();
  final _optionsController = TextEditingController();
  final _answerController = TextEditingController();
  final _explanationController = TextEditingController();
  int _difficulty = 3;

  @override
  void initState() {
    super.initState();
    _selectedChapter = _selectedModule.chapters.first;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _optionsController.dispose();
    _answerController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('添加题目'),
        actions: [
          TextButton(
            onPressed: _saveQuestion,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Module selection
            DropdownButtonFormField<ExamModule>(
              initialValue: _selectedModule,
              decoration: const InputDecoration(labelText: '科目'),
              items: ExamModule.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))).toList(),
              onChanged: (v) {
                setState(() {
                  _selectedModule = v!;
                  _selectedChapter = _selectedModule.chapters.first;
                });
              },
            ),
            const SizedBox(height: 12),

            // Chapter selection
            DropdownButtonFormField<String>(
              initialValue: _selectedChapter,
              decoration: const InputDecoration(labelText: '章节'),
              items: _selectedModule.chapters.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedChapter = v!),
            ),
            const SizedBox(height: 12),

            // Question type
            DropdownButtonFormField<QuestionType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: '题型'),
              items: QuestionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
            ),
            const SizedBox(height: 12),

            // Content
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: '题目内容', hintText: '请输入题目内容'),
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? '请输入题目内容' : null,
            ),
            const SizedBox(height: 12),

            // Options (for choice questions)
            if (_selectedType == QuestionType.singleChoice ||
                _selectedType == QuestionType.multipleChoice) ...[
              TextFormField(
                controller: _optionsController,
                decoration: const InputDecoration(
                  labelText: '选项',
                  hintText: '每行一个选项，如:\nA.选项1\nB.选项2\nC.选项3\nD.选项4',
                ),
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? '请输入选项' : null,
              ),
              const SizedBox(height: 12),
            ],

            // Answer
            TextFormField(
              controller: _answerController,
              decoration: InputDecoration(
                labelText: '正确答案',
                hintText: _selectedType == QuestionType.multipleChoice ? '多个答案用逗号分隔，如: A,B,C' : '如: A',
              ),
              validator: (v) => v == null || v.isEmpty ? '请输入正确答案' : null,
            ),
            const SizedBox(height: 12),

            // Difficulty
            Text('难度: $_difficulty', style: theme.textTheme.bodyMedium),
            Slider(
              value: _difficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_difficulty',
              onChanged: (v) => setState(() => _difficulty = v.round()),
            ),
            const SizedBox(height: 12),

            // Explanation
            TextFormField(
              controller: _explanationController,
              decoration: const InputDecoration(labelText: '解析（选填）', hintText: '请输入题目解析'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _saveQuestion,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('保存题目'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    List<String> options = [];
    if (_selectedType == QuestionType.singleChoice || _selectedType == QuestionType.multipleChoice) {
      options = _optionsController.text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    } else if (_selectedType == QuestionType.trueFalse) {
      options = ['A.正确', 'B.错误'];
    }

    final question = Question(
      content: _contentController.text.trim(),
      type: _selectedType.value,
      options: jsonEncode(options),
      answer: _answerController.text.trim(),
      explanation: _explanationController.text.trim(),
      knowledgePoints: '["$_selectedChapter"]',
      module: _selectedModule.label,
      chapter: _selectedChapter,
      difficulty: _difficulty,
      source: 'manual',
    );

    await ref.read(questionRepositoryProvider).insertQuestion(question);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('题目保存成功')));
      context.pop();
    }
  }
}
