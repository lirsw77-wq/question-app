import '../database/app_database.dart';
import '../models/exam_countdown.dart';

class ExamCountdownRepository {
  final AppDatabase _db;

  ExamCountdownRepository(this._db);

  Future<List<ExamCountdown>> getAllCountdowns() async {
    final db = await _db.database;
    final maps = await db.query(
      'exam_countdowns',
      orderBy: 'exam_date ASC',
    );
    return maps.map((m) => ExamCountdown.fromMap(m)).toList();
  }

  Future<List<ExamCountdown>> getVisibleCountdowns() async {
    final db = await _db.database;
    final maps = await db.query(
      'exam_countdowns',
      where: 'is_visible = 1',
      orderBy: 'exam_date ASC',
    );
    return maps.map((m) => ExamCountdown.fromMap(m)).toList();
  }

  Future<int> addCountdown(ExamCountdown countdown) async {
    final db = await _db.database;
    return await db.insert('exam_countdowns', countdown.toMap());
  }

  Future<void> updateCountdown(ExamCountdown countdown) async {
    final db = await _db.database;
    await db.update(
      'exam_countdowns',
      countdown.toMap(),
      where: 'id = ?',
      whereArgs: [countdown.id],
    );
  }

  Future<void> deleteCountdown(int id) async {
    final db = await _db.database;
    await db.delete(
      'exam_countdowns',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> toggleVisibility(int id, bool isVisible) async {
    final db = await _db.database;
    await db.update(
      'exam_countdowns',
      {'is_visible': isVisible ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
