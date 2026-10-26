import 'package:flutter/material.dart';

/// Paleta Kanagawa (variante wave) do Neovim.
abstract final class Kanagawa {
  static const sumiInk0 = Color(0xFF16161D);
  static const sumiInk3 = Color(0xFF1F1F28);
  static const sumiInk4 = Color(0xFF2A2A37);
  static const sumiInk5 = Color(0xFF363646);
  static const sumiInk6 = Color(0xFF54546D);
  static const fujiWhite = Color(0xFFDCD7BA);
  static const oldWhite = Color(0xFFC8C093);
  static const fujiGray = Color(0xFF727169);
  static const springViolet1 = Color(0xFF938AA9);
  static const oniViolet = Color(0xFF957FB8);
  static const crystalBlue = Color(0xFF7E9CD8);
  static const springBlue = Color(0xFF7FB4CA);
  static const lightBlue = Color(0xFFA3D4D5);
  static const waveBlue1 = Color(0xFF223249);
  static const waveBlue2 = Color(0xFF2D4F67);
  static const springGreen = Color(0xFF98BB6C);
  static const autumnGreen = Color(0xFF76946A);
  static const carpYellow = Color(0xFFE6C384);
  static const boatYellow2 = Color(0xFFC0A36E);
  static const surimiOrange = Color(0xFFFFA066);
  static const autumnRed = Color(0xFFC34043);
  static const waveRed = Color(0xFFE46876);
  static const sakuraPink = Color(0xFFD27E99);
}

/// Tipografia: JetBrains Mono (vai dentro do APK, em assets/fonts).
/// `display` é a versão extra negrito para títulos; os tamanhos seguem a
/// escala antiga das telas e são ajustados aqui para a fonte mono.
abstract final class PixelText {
  static const family = 'JetBrainsMono';
  static const bodyFamily = family;

  static TextStyle display(double size, {Color color = Kanagawa.fujiWhite}) => TextStyle(
      fontFamily: family, fontSize: size * 1.45, fontWeight: FontWeight.w800, color: color, height: 1.25, letterSpacing: .4);

  static TextStyle body(double size, {Color color = Kanagawa.fujiWhite}) =>
      TextStyle(fontFamily: family, fontSize: size * .9, color: color, height: 1.35);
}

ThemeData buildKanagawaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Kanagawa.sumiInk3,
    colorScheme: const ColorScheme.dark(
      surface: Kanagawa.sumiInk4,
      primary: Kanagawa.carpYellow,
      onPrimary: Kanagawa.sumiInk0,
      secondary: Kanagawa.springBlue,
      onSecondary: Kanagawa.sumiInk0,
      error: Kanagawa.autumnRed,
      onSurface: Kanagawa.fujiWhite,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: PixelText.bodyFamily,
      bodyColor: Kanagawa.fujiWhite,
      displayColor: Kanagawa.fujiWhite,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Kanagawa.sumiInk0,
      foregroundColor: Kanagawa.fujiWhite,
      titleTextStyle: PixelText.display(12, color: Kanagawa.carpYellow),
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Kanagawa.sumiInk0,
      indicatorColor: Kanagawa.waveBlue2,
      labelTextStyle: WidgetStatePropertyAll(PixelText.display(7)),
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: Kanagawa.fujiWhite)),
      indicatorShape: const RoundedRectangleBorder(),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Kanagawa.sumiInk4,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Kanagawa.sumiInk0, width: 4),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Kanagawa.carpYellow,
      contentTextStyle: PixelText.display(8, color: Kanagawa.sumiInk0),
      shape: const RoundedRectangleBorder(),
      behavior: SnackBarBehavior.floating,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Kanagawa.sumiInk0,
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide.none),
    ),
  );
}
