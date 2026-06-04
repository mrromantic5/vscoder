import 'package:flutter/foundation.dart';
import '../models/vfile.dart';

class EditorTab {
  final String id;
  final String projectId;
  final String name;
  final String language;
  String content;
  bool isDirty;
  int cursorLine;
  int cursorCol;
  String? devicePath;
  bool isDeviceFile;

  EditorTab({
    required this.id,
    required this.projectId,
    required this.name,
    required this.language,
    this.content      = '',
    this.isDirty      = false,
    this.cursorLine   = 1,
    this.cursorCol    = 1,
    this.devicePath,
    this.isDeviceFile = false,
  });

  factory EditorTab.fromVFile(VFile f) => EditorTab(
    id:           f.id,
    projectId:    f.projectId,
    name:         f.name,
    language:     f.language,
    content:      f.content,
    isDirty:      f.isDirty,
    cursorLine:   f.cursorLine,
    cursorCol:    f.cursorCol,
    devicePath:   f.devicePath,
    isDeviceFile: f.isDeviceFile,
  );
}

class EditorProvider extends ChangeNotifier {
  final List<EditorTab> _tabs = [];
  int    _activeIndex         = -1;
  int    _cursorLine          = 1;
  int    _cursorCol           = 1;
  bool   _explorerVisible     = true;
  bool   _consoleVisible      = false;
  String _activeBottomPanel   = 'console';
  double _bottomPanelHeight   = 220;
  int    _fontSize            = 14;
  bool   _wordWrap            = false;

  List<EditorTab> get tabs              => List.unmodifiable(_tabs);
  EditorTab?      get activeTab         => (_activeIndex >= 0 && _activeIndex < _tabs.length)
                                           ? _tabs[_activeIndex] : null;
  int             get activeIndex       => _activeIndex;
  int             get cursorLine        => _cursorLine;
  int             get cursorCol         => _cursorCol;
  bool            get explorerVisible   => _explorerVisible;
  bool            get consoleVisible    => _consoleVisible;
  String          get activeBottomPanel => _activeBottomPanel;
  double          get bottomPanelHeight => _bottomPanelHeight;
  int             get fontSize          => _fontSize;
  bool            get wordWrap          => _wordWrap;

  // ── Tabs ─────────────────────────────────────────────────────────────────
  void openFile(VFile file) {
    final existing = _tabs.indexWhere((t) => t.id == file.id);
    if (existing >= 0) { _activeIndex = existing; notifyListeners(); return; }
    _tabs.add(EditorTab.fromVFile(file));
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void openDeviceFile({
    required String path,
    required String name,
    required String language,
    required String content,
  }) {
    final existing = _tabs.indexWhere((t) => t.devicePath == path);
    if (existing >= 0) { _activeIndex = existing; notifyListeners(); return; }
    _tabs.add(EditorTab(
      id:           'device:$path',
      projectId:    '__device__',
      name:         name,
      language:     language,
      content:      content,
      devicePath:   path,
      isDeviceFile: true,
    ));
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;
    _tabs.removeAt(index);
    if (_tabs.isEmpty) {
      _activeIndex = -1;
    } else if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    } else if (_activeIndex > index) {
      _activeIndex--;
    }
    notifyListeners();
  }

  void closeTabById(String id) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    if (idx >= 0) closeTab(idx);
  }

  void closeAllTabs() { _tabs.clear(); _activeIndex = -1; notifyListeners(); }

  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) { _activeIndex = index; notifyListeners(); }
  }

  // ── Content ───────────────────────────────────────────────────────────────
  void onContentChanged(String tabId, String content) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx < 0) return;
    _tabs[idx].content = content;
    _tabs[idx].isDirty = true;
    notifyListeners();
  }

  void markTabSaved(String tabId) {
    final idx = _tabs.indexWhere((t) => t.id == tabId);
    if (idx >= 0) { _tabs[idx].isDirty = false; notifyListeners(); }
  }

  void updateCursor(int line, int col) {
    _cursorLine = line;
    _cursorCol  = col;
    if (activeTab != null) {
      activeTab!.cursorLine = line;
      activeTab!.cursorCol  = col;
    }
    notifyListeners();
  }

  // ── UI state ──────────────────────────────────────────────────────────────
  void toggleExplorer()        { _explorerVisible = !_explorerVisible; notifyListeners(); }
  void toggleConsole()         { _consoleVisible  = !_consoleVisible;  notifyListeners(); }
  void showConsole(bool v)     { _consoleVisible  = v;                 notifyListeners(); }
  void setBottomPanel(String p){ _activeBottomPanel = p; _consoleVisible = true; notifyListeners(); }

  void setBottomPanelHeight(double h) {
    _bottomPanelHeight = h.clamp(100.0, 520.0);
    notifyListeners();
  }

  void setFontSize(int s) { _fontSize = s.clamp(10, 28); notifyListeners(); }
  void toggleWordWrap()   { _wordWrap = !_wordWrap;       notifyListeners(); }

  bool get hasDirtyTabs => _tabs.any((t) => t.isDirty);

  bool isTabDirty(String id) {
    final idx = _tabs.indexWhere((t) => t.id == id);
    return idx >= 0 ? _tabs[idx].isDirty : false;
  }
}
