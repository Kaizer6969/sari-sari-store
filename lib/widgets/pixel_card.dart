import 'package:flutter/material.dart';

class PixelCard extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;

  const PixelCard({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFF2C3E50),
    this.borderColor = const Color(0xFFF39C12),
    this.padding = const EdgeInsets.all(12),
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
