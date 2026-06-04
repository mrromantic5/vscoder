import 'package:sqflite/sqflite.dart';
import '../models/vfile.dart';
import 'app_database.dart';

class FileDao {
  final AppDatabase _db;
  FileDao(this._db);

  // ── Files ─────────────────────────────────────────────────────────
  Future<List<VFile>> getFilesForProject(String projectId) async {
    final rows = await _db.db.query(
      'vfiles',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name ASC',
    );
    return rows.map(VFile.fromMap).toList();
  }

  Future<List<VFile>> getFilesInDir(String? dirId, String projectId) async {
    final rows = dirId == null
        ? await _db.db.query(
            'vfiles',
            where: 'project_id = ? AND parent_dir_id IS NULL',
            whereArgs: [projectId],
            orderBy: 'name ASC',
          )
        : await _db.db.query(
            'vfiles',
            where: 'project_id = ? AND parent_dir_id = ?',
            whereArgs: [projectId, dirId],
            orderBy: 'name ASC',
          );
    return rows.map(VFile.fromMap).toList();
  }

  Future<VFile?> getFileById(String id) async {
    final rows = await _db.db.query(
      'vfiles',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : VFile.fromMap(rows.first);
  }

  Future<void> insertFile(VFile file) async {
    await _db.db.insert(
      'vfiles',
      file.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateFile(VFile file) async {
    await _db.db.update(
      'vfiles',
      file.toMap(),
      where: 'id = ?',
      whereArgs: [file.id],
    );
  }

  Future<void> updateContent(String id, String content) async {
    await _db.db.update(
      'vfiles',
      {
        'content':    content,
        'is_dirty':   0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteFile(String id) async {
    await _db.db.delete('vfiles', where: 'id = ?', whereArgs: [id]);
  }

  // ── Directories ───────────────────────────────────────────────────
  Future<List<VDirectory>> getDirsForProject(String projectId) async {
    final rows = await _db.db.query(
      'directories',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'name ASC',
    );
    return rows.map(VDirectory.fromMap).toList();
  }

  Future<List<VDirectory>> getDirsInParent(String? parentId, String projectId) async {
    final rows = parentId == null
        ? await _db.db.query(
            'directories',
            where: 'project_id = ? AND parent_id IS NULL',
            whereArgs: [projectId],
            orderBy: 'name ASC',
          )
        : await _db.db.query(
            'directories',
            where: 'project_id = ? AND parent_id = ?',
            whereArgs: [projectId, parentId],
            orderBy: 'name ASC',
          );
    return rows.map(VDirectory.fromMap).toList();
  }

  Future<void> insertDir(VDirectory dir) async {
    await _db.db.insert(
      'directories',
      dir.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDir(String id) async {
    await _db.db.delete('directories', where: 'id = ?', whereArgs: [id]);
  }
}
