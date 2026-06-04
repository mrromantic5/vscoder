import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/console_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/language_colors.dart';
import '../explorer/explorer_panel.dart';
import '../console/console_panel.dart';
import '../terminal/terminal_panel.dart';
import '../runner/runner_panel.dart';
import 'editor_webview.dart';
import 'toolbar/top_toolbar.dart';
import 'toolbar/control_icons_bar.dart';
import 'editor_controller.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  @override
  void initState() {
    super.initState();
    // Wire editor provider into controller for auto-save
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EditorController.instance.setEditorProvider(
        context.read<EditorProvider>(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _handleBack(context),
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Column(
            children: [
              const TopToolbar(),
              _TabBar(),
              Expanded(child: _Body()),
              _BottomPanelSection(),
              const ControlIconsBar(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext ctx) async {
    final ep = ctx.read<EditorProvider>();
    if (ep.hasDirtyTabs) {
      final save = await showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Leave anyway?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (save != true) return;
    }
    ep.closeAllTabs();
    if (ctx.mounted) Navigator.pushReplacementNamed(ctx, '/projects');
  }
}

// ── Tab bar ───────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (ctx, ep, _) {
        if (ep.tabs.isEmpty) {
          return Container(
            height: 38,
            color: AppColors.surface,
            child: const Divider(height: 1, color: AppColors.border),
          );
        }
        return Container(
          height: 38,
          color: AppColors.surface,
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(top: 4),
                  itemCount: ep.tabs.length,
                  itemBuilder: (_, i) => _Tab(index: i),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final int index;
  const _Tab({required this.index});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (ctx, ep, _) {
        if (index >= ep.tabs.length) return const SizedBox.shrink();
        final tab      = ep.tabs[index];
        final isActive = ep.activeIndex == index;
        final spec     = LanguageColors.get(tab.language);
        final color    = spec.color;

        return GestureDetector(
          onTap: () {
            ep.setActiveTab(index);
            // Reload editor content when switching tabs
            EditorController.instance.setContent(tab.content, tab.language);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(right: 1),
            decoration: BoxDecoration(
              color: isActive ? AppColors.bg : AppColors.surface,
              border: isActive
                  ? Border(top: BorderSide(color: color, width: 2))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isActive ? 1 : 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  tab.name,
                  style: TextStyle(
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (tab.isDirty) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.warning,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => ep.closeTab(index),
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Body (Explorer + Editor) ───────────────────────────────────────────────────
class _Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (ctx, ep, _) {
        final tab = ep.activeTab;
        return Row(
          children: [
            // Explorer panel (slide in/out)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: ep.explorerVisible ? 260 : 0,
              child: ep.explorerVisible
                  ? const ExplorerPanel()
                  : const SizedBox.shrink(),
            ),

            // Editor
            Expanded(
              child: tab == null
                  ? _EmptyEditor()
                  : EditorWebView(
                      key: ValueKey(tab.id),
                      initialContent: tab.content,
                      language:       tab.language,
                      tabId:          tab.id,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyEditor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code_rounded, color: AppColors.textMuted.withOpacity(0.4), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No File Open',
              style: TextStyle(color: AppColors.textMuted, fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open a file from the Explorer\nor create a new one',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom panels (Console / Terminal / Runner) ────────────────────────────────
class _BottomPanelSection extends StatefulWidget {
  @override
  State<_BottomPanelSection> createState() => _BottomPanelSectionState();
}

class _BottomPanelSectionState extends State<_BottomPanelSection> {
  double _dragStartY = 0;
  double _dragStartH = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (ctx, ep, _) {
        if (!ep.consoleVisible) return _PanelTabs(ep: ep, collapsed: true);
        return GestureDetector(
          // Drag handle to resize
          onVerticalDragStart: (d) {
            _dragStartY = d.globalPosition.dy;
            _dragStartH = ep.bottomPanelHeight;
          },
          onVerticalDragUpdate: (d) {
            final delta = _dragStartY - d.globalPosition.dy;
            ep.setBottomPanelHeight(_dragStartH + delta);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PanelTabs(ep: ep, collapsed: false),
              _PanelDragHandle(),
              SizedBox(
                height: ep.bottomPanelHeight,
                child: _PanelContent(panel: ep.activeBottomPanel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelTabs extends StatelessWidget {
  final EditorProvider ep;
  final bool collapsed;
  const _PanelTabs({required this.ep, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsoleProvider>(
      builder: (ctx, cp, _) => Container(
        height: 32,
        color: AppColors.surface,
        child: Column(
          children: [
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Row(
                children: [
                  _PanelTab(
                    label: 'Console',
                    badge: cp.unreadErrors > 0 ? cp.unreadErrors : null,
                    badgeColor: AppColors.danger,
                    active: ep.activeBottomPanel == 'console' && !collapsed,
                    onTap: () {
                      if (ep.activeBottomPanel == 'console' && ep.consoleVisible) {
                        ep.toggleConsole();
                      } else {
                        ep.setBottomPanel('console');
                      }
                    },
                  ),
                  _PanelTab(
                    label: 'Terminal',
                    active: ep.activeBottomPanel == 'terminal' && !collapsed,
                    onTap: () {
                      if (ep.activeBottomPanel == 'terminal' && ep.consoleVisible) {
                        ep.toggleConsole();
                      } else {
                        ep.setBottomPanel('terminal');
                      }
                    },
                  ),
                  _PanelTab(
                    label: 'Runner',
                    active: ep.activeBottomPanel == 'runner' && !collapsed,
                    onTap: () {
                      if (ep.activeBottomPanel == 'runner' && ep.consoleVisible) {
                        ep.toggleConsole();
                      } else {
                        ep.setBottomPanel('runner');
                      }
                    },
                  ),
                  const Spacer(),
                  if (!collapsed)
                    IconButton(
                      onPressed: ep.toggleConsole,
                      icon: const Icon(Icons.expand_more_rounded,
                          color: AppColors.textMuted, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int? badge;
  final Color? badgeColor;

  const _PanelTab({
    required this.label,
    required this.active,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: active
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.accent, width: 2),
                ),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: badgeColor ?? AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PanelDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: AppColors.surface,
      child: Center(
        child: Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _PanelContent extends StatelessWidget {
  final String panel;
  const _PanelContent({required this.panel});

  @override
  Widget build(BuildContext context) {
    switch (panel) {
      case 'terminal': return const TerminalPanel();
      case 'runner':   return const RunnerPanel();
      default:         return const ConsolePanel();
    }
  }
}
