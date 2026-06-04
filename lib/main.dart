import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'core/providers/project_provider.dart';
import 'core/providers/editor_provider.dart';
import 'core/providers/console_provider.dart';

void main() {
  // FIX: Wrap entire app in runZonedGuarded so uncaught async errors
  // never leave the user on a permanent black screen.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Forward Flutter framework errors to the zone's error handler.
    FlutterError.onError = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.empty);
    };

    // Lock to portrait + landscape (both supported)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Full-screen immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0D1117),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // FIX: Initialise database with a try-catch so a DB error never
    // silently crashes the app before runApp() is called.
    final db = AppDatabase();
    try {
      await db.initialize();
    } catch (e, st) {
      debugPrint('[VScoder] DB init failed: $e\n$st');
      // Continue — providers will gracefully handle a broken DB rather
      // than leaving the user on a permanent black screen.
    }

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProjectProvider(db)),
          ChangeNotifierProvider(create: (_) => EditorProvider()),
          ChangeNotifierProvider(create: (_) => ConsoleProvider()),
        ],
        child: const VsCoderApp(),
      ),
    );
  }, (error, stack) {
    // Top-level error handler — logs crashes instead of silently going black.
    debugPrint('[VScoder] Uncaught error: $error\n$stack');
  });
}
