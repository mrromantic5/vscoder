import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/console_provider.dart';
import '../../shared/theme/app_theme.dart';

class ConsolePanel extends StatefulWidget {
  const ConsolePanel({super.key});
  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final _scroll = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildLogs()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ConsoleProvider>(
      builder: (ctx, cp, _) => Container(
        height: 30,
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.terminal_rounded, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 6),
            const Text('Console',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
            if (cp.unreadErrors > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cp.unreadErrors} error${cp.unreadErrors > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Auto-scroll toggle
            GestureDetector(
              onTap: () => setState(() => _autoScroll = !_autoScroll),
              child: Icon(
                Icons.vertical_align_bottom_rounded,
                size: 14,
                color: _autoScroll ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                cp.clearConsole();
                cp.clearAllErrors();
              },
              child: const Icon(Icons.delete_sweep_rounded,
                  size: 14, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogs() {
    return Consumer<ConsoleProvider>(
      builder: (ctx, cp, _) {
        if (cp.consoleLogs.isEmpty) {
          return const Center(
            child: Text(
              'No console output',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_autoScroll && _scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: cp.consoleLogs.length,
          itemBuilder: (_, i) => _LogEntry(entry: cp.consoleLogs[i]),
        );
      },
    );
  }
}

class _LogEntry extends StatelessWidget {
  final ConsoleEntry entry;
  const _LogEntry({required this.entry});

  Color get _color {
    switch (entry.type) {
      case LogType.error:  return AppColors.danger;
      case LogType.warn:   return AppColors.warning;
      case LogType.info:   return AppColors.info;
      case LogType.system: return AppColors.textMuted;
      default:             return AppColors.textSecondary;
    }
  }

  Color get _bg {
    switch (entry.type) {
      case LogType.error: return AppColors.danger.withOpacity(0.06);
      case LogType.warn:  return AppColors.warning.withOpacity(0.04);
      default:            return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: entry.message));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
        );
      },
      child: Container(
        color: _bg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.prefix,
              style: TextStyle(color: _color, fontSize: 11, fontFamily: 'JetBrainsMono'),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entry.message,
                style: TextStyle(
                  color: _color,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
