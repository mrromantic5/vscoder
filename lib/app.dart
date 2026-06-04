import 'package:flutter/material.dart';
import 'shared/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/projects/projects_home.dart';
import 'features/editor/editor_screen.dart';
import 'features/settings/settings_screen.dart';

class VsCoderApp extends StatelessWidget {
  const VsCoderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VScoder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/projects': (_) => const ProjectsHome(),
        '/editor': (_) => const EditorScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
