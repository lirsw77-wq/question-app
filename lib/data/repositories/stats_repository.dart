import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/practice_record.dart';

class StatsRepository {
  final AppDatabase _db;

  StatsRepository(this._db);

  Future<void> insertRecord(PracticeRecord record) async {
    final db = await _db.database;
    await db.insert('practice_records', record.toMap());
  }

  Future<int> getTotalPracticeCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(total_count) FROM practice_records'),
    ) ?? 0;
  }

  Future<int> getTotalCorrectCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(correct_count) FROM practice_records'),
    ) ?? 0;
  }

  Future<int> getLearningDays() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT DATE(timestamp / 1000, "unixepoch", "localtime")) as days FROM practice_records',
    );
    return (result.first['days'] as int?) ?? 0;
  }

  Future<int> getConsecutiveDays() async {
    final db = await _db.database;
    final records = await db.rawQuery('''
      SELECT DISTINCT DATE(timestamp / 1000, 'unixepoch', 'localtime') as day
      FROM practice_records
      ORDER BY day DESC
    ''');
    if (records.isEmpty) return 0;

    int consecutive = 0;
    DateTime checkDate = DateTime.now();
    for (final record in records) {
      final dayStr = record['day'] as String;
      final day = DateTime.parse(dayStr);
      final diff = checkDate.difference(day).inDays;
      if (diff <= 1) {
        consecutive++;
        checkDate = day;
      } else {
        break;
      }
    }
    return consecutive;
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final db = await _db.database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(total_count), 0) as total,
             COALESCE(SUM(correct_count), 0) as correct
      FROM practice_records
      WHERE timestamp >= ?
    ''', [startOfDay]);
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getAccuracyByModule() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT module,
             SUM(total_count) as total,
             SUM(correct_count) as correct,
             CAST(SUM(correct_count) AS REAL) / SUM(total_count) as accuracy
      FROM practice_records
      GROUP BY module
    ''');
  }

  Future<List<Map<String, dynamic>>> getDailyStats(int days) async {
    final db = await _db.database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    return await db.rawQuery('''
      SELECT DATE(timestamp / 1000, 'unixepoch', 'localtime') as day,
             SUM(total_count) as total,
             SUM(correct_count) as correct
      FROM practice_records
      WHERE timestamp >= ?
      GROUP BY day
      ORDER BY day ASC
    ''', [cutoff]);
  }

  Future<List<Map<String, dynamic>>> getWeakChapters() async {
    final db = await _db.database;
    return await db.rawQuery('''
      SELECT module, chapter,
             SUM(total_count) as total,
             SUM(correct_count) as correct,
             CAST(SUM(correct_count) AS REAL) / SUM(total_count) as accuracy
      FROM practice_records
      WHERE chapter IS NOT NULL
      GROUP BY module, chapter
      HAVING total >= 5
      ORDER BY accuracy ASC
      LIMIT 10
    ''');
  }

  Future<List<PracticeRecord>> getRecentRecords({int limit = 20}) async {
    final db = await _db.database;
    final maps = await db.query('practice_records',
        orderBy: 'timestamp DESC', limit: limit);
    return maps.map((m) => PracticeRecord.fromMap(m)).toList();
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('practice_records');
  }
}
