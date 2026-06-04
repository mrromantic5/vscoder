import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('Database not initialized. Call initialize() first.');
    return _db!;
  }

  Future<void> initialize() async {
    final path = join(await getDatabasesPath(), 'vscoder.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id          TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        description TEXT,
        language    TEXT NOT NULL DEFAULT 'plaintext',
        color_hex   TEXT NOT NULL DEFAULT '#58A6FF',
        entry_file  TEXT,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE directories (
        id          TEXT PRIMARY KEY,
        project_id  TEXT NOT NULL,
        parent_id   TEXT,
        name        TEXT NOT NULL,
        path        TEXT NOT NULL,
        created_at  INTEGER NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE,
        FOREIGN KEY(parent_id)  REFERENCES directories(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE vfiles (
        id             TEXT PRIMARY KEY,
        project_id     TEXT NOT NULL,
        parent_dir_id  TEXT,
        name           TEXT NOT NULL,
        path           TEXT NOT NULL,
        language       TEXT NOT NULL DEFAULT 'plaintext',
        content        TEXT,
        device_path    TEXT,
        is_dirty       INTEGER NOT NULL DEFAULT 0,
        cursor_line    INTEGER NOT NULL DEFAULT 1,
        cursor_col     INTEGER NOT NULL DEFAULT 1,
        created_at     INTEGER NOT NULL,
        updated_at     INTEGER NOT NULL,
        FOREIGN KEY(project_id)    REFERENCES projects(id)    ON DELETE CASCADE,
        FOREIGN KEY(parent_dir_id) REFERENCES directories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // Indexes for performance
    await db.execute('CREATE INDEX idx_vfiles_project    ON vfiles(project_id)');
    await db.execute('CREATE INDEX idx_vfiles_dir        ON vfiles(parent_dir_id)');
    await db.execute('CREATE INDEX idx_dirs_project      ON directories(project_id)');
    await db.execute('CREATE INDEX idx_dirs_parent       ON directories(parent_id)');

    // Default settings
    await db.insert('settings', {'key': 'font_size', 'value': '14'});
    await db.insert('settings', {'key': 'tab_size', 'value': '2'});
    await db.insert('settings', {'key': 'word_wrap', 'value': 'false'});
    await db.insert('settings', {'key': 'auto_save', 'value': 'true'});
    await db.insert('settings', {'key': 'theme', 'value': 'vscoder'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE vfiles ADD COLUMN device_path TEXT');
    }
  }

  Future<String?> getSetting(String key) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
