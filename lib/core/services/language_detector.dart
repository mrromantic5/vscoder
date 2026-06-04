import '../../shared/theme/language_colors.dart';

class LanguageDetector {
  static String fromFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return _fromFullName(name);
    final ext = name.substring(dot + 1).toLowerCase();
    return LanguageColors.fromExtension(ext);
  }

  static String _fromFullName(String name) {
    final lower = name.toLowerCase();
    if (lower == 'dockerfile') return 'dockerfile';
    if (lower == 'makefile')   return 'shell';
    if (lower == '.gitignore') return 'plaintext';
    if (lower.startsWith('.env')) return 'plaintext';
    if (lower == 'procfile')   return 'shell';
    return 'plaintext';
  }

  static String fromPath(String path) {
    final name = path.split('/').last.split('\\').last;
    return fromFileName(name);
  }
}
