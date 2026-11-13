import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller global untuk Light & Dark Mode KASI JADI, tersimpan ke SharedPreferences.
class ThemeController {
  static const _prefKey = 'theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == 'dark') {
        mode.value = ThemeMode.dark;
      } else if (saved == 'system') {
        mode.value = ThemeMode.system;
      } else {
        mode.value = ThemeMode.light;
      }
    } catch (_) {
      mode.value = ThemeMode.light;
    }
  }

  static Future<void> setMode(ThemeMode next) async {
    mode.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = switch (next) {
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
      };
      await prefs.setString(_prefKey, raw);
    } catch (_) {}
  }

  static Future<void> toggle() async {
    final next =
        mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setMode(next);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

/// Palet warna formal instansi KASI JADI (Biru Korporat & Slate).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryDeep;
  final Color primaryContainer;
  final Color onPrimary;
  final Color heroStart;
  final Color heroEnd;
  final Color heroBorder;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color info;
  final Color infoBg;
  final Color orange;
  final Color orangeBg;
  final Color teal;
  final Color tealBg;
  final Color ink;
  final Color shadow;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryDeep,
    required this.primaryContainer,
    required this.onPrimary,
    required this.heroStart,
    required this.heroEnd,
    required this.heroBorder,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.info,
    required this.infoBg,
    required this.orange,
    required this.orangeBg,
    required this.teal,
    required this.tealBg,
    required this.ink,
    required this.shadow,
  });

  static const light = AppPalette(
    bg: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5F9),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF0052FF),
    primaryDeep: Color(0xFF003EC7),
    primaryContainer: Color(0xFFEFF6FF),
    onPrimary: Color(0xFFFFFFFF),
    heroStart: Color(0xFF0052FF),
    heroEnd: Color(0xFF003EC7),
    heroBorder: Color(0xFF0043D1),
    success: Color(0xFF0D9488),
    successBg: Color(0xFFF0FDFA),
    warning: Color(0xFFD97706),
    warningBg: Color(0xFFFFFBEB),
    danger: Color(0xFFE11D48),
    dangerBg: Color(0xFFFFF1F2),
    info: Color(0xFF0052FF),
    infoBg: Color(0xFFEFF6FF),
    orange: Color(0xFFD97706),
    orangeBg: Color(0xFFFFFBEB),
    teal: Color(0xFF0D9488),
    tealBg: Color(0xFFF0FDFA),
    ink: Color(0xFF0F172A),
    shadow: Color(0x0D0F172A),
  );

  static const dark = AppPalette(
    bg: Color(0xFF0B1120),
    surface: Color(0xFF111827),
    surfaceMuted: Color(0xFF1E293B),
    surfaceElevated: Color(0xFF1E293B),
    border: Color(0xFF334155),
    borderStrong: Color(0xFF475569),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    primary: Color(0xFF0052FF),
    primaryDeep: Color(0xFF1D4ED8),
    primaryContainer: Color(0xFF172554),
    onPrimary: Color(0xFFFFFFFF),
    heroStart: Color(0xFF111827),
    heroEnd: Color(0xFF1E293B),
    heroBorder: Color(0xFF334155),
    success: Color(0xFF2DD4BF),
    successBg: Color(0xFF042F2E),
    warning: Color(0xFFFBBF24),
    warningBg: Color(0xFF451A03),
    danger: Color(0xFFFB7185),
    dangerBg: Color(0xFF4C0519),
    info: Color(0xFF60A5FA),
    infoBg: Color(0xFF172554),
    orange: Color(0xFFFBBF24),
    orangeBg: Color(0xFF451A03),
    teal: Color(0xFF2DD4BF),
    tealBg: Color(0xFF042F2E),
    ink: Color(0xFFF8FAFC),
    shadow: Color(0x3D000000),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryDeep,
    Color? primaryContainer,
    Color? onPrimary,
    Color? heroStart,
    Color? heroEnd,
    Color? heroBorder,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
    Color? info,
    Color? infoBg,
    Color? orange,
    Color? orangeBg,
    Color? teal,
    Color? tealBg,
    Color? ink,
    Color? shadow,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimary: onPrimary ?? this.onPrimary,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      heroBorder: heroBorder ?? this.heroBorder,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      orange: orange ?? this.orange,
      orangeBg: orangeBg ?? this.orangeBg,
      teal: teal ?? this.teal,
      tealBg: tealBg ?? this.tealBg,
      ink: ink ?? this.ink,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryContainer: Color.lerp(primaryContainer, other.primaryContainer, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      heroBorder: Color.lerp(heroBorder, other.heroBorder, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeBg: Color.lerp(orangeBg, other.orangeBg, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      tealBg: Color.lerp(tealBg, other.tealBg, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

class AppTheme {
  static const String sansFamily = 'PlusJakartaSans';
  static const String monoFamily = 'PlusJakartaSans';

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);

  static TextStyle mono({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: sansFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle tabular({
    double size = 12,
    FontWeight weight = FontWeight.w600,
    Color? color,
  }) =>
      mono(size: size, weight: weight, color: color);

  static BoxDecoration cardDecoration(
    AppPalette p, {
    Color? color,
    Color? borderColor,
    double radius = 14,
    bool elevated = false,
    Offset? shadowOffset,
  }) {
    return BoxDecoration(
      color: color ?? p.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? p.border, width: 1),
      boxShadow: [
        BoxShadow(
          color: p.shadow,
          offset: elevated ? const Offset(0, 4) : const Offset(0, 1),
          blurRadius: elevated ? 16 : 6,
          spreadRadius: 0,
        ),
      ],
    );
  }

  static ThemeData _buildTheme(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.textPrimary,
      secondary: p.teal,
      onSecondary: Colors.white,
      secondaryContainer: p.tealBg,
      onSecondaryContainer: p.textPrimary,
      tertiary: p.orange,
      onTertiary: Colors.white,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: p.border,
      outlineVariant: p.borderStrong,
      shadow: p.shadow,
    );

    final baseText =
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final textTheme = baseText.apply(
      fontFamily: sansFamily,
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: sansFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.bg,
      textTheme: textTheme,
      extensions: [p],
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
          letterSpacing: -0.25,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textSecondary,
        ),
        hintStyle: TextStyle(
          fontFamily: sansFamily,
          fontSize: 13.5,
          color: p.textMuted,
        ),
        enabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.primary, width: 1.5),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, width: 1.5),
        disabledBorder: inputBorder(p.border.withAlpha(120)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: p.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? p.info : p.primary,
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? p.surfaceElevated : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(
          fontFamily: sansFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: p.surface,
        indicatorColor: p.primary.withAlpha(isDark ? 45 : 22),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: sansFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (isDark ? Colors.white : p.primary)
                : p.textMuted,
          );
        }),
      ),
    );
  }

  static ThemeData get lightTheme => _buildTheme(Brightness.light, AppPalette.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark, AppPalette.dark);
}
