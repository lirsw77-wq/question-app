import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import '../models/question.dart';
import '../repositories/question_repository.dart';

class ImportExportService {
  final AppDatabase _db;
  final QuestionRepository _questionRepo;

  ImportExportService(this._db, this._questionRepo);

  /// Export wrong quiz questions as readable text for sharing/printing
  Future<String> exportWrongQuestionsAsText() async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT q.content, q.options, q.answer, q.explanation, q.module, q.chapter,
             q.knowledge_points, wr.wrong_count
      FROM wrong_records wr
      JOIN questions q ON wr.question_id = q.id
      WHERE wr.is_mastered = 0
      ORDER BY q.module, q.chapter, wr.wrong_count DESC
    ''');

    if (results.isEmpty) return '暂无错题记录';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('    上岸事考 - 刷题错题本');
    buffer.writeln('    导出时间：${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln();

    String currentModule = '';
    String currentChapter = '';

    for (int i = 0; i < results.length; i++) {
      final q = results[i];
      final module = q['module'] as String? ?? '';
      final chapter = q['chapter'] as String? ?? '';

      if (module != currentModule) {
        currentModule = module;
        currentChapter = '';
        buffer.writeln('【$module】');
        buffer.writeln('───────────────────────────────────');
      }
      if (chapter != currentChapter) {
        currentChapter = chapter;
        buffer.writeln('  ▶ $chapter');
        buffer.writeln();
      }

      buffer.writeln('${i + 1}. ${q['content']}');

      // Parse options
      final optionsStr = q['options'] as String? ?? '[]';
      try {
        final options = jsonDecode(optionsStr) as List;
        for (final opt in options) {
          buffer.writeln('   $opt');
        }
      } catch (_) {}

      buffer.writeln('   正确答案：${q['answer']}');
      buffer.writeln('   错误次数：${q['wrong_count']}次');

      final explanation = q['explanation'] as String? ?? '';
      if (explanation.isNotEmpty) {
        buffer.writeln('   解析：$explanation');
      }

      final knowledgePoints = q['knowledge_points'] as String? ?? '[]';
      if (knowledgePoints != '[]') {
        buffer.writeln('   知识点：$knowledgePoints');
      }
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('共 ${results.length} 道错题');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  /// Export recite wrong records as readable text
  Future<String> exportReciteWrongAsText() async {
    final db = await _db.database;
    final results = await db.query(
      'recite_wrong_records',
      where: 'is_mastered = 0',
      orderBy: 'knowledge_point, wrong_count DESC',
    );

    if (results.isEmpty) return '暂无背诵错题记录';

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('    上岸事考 - 背诵错题本');
    buffer.writeln('    导出时间：${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('═══════════════════════════════════');
    buffer.writeln();

    String currentKp = '';

    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      final kp = r['knowledge_point'] as String? ?? '';

      if (kp != currentKp) {
        currentKp = kp;
        buffer.writeln('【$kp】');
        buffer.writeln('───────────────────────────────────');
      }

      buffer.writeln('${i + 1}. ${r['content']}');
      buffer.writeln('   错误次数：${r['wrong_count']}次');
      buffer.writeln('   复习阶段：${r['review_stage']}/6');
      buffer.writeln();
    }

    buffer.writeln('═══════════════════════════════════');
    buffer.writeln('共 ${results.length} 条背诵错题');
    buffer.writeln('═══════════════════════════════════');

    return buffer.toString();
  }

  /// Share wrong questions text
  Future<void> shareWrongQuestions() async {
    final text = await exportWrongQuestionsAsText();
    await Share.share(text, subject: '上岸事考-刷题错题本');
  }

  /// Share recite wrong text
  Future<void> shareReciteWrong() async {
    final text = await exportReciteWrongAsText();
    await Share.share(text, subject: '上岸事考-背诵错题本');
  }

  Future<int> importQuestionsFromJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return 0;

    final file = File(result.files.first.path!);
    final content = await file.readAsString();
    final data = json.decode(content);

    int count = 0;
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic> && item.containsKey('questions')) {
          final module = item['module'] as String;
          final chapter = item['chapter'] as String;
          final questions = item['questions'] as List;
          final questionList = questions
              .map((q) => Question.fromJson(q as Map<String, dynamic>, module, chapter))
              .toList();
          await _questionRepo.insertQuestions(questionList);
          count += questionList.length;
        }
      }
    } else if (data is Map<String, dynamic> && data.containsKey('questions')) {
      final module = data['module'] as String;
      final chapter = data['chapter'] as String;
      final questions = data['questions'] as List;
      final questionList = questions
          .map((q) => Question.fromJson(q as Map<String, dynamic>, module, chapter))
          .toList();
      await _questionRepo.insertQuestions(questionList);
      count = questionList.length;
    }
    return count;
  }

  Future<void> exportBackup() async {
    final db = await _db.database;

    final questions = await db.query('questions');
    final wrongRecords = await db.query('wrong_records');
    final favorites = await db.query('favorites');
    final practiceRecords = await db.query('practice_records');
    final settings = await db.query('user_settings');
    final checkInRecords = await db.query('check_in_records');
    final examCountdowns = await db.query('exam_countdowns');
    final currentAffairs = await db.query('current_affairs');
    final reciteWrongRecords = await db.query('recite_wrong_records');

    final backup = {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'questions': questions,
      'wrong_records': wrongRecords,
      'favorites': favorites,
      'practice_records': practiceRecords,
      'user_settings': settings,
      'check_in_records': checkInRecords,
      'exam_countdowns': examCountdowns,
      'current_affairs': currentAffairs,
      'recite_wrong_records': reciteWrongRecords,
    };

    final jsonStr = json.encode(backup);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'henan_exam_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(p.join(directory.path, fileName));
    await file.writeAsString(jsonStr);

    await Share.shareXFiles([XFile(file.path)], subject: '河南事业单位刷题APP数据备份');
  }

  Future<bool> importBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return false;

    final file = File(result.files.first.path!);
    final content = await file.readAsString();
    final backup = json.decode(content) as Map<String, dynamic>;

    final db = await _db.database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('practice_records');
      await txn.delete('favorites');
      await txn.delete('wrong_records');
      await txn.delete('user_settings');
      await txn.delete('check_in_records');
      await txn.delete('exam_countdowns');
      await txn.delete('current_affairs');
      await txn.delete('recite_wrong_records');

      // Import questions if present in backup
      if (backup.containsKey('questions')) {
        await txn.delete('questions');
        for (final q in (backup['questions'] as List? ?? [])) {
          await txn.insert('questions', Map<String, dynamic>.from(q as Map));
        }
      }

      // Import wrong records
      for (final record in (backup['wrong_records'] as List? ?? [])) {
        await txn.insert('wrong_records', Map<String, dynamic>.from(record as Map));
      }
      // Import favorites
      for (final fav in (backup['favorites'] as List? ?? [])) {
        await txn.insert('favorites', Map<String, dynamic>.from(fav as Map));
      }
      // Import practice records
      for (final record in (backup['practice_records'] as List? ?? [])) {
        await txn.insert('practice_records', Map<String, dynamic>.from(record as Map));
      }
      // Import settings
      for (final setting in (backup['user_settings'] as List? ?? [])) {
        await txn.insert('user_settings', Map<String, dynamic>.from(setting as Map));
      }
      // Import check-in records
      for (final record in (backup['check_in_records'] as List? ?? [])) {
        await txn.insert('check_in_records', Map<String, dynamic>.from(record as Map));
      }
      // Import exam countdowns
      for (final record in (backup['exam_countdowns'] as List? ?? [])) {
        await txn.insert('exam_countdowns', Map<String, dynamic>.from(record as Map));
      }
      // Import current affairs
      for (final record in (backup['current_affairs'] as List? ?? [])) {
        await txn.insert('current_affairs', Map<String, dynamic>.from(record as Map));
      }
      // Import recite wrong records
      for (final record in (backup['recite_wrong_records'] as List? ?? [])) {
        await txn.insert('recite_wrong_records', Map<String, dynamic>.from(record as Map));
      }
    });
    return true;
  }
}
