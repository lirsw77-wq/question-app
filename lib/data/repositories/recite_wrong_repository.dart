import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/recite_wrong_record.dart';

class ReciteWrongRepository {
  final AppDatabase _db;

  ReciteWrongRepository(this._db);

  Future<void> addRecord(String knowledgePoint, String content) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query(
      'recite_wrong_records',
      where: 'knowledge_point = ? AND content = ?',
      whereArgs: [knowledgePoint, content],
    );

    if (existing.isNotEmpty) {
      final record = ReciteWrongRecord.fromMap(existing.first);
      await db.update('recite_wrong_records', {
        'wrong_count': record.wrongCount + 1,
        'last_wrong_time': now,
        'next_review_time': now + _getReviewInterval(0),
        'review_stage': 0,
        'is_mastered': 0,
      }, where: 'id = ?', whereArgs: [record.id]);
    } else {
      await db.insert('recite_wrong_records', ReciteWrongRecord(
        knowledgePoint: knowledgePoint,
        content: content,
        wrongCount: 1,
        lastWrongTime: now,
        nextReviewTime: now + _getReviewInterval(0),
      ).toMap());
    }
  }

  Future<void> markCorrect(int id) async {
    final db = await _db.database;
    final existing = await db.query('recite_wrong_records', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      final record = ReciteWrongRecord.fromMap(existing.first);
      final newStage = record.reviewStage + 1;
      if (newStage >= 6) {
        await db.update('recite_wrong_records', {
          'review_stage': newStage,
          'is_mastered': 1,
          'next_review_time': 0,
        }, where: 'id = ?', whereArgs: [id]);
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.update('recite_wrong_records', {
          'review_stage': newStage,
          'next_review_time': now + _getReviewInterval(newStage),
        }, where: 'id = ?', whereArgs: [id]);
      }
    }
  }

  Future<void> markWrongAgain(int id) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await db.query('recite_wrong_records', where: 'id = ?', whereArgs: [id]);
    if (existing.isNotEmpty) {
      await db.update('recite_wrong_records', {
        'review_stage': 0,
        'next_review_time': now + _getReviewInterval(0),
        'is_mastered': 0,
        'wrong_count': (existing.first['wrong_count'] as int) + 1,
        'last_wrong_time': now,
      }, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<List<ReciteWrongRecord>> getAllRecords() async {
    final db = await _db.database;
    final maps = await db.query('recite_wrong_records', orderBy: 'last_wrong_time DESC');
    return maps.map((m) => ReciteWrongRecord.fromMap(m)).toList();
  }

  Future<List<ReciteWrongRecord>> getUnmasteredRecords() async {
    final db = await _db.database;
    final maps = await db.query(
      'recite_wrong_records',
      where: 'is_mastered = 0',
      orderBy: 'last_wrong_time DESC',
    );
    return maps.map((m) => ReciteWrongRecord.fromMap(m)).toList();
  }

  Future<List<ReciteWrongRecord>> getDueReviewRecords() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.query(
      'recite_wrong_records',
      where: 'is_mastered = 0 AND next_review_time <= ?',
      whereArgs: [now],
      orderBy: 'next_review_time ASC',
    );
    return maps.map((m) => ReciteWrongRecord.fromMap(m)).toList();
  }

  Future<int> getUnmasteredCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM recite_wrong_records WHERE is_mastered = 0'),
    ) ?? 0;
  }

  Future<int> getDueReviewCount() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM recite_wrong_records WHERE is_mastered = 0 AND next_review_time <= ?',
        [now],
      ),
    ) ?? 0;
  }

  Future<Map<String, int>> getStatsByKnowledgePoint() async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT knowledge_point, COUNT(*) as cnt
      FROM recite_wrong_records
      WHERE is_mastered = 0
      GROUP BY knowledge_point
      ORDER BY cnt DESC
    ''');
    final Map<String, int> stats = {};
    for (final r in results) {
      stats[r['knowledge_point'] as String] = r['cnt'] as int;
    }
    return stats;
  }

  Future<void> deleteById(int id) async {
    final db = await _db.database;
    await db.delete('recite_wrong_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('recite_wrong_records');
  }

  int _getReviewInterval(int stage) {
    const intervals = [
      1 * 24 * 60 * 60 * 1000,
      2 * 24 * 60 * 60 * 1000,
      4 * 24 * 60 * 60 * 1000,
      7 * 24 * 60 * 60 * 1000,
      15 * 24 * 60 * 60 * 1000,
      30 * 24 * 60 * 60 * 1000,
    ];
    return stage < intervals.length ? intervals[stage] : intervals.last;
  }
}
