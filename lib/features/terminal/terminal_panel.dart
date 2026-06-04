import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/providers/console_provider.dart';
import '../../shared/theme/app_theme.dart';

class TerminalPanel extends StatefulWidget {
  const TerminalPanel({super.key});
  @override
  State<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<TerminalPanel> {
  final _inputCtrl = TextEditingController();
  final _scroll    = ScrollController();
  final _focus     = FocusNode();
  final _history   = <String>[];
  int  _historyIdx = -1;
  String _cwd      = '';
  bool _running    = false;

  @override
  void initState() {
    super.initState();
    _initCwd();
  }

  Future<void> _initCwd() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() => _cwd = dir.path);
    _addLine('VScoder Terminal v1.0', type: LogType.system);
    _addLine('Dir: $_cwd', type: LogType.system);
    _addLine('Type "help" for available commands.', type: LogType.system);
    _addLine('', type: LogType.output);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildOutput()),
          _buildInput(),
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
          const Icon(Icons.terminal_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          const Text('Terminal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
          const Spacer(),
          GestureDetector(
            onTap: () => context.read<ConsoleProvider>().clearTerminal(),
            child: const Icon(Icons.delete_sweep_rounded,
                size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    return Consumer<ConsoleProvider>(
      builder: (ctx, cp, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
            );
          }
        });
        return GestureDetector(
          onTap: () => _focus.requestFocus(),
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            itemCount: cp.terminalLogs.length,
            itemBuilder: (_, i) {
              final e = cp.terminalLogs[i];
              return Text(
                e.message,
                style: TextStyle(
                  color: _termColor(e.type),
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                  height: 1.5,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Row(
        children: [
          Text(
            '${_shortCwd()} \$ ',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: _onKey,
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focus,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: _running ? null : _execute,
                enabled: !_running,
              ),
            ),
          ),
          if (_running)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  void _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return;
    if (e.logicalKey == LogicalKeyboardKey.arrowUp && _history.isNotEmpty) {
      _historyIdx = (_historyIdx + 1).clamp(0, _history.length - 1);
      _inputCtrl.text = _history[_historyIdx];
      _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length);
    } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_historyIdx > 0) {
        _historyIdx--;
        _inputCtrl.text = _history[_historyIdx];
      } else {
        _historyIdx = -1;
        _inputCtrl.clear();
      }
    }
  }

  Future<void> _execute(String raw) async {
    final cmd = raw.trim();
    if (cmd.isEmpty) return;
    _history.insert(0, cmd);
    _historyIdx = -1;
    _inputCtrl.clear();
    _addLine('${_shortCwd()} \$ $cmd', type: LogType.command);

    final parts = cmd.split(RegExp(r'\s+'));
    final exe   = parts[0].toLowerCase();
    final args  = parts.sublist(1);

    switch (exe) {
      case 'clear': case 'cls':
        context.read<ConsoleProvider>().clearTerminal();
        _addLine('');
      case 'help':
        _printHelp();
      case 'pwd':
        _addLine(_cwd);
      case 'ls': case 'dir':
        await _ls(args.isNotEmpty ? args[0] : _cwd);
      case 'cd':
        await _cd(args.isNotEmpty ? args[0] : _cwd);
      case 'mkdir':
        if (args.isEmpty) { _addLine('mkdir: missing name', type: LogType.error); break; }
        await _mkdir(args[0]);
      case 'touch':
        if (args.isEmpty) { _addLine('touch: missing name', type: LogType.error); break; }
        await _touch(args[0]);
      case 'cat':
        if (args.isEmpty) { _addLine('cat: missing file', type: LogType.error); break; }
        await _cat(args[0]);
      case 'rm':
        if (args.isEmpty) { _addLine('rm: missing path', type: LogType.error); break; }
        await _rm(args[0]);
      case 'echo':
        _addLine(args.join(' '));
      case 'date':
        _addLine(DateTime.now().toString());
      case 'whoami':
        _addLine('vscoder-user');
      case 'uname':
        _addLine('Android ${Platform.operatingSystemVersion}');
      default:
        await _runProcess(exe, args);
    }
  }

  Future<void> _runProcess(String exe, List<String> args) async {
    setState(() => _running = true);
    try {
      final result = await Process.run(
        exe, args,
        workingDirectory: _cwd,
        runInShell: true,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      ).timeout(const Duration(seconds: 30));

      final out = result.stdout.toString().trim();
      final err = result.stderr.toString().trim();
      if (out.isNotEmpty) _addLines(out);
      if (err.isNotEmpty) _addLines(err, type: LogType.error);
      if (result.exitCode != 0 && err.isEmpty && out.isEmpty) {
        _addLine('Exit code: ${result.exitCode}', type: LogType.warn);
      }
    } on ProcessException catch (e) {
      _addLine('Not found: ${e.executable}. Type "help" for commands.', type: LogType.error);
    } catch (e) {
      _addLine('Error: $e', type: LogType.error);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _ls(String p) async {
    try {
      final dir = Directory(p.startsWith('/') ? p : '$_cwd/$p');
      final list = await dir.list().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      if (list.isEmpty) { _addLine('(empty)'); return; }
      for (final e in list) {
        final n = e.path.split('/').last;
        _addLine(e is Directory ? '📁 $n/' : '📄 $n',
            type: e is Directory ? LogType.info : LogType.output);
      }
    } catch (e) {
      _addLine('ls: $e', type: LogType.error);
    }
  }

  Future<void> _cd(String p) async {
    final np = p == '..' ? File(_cwd).parent.path
        : p.startsWith('/') ? p : '$_cwd/$p';
    if (await Directory(np).exists()) {
      setState(() => _cwd = np);
    } else {
      _addLine('cd: no such directory: $p', type: LogType.error);
    }
  }

  Future<void> _mkdir(String n) async {
    try {
      await Directory('$_cwd/$n').create(recursive: true);
      _addLine('Created: $n');
    } catch (e) { _addLine('mkdir: $e', type: LogType.error); }
  }

  Future<void> _touch(String n) async {
    try {
      await File('$_cwd/$n').create(recursive: true);
      _addLine('Created: $n');
    } catch (e) { _addLine('touch: $e', type: LogType.error); }
  }

  Future<void> _cat(String n) async {
    try {
      final c = await File(n.startsWith('/') ? n : '$_cwd/$n').readAsString();
      _addLines(c);
    } catch (e) { _addLine('cat: $e', type: LogType.error); }
  }

  Future<void> _rm(String n) async {
    try {
      final p = n.startsWith('/') ? n : '$_cwd/$n';
      if (await Directory(p).exists()) {
        await Directory(p).delete(recursive: true);
      } else {
        await File(p).delete();
      }
      _addLine('Removed: $n');
    } catch (e) { _addLine('rm: $e', type: LogType.error); }
  }

  void _printHelp() {
    for (final l in [
      'clear/cls   — Clear terminal',
      'pwd         — Print working dir',
      'ls [dir]    — List files',
      'cd <dir>    — Change directory',
      'mkdir <n>   — Create directory',
      'touch <f>   — Create file',
      'cat <f>     — Print file',
      'rm <p>      — Remove file/dir',
      'echo <txt>  — Print text',
      'date        — Current date/time',
      'whoami      — Current user',
      '<cmd>       — Run system process',
    ]) { _addLine('  $l'); }
  }

  void _addLine(String msg, {LogType type = LogType.output}) =>
      context.read<ConsoleProvider>().addTerminal(msg, type: type);

  void _addLines(String ml, {LogType type = LogType.output}) {
    for (final l in ml.split('\n')) _addLine(l, type: type);
  }

  Color _termColor(LogType t) {
    switch (t) {
      case LogType.error:   return AppColors.danger;
      case LogType.warn:    return AppColors.warning;
      case LogType.info:    return AppColors.info;
      case LogType.system:  return AppColors.textMuted;
      case LogType.command: return AppColors.success;
      default:              return AppColors.textSecondary;
    }
  }

  String _shortCwd() {
    final parts = _cwd.split('/');
    return parts.length > 2 ? '~/${parts.last}' : _cwd;
  }
}
