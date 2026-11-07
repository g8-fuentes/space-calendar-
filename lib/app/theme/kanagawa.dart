import 'package:flutter/material.dart';

/// Cores fixas dos desenhos em pixel art (personagem, cena, chama): não
/// mudam com o tema.
abstract final class Px {
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

/// Cores da interface. O tema escuro é um terminal verde, à la Matrix; o
/// claro é papel com tinta verde. Mudam com [light].
abstract final class Kanagawa {
  /// Tema claro ligado (ver Ajustes).
  static bool light = false;

  static Color get sumiInk0 => light ? const Color(0xFFE3EAE0) : const Color(0xFF070B08);
  static Color get sumiInk3 => light ? const Color(0xFFF2F5EF) : const Color(0xFF0B110C);
  static Color get sumiInk4 => light ? const Color(0xFFFFFFFF) : const Color(0xFF111A13);
  static Color get sumiInk5 => light ? const Color(0xFFE8EEE5) : const Color(0xFF1A271C);
  static Color get sumiInk6 => light ? const Color(0xFFB3C2AF) : const Color(0xFF2F4733);
  static Color get fujiWhite => light ? const Color(0xFF17261A) : const Color(0xFFCDEFD0);
  static Color get oldWhite => light ? const Color(0xFF34463A) : const Color(0xFFA6D8AA);
  static Color get fujiGray => light ? const Color(0xFF6B7A6D) : const Color(0xFF5F7F63);
  static Color get springViolet1 => light ? const Color(0xFF56685A) : const Color(0xFF80A886);
  static Color get oniViolet => light ? const Color(0xFF6A4C93) : const Color(0xFF957FB8);
  static Color get crystalBlue => light ? const Color(0xFF3B5BA0) : const Color(0xFF7E9CD8);
  static Color get springBlue => light ? const Color(0xFF2F6F8F) : const Color(0xFF7FB4CA);
  static Color get lightBlue => light ? const Color(0xFF2F7F86) : const Color(0xFFA3D4D5);
  static Color get waveBlue1 => light ? const Color(0xFFD6EED9) : const Color(0xFF10301A);
  static Color get waveBlue2 => light ? const Color(0xFFB5E0BF) : const Color(0xFF1E5A2E);
  static Color get springGreen => light ? const Color(0xFF2F8F46) : const Color(0xFF98BB6C);
  static Color get autumnGreen => light ? const Color(0xFF4D7A3A) : const Color(0xFF76946A);
  static Color get carpYellow => light ? const Color(0xFF14833A) : const Color(0xFF3CFF6B);
  static Color get boatYellow2 => light ? const Color(0xFF8A6D2F) : const Color(0xFFC0A36E);
  static Color get surimiOrange => light ? const Color(0xFFC2621A) : const Color(0xFFFFA066);
  static Color get autumnRed => light ? const Color(0xFFB3363A) : const Color(0xFFC34043);
  static Color get waveRed => light ? const Color(0xFFC04A55) : const Color(0xFFE46876);
  static Color get sakuraPink => light ? const Color(0xFFA8456C) : const Color(0xFFD27E99);

  /// Cor de categoria (pastel) legível no tema atual.
  static Color ink(Color c) => light ? Color.lerp(c, const Color(0xFF000000), .35)! : c;
}

/// Tipografia: JetBrains Mono (vai dentro do APK, em assets/fonts).
/// `display` é a versão extra negrito para títulos; os tamanhos seguem a
/// escala antiga das telas e são ajustados aqui para a fonte mono.
abstract final class PixelText {
  static const family = 'JetBrainsMono';
  static const bodyFamily = family;

  static TextStyle display(double size, {Color? color}) => TextStyle(
      fontFamily: family,
      fontSize: size * 1.45,
      fontWeight: FontWeight.w800,
      color: color ?? Kanagawa.fujiWhite,
      height: 1.25,
      letterSpacing: .4);

  static TextStyle body(double size, {Color? color}) =>
      TextStyle(fontFamily: family, fontSize: size * .9, color: color ?? Kanagawa.fujiWhite, height: 1.35);
}

ThemeData buildKanagawaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Kanagawa.light ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: Kanagawa.sumiInk3,
    colorScheme: (Kanagawa.light ? ColorScheme.light : ColorScheme.dark)(
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
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: Kanagawa.fujiWhite)),
      indicatorShape: const RoundedRectangleBorder(),
    ),
    dialogTheme: DialogThemeData(
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
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Kanagawa.sumiInk0,
      border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide.none),
    ),
  );
}
