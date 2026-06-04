class Project {
  final String id;
  final String name;
  final String? description;
  final String language;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? entryFile;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.language,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.entryFile,
  });

  factory Project.fromMap(Map<String, dynamic> map) => Project(
        id:          map['id'] as String,
        name:        map['name'] as String,
        description: map['description'] as String?,
        language:    map['language'] as String? ?? 'plaintext',
        colorHex:    map['color_hex'] as String? ?? '#58A6FF',
        createdAt:   DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:   DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
        entryFile:   map['entry_file'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id':          id,
        'name':        name,
        'description': description,
        'language':    language,
        'color_hex':   colorHex,
        'created_at':  createdAt.millisecondsSinceEpoch,
        'updated_at':  updatedAt.millisecondsSinceEpoch,
        'entry_file':  entryFile,
      };

  Project copyWith({
    String? name,
    String? description,
    String? language,
    String? colorHex,
    DateTime? updatedAt,
    String? entryFile,
  }) =>
      Project(
        id:          id,
        name:        name ?? this.name,
        description: description ?? this.description,
        language:    language ?? this.language,
        colorHex:    colorHex ?? this.colorHex,
        createdAt:   createdAt,
        updatedAt:   updatedAt ?? this.updatedAt,
        entryFile:   entryFile ?? this.entryFile,
      );
}
