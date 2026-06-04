import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import 'app_database.dart';

class ProjectDao {
  final AppDatabase _db;
  ProjectDao(this._db);

  Future<List<Project>> getAll() async {
    final rows = await _db.db.query(
      'projects',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Project.fromMap).toList();
  }

  Future<Project?> getById(String id) async {
    final rows = await _db.db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Project.fromMap(rows.first);
  }

  Future<void> insert(Project project) async {
    await _db.db.insert(
      'projects',
      project.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(Project project) async {
    await _db.db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
  }

  Future<void> delete(String id) async {
    await _db.db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> count() async {
    final result = await _db.db.rawQuery('SELECT COUNT(*) FROM projects');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
