import 'package:flutter/material.dart';
import '../../../../data/models/question.dart';
import '../../../../domain/enums/question_type.dart';
import '../../../widgets/question_type_badge.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final String? userAnswer;
  final bool isAnswered;
  final Function(String) onAnswer;

  const QuestionCard({
    super.key,
    required this.question,
    this.userAnswer,
    required this.isAnswered,
    required this.onAnswer,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  final Set<String> _selectedOptions = {};
  final TextEditingController _fillController = TextEditingController();
  final TextEditingController _essayController = TextEditingController();

  @override
  void dispose() {
    _fillController.dispose();
    _essayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qType = QuestionType.fromValue(widget.question.type);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam source badge (top-left) - only for imported questions
            if (widget.question.source != 'builtin')
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  (widget.question.examSource != null && widget.question.examSource!.isNotEmpty)
                      ? widget.question.examSource!
                      : '未知来源真题',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            // Type badge, difficulty, chapter
            Row(
              children: [
                QuestionTypeBadge(type: widget.question.type),
                const SizedBox(width: 8),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < widget.question.difficulty ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  )),
                ),
                const Spacer(),
                Text(widget.question.chapter, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),

            // Question content
            Text(widget.question.content, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            const SizedBox(height: 16),

            // Answer area based on type
            if (!widget.isAnswered) ...[
              _buildAnswerInput(qType),
            ] else ...[
              _buildAnsweredState(qType),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(QuestionType type) {
    switch (type) {
      case QuestionType.singleChoice:
        return _buildSingleChoice();
      case QuestionType.multipleChoice:
        return _buildMultipleChoice();
      case QuestionType.trueFalse:
        return _buildTrueFalse();
      case QuestionType.fillBlank:
        return _buildFillBlank();
      case QuestionType.essay:
        return _buildEssay();
    }
  }

  Widget _buildSingleChoice() {
    final options = widget.question.optionsList;
    return Column(
      children: options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final letter = option.substring(0, 1);
                widget.onAnswer(letter);
              },
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(12),
              ),
              child: Text(option),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoice() {
    final options = widget.question.optionsList;
    return Column(
      children: [
        ...options.map((option) {
          final letter = option.substring(0, 1);
          return CheckboxListTile(
            value: _selectedOptions.contains(letter),
            title: Text(option),
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _selectedOptions.add(letter);
                } else {
                  _selectedOptions.remove(letter);
                }
              });
            },
          );
        }),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedOptions.isEmpty
                ? null
                : () => widget.onAnswer((_selectedOptions.toList()..sort()).join(',')),
            child: const Text('提交答案'),
          ),
        ),
      ],
    );
  }

  Widget _buildTrueFalse() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => widget.onAnswer('A'),
            icon: const Icon(Icons.check, color: Colors.green),
            label: const Text('正确'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => widget.onAnswer('B'),
            icon: const Icon(Icons.close, color: Colors.red),
            label: const Text('错误'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildFillBlank() {
    return Column(
      children: [
        TextField(
          controller: _fillController,
          decoration: const InputDecoration(
            hintText: '请输入答案',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _fillController.text.isEmpty
                ? null
                : () => widget.onAnswer(_fillController.text),
            child: const Text('提交答案'),
          ),
        ),
      ],
    );
  }

  Widget _buildEssay() {
    return Column(
      children: [
        TextField(
          controller: _essayController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '请输入你的答案（提交后可对照参考答案）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onAnswer(_essayController.text),
            child: const Text('提交答案'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnsweredState(QuestionType type) {
    if (type == QuestionType.essay) {
      return const SizedBox(); // Essay shows explanation directly
    }

    final options = widget.question.optionsList;
    final correctAnswer = widget.question.answer;
    final userAnswer = widget.userAnswer ?? '';

    if (type == QuestionType.singleChoice || type == QuestionType.trueFalse) {
      return Column(
        children: options.map((option) {
          final letter = option.substring(0, 1);
          final isCorrect = letter == correctAnswer;
          final isUserChoice = letter == userAnswer;

          Color? bgColor;
          if (isCorrect) bgColor = Colors.green.withValues(alpha: 0.1);
          if (isUserChoice && !isCorrect) bgColor = Colors.red.withValues(alpha: 0.1);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect
                    ? Colors.green
                    : (isUserChoice ? Colors.red : Colors.grey.shade300),
                width: isCorrect || isUserChoice ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                if (isUserChoice && !isCorrect) const Icon(Icons.cancel, color: Colors.red, size: 20),
                if (!isCorrect && !isUserChoice) const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(option)),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (type == QuestionType.multipleChoice) {
      final correctSet = correctAnswer.split(',').map((e) => e.trim()).toSet();
      final userSet = userAnswer.split(',').map((e) => e.trim()).toSet();

      return Column(
        children: options.map((option) {
          final letter = option.substring(0, 1);
          final isCorrect = correctSet.contains(letter);
          final isUserChoice = userSet.contains(letter);

          Color? bgColor;
          if (isCorrect) bgColor = Colors.green.withValues(alpha: 0.1);
          if (isUserChoice && !isCorrect) bgColor = Colors.red.withValues(alpha: 0.1);

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCorrect
                    ? Colors.green
                    : (isUserChoice ? Colors.red : Colors.grey.shade300),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                if (isUserChoice && !isCorrect) const Icon(Icons.cancel, color: Colors.red, size: 20),
                if (!isCorrect && !isUserChoice) const SizedBox(width: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(option)),
              ],
            ),
          );
        }).toList(),
      );
    }

    if (type == QuestionType.fillBlank) {
      final isCorrect = userAnswer.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('你的答案: $userAnswer', style: TextStyle(color: isCorrect ? Colors.green : Colors.red)),
          if (!isCorrect) Text('正确答案: $correctAnswer', style: const TextStyle(color: Colors.green)),
        ],
      );
    }

    return const SizedBox();
  }
}
