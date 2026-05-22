import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/wrong_record.dart';

class WrongRecordRepository {
  final AppDatabase _db;

  WrongRecordRepository(this._db);

  Future<void> addWrongRecord(int questionId) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('wrong_records',
        where: 'question_id = ?', whereArgs: [questionId]);

    if (existing.isNotEmpty) {
      final record = WrongRecord.fromMap(existing.first);
      await db.update('wrong_records', {
        'wrong_count': record.wrongCount + 1,
        'last_wrong_time': now,
        'next_review_time': now + _getReviewInterval(0),
        'review_stage': 0,
        'is_mastered': 0,
      }, where: 'id = ?', whereArgs: [record.id]);
    } else {
      await db.insert('wrong_records', WrongRecord(
        questionId: questionId,
        wrongCount: 1,
        lastWrongTime: now,
        nextReviewTime: now + _getReviewInterval(0),
        reviewStage: 0,
        isMastered: false,
      ).toMap());
    }
  }

  Future<void> markCorrect(int questionId) async {
    final db = await _db.database;
    final existing = await db.query('wrong_records',
        where: 'question_id = ?', whereArgs: [questionId]);

    if (existing.isNotEmpty) {
      final record = WrongRecord.fromMap(existing.first);
      final newStage = record.reviewStage + 1;
      if (newStage >= 6) {
        await db.update('wrong_records', {
          'review_stage': newStage,
          'is_mastered': 1,
          'next_review_time': 0,
        }, where: 'id = ?', whereArgs: [record.id]);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.update('wrong_records', {
          'review_stage': newStage,
          'next_review_time': now + _getReviewInterval(newStage),
        }, where: 'id = ?', whereArgs: [record.id]);
      }
    }
  }

  Future<void> markWrongAgain(int questionId) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('wrong_records',
        where: 'question_id = ?', whereArgs: [questionId]);

    if (existing.isNotEmpty) {
      await db.update('wrong_records', {
        'review_stage': 0,
        'next_review_time': now + _getReviewInterval(0),
        'is_mastered': 0,
        'wrong_count': (existing.first['wrong_count'] as int) + 1,
        'last_wrong_time': now,
      }, where: 'question_id = ?', whereArgs: [questionId]);
    }
  }

  Future<List<WrongRecord>> getAllWrongRecords() async {
    final db = await _db.database;
    final maps = await db.query('wrong_records', orderBy: 'last_wrong_time DESC');
    return maps.map((m) => WrongRecord.fromMap(m)).toList();
  }

  Future<List<WrongRecord>> getUnmasteredRecords() async {
    final db = await _db.database;
    final maps = await db.query('wrong_records',
        where: 'is_mastered = 0', orderBy: 'last_wrong_time DESC');
    return maps.map((m) => WrongRecord.fromMap(m)).toList();
  }

  Future<List<int>> getDueReviewQuestionIds() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query('wrong_records',
        where: 'is_mastered = 0 AND next_review_time <= ?',
        whereArgs: [now],
        orderBy: 'next_review_time ASC');
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<List<int>> getWrongQuestionIdsByModule(String module) async {
    final db = await _db.database;
    final maps = await db.rawQuery('''
      SELECT wr.question_id FROM wrong_records wr
      JOIN questions q ON wr.question_id = q.id
      WHERE q.module = ? AND wr.is_mastered = 0
      ORDER BY wr.wrong_count DESC
    ''', [module]);
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<WrongRecord?> getWrongRecord(int questionId) async {
    final db = await _db.database;
    final maps = await db.query('wrong_records',
        where: 'question_id = ?', whereArgs: [questionId]);
    if (maps.isEmpty) return null;
    return WrongRecord.fromMap(maps.first);
  }

  Future<int> getWrongCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM wrong_records WHERE is_mastered = 0'),
    ) ?? 0;
  }

  Future<int> getDueReviewCount() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM wrong_records WHERE is_mastered = 0 AND next_review_time <= ?',
        [now],
      ),
    ) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getWrongStatsByModule() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT q.module, q.chapter, q.knowledge_points,
             COUNT(*) as wrong_count,
             SUM(wr.wrong_count) as total_wrong_times
      FROM wrong_records wr
      JOIN questions q ON wr.question_id = q.id
      WHERE wr.is_mastered = 0
      GROUP BY q.module, q.chapter
      ORDER BY wrong_count DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getKnowledgePointStats() async {
    final db = await _db.database;

    // Get all wrong questions with their knowledge points
    final wrongQuestions = await db.rawQuery('''
      SELECT q.id, q.module, q.chapter, q.knowledge_points, q.content,
             wr.wrong_count, wr.is_mastered
      FROM wrong_records wr
      JOIN questions q ON wr.question_id = q.id
      WHERE wr.is_mastered = 0
      ORDER BY wr.wrong_count DESC
    ''');

    // Parse knowledge points and count occurrences
    final Map<String, Map<String, dynamic>> knowledgePointMap = {};

    for (final q in wrongQuestions) {
      final knowledgePointsStr = q['knowledge_points'] as String? ?? '[]';
      final module = q['module'] as String? ?? '';
      final chapter = q['chapter'] as String? ?? '';
      final wrongCount = q['wrong_count'] as int? ?? 1;

      // Parse knowledge points from JSON array
      List<String> knowledgePoints = [];
      try {
        if (knowledgePointsStr.startsWith('[')) {
          final List<dynamic> parsed = _parseJsonArray(knowledgePointsStr);
          knowledgePoints = parsed.map((e) => e.toString()).toList();
        }
      } catch (_) {}

      // If no knowledge points specified, use chapter as knowledge point
      if (knowledgePoints.isEmpty) {
        knowledgePoints = [chapter];
      }

      // Count each knowledge point
      for (final kp in knowledgePoints) {
        if (kp.isEmpty) continue;
        final key = '$module|$kp';
        if (knowledgePointMap.containsKey(key)) {
          knowledgePointMap[key]!['wrong_count'] =
              (knowledgePointMap[key]!['wrong_count'] as int) + wrongCount;
          knowledgePointMap[key]!['question_count'] =
              (knowledgePointMap[key]!['question_count'] as int) + 1;
        } else {
          knowledgePointMap[key] = {
            'module': module,
            'knowledge_point': kp,
            'wrong_count': wrongCount,
            'question_count': 1,
          };
        }
      }
    }

    // Get total questions per knowledge point for accuracy calculation
    final result = <Map<String, dynamic>>[];
    for (final entry in knowledgePointMap.entries) {
      final kp = entry.value['knowledge_point'] as String;
      final module = entry.value['module'] as String;

      // Count total questions with this knowledge point
      final totalResult = await db.rawQuery('''
        SELECT COUNT(*) as total
        FROM questions
        WHERE module = ? AND (
          knowledge_points LIKE ? OR
          (knowledge_points = '[]' AND chapter = ?)
        )
      ''', [module, '%$kp%', kp]);

      final total = Sqflite.firstIntValue(totalResult) ?? 0;
      final wrongCount = entry.value['wrong_count'] as int;

      result.add({
        'module': module,
        'knowledge_point': kp,
        'chapter': kp,
        'wrong_count': wrongCount,
        'question_count': entry.value['question_count'] as int,
        'total_questions': total,
      });
    }

    // Sort by wrong count descending
    result.sort((a, b) =>
        (b['wrong_count'] as int).compareTo(a['wrong_count'] as int));

    return result;
  }

  List<dynamic> _parseJsonArray(String jsonStr) {
    // Simple JSON array parser
    final content = jsonStr.substring(1, jsonStr.length - 1).trim();
    if (content.isEmpty) return [];

    final items = <String>[];
    final buffer = StringBuffer();
    bool inQuote = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '"') {
        inQuote = !inQuote;
      } else if (char == ',' && !inQuote) {
        items.add(buffer.toString().trim().replaceAll('"', ''));
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      items.add(buffer.toString().trim().replaceAll('"', ''));
    }

    return items;
  }

  Future<void> deleteByQuestionId(int questionId) async {
    final db = await _db.database;
    await db.delete('wrong_records', where: 'question_id = ?', whereArgs: [questionId]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('wrong_records');
  }

  int _getReviewInterval(int stage) {
    // Ebbinghaus intervals in milliseconds
    const intervals = [
      1 * 24 * 60 * 60 * 1000,   // 1 day
      2 * 24 * 60 * 60 * 1000,   // 2 days
      4 * 24 * 60 * 60 * 1000,   // 4 days
      7 * 24 * 60 * 60 * 1000,   // 7 days
      15 * 24 * 60 * 60 * 1000,  // 15 days
      30 * 24 * 60 * 60 * 1000,  // 30 days
    ];
    return stage < intervals.length ? intervals[stage] : intervals.last;
  }
}
