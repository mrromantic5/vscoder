import 'package:sqflite/sqflite.dart';
import '../models/project.dart';
import 'app_database.dart';

class ProjectDao {
  final AppDatabase _db;
  ProjectDao(this._db);

  Future<List<Project>> getAll() async {
    final rows = await _db.db.query('projects', orderBy: 'updated_at DESC');
    return rows.map(Project.fromMap).toList();
  }

  Future<void> insert(Project p) async {
    await _db.db.insert('projects', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> delete(String id) async {
    await _db.db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> rename(String id, String newName) async {
    await _db.db.update(
      'projects',
      {'name': newName, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> touch(String id) async {
    await _db.db.update(
      'projects',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
