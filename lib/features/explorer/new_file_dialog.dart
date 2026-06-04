import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/language_colors.dart';

class NewFileDialog extends StatefulWidget {
  const NewFileDialog({super.key});
  @override
  State<NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<NewFileDialog> {
  final _ctrl = TextEditingController();

  final _templates = [
    ('index.html', 'HTML'),
    ('style.css', 'CSS'),
    ('script.js', 'JS'),
    ('main.py', 'Python'),
    ('main.dart', 'Dart'),
    ('App.tsx', 'TSX'),
    ('index.ts', 'TS'),
    ('main.go', 'Go'),
    ('main.rs', 'Rust'),
    ('Main.java', 'Java'),
    ('README.md', 'MD'),
    ('data.json', 'JSON'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New File',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 16),

              TextField(
                controller: _ctrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'JetBrainsMono'),
                decoration: const InputDecoration(
                  hintText: 'filename.js',
                  prefixIcon: Icon(Icons.insert_drive_file_outlined),
                ),
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 14),
              const Text('Quick templates',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _templates.map((t) {
                  final (name, label) = t;
                  return GestureDetector(
                    onTap: () {
                      _ctrl.text = name;
                      _ctrl.selection = TextSelection.fromPosition(
                        TextPosition(offset: name.indexOf('.')),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, {'name': name});
  }
}
