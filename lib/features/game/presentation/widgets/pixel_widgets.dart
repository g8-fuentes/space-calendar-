import 'package:flutter/material.dart';

import '../../../../app/theme/kanagawa.dart';
import '../../../../core/sound/sfx.dart';

/// Painel com borda grossa e sombra dura, no estilo dos jogos 8-bit.
class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = Kanagawa.sumiInk4,
    this.borderColor = Kanagawa.sumiInk0,
    this.accent,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color borderColor;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          top: BorderSide(color: borderColor, width: 3),
          right: BorderSide(color: borderColor, width: 3),
          bottom: BorderSide(color: borderColor, width: 3),
          left: BorderSide(color: accent ?? borderColor, width: accent == null ? 3 : 5),
        ),
        boxShadow: const [BoxShadow(color: Color(0x66000000), offset: Offset(3, 3))],
      ),
      child: child,
    );
  }
}

class PixelBar extends StatelessWidget {
  const PixelBar({
    super.key,
    required this.value,
    this.color = Kanagawa.springBlue,
    this.height = 12,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      color: Kanagawa.sumiInk0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          heightFactor: 1,
          child: ColoredBox(color: color),
        ),
      ),
    );
  }
}

class PixelButton extends StatelessWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Kanagawa.carpYellow,
    this.textColor = Kanagawa.sumiInk0,
    this.dense = false,
    this.sound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final bool dense;

  /// Toca o clique. Desligue quando a própria ação já tem som.
  final bool sound;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? color : Kanagawa.sumiInk5,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Kanagawa.sumiInk0, width: 3),
        ),
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  if (sound) Sfx.click.play();
                  onPressed!();
                },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 7 : 11),
            child: Text(
              label.toUpperCase(),
              style: PixelText.display(dense ? 7 : 8,
                  color: enabled ? textColor : Kanagawa.springViolet1),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.color = Kanagawa.springViolet1});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: PixelText.display(9, color: color));
}
