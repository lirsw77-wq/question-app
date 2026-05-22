import '../database/app_database.dart';
import '../models/import_job.dart';

class ImportJobRepository {
  final AppDatabase _db;

  ImportJobRepository(this._db);

  Future<int> insertJob(ImportJob job) async {
    final db = await _db.database;
    return await db.insert('import_jobs', job.toMap());
  }

  Future<void> updateJob(ImportJob job) async {
    final db = await _db.database;
    await db.update('import_jobs', job.toMap(), where: 'id = ?', whereArgs: [job.id]);
  }

  Future<ImportJob?> getJobById(int id) async {
    final db = await _db.database;
    final maps = await db.query('import_jobs', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ImportJob.fromMap(maps.first);
  }

  Future<List<ImportJob>> getPendingJobs() async {
    final db = await _db.database;
    final maps = await db.query('import_jobs',
        where: 'status IN (?, ?)', whereArgs: ['pending', 'importing'],
        orderBy: 'created_at DESC');
    return maps.map((m) => ImportJob.fromMap(m)).toList();
  }

  Future<List<ImportJob>> getAllJobs() async {
    final db = await _db.database;
    final maps = await db.query('import_jobs', orderBy: 'created_at DESC');
    return maps.map((m) => ImportJob.fromMap(m)).toList();
  }

  Future<void> deleteJob(int id) async {
    final db = await _db.database;
    await db.delete('import_jobs', where: 'id = ?', whereArgs: [id]);
  }
}
