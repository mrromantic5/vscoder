import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/services/file_system_service.dart';

/// Singleton that holds the active InAppWebViewController
/// and exposes high-level editor commands to the rest of the app.
class EditorController {
  EditorController._();
  static final instance = EditorController._();

  InAppWebViewController? _controller;
  final _fss = FileSystemService();

  void setController(InAppWebViewController ctrl) {
    _controller = ctrl;
  }

  bool get isReady => _controller != null;

  // ── Basic edit commands ──────────────────────────────────────────
  Future<void> undo() => _eval('window.vsEditor.undo()');
  Future<void> redo() => _eval('window.vsEditor.redo()');
  Future<void> selectAll() => _eval('window.vsEditor.selectAll()');
  Future<void> copy() => _eval('window.vsEditor.copy()');
  Future<void> paste() => _eval('window.vsEditor.paste()');
  Future<void> openSearch() => _eval('window.vsEditor.openSearch()');
  Future<void> focus() => _eval('window.vsEditor.focus()');

  Future<void> insert(String text) async {
    final escaped = _escape(text);
    await _eval('window.vsEditor.insert(`$escaped`)');
  }

  Future<void> setLanguage(String lang) async {
    await _eval('window.vsEditor.setLanguage("$lang")');
  }

  Future<void> setFontSize(int size) async {
    await _eval('window.vsEditor.setFontSize($size)');
  }

  Future<void> goToLine(int line) async {
    await _eval('window.vsEditor.goToLine($line)');
  }

  // ── Content ───────────────────────────────────────────────────────
  Future<String?> getContent() async {
    final result = await _controller?.evaluateJavascript(
      source: 'window.vsEditor.getContent()',
    );
    return result as String?;
  }

  Future<void> setContent(String content, String language) async {
    final escaped = _escape(content);
    await _eval('window.vsEditor.setContent(`$escaped`, "$language")');
  }

  Future<void> markClean() => _eval('window.vsEditor.markClean()');

  // ── Auto-save handler ─────────────────────────────────────────────
  Future<void> requestAutoSave(String tabId, String content) async {
    // This is called by EditorWebView's debouncer.
    // EditorProvider.markTabSaved is called after actual save.
    // For device files, write directly:
    final ep = _editorProvider;
    if (ep == null) return;
    final tab = ep.tabs.firstWhere(
      (t) => t.id == tabId,
      orElse: () => EditorTab(id: '', projectId: '', name: '', language: ''),
    );
    if (tab.isDeviceFile && tab.devicePath != null) {
      await _fss.writeFile(tab.devicePath!, content);
    }
    ep.markTabSaved(tabId);
  }

  // Poor-man's way to get EditorProvider — inject if needed
  EditorProvider? _editorProvider;
  void setEditorProvider(EditorProvider ep) => _editorProvider = ep;

  // ── Internal ──────────────────────────────────────────────────────
  Future<void> _eval(String js) async {
    await _controller?.evaluateJavascript(source: js);
  }

  String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('`', '\\`')
      .replaceAll('\$', '\\\$');
}
