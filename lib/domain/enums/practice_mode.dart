enum PracticeMode {
  sequential('sequential', '顺序练习'),
  random('random', '随机练习'),
  exam('exam', '模拟考试'),
  wrong('wrong', '错题练习'),
  favorite('favorite', '收藏练习'),
  review('review', '智能复习'),
  newOnly('newOnly', '新题练习'),
  wrongOnly('wrongOnly', '仅错题');

  final String value;
  final String label;
  const PracticeMode(this.value, this.label);

  static PracticeMode fromValue(String value) {
    return PracticeMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PracticeMode.sequential,
    );
  }
}
