import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/editor_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../editor/editor_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = AppDatabase();
  int _fontSize = 14;
  int _tabSize  = 2;
  bool _autoSave   = true;
  bool _wordWrap   = false;
  bool _lineNumbers = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final fs = await _db.getSetting('font_size');
    final ts = await _db.getSetting('tab_size');
    final as_ = await _db.getSetting('auto_save');
    final ww = await _db.getSetting('word_wrap');
    setState(() {
      _fontSize  = int.tryParse(fs ?? '14') ?? 14;
      _tabSize   = int.tryParse(ts ?? '2') ?? 2;
      _autoSave  = (as_ ?? 'true') == 'true';
      _wordWrap  = (ww ?? 'false') == 'true';
      _loading   = false;
    });
  }

  Future<void> _save() async {
    await _db.setSetting('font_size', '$_fontSize');
    await _db.setSetting('tab_size',  '$_tabSize');
    await _db.setSetting('auto_save', '$_autoSave');
    await _db.setSetting('word_wrap', '$_wordWrap');
    if (mounted) {
      context.read<EditorProvider>().setFontSize(_fontSize);
      EditorController.instance.setFontSize(_fontSize);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), duration: Duration(seconds: 1)),
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
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Section(title: 'Editor', children: [
                  _SliderSetting(
                    label: 'Font Size',
                    value: _fontSize.toDouble(),
                    min: 10, max: 28,
                    display: '$_fontSize px',
                    onChanged: (v) => setState(() => _fontSize = v.toInt()),
                  ),
                  _SliderSetting(
                    label: 'Tab Size',
                    value: _tabSize.toDouble(),
                    min: 2, max: 8,
                    display: '$_tabSize spaces',
                    onChanged: (v) => setState(() => _tabSize = v.toInt()),
                  ),
                  _ToggleSetting(
                    label: 'Word Wrap',
                    subtitle: 'Wrap long lines',
                    value: _wordWrap,
                    onChanged: (v) => setState(() => _wordWrap = v),
                  ),
                  _ToggleSetting(
                    label: 'Auto Save',
                    subtitle: 'Save files automatically while typing',
                    value: _autoSave,
                    onChanged: (v) => setState(() => _autoSave = v),
                  ),
                ]),
                const SizedBox(height: 20),
                _Section(title: 'About', children: [
                  _InfoRow(label: 'App', value: 'VScoder'),
                  _InfoRow(label: 'Version', value: '1.0.0'),
                  _InfoRow(label: 'Engine', value: 'CodeMirror 6'),
                  _InfoRow(label: 'Built with', value: 'Flutter'),
                ]),
              ],
            ),
    );
  }
}

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
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(title,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              )),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleSetting({
    required this.label, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.accent),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label, display;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  const _SliderSetting({
    required this.label, required this.value,
    required this.min, required this.max,
    required this.display, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              const Spacer(),
              Text(display, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          Slider(
            value: value, min: min, max: max,
            divisions: (max - min).toInt(),
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
    );
  }
}
