import 'package:flutter/material.dart';
import 'pixel_text.dart';

class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double? width;
  final double height;
  final double fontSize;
  final Widget? icon;
  final bool enabled;

  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFFE67E22), // warm retro orange
    this.textColor = Colors.white,
    this.width,
    this.height = 44,
    this.fontSize = 13,
    this.icon,
    this.enabled = true,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveEnabled = widget.enabled && widget.onPressed != null;
    final baseColor = effectiveEnabled ? widget.color : Colors.grey.shade700;

    // Pixel highlight (top-left) & shadow (bottom-right)
    final highlightColor = HSLColor.fromColor(baseColor)
        .withLightness((HSLColor.fromColor(baseColor).lightness + 0.2).clamp(0.0, 1.0))
        .toColor();
    final shadowColor = HSLColor.fromColor(baseColor)
        .withLightness((HSLColor.fromColor(baseColor).lightness - 0.25).clamp(0.0, 1.0))
        .toColor();

    return GestureDetector(
      onTapDown: effectiveEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: effectiveEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: effectiveEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: effectiveEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(
          0,
          _isPressed ? 3 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: baseColor,
          border: Border(
            top: BorderSide(
              color: _isPressed ? shadowColor : highlightColor,
              width: 3,
            ),
            left: BorderSide(
              color: _isPressed ? shadowColor : highlightColor,
              width: 3,
            ),
            right: BorderSide(
              color: _isPressed ? highlightColor : shadowColor,
              width: 3,
            ),
            bottom: BorderSide(
              color: _isPressed ? highlightColor : shadowColor,
              width: _isPressed ? 3 : 5,
            ),
          ),
          boxShadow: [
            if (!_isPressed)
              BoxShadow(
                color: const Color(0x66000000),
                offset: const Offset(0, 3),
                blurRadius: 0,
              ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: PixelText(
                      widget.label,
                      size: widget.fontSize,
                      color: effectiveEnabled ? widget.textColor : Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
