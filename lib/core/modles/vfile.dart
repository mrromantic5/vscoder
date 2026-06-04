class VFile {
  final String id;
  final String projectId;
  final String? parentDirId;
  final String name;
  final String path;        // virtual path like /src/index.js
  final String language;
  final String content;
  final String? devicePath; // real device path (if linked)
  final bool isDirty;
  final int cursorLine;
  final int cursorCol;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VFile({
    required this.id,
    required this.projectId,
    this.parentDirId,
    required this.name,
    required this.path,
    required this.language,
    required this.content,
    this.devicePath,
    this.isDirty = false,
    this.cursorLine = 1,
    this.cursorCol = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VFile.fromMap(Map<String, dynamic> map) => VFile(
    id:           map['id'] as String,
    projectId:    map['project_id'] as String,
    parentDirId:  map['parent_dir_id'] as String?,
    name:         map['name'] as String,
    path:         map['path'] as String,
    language:     map['language'] as String? ?? 'plaintext',
    content:      map['content'] as String? ?? '',
    devicePath:   map['device_path'] as String?,
    isDirty:      (map['is_dirty'] as int? ?? 0) == 1,
    cursorLine:   map['cursor_line'] as int? ?? 1,
    cursorCol:    map['cursor_col'] as int? ?? 1,
    createdAt:    DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt:    DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );

  Map<String, dynamic> toMap() => {
    'id':            id,
    'project_id':    projectId,
    'parent_dir_id': parentDirId,
    'name':          name,
    'path':          path,
    'language':      language,
    'content':       content,
    'device_path':   devicePath,
    'is_dirty':      isDirty ? 1 : 0,
    'cursor_line':   cursorLine,
    'cursor_col':    cursorCol,
    'created_at':    createdAt.millisecondsSinceEpoch,
    'updated_at':    updatedAt.millisecondsSinceEpoch,
  };

  VFile copyWith({
    String? name,
    String? content,
    String? language,
    String? devicePath,
    bool? isDirty,
    int? cursorLine,
    int? cursorCol,
    DateTime? updatedAt,
  }) =>
      VFile(
        id:          id,
        projectId:   projectId,
        parentDirId: parentDirId,
        name:        name ?? this.name,
        path:        path,
        language:    language ?? this.language,
        content:     content ?? this.content,
        devicePath:  devicePath ?? this.devicePath,
        isDirty:     isDirty ?? this.isDirty,
        cursorLine:  cursorLine ?? this.cursorLine,
        cursorCol:   cursorCol ?? this.cursorCol,
        createdAt:   createdAt,
        updatedAt:   updatedAt ?? this.updatedAt,
      );

  /// Whether this file is backed by a device path
  bool get isDeviceFile => devicePath != null && devicePath!.isNotEmpty;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot >= 0 ? name.substring(dot + 1) : '';
  }
}

class VDirectory {
  final String id;
  final String projectId;
  final String? parentId;
  final String name;
  final String path;
  final DateTime createdAt;

  const VDirectory({
    required this.id,
    required this.projectId,
    this.parentId,
    required this.name,
    required this.path,
    required this.createdAt,
  });

  factory VDirectory.fromMap(Map<String, dynamic> m) => VDirectory(
    id:        m['id'] as String,
    projectId: m['project_id'] as String,
    parentId:  m['parent_id'] as String?,
    name:      m['name'] as String,
    path:      m['path'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );

  Map<String, dynamic> toMap() => {
    'id':         id,
    'project_id': projectId,
    'parent_id':  parentId,
    'name':       name,
    'path':       path,
    'created_at': createdAt.millisecondsSinceEpoch,
  };
}
