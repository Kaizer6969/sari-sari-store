import 'package:flutter/material.dart';

class StoreAtmospherePainter extends CustomPainter {
  final int hour;
  final int minute;

  StoreAtmospherePainter({
    required this.hour,
    required this.minute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Daytime (6:00 AM to 4:00 PM) -> Crisp natural sunlight, no dark overlays!
    if (hour >= 6 && hour < 16) {
      return; // No overlay needed, the artwork is already bright morning/daytime!
    }

    // 2. Sunset / Golden Hour (4:00 PM to 6:30 PM) -> Warm golden/amber glow
    if (hour >= 16 && hour < 19) {
      final sunsetTint = Paint()
        ..color = const Color(0x22E65100) // Soft warm amber sunset wash
        ..blendMode = BlendMode.colorBurn;
      canvas.drawRect(rect, sunsetTint);
      return;
    }

    // 3. Nighttime (7:00 PM to 5:59 AM) -> Natural smooth twilight darkening
    final nightTint = Paint()
      ..color = const Color(0x450D1B2A) // Soft navy night atmosphere
      ..blendMode = BlendMode.darken;
    canvas.drawRect(rect, nightTint);

    // Warm indoor store counter light in the dark
    final lampGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.2),
        radius: 0.7,
        colors: [
          const Color(0x35FFE082), // Warm tungsten yellow
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, lampGlow);
  }

  @override
  bool shouldRepaint(covariant StoreAtmospherePainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }
}
