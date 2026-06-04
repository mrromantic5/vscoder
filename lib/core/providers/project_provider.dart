import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/project_dao.dart';
import '../database/file_dao.dart';
import '../models/project.dart';
import '../models/vfile.dart';
import '../services/language_detector.dart';
import '../../shared/theme/language_colors.dart';

class ProjectProvider extends ChangeNotifier {
  final AppDatabase _db;
  late final ProjectDao _projectDao;
  late final FileDao    _fileDao;

  List<Project>    _projects      = [];
  Project?         _activeProject;
  List<VFile>      _files         = [];
  List<VDirectory> _dirs          = [];
  bool             _loading       = false;

  List<Project>    get projects      => List.unmodifiable(_projects);
  Project?         get activeProject => _activeProject;
  List<VFile>      get files         => List.unmodifiable(_files);
  List<VDirectory> get dirs          => List.unmodifiable(_dirs);
  bool             get loading       => _loading;

  ProjectProvider(this._db) {
    _projectDao = ProjectDao(_db);
    _fileDao    = FileDao(_db);
    loadProjects();
  }

  Future<void> loadProjects() async {
    _loading = true;
    notifyListeners();
    _projects = await _projectDao.getAll();
    _loading  = false;
    notifyListeners();
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
    _files = await _fileDao.getFilesForProject(projectId);
    _dirs  = await _fileDao.getDirsForProject(projectId);
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
    final allDirs = await _fileDao.getDirsForProject(projectId);
    try { return allDirs.firstWhere((d) => d.id == parentId).path; }
    catch (_) { return ''; }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<VFile> filesInDir(String? dirId) => _files
      .where((f) => f.parentDirId == dirId)
      .toList()..sort((a, b) => a.name.compareTo(b.name));

  List<VDirectory> dirsInParent(String? parentId) => _dirs
      .where((d) => d.parentId == parentId)
      .toList()..sort((a, b) => a.name.compareTo(b.name));
}
