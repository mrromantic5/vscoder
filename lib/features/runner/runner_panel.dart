import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  InAppWebViewController? _ctrl;
  bool    _running     = false;
  bool    _hasOutput   = false;
  String? _lastLanguage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildView()),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 32,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 5),
          const Text('Runner',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
          if (_lastLanguage != null) ...[
            const SizedBox(width: 6),
            _LangBadge(lang: _lastLanguage!),
          ],
          const Spacer(),
          if (_running)
            const SizedBox(
              width: 11, height: 11,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.success),
            ),
          const SizedBox(width: 6),
          // Run button
          _RunBtn(onTap: _run),
          const SizedBox(width: 4),
          // Refresh / clear
          _HeaderIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'Clear',
            onTap: () {
              _ctrl?.evaluateJavascript(source: 'window.vsRunner?.clear()');
              setState(() { _hasOutput = false; _lastLanguage = null; });
              context.read<ConsoleProvider>().clearRunner();
            },
          ),
          // ── Fullscreen button ───────────────────────────────────────────
          _HeaderIcon(
            icon: Icons.open_in_full_rounded,
            tooltip: 'Fullscreen',
            onTap: _openFullscreen,
          ),
        ],
      ),
    );
  }

  // ── WebView ──────────────────────────────────────────────────────────────
  Widget _buildView() {
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
          onWebViewCreated: (c) {
            _ctrl = c;
            _registerHandlers(c);
          },
          onLoadStop: (_, __) async {
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
        // Empty-state overlay
        if (!_hasOutput) _EmptyState(onRun: _run),
      ],
    );
  }

  // ── Fullscreen ────────────────────────────────────────────────────────────
  Future<void> _openFullscreen() async {
    // Build JS bundle from the current tab before pushing
    final ep  = context.read<EditorProvider>();
    final tab = ep.activeTab;
    if (tab == null) return;

    final content  = await EditorController.instance.getContent() ?? tab.content;
    final lang     = tab.language.toLowerCase();
    final runJs    = ExecutionEngine.buildRunnerJs(lang, content);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FullscreenRunner(
          language: tab.language,
          runJs: runJs,
        ),
      ),
    );
  }

  void _registerHandlers(InAppWebViewController c) {
    c.addJavaScriptHandler(
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
    if (_running || _ctrl == null) return;

    final ep  = context.read<EditorProvider>();
    final tab = ep.activeTab;
    if (tab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file to run'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() { _running = true; _hasOutput = true; _lastLanguage = tab.language; });

    final content = await EditorController.instance.getContent() ?? tab.content;
    final lang    = tab.language.toLowerCase();
    final type    = ExecutionEngine.typeFor(lang);

    if (type == ExecutionType.unsupported) {
      context.read<ConsoleProvider>().addRunner('warn',
          '⚠ Direct execution not available for ${tab.language}.\n'
          'Use the Terminal to build and run compiled languages.');
      setState(() => _running = false);
      return;
    }

    await _ctrl!.evaluateJavascript(source: 'window.vsRunner?.clear()');
    context.read<ConsoleProvider>().clearRunner();
    await _ctrl!.evaluateJavascript(source: ExecutionEngine.buildRunnerJs(lang, content));
    setState(() => _running = false);
  }
}

// ── Fullscreen Runner Page ────────────────────────────────────────────────────
class FullscreenRunner extends StatefulWidget {
  final String language;
  final String runJs;
  const FullscreenRunner({super.key, required this.language, required this.runJs});

  @override
  State<FullscreenRunner> createState() => _FullscreenRunnerState();
}

class _FullscreenRunnerState extends State<FullscreenRunner> {
  InAppWebViewController? _ctrl;
  bool _running   = true;
  bool _showBar   = true;  // auto-hide toolbar after a few seconds

  @override
  void initState() {
    super.initState();
    // Auto-hide the top bar after 3 s for true immersive feel
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showBar = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Full-bleed WebView ──────────────────────────────────────
            Positioned.fill(
              child: InAppWebView(
                initialFile: 'assets/runner/runner.html',
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  allowFileAccessFromFileURLs: true,
                  allowUniversalAccessFromFileURLs: true,
                  allowFileAccess: true,
                  useHybridComposition: true,
                  supportZoom: true,
                ),
                onWebViewCreated: (c) {
                  _ctrl = c;
                  c.addJavaScriptHandler(handlerName: 'onRunnerLog', callback: (_) {});
                },
                onLoadStop: (_, __) async {
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _ctrl?.evaluateJavascript(source: widget.runJs);
                  if (mounted) setState(() => _running = false);
                },
              ),
            ),

            // ── Loading overlay ─────────────────────────────────────────
            if (_running)
              Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                      SizedBox(height: 12),
                      Text('Running…', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                ),
              ),

            // ── Top overlay bar (tap to toggle) ─────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showBar = !_showBar),
              behavior: HitTestBehavior.translucent,
              child: Align(
                alignment: Alignment.topCenter,
                child: AnimatedSlide(
                  offset: _showBar ? Offset.zero : const Offset(0, -1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    opacity: _showBar ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: SafeArea(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                        ),
                        child: Row(
                          children: [
                            _LangBadge(lang: widget.language),
                            const SizedBox(width: 8),
                            const Text('Preview',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            // Refresh
                            _OverlayBtn(
                              icon: Icons.refresh_rounded,
                              tooltip: 'Re-run',
                              onTap: () async {
                                setState(() => _running = true);
                                await _ctrl?.evaluateJavascript(source: 'window.vsRunner?.clear()');
                                await Future.delayed(const Duration(milliseconds: 100));
                                await _ctrl?.evaluateJavascript(source: widget.runJs);
                                if (mounted) setState(() => _running = false);
                              },
                            ),
                            const SizedBox(width: 4),
                            // Close fullscreen
                            _OverlayBtn(
                              icon: Icons.close_fullscreen_rounded,
                              tooltip: 'Exit fullscreen',
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Tap-hint label (fades with bar) ─────────────────────────
            if (!_showBar && !_running)
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _showBar ? 0 : 0.4,
                      duration: const Duration(milliseconds: 400),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('Tap to show controls',
                            style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _LangBadge extends StatelessWidget {
  final String lang;
  const _LangBadge({required this.lang});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(lang.toUpperCase(),
          style: const TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

class _RunBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _RunBtn({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.success.withOpacity(0.4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, size: 12, color: AppColors.success),
            SizedBox(width: 3),
            Text('Run', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Icon(icon, size: 15, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _OverlayBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _OverlayBtn({required this.icon, required this.tooltip, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRun;
  const _EmptyState({required this.onRun});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.success.withOpacity(0.2)),
              ),
              child: const Icon(Icons.play_arrow_rounded, size: 28, color: AppColors.success),
            ),
            const SizedBox(height: 14),
            const Text('Ready to run', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Press Run to execute your code', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Run'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: onRun,
            ),
          ],
        ),
      ),
    );
  }
}
