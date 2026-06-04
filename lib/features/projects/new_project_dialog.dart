import 'package:flutter/material.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/language_colors.dart';

class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});
  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _language = 'javascript';
  final _form = GlobalKey<FormState>();

  final _popularLangs = [
    'javascript', 'typescript', 'python', 'dart', 'java',
    'kotlin', 'cpp', 'go', 'rust', 'php', 'html', 'css',
    'swift', 'ruby', 'sql',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('New Project',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'my-awesome-app',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 20),

                // Language
                const Text('Primary Language',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 10),

                SizedBox(
                  height: 120,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.6,
                    ),
                    itemCount: _popularLangs.length,
                    itemBuilder: (_, i) {
                      final lang = _popularLangs[i];
                      final spec = LanguageColors.get(lang);
                      final selected = _language == lang;
                      final color = spec.color;
                      return GestureDetector(
                        onTap: () => setState(() => _language = lang),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withOpacity(0.2)
                                : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected ? color : AppColors.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            spec.icon,
                            style: TextStyle(
                              color: selected ? color : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
      ),
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, {
      'name':        _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'language':    _language,
    });
  }
}
