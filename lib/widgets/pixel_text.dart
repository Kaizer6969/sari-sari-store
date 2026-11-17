import 'package:flutter/material.dart';

class PixelText extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool hasShadow;

  const PixelText(
    this.text, {
    super.key,
    this.size = 14,
    this.color = Colors.white,
    this.textAlign = TextAlign.left,
    this.fontWeight = FontWeight.w700,
    this.maxLines,
    this.overflow,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: size,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: 1.2,
        height: 1.2,
        shadows: hasShadow
            ? [
                Shadow(
                  offset: const Offset(1.5, 1.5),
                  blurRadius: 0,
                  color: const Color(0xD9000000),
                ),
              ]
            : null,
      ),
    );
  }
}
