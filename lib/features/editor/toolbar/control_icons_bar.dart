import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/app_theme.dart';
import '../editor_controller.dart';

/// The extra symbol bar shown above the keyboard in the editor.
/// Provides quick access to brackets, semicolons, arrow keys, etc.
class ControlIconsBar extends StatelessWidget {
  const ControlIconsBar({super.key});

  static const _symbols = [
    _SymBtn(label: 'Tab',  value: '\t',  isText: false, icon: Icons.keyboard_tab_rounded),
    _SymBtn(label: '{',    value: '{',   isText: true),
    _SymBtn(label: '}',    value: '}',   isText: true),
    _SymBtn(label: '(',    value: '(',   isText: true),
    _SymBtn(label: ')',    value: ')',   isText: true),
    _SymBtn(label: '[',    value: '[',   isText: true),
    _SymBtn(label: ']',    value: ']',   isText: true),
    _SymBtn(label: ';',    value: ';',   isText: true),
    _SymBtn(label: ':',    value: ':',   isText: true),
    _SymBtn(label: '.',    value: '.',   isText: true),
    _SymBtn(label: ',',    value: ',',   isText: true),
    _SymBtn(label: '=',    value: '=',   isText: true),
    _SymBtn(label: '"',    value: '"',   isText: true),
    _SymBtn(label: "'",    value: "'",   isText: true),
    _SymBtn(label: '`',    value: '`',   isText: true),
    _SymBtn(label: '/',    value: '/',   isText: true),
    _SymBtn(label: '\\',   value: '\\',  isText: true),
    _SymBtn(label: '_',    value: '_',   isText: true),
    _SymBtn(label: '-',    value: '-',   isText: true),
    _SymBtn(label: '+',    value: '+',   isText: true),
    _SymBtn(label: '*',    value: '*',   isText: true),
    _SymBtn(label: '&',    value: '&',   isText: true),
    _SymBtn(label: '|',    value: '|',   isText: true),
    _SymBtn(label: '!',    value: '!',   isText: true),
    _SymBtn(label: '?',    value: '?',   isText: true),
    _SymBtn(label: '<',    value: '<',   isText: true),
    _SymBtn(label: '>',    value: '>',   isText: true),
    _SymBtn(label: '#',    value: '#',   isText: true),
    _SymBtn(label: '@',    value: '@',   isText: true),
    _SymBtn(label: '%',    value: '%',   isText: true),
    _SymBtn(label: '^',    value: '^',   isText: true),
    _SymBtn(label: '~',    value: '~',   isText: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.surface,
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _symbols.length,
              itemBuilder: (_, i) => _SymbolButton(btn: _symbols[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SymBtn {
  final String label;
  final String value;
  final bool isText;
  final IconData? icon;

  const _SymBtn({
    required this.label,
    required this.value,
    required this.isText,
    this.icon,
  });
}

class _SymbolButton extends StatelessWidget {
  final _SymBtn btn;
  const _SymbolButton({required this.btn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        EditorController.instance.insert(btn.value);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: btn.icon != null
            ? Icon(btn.icon, size: 16, color: AppColors.textSecondary)
            : Text(
                btn.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'JetBrainsMono',
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
