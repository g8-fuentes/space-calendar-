import 'package:flutter/material.dart';

/// Paleta Tokyo Night Moon (tema escuro) e Tokyo Night Day (tema claro).
///
/// Os nomes dos campos vêm do tema antigo e viraram só "posições" de cor:
/// `sumiInk*` são os fundos, `fujiWhite`/`oldWhite`/`fujiGray` os textos e
/// `carpYellow` é a cor de destaque (o azul do Tokyo Night).

/// Cores fixas dos desenhos em pixel art (personagem, cena, chama): não
/// mudam com o tema. Sempre Tokyo Night Moon.
abstract final class Px {
  static const sumiInk0 = Color(0xFF1B1D2B); // black
  static const sumiInk3 = Color(0xFF222436); // bg
  static const sumiInk4 = Color(0xFF2F334D); // bg_highlight
  static const sumiInk5 = Color(0xFF3B4261); // fg_gutter
  static const sumiInk6 = Color(0xFF444A73); // terminal_black
  static const fujiWhite = Color(0xFFC8D3F5); // fg
  static const oldWhite = Color(0xFF828BB8); // fg_dark
  static const fujiGray = Color(0xFF636DA6); // comment
  static const springViolet1 = Color(0xFF737AA2); // dark5
  static const oniViolet = Color(0xFFC099FF); // magenta
  static const crystalBlue = Color(0xFF65BCFF); // blue1
  static const springBlue = Color(0xFF86E1FC); // cyan
  static const lightBlue = Color(0xFF89DDFF); // blue5
  static const waveBlue1 = Color(0xFF2D3F76); // bg_visual
  static const waveBlue2 = Color(0xFF394B70); // blue7
  static const springGreen = Color(0xFFC3E88D); // green
  static const autumnGreen = Color(0xFF4FD6BE); // teal
  static const carpYellow = Color(0xFF82AAFF); // blue (destaque)
  static const boatYellow2 = Color(0xFFFFC777); // yellow
  static const surimiOrange = Color(0xFFFF966C); // orange
  static const autumnRed = Color(0xFFC53B53); // red1
  static const waveRed = Color(0xFFFF757F); // red
  static const sakuraPink = Color(0xFFFCA7EA); // purple
}

/// Cores da interface. O tema escuro é o Tokyo Night Moon; o claro é o
/// Tokyo Night Day. Mudam com [light].
abstract final class Kanagawa {
  /// Tema claro ligado (ver Ajustes).
  static bool light = false;

  static Color get sumiInk0 => light ? const Color(0xFFD0D5E3) : Px.sumiInk0;
  static Color get sumiInk3 => light ? const Color(0xFFE1E2E7) : Px.sumiInk3;
  static Color get sumiInk4 => light ? const Color(0xFFE9E9EC) : Px.sumiInk4;
  static Color get sumiInk5 => light ? const Color(0xFFC4C8DA) : Px.sumiInk5;
  static Color get sumiInk6 => light ? const Color(0xFFA8AECB) : Px.sumiInk6;
  static Color get fujiWhite => light ? const Color(0xFF3760BF) : Px.fujiWhite;
  static Color get oldWhite => light ? const Color(0xFF6172B0) : Px.oldWhite;
  static Color get fujiGray => light ? const Color(0xFF848CB5) : Px.fujiGray;
  static Color get springViolet1 => light ? const Color(0xFF68709A) : Px.springViolet1;
  static Color get oniViolet => light ? const Color(0xFF9854F1) : Px.oniViolet;
  static Color get crystalBlue => light ? const Color(0xFF188092) : Px.crystalBlue;
  static Color get springBlue => light ? const Color(0xFF007197) : Px.springBlue;
  static Color get lightBlue => light ? const Color(0xFF006A83) : Px.lightBlue;
  static Color get waveBlue1 => light ? const Color(0xFFD5D9EC) : Px.waveBlue1;
  static Color get waveBlue2 => light ? const Color(0xFFB7C1E3) : Px.waveBlue2;
  static Color get springGreen => light ? const Color(0xFF587539) : Px.springGreen;
  static Color get autumnGreen => light ? const Color(0xFF118C74) : Px.autumnGreen;
  static Color get carpYellow => light ? const Color(0xFF2E7DE9) : Px.carpYellow;
  static Color get boatYellow2 => light ? const Color(0xFF8C6C3E) : Px.boatYellow2;
  static Color get surimiOrange => light ? const Color(0xFFB15C00) : Px.surimiOrange;
  static Color get autumnRed => light ? const Color(0xFFC64343) : Px.autumnRed;
  static Color get waveRed => light ? const Color(0xFFF52A65) : Px.waveRed;
  static Color get sakuraPink => light ? const Color(0xFF7847BD) : Px.sakuraPink;

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
