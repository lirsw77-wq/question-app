enum ExamModule {
  gongji('公共基础知识', 'gongji', ['政治', '法律', '经济', '管理', '公文', '科技', '人文', '时政']),
  zhiCe('职业能力测验', 'zhiCe', ['言语理解', '数量关系', '判断推理', '资料分析']),
  shenLun('申论', 'shenLun', ['归纳概括', '提出对策', '综合分析', '贯彻执行', '大作文']);

  final String label;
  final String assetKey;
  final List<String> chapters;
  const ExamModule(this.label, this.assetKey, this.chapters);

  static ExamModule fromLabel(String label) {
    return ExamModule.values.firstWhere(
      (e) => e.label == label,
      orElse: () => ExamModule.gongji,
    );
  }
}
