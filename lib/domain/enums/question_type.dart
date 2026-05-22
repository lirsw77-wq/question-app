enum QuestionType {
  singleChoice('single_choice', '单选题'),
  multipleChoice('multiple_choice', '多选题'),
  trueFalse('true_false', '判断题'),
  fillBlank('fill_blank', '填空题'),
  essay('essay', '主观题');

  final String value;
  final String label;
  const QuestionType(this.value, this.label);

  static QuestionType fromValue(String value) {
    return QuestionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => QuestionType.singleChoice,
    );
  }
}
