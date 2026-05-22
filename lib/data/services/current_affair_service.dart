import 'package:dio/dio.dart';
import '../models/current_affair.dart';
import '../repositories/current_affair_repository.dart';

class CurrentAffairService {
  final CurrentAffairRepository _repo;
  final Dio _dio = Dio();

  // 使用免费的时政API获取数据
  static const String _baseUrl = 'https://api.oioweb.cn/api/common/HotList';

  CurrentAffairService(this._repo);

  /// 获取热点新闻列表
  Future<List<CurrentAffair>> fetchHotNews({int page = 1}) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {'type': 'weibo'},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['code'] == 200 && data['result'] != null) {
          final List<dynamic> items = data['result'];
          final now = DateTime.now().millisecondsSinceEpoch;
          final affairs = items.take(30).map((item) {
            return CurrentAffair(
              title: item['title']?.toString() ?? '未知标题',
              content: item['desc']?.toString() ?? item['title']?.toString() ?? '',
              category: _categorizeTitle(item['title']?.toString() ?? ''),
              source: '微博热搜',
              publishDate: now,
              createdAt: now,
            );
          }).toList();

          // 批量保存到数据库
          await _repo.batchInsert(affairs);
          return affairs;
        }
      }
    } catch (e) {
      // 网络失败时从本地获取
    }

    // 从本地数据库获取
    return await _repo.getAll();
  }

  /// 根据标题自动分类
  String _categorizeTitle(String title) {
    if (title.contains('经济') || title.contains('GDP') || title.contains('股市') || title.contains('金融')) {
      return '经济';
    }
    if (title.contains('政治') || title.contains('两会') || title.contains('政府') || title.contains('政策')) {
      return '政治';
    }
    if (title.contains('科技') || title.contains('AI') || title.contains('航天') || title.contains('芯片')) {
      return '科技';
    }
    if (title.contains('法律') || title.contains('法规') || title.contains('司法')) {
      return '法律';
    }
    if (title.contains('教育') || title.contains('高考') || title.contains('考试')) {
      return '教育';
    }
    if (title.contains('社会') || title.contains('民生') || title.contains('健康')) {
      return '社会';
    }
    return '综合';
  }

  /// 获取所有分类
  List<String> getCategories() {
    return ['全部', '政治', '经济', '科技', '法律', '教育', '社会', '综合'];
  }
}
