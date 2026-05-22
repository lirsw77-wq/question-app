import '../../domain/enums/exam_module.dart';

class QuestionClassifier {
  static final Map<String, List<String>> _keywordMap = {
    '法律': ['宪法', '民法', '刑法', '行政法', '诉讼', '法律', '法规', '司法', '条款', '处罚', '犯罪', '民事', '刑事', '仲裁', '侵权', '合同法', '劳动法'],
    '政治': ['马克思', '毛泽东', '习近平', '中国特色社会主义', '哲学', '唯物', '辩证', '意识形态', '社会主义', '共产党', '政治', '思想', '理论', '发展观', '矛盾'],
    '经济': ['GDP', '通货', '市场', '宏观', '微观', '财政', '税收', '货币', '金融', '经济', '贸易', '投资', '消费', '产业', '供给', '需求', '通胀'],
    '管理': ['管理', '组织', '领导', '决策', '人事', '行政管理', '公共管理', '激励', '沟通', '协调', '计划', '控制', '效率', '绩效'],
    '公文': ['公文', '通知', '通报', '报告', '请示', '函', '批复', '纪要', '决定', '命令', '公告', '通告', '议案', '意见', '会议纪要'],
    '科技': ['科技', '互联网', '航天', '生物', '物理', '化学', '信息技术', '人工智能', '量子', '芯片', '5G', '大数据', '云计算', '基因', '新能源'],
    '人文': ['历史', '文学', '艺术', '传统文化', '诗词', '书法', '哲学', '文化', '教育', '道德', '礼仪', '民俗', '遗产', '考古'],
    '时政': ['二十大', '两会', '政府工作报告', '时事', '最新', '2024', '2025', '2026', '十四五', '全面建设', '现代化', '新质生产力', '乡村振兴', '一带一路'],
    '言语理解': ['选词填空', '阅读理解', '语句', '排列', '词语', '成语', '病句', '歧义', '概括', '主旨'],
    '数量关系': ['计算', '数列', '比例', '工程', '行程', '排列组合', '概率', '方程', '几何', '利润', '浓度', '年龄'],
    '判断推理': ['图形', '逻辑', '类比', '定义判断', '推理', '三段论', '假言', '真假', '削弱', '加强'],
    '资料分析': ['增长率', '比重', '倍数', '统计', '图表', '同比', '环比', '基期', '现期', '百分比'],
    '归纳概括': ['概括', '归纳', '总结', '材料', '要点', '提炼'],
    '提出对策': ['对策', '建议', '措施', '方案', '解决', '应对'],
    '综合分析': ['分析', '评价', '看法', '认识', '理解', '启示'],
    '贯彻执行': ['公文写作', '倡议书', '讲话稿', '方案', '报告', '发言稿', '调研'],
    '大作文': ['作文', '议论文', '论述', '论点', '论据', '论证'],
  };

  ({String module, String chapter}) classify(String content) {
    final scores = <String, int>{};
    for (final entry in _keywordMap.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (content.contains(keyword)) score++;
      }
      if (score > 0) scores[entry.key] = score;
    }

    if (scores.isEmpty) return (module: '公共基础知识', chapter: '政治');

    final best = scores.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (best.value < 1) return (module: '公共基础知识', chapter: '政治');

    final chapter = best.key;
    final module = _getModuleForChapter(chapter);
    return (module: module, chapter: chapter);
  }

  String _getModuleForChapter(String chapter) {
    for (final m in ExamModule.values) {
      if (m.chapters.contains(chapter)) return m.label;
    }
    return '公共基础知识';
  }
}
