import 'package:sqflite/sqflite.dart';
import '../database/app_database.dart';
import '../models/favorite.dart';

class FavoriteRepository {
  final AppDatabase _db;

  FavoriteRepository(this._db);

  Future<void> toggleFavorite(int questionId) async {
    final db = await _db.database;
    final existing = await db.query('favorites',
        where: 'question_id = ?', whereArgs: [questionId]);
    if (existing.isNotEmpty) {
      await db.delete('favorites', where: 'question_id = ?', whereArgs: [questionId]);
    } else {
      await db.insert('favorites', Favorite(
        questionId: questionId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ).toMap());
    }
  }

  Future<bool> isFavorite(int questionId) async {
    final db = await _db.database;
    final maps = await db.query('favorites',
        where: 'question_id = ?', whereArgs: [questionId]);
    return maps.isNotEmpty;
  }

  Future<List<int>> getFavoriteQuestionIds({String? module}) async {
    final db = await _db.database;
    if (module != null) {
      final maps = await db.rawQuery('''
        SELECT f.question_id FROM favorites f
        JOIN questions q ON f.question_id = q.id
        WHERE q.module = ?
        ORDER BY f.created_at DESC
      ''', [module]);
      return maps.map((m) => m['question_id'] as int).toList();
    }
    final maps = await db.query('favorites', orderBy: 'created_at DESC');
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<int> getFavoriteCount() async {
    final db = await _db.database;
    return Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM favorites'),
    ) ?? 0;
  }

  Future<void> removeFavorite(int questionId) async {
    final db = await _db.database;
    await db.delete('favorites', where: 'question_id = ?', whereArgs: [questionId]);
  }

  Future<void> deleteAll() async {
    final db = await _db.database;
    await db.delete('favorites');
  }
}
