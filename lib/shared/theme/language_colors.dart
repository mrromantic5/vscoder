import 'package:flutter/material.dart';

class LanguageColor {
  final String name;
  final Color color;
  final String icon;
  final List<String> extensions;

  const LanguageColor({
    required this.name,
    required this.color,
    required this.icon,
    required this.extensions,
  });
}

class LanguageColors {
  static const _langs = <String, LanguageColor>{
    'javascript': LanguageColor(
      name: 'JavaScript', color: Color(0xFFF7DF1E),
      icon: 'JS', extensions: ['js', 'mjs', 'cjs'],
    ),
    'typescript': LanguageColor(
      name: 'TypeScript', color: Color(0xFF3178C6),
      icon: 'TS', extensions: ['ts'],
    ),
    'jsx': LanguageColor(
      name: 'JSX', color: Color(0xFF61DAFB),
      icon: 'JSX', extensions: ['jsx'],
    ),
    'tsx': LanguageColor(
      name: 'TSX', color: Color(0xFF61DAFB),
      icon: 'TSX', extensions: ['tsx'],
    ),
    'python': LanguageColor(
      name: 'Python', color: Color(0xFF3776AB),
      icon: 'PY', extensions: ['py', 'pyw', 'pyi'],
    ),
    'java': LanguageColor(
      name: 'Java', color: Color(0xFFED8B00),
      icon: 'JAVA', extensions: ['java'],
    ),
    'kotlin': LanguageColor(
      name: 'Kotlin', color: Color(0xFF7F52FF),
      icon: 'KT', extensions: ['kt', 'kts'],
    ),
    'swift': LanguageColor(
      name: 'Swift', color: Color(0xFFFA7343),
      icon: 'SWIFT', extensions: ['swift'],
    ),
    'dart': LanguageColor(
      name: 'Dart', color: Color(0xFF00B4AB),
      icon: 'DART', extensions: ['dart'],
    ),
    'c': LanguageColor(
      name: 'C', color: Color(0xFF555555),
      icon: 'C', extensions: ['c', 'h'],
    ),
    'cpp': LanguageColor(
      name: 'C++', color: Color(0xFF00599C),
      icon: 'C++', extensions: ['cpp', 'cc', 'cxx', 'hpp', 'hxx'],
    ),
    'csharp': LanguageColor(
      name: 'C#', color: Color(0xFF239120),
      icon: 'C#', extensions: ['cs'],
    ),
    'go': LanguageColor(
      name: 'Go', color: Color(0xFF00ADD8),
      icon: 'GO', extensions: ['go'],
    ),
    'rust': LanguageColor(
      name: 'Rust', color: Color(0xFFCE412B),
      icon: 'RS', extensions: ['rs'],
    ),
    'php': LanguageColor(
      name: 'PHP', color: Color(0xFF777BB4),
      icon: 'PHP', extensions: ['php', 'phtml'],
    ),
    'ruby': LanguageColor(
      name: 'Ruby', color: Color(0xFFCC342D),
      icon: 'RB', extensions: ['rb', 'gemspec'],
    ),
    'html': LanguageColor(
      name: 'HTML', color: Color(0xFFE34C26),
      icon: 'HTML', extensions: ['html', 'htm'],
    ),
    'css': LanguageColor(
      name: 'CSS', color: Color(0xFF264DE4),
      icon: 'CSS', extensions: ['css'],
    ),
    'scss': LanguageColor(
      name: 'SCSS', color: Color(0xFFCD6799),
      icon: 'SCSS', extensions: ['scss'],
    ),
    'sass': LanguageColor(
      name: 'Sass', color: Color(0xFFCD6799),
      icon: 'SASS', extensions: ['sass'],
    ),
    'less': LanguageColor(
      name: 'Less', color: Color(0xFF1D365D),
      icon: 'LESS', extensions: ['less'],
    ),
    'sql': LanguageColor(
      name: 'SQL', color: Color(0xFFE38C00),
      icon: 'SQL', extensions: ['sql'],
    ),
    'shell': LanguageColor(
      name: 'Shell', color: Color(0xFF4EAA25),
      icon: 'SH', extensions: ['sh', 'bash', 'zsh', 'fish'],
    ),
    'bash': LanguageColor(
      name: 'Bash', color: Color(0xFF4EAA25),
      icon: 'SH', extensions: ['bash'],
    ),
    'json': LanguageColor(
      name: 'JSON', color: Color(0xFF91A860),
      icon: 'JSON', extensions: ['json', 'jsonc'],
    ),
    'yaml': LanguageColor(
      name: 'YAML', color: Color(0xFFCB9820),
      icon: 'YAML', extensions: ['yaml', 'yml'],
    ),
    'xml': LanguageColor(
      name: 'XML', color: Color(0xFF0060AC),
      icon: 'XML', extensions: ['xml', 'svg', 'rss'],
    ),
    'markdown': LanguageColor(
      name: 'Markdown', color: Color(0xFF083FA1),
      icon: 'MD', extensions: ['md', 'mdx', 'markdown'],
    ),
    'vue': LanguageColor(
      name: 'Vue', color: Color(0xFF42B883),
      icon: 'VUE', extensions: ['vue'],
    ),
    'svelte': LanguageColor(
      name: 'Svelte', color: Color(0xFFFF3E00),
      icon: 'SVELTE', extensions: ['svelte'],
    ),
    'r': LanguageColor(
      name: 'R', color: Color(0xFF276DC3),
      icon: 'R', extensions: ['r', 'R'],
    ),
    'perl': LanguageColor(
      name: 'Perl', color: Color(0xFF39457E),
      icon: 'PL', extensions: ['pl', 'pm'],
    ),
    'lua': LanguageColor(
      name: 'Lua', color: Color(0xFF000080),
      icon: 'LUA', extensions: ['lua'],
    ),
    'groovy': LanguageColor(
      name: 'Groovy', color: Color(0xFF4298B8),
      icon: 'GV', extensions: ['groovy', 'gvy'],
    ),
    'scala': LanguageColor(
      name: 'Scala', color: Color(0xFFDC322F),
      icon: 'SCALA', extensions: ['scala'],
    ),
    'haskell': LanguageColor(
      name: 'Haskell', color: Color(0xFF5D4F85),
      icon: 'HS', extensions: ['hs'],
    ),
    'elixir': LanguageColor(
      name: 'Elixir', color: Color(0xFF6E4A7E),
      icon: 'EX', extensions: ['ex', 'exs'],
    ),
    'clojure': LanguageColor(
      name: 'Clojure', color: Color(0xFF5881D8),
      icon: 'CLJ', extensions: ['clj', 'cljs'],
    ),
    'toml': LanguageColor(
      name: 'TOML', color: Color(0xFF9C4221),
      icon: 'TOML', extensions: ['toml'],
    ),
    'ini': LanguageColor(
      name: 'INI', color: Color(0xFF6E6E6E),
      icon: 'INI', extensions: ['ini', 'cfg', 'conf'],
    ),
    'dockerfile': LanguageColor(
      name: 'Dockerfile', color: Color(0xFF0DB7ED),
      icon: 'DOCKER', extensions: ['dockerfile'],
    ),
    'graphql': LanguageColor(
      name: 'GraphQL', color: Color(0xFFE10098),
      icon: 'GQL', extensions: ['graphql', 'gql'],
    ),
    'diff': LanguageColor(
      name: 'Diff', color: Color(0xFF6E6E6E),
      icon: 'DIFF', extensions: ['diff', 'patch'],
    ),
    'plaintext': LanguageColor(
      name: 'Plain Text', color: Color(0xFF8B949E),
      icon: 'TXT', extensions: ['txt', 'text'],
    ),
  };

  static LanguageColor get(String language) {
    return _langs[language.toLowerCase()] ??
        const LanguageColor(
          name: 'Plain Text', color: Color(0xFF8B949E),
          icon: 'TXT', extensions: [],
        );
  }

  static String fromExtension(String ext) {
    final lower = ext.toLowerCase().replaceFirst('.', '');
    for (final entry in _langs.entries) {
      if (entry.value.extensions.contains(lower)) return entry.key;
    }
    return 'plaintext';
  }

  static Color colorOf(String language) => get(language).color;

  static List<String> get allLanguages => _langs.keys.toList()..sort();
}
