import 'package:flutter/foundation.dart';

enum LogType { log, warn, error, info, system, command, output }

class ConsoleEntry {
  final LogType type;
  final String message;
  final DateTime timestamp;

  ConsoleEntry({
    required this.type,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get prefix {
    switch (type) {
      case LogType.log:     return '▸';
      case LogType.warn:    return '⚠';
      case LogType.error:   return '✕';
      case LogType.info:    return 'ℹ';
      case LogType.system:  return '⚙';
      case LogType.command: return '\$';
      case LogType.output:  return ' ';
    }
  }
}

class ConsoleProvider extends ChangeNotifier {
  final List<ConsoleEntry> _consoleLogs  = [];
  final List<ConsoleEntry> _terminalLogs = [];
  final List<ConsoleEntry> _runnerLogs   = [];
  int _unreadErrors = 0;

  List<ConsoleEntry> get consoleLogs  => _consoleLogs;
  List<ConsoleEntry> get terminalLogs => _terminalLogs;
  List<ConsoleEntry> get runnerLogs   => _runnerLogs;
  int get unreadErrors => _unreadErrors;

  void addConsole(String typeStr, String message) {
    final type = _parseType(typeStr);
    _consoleLogs.add(ConsoleEntry(type: type, message: message));
    if (type == LogType.error) _unreadErrors++;
    if (_consoleLogs.length > 500) _consoleLogs.removeAt(0);
    notifyListeners();
  }

  void addTerminal(String message, {LogType type = LogType.output}) {
    _terminalLogs.add(ConsoleEntry(type: type, message: message));
    if (_terminalLogs.length > 1000) _terminalLogs.removeAt(0);
    notifyListeners();
  }

  void addRunner(String typeStr, String message) {
    final type = _parseType(typeStr);
    _runnerLogs.add(ConsoleEntry(type: type, message: message));
    if (_runnerLogs.length > 500) _runnerLogs.removeAt(0);
    notifyListeners();
  }

  void addSystem(String message) {
    _consoleLogs.add(ConsoleEntry(type: LogType.system, message: message));
    notifyListeners();
  }

  void clearConsole() {
    _consoleLogs.clear();
    _unreadErrors = 0;
    notifyListeners();
  }

  void clearTerminal() {
    _terminalLogs.clear();
    notifyListeners();
  }

  void clearRunner() {
    _runnerLogs.clear();
    notifyListeners();
  }

  void clearAllErrors() {
    _unreadErrors = 0;
    notifyListeners();
  }

  LogType _parseType(String s) {
    switch (s.toLowerCase()) {
      case 'error': return LogType.error;
      case 'warn':  return LogType.warn;
      case 'info':  return LogType.info;
      default:      return LogType.log;
    }
  }
}
