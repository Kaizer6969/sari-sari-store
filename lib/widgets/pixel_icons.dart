import 'package:flutter/material.dart';

class PixelPlayIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PixelPlayIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelPlayPainter(color: color),
    );
  }
}

class _PixelPlayPainter extends CustomPainter {
  final Color color;
  _PixelPlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.15, h * 0.1)
      ..lineTo(w * 0.9, h * 0.5)
      ..lineTo(w * 0.15, h * 0.9)
      ..close();

    // Dark outline
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, strokePaint);

    // Fill
    final fillPaint = Paint()..color = color;
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PixelDiskIcon extends StatelessWidget {
  final double size;
  const PixelDiskIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelDiskPainter(),
    );
  }
}

class _PixelDiskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Body of floppy disk (cream/beige)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, w - 4, h - 4),
      const Radius.circular(3),
    );

    // Outline
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    // Fill
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFFFDEBD0));

    // Metal shutter on top
    final shutter = Rect.fromLTWH(w * 0.25, 3, w * 0.5, h * 0.45);
    canvas.drawRect(shutter, Paint()..color = const Color(0xFF95A5A6));
    canvas.drawRect(
      shutter,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    // Shutter hole
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, 6, w * 0.15, h * 0.25),
      Paint()..color = const Color(0xFF2C3E50),
    );

    // White label on bottom
    final label = Rect.fromLTWH(w * 0.2, h * 0.55, w * 0.6, h * 0.35);
    canvas.drawRect(label, Paint()..color = Colors.white);
    canvas.drawRect(
      label,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PixelWrenchIcon extends StatelessWidget {
  final double size;
  const PixelWrenchIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelWrenchPainter(),
    );
  }
}

class _PixelWrenchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.785); // 45 degrees

    // Handle
    final handle = Rect.fromLTWH(-w * 0.1, -h * 0.1, w * 0.2, h * 0.6);
    canvas.drawRect(handle, Paint()..color = const Color(0xFFBDC3C7));
    canvas.drawRect(
      handle,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Head
    final head = Rect.fromCircle(center: Offset(0, -h * 0.25), radius: w * 0.25);
    canvas.drawArc(
      head,
      0.6,
      5.1,
      true,
      Paint()..color = const Color(0xFFE0E0E0),
    );
    canvas.drawArc(
      head,
      0.6,
      5.1,
      true,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PixelGearIcon extends StatelessWidget {
  final double size;
  const PixelGearIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PixelGearPainter(),
    );
  }
}

class _PixelGearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    // Outer gear teeth
    final cPaint = Paint()..color = const Color(0xFFD7BDE2);
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i * 3.14159) / 3);
      final tooth = Rect.fromLTWH(-w * 0.12, -h * 0.45, w * 0.24, h * 0.9);
      canvas.drawRect(tooth, cPaint);
      canvas.drawRect(tooth, borderPaint);
      canvas.restore();
    }

    // Inner circle
    canvas.drawCircle(center, w * 0.35, cPaint);
    canvas.drawCircle(center, w * 0.35, borderPaint);

    // Center hole
    canvas.drawCircle(center, w * 0.15, Paint()..color = const Color(0xFF9E58C4));
    canvas.drawCircle(center, w * 0.15, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
