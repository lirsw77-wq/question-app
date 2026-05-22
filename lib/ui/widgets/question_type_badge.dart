import 'package:flutter/material.dart';
import '../../domain/enums/question_type.dart';

class QuestionTypeBadge extends StatelessWidget {
  final String type;
  const QuestionTypeBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final qType = QuestionType.fromValue(type);
    Color color;
    switch (qType) {
      case QuestionType.singleChoice:
        color = Colors.blue;
        break;
      case QuestionType.multipleChoice:
        color = Colors.purple;
        break;
      case QuestionType.trueFalse:
        color = Colors.teal;
        break;
      case QuestionType.fillBlank:
        color = Colors.orange;
        break;
      case QuestionType.essay:
        color = Colors.brown;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(qType.label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
