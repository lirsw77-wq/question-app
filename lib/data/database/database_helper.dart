import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'app_database.dart';
import '../models/question.dart';

class DatabaseHelper {
  final AppDatabase _appDatabase;

  DatabaseHelper(this._appDatabase);

  Future<bool> isDatabasePopulated() async {
    final db = await _appDatabase.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );
    return (count ?? 0) > 0;
  }

  Future<void> loadBuiltinQuestions() async {
    final db = await _appDatabase.database;
    final assetFiles = [
      'assets/questions/gongji/zhengzhi.json',
      'assets/questions/gongji/falv.json',
      'assets/questions/gongji/jingji.json',
      'assets/questions/gongji/guanli.json',
      'assets/questions/gongji/gongwen.json',
      'assets/questions/gongji/keji.json',
      'assets/questions/gongji/renwen.json',
      'assets/questions/gongji/shizheng.json',
      'assets/questions/zhiCe/yanyu.json',
      'assets/questions/zhiCe/shuliang.json',
      'assets/questions/zhiCe/panduan.json',
      'assets/questions/zhiCe/ziliao.json',
      'assets/questions/shenLun/guina.json',
      'assets/questions/shenLun/duice.json',
      'assets/questions/shenLun/fenxi.json',
      'assets/questions/shenLun/zhixing.json',
      'assets/questions/shenLun/zuowen.json',
    ];

    final batch = db.batch();
    for (final filePath in assetFiles) {
      try {
        final jsonStr = await rootBundle.loadString(filePath);
        final data = json.decode(jsonStr);
        final module = data['module'] as String;
        final chapter = data['chapter'] as String;
        final questions = data['questions'] as List;
        for (final q in questions) {
          final question = Question.fromJson(q as Map<String, dynamic>, module, chapter);
          batch.insert('questions', question.toMap());
        }
      } catch (_) {
        // Asset file not found, skip
      }
    }
    await batch.commit(noResult: true);
  }
}
