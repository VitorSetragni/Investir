import 'package:flutter/material.dart';

@immutable
class AppPalette {
  final Color bg, panel, line, mint, muted, amber, negative;
  const AppPalette({
    required this.bg,
    required this.panel,
    required this.line,
    required this.mint,
    required this.muted,
    required this.amber,
    required this.negative,
  });

  static const dark = AppPalette(
    bg: Color(0xFF0B111B),
    panel: Color(0xFF131D2B),
    line: Color(0xFF273449),
    mint: Color(0xFF74E5B2),
    muted: Color(0xFF9BAEC6),
    amber: Color(0xFFF5C47C),
    negative: Color(0xFFFF9B9B),
  );

  static const light = AppPalette(
    bg: Color(0xFFF5F7FA),
    panel: Colors.white,
    line: Color(0xFFD6DFE7),
    mint: Color(0xFF146B4B),
    muted: Color(0xFF526174),
    amber: Color(0xFF855000),
    negative: Color(0xFFAF2330),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).brightness == Brightness.dark
      ? AppPalette.dark
      : AppPalette.light;
}

Color statusColor(BuildContext context, String status) => switch (status) {
  'preferred' || 'pass' => context.palette.mint,
  'acceptable' => context.palette.amber,
  'excluded' || 'fail' => context.palette.negative,
  _ => context.palette.muted,
};

ThemeData investirTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: p.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.mint,
      brightness: brightness,
      surface: p.panel,
      primary: p.mint,
    ),
    fontFamily: 'Roboto',
    dividerColor: p.line,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: p.panel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.panel,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
    ),
  );
}
