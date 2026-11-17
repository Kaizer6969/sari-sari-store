import 'package:flutter/material.dart';

class RetroMenuButton extends StatefulWidget {
  final String label;
  final Widget icon;
  final Color backgroundColor;
  final VoidCallback? onPressed;
  final double height;
  final double? width;
  final double fontSize;
  final bool isPrimary;

  const RetroMenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.height = 54,
    this.width = 240,
    this.fontSize = 18,
    this.isPrimary = false,
  });

  @override
  State<RetroMenuButton> createState() => _RetroMenuButtonState();
}

class _RetroMenuButtonState extends State<RetroMenuButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    final baseColor = isEnabled ? widget.backgroundColor : Colors.grey.shade700;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black, // Dark outer outline
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              if (!_isPressed)
                const BoxShadow(
                  color: Colors.black54,
                  offset: Offset(0, 5),
                  blurRadius: 0,
                ),
            ],
          ),
          padding: const EdgeInsets.all(3.5), // Black outer border thickness
          child: Container(
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: Colors.white.withAlpha(200), // White inner highlight border
                width: 2.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.icon,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: const [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 0,
                          color: Colors.black87,
                        ),
                        Shadow(
                          offset: Offset(-1, -1),
                          blurRadius: 0,
                          color: Colors.black45,
                        ),
                      ],
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
