import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/editor_provider.dart';
import '../../../core/providers/project_provider.dart';
import '../../../core/providers/console_provider.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/language_colors.dart';
import '../editor_controller.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<EditorProvider, ProjectProvider>(
      builder: (ctx, ep, pp, _) {
        final tab = ep.activeTab;
        return Container(
          height: 48,
          color: AppColors.surface,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Back / Explorer toggle
                    _ToolBtn(
                      icon: Icons.menu_rounded,
                      tooltip: 'Toggle Explorer',
                      onTap: ep.toggleExplorer,
                    ),

                    // Undo / Redo
                    _ToolBtn(icon: Icons.undo_rounded, tooltip: 'Undo',
                        onTap: EditorController.instance.undo),
                    _ToolBtn(icon: Icons.redo_rounded, tooltip: 'Redo',
                        onTap: EditorController.instance.redo),

                    // Search
                    _ToolBtn(icon: Icons.search_rounded, tooltip: 'Find & Replace',
                        onTap: EditorController.instance.openSearch),

                    const Spacer(),

                    // Status: cursor position
                    if (tab != null) ...[
                      GestureDetector(
                        onTap: () => _showGoToLine(context, ep),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Ln ${ep.cursorLine}, Col ${ep.cursorCol}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Language badge
                      _LanguageBadge(language: tab.language),
                      const SizedBox(width: 8),
                    ],

                    // Save
                    _ToolBtn(
                      icon: Icons.save_rounded,
                      tooltip: 'Save',
                      active: tab?.isDirty ?? false,
                      activeColor: AppColors.warning,
                      onTap: () => _save(context),
                    ),

                    // Run
                    _ToolBtn(
                      icon: Icons.play_arrow_rounded,
                      tooltip: 'Run',
                      activeColor: AppColors.success,
                      active: true,
                      onTap: () => _run(context),
                    ),

                    // More options
                    _MoreMenu(),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save(BuildContext ctx) async {
    final ep = ctx.read<EditorProvider>();
    final pp = ctx.read<ProjectProvider>();
    final tab = ep.activeTab;
    if (tab == null) return;

    final content = await EditorController.instance.getContent();
    if (content == null) return;

    if (tab.isDeviceFile && tab.devicePath != null) {
      // already auto-saved; just mark clean
      EditorController.instance.markClean();
      ep.markTabSaved(tab.id);
    } else {
      // Save to DB
      await pp.saveFileContent(tab.id, content);
      ep.markTabSaved(tab.id);
    }

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text('${tab.name} saved'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.success.withOpacity(0.9),
      ),
    );
  }

  void _run(BuildContext ctx) {
    ctx.read<EditorProvider>().setBottomPanel('runner');
    // EditorScreen handles actual run via ConsoleProvider + RunnerPanel
    ctx.read<ConsoleProvider>().clearRunner();
    // Signal the runner via a key or broadcast — handled by RunnerPanel listening to EditorProvider
  }

  void _showGoToLine(BuildContext ctx, EditorProvider ep) {
    final ctrl = TextEditingController(text: '${ep.cursorLine}');
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Go to Line'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Line number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final line = int.tryParse(ctrl.text);
              if (line != null) EditorController.instance.goToLine(line);
              Navigator.pop(ctx);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final Color? activeColor;

  const _ToolBtn({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active && activeColor != null
        ? activeColor!
        : AppColors.textSecondary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 40, height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;
  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    final spec = LanguageColors.get(language);
    final color = spec.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        spec.icon,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 18),
      tooltip: 'More',
      onSelected: (v) {
        switch (v) {
          case 'select_all': EditorController.instance.selectAll(); break;
          case 'copy':       EditorController.instance.copy();      break;
          case 'paste':      EditorController.instance.paste();     break;
          case 'font_up':
            context.read<EditorProvider>().setFontSize(
              context.read<EditorProvider>().fontSize + 1,
            );
            EditorController.instance.setFontSize(
              context.read<EditorProvider>().fontSize,
            );
            break;
          case 'font_down':
            context.read<EditorProvider>().setFontSize(
              context.read<EditorProvider>().fontSize - 1,
            );
            EditorController.instance.setFontSize(
              context.read<EditorProvider>().fontSize,
            );
            break;
          case 'wrap':
            context.read<EditorProvider>().toggleWordWrap();
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'select_all', child: Text('Select All')),
        PopupMenuItem(value: 'copy',       child: Text('Copy')),
        PopupMenuItem(value: 'paste',      child: Text('Paste')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'font_up',    child: Text('Font Size +')),
        PopupMenuItem(value: 'font_down',  child: Text('Font Size −')),
        PopupMenuItem(value: 'wrap',       child: Text('Toggle Word Wrap')),
      ],
    );
  }
}
