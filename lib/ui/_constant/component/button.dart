import 'package:counter/ui/_constant/theme/devcoop_colors.dart';
import 'package:counter/ui/_constant/theme/devcoop_text_style.dart';
import 'package:counter/utils/sound_utils.dart';
import 'package:flutter/material.dart';

class MainTextButton extends StatefulWidget {
  final dynamic text;
  final bool isButtonDisabled;
  final Function()? onTap;
  final Color? color;

  const MainTextButton({
    Key? key,
    required this.text,
    this.isButtonDisabled = false,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  State<MainTextButton> createState() => _MainTextButtonState();
}

class _MainTextButtonState extends State<MainTextButton> {
  bool isPressed = false;

  Color _getLighterColor(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.isButtonDisabled
          ? null
          : () {
              SoundUtils.playSound(SoundType.click);
              widget.onTap?.call();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.translationValues(0, 0, 0),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 50,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.isButtonDisabled
              ? Colors.grey
              : isPressed
                  ? _getLighterColor(widget.color ?? DevCoopColors.primary)
                  : widget.color ?? DevCoopColors.primary,
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    color: DevCoopColors.black.withOpacity(0.25),
                    blurRadius: 4.0,
                  ),
                ],
        ),
        child: widget.text is String
            ? Text(
                widget.text,
                style: DevCoopTextStyle.bold_30.copyWith(
                  color: DevCoopColors.black,
                  fontSize: 24,
                ),
              )
            : widget.text,
      ),
    );
  }
}

// Helper function to maintain backwards compatibility
Widget mainTextButton({
  required dynamic text,
  bool isButtonDisabled = false,
  required Function()? onTap,
  Color? color,
}) {
  return MainTextButton(
    text: text,
    isButtonDisabled: isButtonDisabled,
    onTap: onTap,
    color: color,
  );
}

class PinButton extends StatefulWidget {
  final dynamic text;
  final Function() onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const PinButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<PinButton> createState() => _PinButtonState();
}

class _PinButtonState extends State<PinButton> {
  bool isPressed = false;

  Color _getLighterColor(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: () {
        SoundUtils.playSound(SoundType.click);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.translationValues(0, 0, 0),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isPressed
              ? _getLighterColor(
                  widget.backgroundColor ?? const Color(0xFFECECEC))
              : widget.backgroundColor ?? const Color(0xFFECECEC),
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 4.0,
                  ),
                ],
        ),
        child: Center(
          child: widget.text is String
              ? Text(
                  widget.text,
                  style: DevCoopTextStyle.bold_30.copyWith(
                    color: widget.textColor ?? DevCoopColors.black,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                )
              : widget.text,
        ),
      ),
    );
  }
}

class SpecialPinButton extends StatefulWidget {
  final dynamic text;
  final Function() onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const SpecialPinButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  State<SpecialPinButton> createState() => _SpecialPinButtonState();
}

class _SpecialPinButtonState extends State<SpecialPinButton> {
  bool isPressed = false;

  Color _getLighterColor(Color color) {
    HSLColor hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.3).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: () {
        SoundUtils.playSound(SoundType.click);
        widget.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: isPressed
            ? Matrix4.translationValues(0, 2, 0)
            : Matrix4.translationValues(0, 0, 0),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isPressed
              ? _getLighterColor(widget.backgroundColor ?? DevCoopColors.error)
              : widget.backgroundColor ?? DevCoopColors.error,
          boxShadow: isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 4.0,
                  ),
                ],
        ),
        child: Center(
          child: widget.text is String
              ? Text(
                  widget.text,
                  style: DevCoopTextStyle.bold_30.copyWith(
                    color: widget.textColor ?? DevCoopColors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                )
              : widget.text,
        ),
      ),
    );
  }
}

Widget pinButton({
  required dynamic text,
  required Function() onTap,
  Color? backgroundColor,
  Color? textColor,
}) {
  return PinButton(
    text: text,
    onTap: onTap,
    backgroundColor: backgroundColor,
    textColor: textColor,
  );
}

Widget specialPinButton({
  required dynamic text,
  required Function() onTap,
  Color? backgroundColor,
  Color? textColor,
}) {
  return SpecialPinButton(
    text: text,
    onTap: onTap,
    backgroundColor: backgroundColor,
    textColor: textColor,
  );
}
