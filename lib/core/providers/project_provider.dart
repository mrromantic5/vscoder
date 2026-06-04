import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/project_dao.dart';
import '../database/file_dao.dart';
import '../models/project.dart';
import '../models/vfile.dart';
import '../services/language_detector.dart';
import '../../shared/theme/language_colors.dart';

enum ProjectSort { dateDesc, dateAsc, nameAsc, nameDesc, language }

class ProjectProvider extends ChangeNotifier {
  final AppDatabase _db;
  late final ProjectDao _projectDao;
  late final FileDao    _fileDao;

  List<Project>    _projects      = [];
  Project?         _activeProject;
  List<VFile>      _files         = [];
  List<VDirectory> _dirs          = [];
  bool             _loading       = false;
  String?          _error;
  ProjectSort      _sort          = ProjectSort.dateDesc;

  List<Project>    get projects      => _sortedProjects();
  Project?         get activeProject => _activeProject;
  List<VFile>      get files         => List.unmodifiable(_files);
  List<VDirectory> get dirs          => List.unmodifiable(_dirs);
  bool             get loading       => _loading;
  String?          get error         => _error;
  ProjectSort      get sort          => _sort;

  ProjectProvider(this._db) {
    _projectDao = ProjectDao(_db);
    _fileDao    = FileDao(_db);
    loadProjects();
  }

  // ── BUG FIX: try/finally guarantees _loading = false even when DB is broken
  Future<void> loadProjects() async {
    _loading = true;
    _error   = null;
    notifyListeners();
    try {
      _projects = await _projectDao.getAll();
    } catch (e) {
      debugPrint('[ProjectProvider] loadProjects error: $e');
      _error    = 'Could not load projects. Tap to retry.';
      _projects = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setSort(ProjectSort s) {
    _sort = s;
    notifyListeners();
  }

  List<Project> _sortedProjects() {
    final list = List<Project>.from(_projects);
    switch (_sort) {
      case ProjectSort.dateDesc:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case ProjectSort.dateAsc:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case ProjectSort.nameAsc:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProjectSort.nameDesc:
        list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case ProjectSort.language:
        list.sort((a, b) => a.language.compareTo(b.language));
    }
    return list;
  }

  Future<Project> createProject({
    required String name,
    String? description,
    required String language,
  }) async {
    final color = LanguageColors.colorOf(language);
    final hex   = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    final now   = DateTime.now();
    final p = Project(
      id:          const Uuid().v4(),
      name:        name,
      description: description,
      language:    language,
      colorHex:    hex,
      createdAt:   now,
      updatedAt:   now,
    );
    await _projectDao.insert(p);
    await loadProjects();
    return p;
  }

  Future<void> duplicateProject(Project source) async {
    final now = DateTime.now();
    final newProject = Project(
      id:          const Uuid().v4(),
      name:        '${source.name} (copy)',
      description: source.description,
      language:    source.language,
      colorHex:    source.colorHex,
      createdAt:   now,
      updatedAt:   now,
    );
    await _projectDao.insert(newProject);
    // Copy all files using full constructor (copyWith doesn't expose id/projectId)
    final srcFiles = await _fileDao.getFilesForProject(source.id);
    for (final f in srcFiles) {
      await _fileDao.insertFile(VFile(
        id:          const Uuid().v4(),
        projectId:   newProject.id,
        parentDirId: f.parentDirId,
        name:        f.name,
        path:        f.path,
        language:    f.language,
        content:     f.content,
        devicePath:  f.devicePath,
        createdAt:   now,
        updatedAt:   now,
      ));
    }
    await loadProjects();
  }

  Future<void> renameProject(String id, String newName) async {
    await _projectDao.rename(id, newName);
    await loadProjects();
  }

  Future<void> deleteProject(String id) async {
    await _projectDao.delete(id);
    if (_activeProject?.id == id) {
      _activeProject = null;
      _files = [];
      _dirs  = [];
    }
    await loadProjects();
  }

  Future<void> setActiveProject(Project project) async {
    _activeProject = project;
    await _loadContents(project.id);
    notifyListeners();
  }

  Future<void> _loadContents(String projectId) async {
    try {
      _files = await _fileDao.getFilesForProject(projectId);
      _dirs  = await _fileDao.getDirsForProject(projectId);
    } catch (e) {
      debugPrint('[ProjectProvider] _loadContents error: $e');
      _files = [];
      _dirs  = [];
    }
    notifyListeners();
  }

  // ── Files ─────────────────────────────────────────────────────────────────
  Future<VFile> createFile({
    required String projectId,
    required String name,
    String? parentDirId,
    String content = '',
  }) async {
    final lang   = LanguageDetector.fromFileName(name);
    final pPath  = await _parentPath(parentDirId, projectId);
    final now    = DateTime.now();
    final f = VFile(
      id:          const Uuid().v4(),
      projectId:   projectId,
      parentDirId: parentDirId,
      name:        name,
      path:        '${pPath.isEmpty ? '' : pPath}/$name',
      language:    lang,
      content:     content,
      createdAt:   now,
      updatedAt:   now,
    );
    await _fileDao.insertFile(f);
    // Update project's updatedAt
    await _projectDao.touch(projectId);
    await _loadContents(projectId);
    return f;
  }

  Future<void> saveFileContent(String fileId, String content) async {
    await _fileDao.updateContent(fileId, content);
    final idx = _files.indexWhere((f) => f.id == fileId);
    if (idx >= 0) {
      _files = List.from(_files)..[idx] = _files[idx].copyWith(
        content:   content,
        isDirty:   false,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteFile(String fileId, String projectId) async {
    await _fileDao.deleteFile(fileId);
    await _loadContents(projectId);
  }

  // ── Directories ───────────────────────────────────────────────────────────
  Future<VDirectory> createDirectory({
    required String projectId,
    required String name,
    String? parentId,
  }) async {
    final pPath = await _parentPath(parentId, projectId);
    final d = VDirectory(
      id:        const Uuid().v4(),
      projectId: projectId,
      parentId:  parentId,
      name:      name,
      path:      '${pPath.isEmpty ? '' : pPath}/$name',
      createdAt: DateTime.now(),
    );
    await _fileDao.insertDir(d);
    await _loadContents(projectId);
    return d;
  }

  Future<void> deleteDirectory(String dirId, String projectId) async {
    await _fileDao.deleteDir(dirId);
    await _loadContents(projectId);
  }

  Future<String> _parentPath(String? parentId, String projectId) async {
    if (parentId == null) return '';
    try {
      final allDirs = await _fileDao.getDirsForProject(projectId);
      return allDirs.firstWhere((d) => d.id == parentId).path;
    } catch (_) {
      return '';
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  int fileCountFor(String projectId) =>
      _files.where((f) => f.projectId == projectId).length;

  int get totalFileCount => _files.length;

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<VFile> filesInDir(String? dirId) => _files
      .where((f) => f.parentDirId == dirId)
      .toList()..sort((a, b) => a.name.compareTo(b.name));

  List<VDirectory> dirsInParent(String? parentId) => _dirs
      .where((d) => d.parentId == parentId)
      .toList()..sort((a, b) => a.name.compareTo(b.name));
}
