import 'package:flutter/material.dart';

/// Couleurs et style unifiés pour toute l'application, inspirés du design MedCare Systems
class AppColors {
  static const Color sidebarBg = Color(0xFF16233F);
  static const Color sidebarBgLight = Color(0xFF1D2E52);
  static const Color primaryBlue = Color(0xFF1A56DB);
  static const Color primaryBlueDark = Color(0xFF13408A);
  static const Color background = Color(0xFFF4F6FA);
  static const Color cardBorder = Color(0xFFE5E9F0);
  static const Color textDark = Color(0xFF1A1E2C);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color success = Color(0xFF12B76A);
  static const Color pending = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF59E0B);
}

/// Couleurs équivalentes pour le mode sombre.
class AppDarkColors {
  static const Color background = Color(0xFF0F1729);
  static const Color cardBackground = Color(0xFF1B2740);
  static const Color cardBorder = Color(0xFF2A3854);
  static const Color textLight = Color(0xFFE7EAF0);
  static const Color textGrey = Color(0xFF97A2B8);
}

/// Contrôleur global du thème (clair / sombre), accessible depuis
/// n'importe quel écran (ex : le bouton dans la barre latérale) sans
/// avoir à faire remonter l'état manuellement jusqu'à [MaterialApp].
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  bool get isDark => themeMode.value == ThemeMode.dark;

  void toggle() {
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}

/// Renvoie les couleurs de fond de carte / texte adaptées au thème actuel
/// du [BuildContext] donné, pour les écrans convertis au mode sombre.
class ContextColors {
  static Color cardBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppDarkColors.cardBackground
      : Colors.white;

  static Color cardBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppDarkColors.cardBorder
      : AppColors.cardBorder;

  static Color textPrimary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppDarkColors.textLight
      : AppColors.textDark;

  static Color textSecondary(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppDarkColors.textGrey
      : AppColors.textGrey;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB8C0CC), width: 1.3),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB8C0CC), width: 1.3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8A93A3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

/// Thème sombre. Les composants standards (boutons, champs de texte,
/// arrière-plan général) basculent automatiquement. Les écrans utilisant
/// des couleurs fixes (ex : cartes blanches) doivent utiliser
/// [ContextColors] pour suivre également le mode sombre.
ThemeData buildAppDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppDarkColors.background,
    cardColor: AppDarkColors.cardBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      brightness: Brightness.dark,
    ),
    fontFamily: 'Roboto',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppDarkColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppDarkColors.cardBorder,
          width: 1.3,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppDarkColors.cardBorder,
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
      hintStyle: const TextStyle(color: AppDarkColors.textGrey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}
