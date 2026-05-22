import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/question.dart';

class QuestionRepository {
  final AppDatabase _db;

  QuestionRepository(this._db);

  Future<List<Question>> getQuestionsByModule(String module) async {
    final db = await _db.database;
    final maps = await db.query('questions', where: 'module = ?', whereArgs: [module]);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<List<Question>> getQuestionsByChapter(String module, String chapter) async {
    final db = await _db.database;
    final maps = await db.query('questions',
        where: 'module = ? AND chapter = ?', whereArgs: [module, chapter]);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<List<Question>> getRandomQuestions(String module, int count, {String? chapter}) async {
    final db = await _db.database;
    final where = chapter != null ? 'module = ? AND chapter = ?' : 'module = ?';
    final args = chapter != null ? [module, chapter] : [module];
    final maps = await db.query('questions',
        where: where, whereArgs: args, orderBy: 'RANDOM()', limit: count);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<Question?> getQuestionById(int id) async {
    final db = await _db.database;
    final maps = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Question.fromMap(maps.first);
  }

  Future<List<Question>> getQuestionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await _db.database;
    final placeholders = ids.map((_) => '?').join(',');
    final maps = await db.query('questions',
        where: 'id IN ($placeholders)', whereArgs: ids);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<List<Question>> getSimilarQuestions(Question question, int count) async {
    final db = await _db.database;
    // Priority: same chapter + same type, then same chapter, then same module
    var maps = await db.query('questions',
        where: 'module = ? AND chapter = ? AND type = ? AND id != ?',
        whereArgs: [question.module, question.chapter, question.type, question.id],
        orderBy: 'RANDOM()', limit: count);

    if (maps.length < count) {
      final remaining = count - maps.length;
      final existingIds = maps.map((m) => m['id'] as int).toList();
      existingIds.add(question.id!);
      final placeholders = existingIds.map((_) => '?').join(',');
      final moreMaps = await db.query('questions',
          where: 'module = ? AND chapter = ? AND id NOT IN ($placeholders)',
          whereArgs: [question.module, question.chapter, ...existingIds],
          orderBy: 'RANDOM()', limit: remaining);
      maps = [...maps, ...moreMaps];
    }

    if (maps.length < count) {
      final existingIds = maps.map((m) => m['id'] as int).toList();
      existingIds.add(question.id!);
      final placeholders = existingIds.map((_) => '?').join(',');
      final moreMaps = await db.query('questions',
          where: 'module = ? AND id NOT IN ($placeholders)',
          whereArgs: [question.module, ...existingIds],
          orderBy: 'RANDOM()', limit: count - maps.length);
      maps = [...maps, ...moreMaps];
    }

    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<int> getQuestionCount(String module, {String? chapter}) async {
    final db = await _db.database;
    final where = chapter != null ? 'module = ? AND chapter = ?' : 'module = ?';
    final args = chapter != null ? [module, chapter] : [module];
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions WHERE $where', args),
    );
    return count ?? 0;
  }

  Future<int> insertQuestion(Question question) async {
    final db = await _db.database;
    return await db.insert('questions', question.toMap());
  }

  Future<void> insertQuestions(List<Question> questions) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getChapterStats(String module) async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT chapter,
             COUNT(*) as total,
             SUM(CASE WHEN id IN (
               SELECT question_id FROM wrong_records WHERE is_mastered = 0
             ) THEN 1 ELSE 0 END) as wrong_count
      FROM questions WHERE module = ?
      GROUP BY chapter
    ''', [module]);
  }

  Future<List<Question>> getAllQuestions() async {
    final db = await _db.database;
    final maps = await db.query('questions');
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<void> deleteQuestion(int id) async {
    final db = await _db.database;
    await db.delete('wrong_records', where: 'question_id = ?', whereArgs: [id]);
    await db.delete('favorites', where: 'question_id = ?', whereArgs: [id]);
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateQuestion(Question question) async {
    final db = await _db.database;
    await db.update('questions', question.toMap(), where: 'id = ?', whereArgs: [question.id]);
  }

  Future<bool> existsDuplicate(String content, String options) async {
    final db = await _db.database;
    final normalizedContent = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalizedOptions = options.trim().replaceAll(RegExp(r'\s+'), ' ');
    final maps = await db.query('questions',
      where: 'content = ? AND options = ?',
      whereArgs: [normalizedContent, normalizedOptions],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  Future<void> deleteQuestionsByModule(String module) async {
    final db = await _db.database;
    final questions = await db.query('questions',
        where: 'module = ?', whereArgs: [module], columns: ['id']);
    final ids = questions.map((q) => q['id'] as int).toList();
    if (ids.isEmpty) return;
    for (final id in ids) {
      await db.delete('wrong_records', where: 'question_id = ?', whereArgs: [id]);
      await db.delete('favorites', where: 'question_id = ?', whereArgs: [id]);
    }
    await db.delete('questions', where: 'module = ?', whereArgs: [module]);
  }

  Future<List<Question>> getFilteredQuestions(String module, {String? examSource}) async {
    final db = await _db.database;
    String where = 'module = ?';
    List<dynamic> args = [module];
    if (examSource != null && examSource.isNotEmpty) {
      where += ' AND exam_source LIKE ?';
      args.add('%$examSource%');
    }
    final maps = await db.query('questions', where: where, whereArgs: args);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  Future<List<String>> getDistinctExamSources(String module) async {
    final db = await _db.database;
    final maps = await db.rawQuery(
      "SELECT DISTINCT exam_source FROM questions WHERE module = ? AND exam_source IS NOT NULL AND exam_source != ''",
      [module],
    );
    return maps.map((m) => m['exam_source'] as String).toList();
  }

  Future<int> getTotalQuestionCount() async {
    final db = await _db.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );
    return count ?? 0;
  }

  Future<Map<String, int>> getQuestionCountByModule() async {
    final db = await _db.database;
    final maps = await db.rawQuery('SELECT module, COUNT(*) as cnt FROM questions GROUP BY module');
    return {for (var m in maps) m['module'] as String: m['cnt'] as int};
  }
}
