import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/editor_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../editor/editor_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = AppDatabase();

  // Editor prefs
  int  _fontSize   = 14;
  int  _tabSize    = 2;
  bool _autoSave   = true;
  bool _wordWrap   = false;
  bool _lineNumbers = true;
  bool _bracketMatch = true;
  bool _minimap    = false;
  double _lineHeight = 1.5;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ── BUG FIX: try/catch so DB failure never leaves _loading = true ─────────
  Future<void> _loadSettings() async {
    try {
      final fs  = await _db.getSetting('font_size');
      final ts  = await _db.getSetting('tab_size');
      final as_ = await _db.getSetting('auto_save');
      final ww  = await _db.getSetting('word_wrap');
      final ln  = await _db.getSetting('line_numbers');
      final bm  = await _db.getSetting('bracket_match');
      final mm  = await _db.getSetting('minimap');
      final lh  = await _db.getSetting('line_height');
      if (mounted) {
        setState(() {
          _fontSize    = int.tryParse(fs  ?? '14') ?? 14;
          _tabSize     = int.tryParse(ts  ?? '2')  ?? 2;
          _autoSave    = (as_ ?? 'true')   == 'true';
          _wordWrap    = (ww  ?? 'false')  == 'true';
          _lineNumbers = (ln  ?? 'true')   == 'true';
          _bracketMatch= (bm  ?? 'true')   == 'true';
          _minimap     = (mm  ?? 'false')  == 'true';
          _lineHeight  = double.tryParse(lh ?? '1.5') ?? 1.5;
          _loading     = false;
        });
      }
    } catch (e) {
      debugPrint('[Settings] _loadSettings error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      await _db.setSetting('font_size',     '$_fontSize');
      await _db.setSetting('tab_size',      '$_tabSize');
      await _db.setSetting('auto_save',     '$_autoSave');
      await _db.setSetting('word_wrap',     '$_wordWrap');
      await _db.setSetting('line_numbers',  '$_lineNumbers');
      await _db.setSetting('bracket_match', '$_bracketMatch');
      await _db.setSetting('minimap',       '$_minimap');
      await _db.setSetting('line_height',   '$_lineHeight');
    } catch (e) {
      debugPrint('[Settings] save error: $e');
    }
    if (mounted) {
      context.read<EditorProvider>().setFontSize(_fontSize);
      EditorController.instance.setFontSize(_fontSize);
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Settings saved'),
          ]),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                SizedBox(height: 12),
                Text('Loading settings…', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 60),
              children: [

                // ── Editor ─────────────────────────────────────────────────
                _Section(title: 'EDITOR', children: [
                  _SliderTile(
                    label: 'Font Size',
                    icon: Icons.text_fields_rounded,
                    value: _fontSize.toDouble(), min: 10, max: 28,
                    display: '$_fontSize px',
                    onChanged: (v) => setState(() => _fontSize = v.toInt()),
                  ),
                  _divider(),
                  _SliderTile(
                    label: 'Tab Size',
                    icon: Icons.space_bar_rounded,
                    value: _tabSize.toDouble(), min: 2, max: 8,
                    display: '$_tabSize spaces',
                    onChanged: (v) => setState(() => _tabSize = v.toInt()),
                  ),
                  _divider(),
                  _SliderTile(
                    label: 'Line Height',
                    icon: Icons.format_line_spacing_rounded,
                    value: _lineHeight, min: 1.0, max: 2.5,
                    display: _lineHeight.toStringAsFixed(1),
                    divisions: 15,
                    onChanged: (v) => setState(() => _lineHeight = (v * 10).round() / 10),
                  ),
                  _divider(),
                  _ToggleTile(label: 'Word Wrap', subtitle: 'Wrap long lines instead of scrolling', icon: Icons.wrap_text_rounded, value: _wordWrap, onChanged: (v) => setState(() => _wordWrap = v)),
                  _divider(),
                  _ToggleTile(label: 'Line Numbers', subtitle: 'Show line numbers in gutter', icon: Icons.format_list_numbered_rounded, value: _lineNumbers, onChanged: (v) => setState(() => _lineNumbers = v)),
                  _divider(),
                  _ToggleTile(label: 'Bracket Matching', subtitle: 'Highlight matching brackets', icon: Icons.code_rounded, value: _bracketMatch, onChanged: (v) => setState(() => _bracketMatch = v)),
                  _divider(),
                  _ToggleTile(label: 'Minimap', subtitle: 'Show code overview minimap', icon: Icons.map_outlined, value: _minimap, onChanged: (v) => setState(() => _minimap = v)),
                  _divider(),
                  _ToggleTile(label: 'Auto Save', subtitle: 'Save files automatically while typing', icon: Icons.save_outlined, value: _autoSave, onChanged: (v) => setState(() => _autoSave = v)),
                ]),

                const SizedBox(height: 24),

                // ── Font Preview ───────────────────────────────────────────
                _Section(title: 'FONT PREVIEW', children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'const greet = (name) => {\n  return `Hello, \${name}!`;\n};',
                        style: TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: _fontSize.toDouble(),
                          height: _lineHeight,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Keyboard Shortcuts ─────────────────────────────────────
                _Section(title: 'KEYBOARD SHORTCUTS', children: [
                  _ActionTile(
                    label: 'View All Shortcuts',
                    icon: Icons.keyboard_rounded,
                    onTap: () => _showShortcuts(context),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── Stats ─────────────────────────────────────────────────
                _StatsSection(),

                const SizedBox(height: 24),

                // ── Data ──────────────────────────────────────────────────
                _Section(title: 'DATA', children: [
                  _ActionTile(
                    label: 'Clear All Projects',
                    icon: Icons.delete_sweep_outlined,
                    color: AppColors.danger,
                    onTap: () => _confirmClearAll(context),
                  ),
                ]),

                const SizedBox(height: 24),

                // ── About ─────────────────────────────────────────────────
                _Section(title: 'ABOUT', children: [
                  _InfoRow(label: 'App',         value: 'VScoder',       icon: Icons.code_rounded),
                  _divider(),
                  _InfoRow(label: 'Version',     value: '1.2.0 (3)',     icon: Icons.tag_rounded),
                  _divider(),
                  _InfoRow(label: 'Editor Engine', value: 'CodeMirror 6', icon: Icons.edit_note_rounded),
                  _divider(),
                  _InfoRow(label: 'Framework',   value: 'Flutter',        icon: Icons.flutter_dash_rounded),
                  _divider(),
                  _InfoRow(label: 'Platform',    value: 'Android',        icon: Icons.android_rounded),
                ]),

                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'VScoder — Built with ♥ in Flutter',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
    );
  }

  void _showShortcuts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ShortcutsSheet(),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear All Data', style: TextStyle(color: AppColors.danger)),
        content: const Text('This will permanently delete all projects and files. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final pp = context.read<ProjectProvider>();
      for (final p in pp.projects) {
        await pp.deleteProject(p.id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All projects deleted'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderSub);
}

// ── Stats section ─────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectProvider>(
      builder: (_, pp, __) {
        final projectCount = pp.projects.length;
        final langs = pp.projects.map((p) => p.language).toSet().length;
        return _Section(title: 'WORKSPACE STATS', children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(value: '$projectCount', label: 'Projects',  color: AppColors.accent),
                const SizedBox(width: 10),
                _StatCard(value: '$langs',         label: 'Languages', color: AppColors.success),
              ],
            ),
          ),
        ]);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Keyboard shortcuts sheet ──────────────────────────────────────────────────
class _ShortcutsSheet extends StatelessWidget {
  const _ShortcutsSheet();
  static const _shortcuts = [
    ('Ctrl + S',       'Save file'),
    ('Ctrl + Z',       'Undo'),
    ('Ctrl + Y',       'Redo'),
    ('Ctrl + A',       'Select all'),
    ('Ctrl + F',       'Find / Replace'),
    ('Ctrl + /',       'Toggle comment'),
    ('Ctrl + ]',       'Indent line'),
    ('Ctrl + [',       'Outdent line'),
    ('Alt + ↑/↓',      'Move line up/down'),
    ('Ctrl + D',       'Duplicate line'),
    ('Ctrl + L',       'Select line'),
    ('Ctrl + Shift + K','Delete line'),
    ('F11',            'Fullscreen preview'),
    ('Esc',            'Close panel'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Keyboard Shortcuts', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _shortcuts.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderSub),
              itemBuilder: (_, i) {
                final (key, label) = _shortcuts[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(key, style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable section wrapper ───────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.label, required this.subtitle, required this.icon, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted, size: 18),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.accent),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String label, display;
  final IconData icon;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  const _SliderTile({required this.label, required this.icon, required this.value, required this.min, required this.max, required this.display, required this.onChanged, this.divisions});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.textMuted, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
              child: Text(display, style: const TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          Slider(value: value, min: min, max: max, divisions: divisions ?? (max - min).toInt(), activeColor: AppColors.accent, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _ActionTile({required this.label, required this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: c, size: 18),
      title: Text(label, style: TextStyle(color: c, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoRow({required this.label, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textMuted, size: 16),
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      dense: true,
    );
  }
}
