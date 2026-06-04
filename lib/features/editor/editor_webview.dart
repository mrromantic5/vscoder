import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/providers/console_provider.dart';
import '../../core/utils/debouncer.dart';
import 'editor_controller.dart';

class EditorWebView extends StatefulWidget {
  final String initialContent;
  final String language;
  final String tabId;

  const EditorWebView({
    super.key,
    required this.initialContent,
    required this.language,
    required this.tabId,
  });

  @override
  State<EditorWebView> createState() => _EditorWebViewState();
}

class _EditorWebViewState extends State<EditorWebView> {
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));
  bool _editorReady = false;

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialFile: 'assets/editor/index.html',
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        allowFileAccess: true,
        useHybridComposition: true,
        supportZoom: false,
        transparentBackground: true,
        disableContextMenu: true,
        builtInZoomControls: false,
        displayZoomControls: false,
        domStorageEnabled: true,
        databaseEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) {
        EditorController.instance.setController(controller);
        _registerHandlers(controller);
      },
      onLoadStop: (controller, url) async {
        await _initEditor(controller);
      },
      onConsoleMessage: (controller, msg) {
        final cp = context.read<ConsoleProvider>();
        cp.addConsole(
          msg.messageLevel == ConsoleMessageLevel.ERROR ? 'error'
              : msg.messageLevel == ConsoleMessageLevel.WARNING ? 'warn'
              : 'log',
          msg.message,
        );
      },
    );
  }

  void _registerHandlers(InAppWebViewController controller) {
    // Editor ready
    controller.addJavaScriptHandler(
      handlerName: 'onEditorReady',
      callback: (_) async {
        _editorReady = true;
        await _setContent(controller, widget.initialContent, widget.language);
        final ep = context.read<EditorProvider>();
        await controller.evaluateJavascript(
          source: 'window.vsEditor.setFontSize(${ep.fontSize})',
        );
      },
    );

    // Content changed
    controller.addJavaScriptHandler(
      handlerName: 'onContentChange',
      callback: (args) {
        if (args.isEmpty) return;
        final content  = args[0] as String? ?? '';
        final dirty    = args.length > 1 ? (args[1] as bool? ?? true) : true;

        final ep = context.read<EditorProvider>();
        ep.onContentChanged(widget.tabId, content);

        // Auto-save to device file
        if (dirty) {
          _saveDebouncer.run(() {
            EditorController.instance.requestAutoSave(widget.tabId, content);
          });
        }
      },
    );

    // Cursor moved
    controller.addJavaScriptHandler(
      handlerName: 'onCursorMove',
      callback: (args) {
        if (args.length < 2) return;
        final line = (args[0] as num?)?.toInt() ?? 1;
        final col  = (args[1] as num?)?.toInt() ?? 1;
        context.read<EditorProvider>().updateCursor(line, col);
      },
    );

    // Console log from editor
    controller.addJavaScriptHandler(
      handlerName: 'onConsoleLog',
      callback: (args) {
        if (args.length < 2) return;
        context.read<ConsoleProvider>().addConsole(
          args[0] as String? ?? 'log',
          args[1] as String? ?? '',
        );
      },
    );

    // Format request
    controller.addJavaScriptHandler(
      handlerName: 'onFormatRequest',
      callback: (_) {
        // Future: integrate prettier
      },
    );

    // Escape key
    controller.addJavaScriptHandler(
      handlerName: 'onEscapeKey',
      callback: (_) {
        context.read<EditorProvider>().showConsole(false);
      },
    );
  }

  Future<void> _initEditor(InAppWebViewController controller) async {
    // Wait for vsEditor to be ready (retry up to 20x)
    for (var i = 0; i < 20; i++) {
      final ready = await controller.evaluateJavascript(
        source: 'window.vsEditor ? window.vsEditor.isReady() : false',
      );
      if (ready == true) {
        _editorReady = true;
        await _setContent(controller, widget.initialContent, widget.language);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _setContent(
    InAppWebViewController controller,
    String content,
    String language,
  ) async {
    final escaped = _escapeForJs(content);
    await controller.evaluateJavascript(
      source: 'window.vsEditor.setContent(`$escaped`, "$language")',
    );
  }

  String _escapeForJs(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll('`', '\\`')
      .replaceAll('\$', '\\\$');
}
