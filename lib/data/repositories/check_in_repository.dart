import '../database/app_database.dart';
import '../models/check_in_record.dart';

class CheckInRepository {
  final AppDatabase _db;

  CheckInRepository(this._db);

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<CheckInRecord?> getTodayRecord() async {
    final db = await _db.database;
    final today = _getTodayKey();
    final maps = await db.query(
      'check_in_records',
      where: 'date = ?',
      whereArgs: [today],
    );
    if (maps.isEmpty) return null;
    return CheckInRecord.fromMap(maps.first);
  }

  Future<void> checkIn() async {
    final db = await _db.database;
    final today = _getTodayKey();
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await getTodayRecord();
    if (existing == null) {
      await db.insert('check_in_records', CheckInRecord(
        date: today,
        createdAt: now,
      ).toMap());
    }
  }

  Future<void> updateStudyDuration(int seconds) async {
    final db = await _db.database;
    final today = _getTodayKey();

    final existing = await getTodayRecord();
    if (existing != null) {
      await db.update(
        'check_in_records',
        {'study_duration': existing.studyDuration + seconds},
        where: 'date = ?',
        whereArgs: [today],
      );
    } else {
      await db.insert('check_in_records', CheckInRecord(
        date: today,
        studyDuration: seconds,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toMap());
    }
  }

  Future<void> incrementPracticeCount() async {
    final db = await _db.database;
    final today = _getTodayKey();

    final existing = await getTodayRecord();
    if (existing != null) {
      await db.update(
        'check_in_records',
        {'practice_count': existing.practiceCount + 1},
        where: 'date = ?',
        whereArgs: [today],
      );
    } else {
      await db.insert('check_in_records', CheckInRecord(
        date: today,
        practiceCount: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toMap());
    }
  }

  Future<void> incrementReciteCount() async {
    final db = await _db.database;
    final today = _getTodayKey();

    final existing = await getTodayRecord();
    if (existing != null) {
      await db.update(
        'check_in_records',
        {'recite_count': existing.reciteCount + 1},
        where: 'date = ?',
        whereArgs: [today],
      );
    } else {
      await db.insert('check_in_records', CheckInRecord(
        date: today,
        reciteCount: 1,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toMap());
    }
  }

  Future<int> getConsecutiveDays() async {
    final db = await _db.database;
    final records = await db.query(
      'check_in_records',
      orderBy: 'date DESC',
    );

    if (records.isEmpty) return 0;

    int consecutiveDays = 0;
    DateTime checkDate = DateTime.now();

    for (final record in records) {
      final recordDate = record['date'] as String;
      final expectedDate = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';

      if (recordDate == expectedDate) {
        consecutiveDays++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return consecutiveDays;
  }

  Future<List<CheckInRecord>> getMonthRecords(int year, int month) async {
    final db = await _db.database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final endDate = '$year-${month.toString().padLeft(2, '0')}-31';

    final maps = await db.query(
      'check_in_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );

    return maps.map((m) => CheckInRecord.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    final record = await getTodayRecord();
    return {
      'isChecked': record?.isChecked ?? false,
      'studyDuration': record?.studyDuration ?? 0,
      'practiceCount': record?.practiceCount ?? 0,
      'reciteCount': record?.reciteCount ?? 0,
    };
  }
}
