class KnowledgePointStat {
  final String name;
  final String module;
  final String chapter;
  final int totalQuestions;
  final int wrongCount;
  final double accuracy;

  KnowledgePointStat({
    required this.name,
    required this.module,
    required this.chapter,
    required this.totalQuestions,
    required this.wrongCount,
    required this.accuracy,
  });
}
