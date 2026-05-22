import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/current_affair.dart';

class CurrentAffairRepository {
  final AppDatabase _db;

  CurrentAffairRepository(this._db);

  Future<List<CurrentAffair>> getAll({String? category, int limit = 50, int offset = 0}) async {
    final db = await _db.database;
    String? where;
    List<dynamic>? whereArgs;
    if (category != null && category != '全部') {
      where = 'category = ?';
      whereArgs = [category];
    }
    final maps = await db.query(
      'current_affairs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'publish_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => CurrentAffair.fromMap(m)).toList();
  }

  Future<List<CurrentAffair>> getFavorites() async {
    final db = await _db.database;
    final maps = await db.query(
      'current_affairs',
      where: 'is_favorite = 1',
      orderBy: 'publish_date DESC',
    );
    return maps.map((m) => CurrentAffair.fromMap(m)).toList();
  }

  Future<CurrentAffair?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query('current_affairs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CurrentAffair.fromMap(maps.first);
  }

  Future<int> insert(CurrentAffair affair) async {
    final db = await _db.database;
    return await db.insert('current_affairs', affair.toMap());
  }

  Future<void> batchInsert(List<CurrentAffair> affairs) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final a in affairs) {
      batch.insert('current_affairs', a.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> markAsRead(int id) async {
    final db = await _db.database;
    await db.update('current_affairs', {'is_read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleFavorite(int id) async {
    final db = await _db.database;
    final affair = await getById(id);
    if (affair != null) {
      await db.update(
        'current_affairs',
        {'is_favorite': affair.isFavorite ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> updateAiSummary(int id, String summary) async {
    final db = await _db.database;
    await db.update('current_affairs', {'ai_summary': summary}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCount() async {
    final db = await _db.database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM current_affairs');
    return result.first['cnt'] as int;
  }
}
