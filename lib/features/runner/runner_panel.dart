import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/providers/console_provider.dart';
import '../../core/services/execution_engine.dart';
import '../../shared/theme/app_theme.dart';
import '../editor/editor_controller.dart';

class RunnerPanel extends StatefulWidget {
  const RunnerPanel({super.key});
  @override
  State<RunnerPanel> createState() => _RunnerPanelState();
}

class _RunnerPanelState extends State<RunnerPanel> {
  InAppWebViewController? _runnerCtrl;
  bool _running = false;
  bool _hasOutput = false;
  String? _lastLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildRunnerView()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 30,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('Runner',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          if (_lastLanguage != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _lastLanguage!.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (_running)
            const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.success,
              ),
            ),
          const SizedBox(width: 8),
          // Re-run button
          GestureDetector(
            onTap: _run,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.success.withOpacity(0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 12, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Run', style: TextStyle(
                    color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700,
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Clear
          GestureDetector(
            onTap: () {
              _runnerCtrl?.evaluateJavascript(source: 'window.vsRunner?.clear()');
              setState(() { _hasOutput = false; _lastLanguage = null; });
              context.read<ConsoleProvider>().clearRunner();
            },
            child: const Icon(Icons.refresh_rounded, size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildRunnerView() {
    return Stack(
      children: [
        InAppWebView(
          initialFile: 'assets/runner/runner.html',
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            allowFileAccess: true,
            useHybridComposition: true,
            supportZoom: true,
            transparentBackground: false,
          ),
          onWebViewCreated: (ctrl) {
            _runnerCtrl = ctrl;
            _registerRunnerHandlers(ctrl);
          },
          onLoadStop: (ctrl, _) async {
            // Auto-run when panel first opens
            await Future.delayed(const Duration(milliseconds: 300));
            _run();
          },
          onConsoleMessage: (_, msg) {
            context.read<ConsoleProvider>().addRunner(
              msg.messageLevel == ConsoleMessageLevel.ERROR ? 'error'
                  : msg.messageLevel == ConsoleMessageLevel.WARNING ? 'warn'
                  : 'log',
              msg.message,
            );
          },
        ),

        // Empty state overlay
        if (!_hasOutput)
          Container(
            color: AppColors.bg,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  const Text('Press Run to execute',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Run'),
                    onPressed: _run,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _registerRunnerHandlers(InAppWebViewController ctrl) {
    ctrl.addJavaScriptHandler(
      handlerName: 'onRunnerLog',
      callback: (args) {
        if (args.length < 2) return;
        context.read<ConsoleProvider>().addRunner(
          args[0] as String? ?? 'log',
          args[1] as String? ?? '',
        );
      },
    );
  }

  Future<void> _run() async {
    if (_running || _runnerCtrl == null) return;

    final ep  = context.read<EditorProvider>();
    final tab = ep.activeTab;
    if (tab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file to run')),
      );
      return;
    }

    setState(() { _running = true; _hasOutput = true; _lastLanguage = tab.language; });

    // Get latest content from editor
    final content = await EditorController.instance.getContent() ?? tab.content;
    final lang    = tab.language.toLowerCase();
    final type    = ExecutionEngine.typeFor(lang);

    if (type == ExecutionType.unsupported) {
      context.read<ConsoleProvider>().addRunner('warn',
          '⚠ Direct execution not available for ${tab.language}.\n'
          'For compiled languages, use the Terminal to build and run.');
      setState(() => _running = false);
      return;
    }

    // Clear previous state
    await _runnerCtrl!.evaluateJavascript(source: 'window.vsRunner?.clear()');
    context.read<ConsoleProvider>().clearRunner();

    // Build runner JS
    final runJs = ExecutionEngine.buildRunnerJs(lang, content);
    await _runnerCtrl!.evaluateJavascript(source: runJs);

    setState(() => _running = false);
  }
}
