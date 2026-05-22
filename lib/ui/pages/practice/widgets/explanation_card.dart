import 'package:flutter/material.dart';
import '../../../../data/models/question.dart';

class ExplanationCard extends StatelessWidget {
  final Question question;
  final bool isCorrect;
  final String userAnswer;

  const ExplanationCard({
    super.key,
    required this.question,
    required this.isCorrect,
    required this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isCorrect ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isCorrect ? '回答正确!' : '回答错误',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('正确答案: ${question.answer}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (!isCorrect && userAnswer.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('你的答案: $userAnswer', style: const TextStyle(color: Colors.red)),
              ),
            if (question.explanation.isNotEmpty) ...[
              const Divider(height: 16),
              Text('解析:', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(question.explanation, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            ],
          ],
        ),
      ),
    );
  }
}
