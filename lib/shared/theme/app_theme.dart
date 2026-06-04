import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // ── Background layers ────────────────────────────────────────────
  static const bg         = Color(0xFF0D1117); // Deepest background
  static const surface    = Color(0xFF161B22); // Cards, panels
  static const surfaceAlt = Color(0xFF21262D); // Elevated surface
  static const surfaceHov = Color(0xFF30363D); // Hover states
  static const border     = Color(0xFF30363D); // Borders
  static const borderSub  = Color(0xFF21262D); // Subtle borders

  // ── Text ─────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted     = Color(0xFF484F58);
  static const textDisabled  = Color(0xFF3D444D);

  // ── Accent / Brand ───────────────────────────────────────────────
  static const accent     = Color(0xFF58A6FF); // Blue — primary accent
  static const accentGlow = Color(0x2058A6FF);

  // ── Semantic ─────────────────────────────────────────────────────
  static const success = Color(0xFF3FB950); // Green
  static const warning = Color(0xFFD29922); // Amber
  static const danger  = Color(0xFFF85149); // Red
  static const info    = Color(0xFF58A6FF); // Blue

  // ── Token colors (matching editor syntax) ───────────────────────
  static const keyword   = Color(0xFFFF7B72);
  static const string    = Color(0xFFA5D6FF);
  static const number    = Color(0xFF79C0FF);
  static const comment   = Color(0xFF8B949E);
  static const func      = Color(0xFFD2A8FF);
  static const variable  = Color(0xFFFFA657);
  static const type      = Color(0xFFF0883E);
  static const tag       = Color(0xFF7EE787);
}

class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.func,
      tertiary: AppColors.success,
      error: AppColors.danger,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onPrimary: Colors.white,
      outline: AppColors.border,
    ),
    // System font stack (JetBrainsMono loaded via pubspec)

    // ── AppBar ───────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black26,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    ),

    // ── Cards ────────────────────────────────────────────────────
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
    ),

    // ── Buttons ──────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    ),

    // ── Inputs ───────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      prefixIconColor: AppColors.textSecondary,
    ),

    // ── Dialogs ──────────────────────────────────────────────────
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      titleTextStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),

    // ── Snackbar ─────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceAlt,
      contentTextStyle: const TextStyle(color: AppColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── Divider ──────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // ── BottomSheet ──────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    // ── ListTile ─────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      textColor: AppColors.textPrimary,
      iconColor: AppColors.textSecondary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    // ── IconButton ───────────────────────────────────────────────
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
      ),
    ),

    // ── PopupMenu ────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceAlt,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
    ),

    // ── Chips ────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceAlt,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),

    // ── Tab bar ──────────────────────────────────────────────────
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.accent,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.accent,
      dividerColor: AppColors.border,
    ),

    // ── Text ─────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge:  TextStyle(color: AppColors.textPrimary,   fontSize: 32, fontWeight: FontWeight.w700),
      displayMedium: TextStyle(color: AppColors.textPrimary,   fontSize: 28, fontWeight: FontWeight.w700),
      headlineLarge: TextStyle(color: AppColors.textPrimary,   fontSize: 24, fontWeight: FontWeight.w700),
      headlineMedium:TextStyle(color: AppColors.textPrimary,   fontSize: 20, fontWeight: FontWeight.w600),
      headlineSmall: TextStyle(color: AppColors.textPrimary,   fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge:    TextStyle(color: AppColors.textPrimary,   fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium:   TextStyle(color: AppColors.textPrimary,   fontSize: 14, fontWeight: FontWeight.w600),
      titleSmall:    TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
      bodyLarge:     TextStyle(color: AppColors.textPrimary,   fontSize: 15),
      bodyMedium:    TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall:     TextStyle(color: AppColors.textMuted,     fontSize: 12),
      labelLarge:    TextStyle(color: AppColors.textPrimary,   fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium:   TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall:    TextStyle(color: AppColors.textMuted,     fontSize: 11),
    ),
  );
}
