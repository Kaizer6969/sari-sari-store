import 'package:flutter/material.dart';

enum VehicleType { jeepney, tricycle, motorcycle }

class PassingVehicle {
  double x;
  double speed;
  VehicleType type;
  Color primaryColor;
  Color secondaryColor;
  bool directionRight; // true: L -> R, false: R -> L

  PassingVehicle({
    required this.x,
    required this.speed,
    required this.type,
    required this.primaryColor,
    required this.secondaryColor,
    this.directionRight = true,
  });
}

class PassingTrafficPainter extends CustomPainter {
  final List<PassingVehicle> vehicles;
  final double animationVal;

  PassingTrafficPainter({
    required this.vehicles,
    required this.animationVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 1024.0;
    final scaleY = size.height / 571.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    // Clip to the outside window openings (so vehicles don't draw over the wooden counter walls)
    // 1. Left iron gate opening
    final gatePath = Path()..addRect(const Rect.fromLTWH(100, 130, 120, 240));
    // 2. Main counter window opening
    final windowPath = Path()..addRect(const Rect.fromLTWH(224, 130, 296, 220));

    final combinedPath = Path.combine(PathOperation.union, gatePath, windowPath);
    canvas.clipPath(combinedPath);

    // Draw each passing vehicle along the road (Road y ≈ 265 to 290)
    for (final v in vehicles) {
      canvas.save();
      canvas.translate(v.x, 262);

      switch (v.type) {
        case VehicleType.jeepney:
          _drawJeepney(canvas, v);
          break;
        case VehicleType.tricycle:
          _drawTricycle(canvas, v);
          break;
        case VehicleType.motorcycle:
          _drawMotorcycle(canvas, v);
          break;
      }

      canvas.restore();
    }

    canvas.restore();
  }

  void _drawJeepney(Canvas canvas, PassingVehicle v) {
    const w = 110.0;

    // Body
    final bodyPaint = Paint()..color = v.primaryColor;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Jeepney lower body
    canvas.drawRect(const Rect.fromLTWH(0, 10, w, 18), bodyPaint);
    canvas.drawRect(const Rect.fromLTWH(0, 10, w, 18), strokePaint);

    // Chrome front hood (if moving right, hood is on right; if left, hood is on left)
    final hoodRect = v.directionRight
        ? const Rect.fromLTWH(w - 24, 12, 24, 16)
        : const Rect.fromLTWH(0, 12, 24, 16);
    canvas.drawRect(hoodRect, Paint()..color = const Color(0xFFD5D8DC));
    canvas.drawRect(hoodRect, strokePaint);

    // Chrome horse/bullbar on hood
    final bullbarX = v.directionRight ? w - 4.0 : 2.0;
    canvas.drawRect(Rect.fromLTWH(bullbarX, 8, 4, 12), Paint()..color = Colors.amber);

    // Roof & Pillars
    final roofRect = const Rect.fromLTWH(4, 0, w - 8, 5);
    canvas.drawRect(roofRect, Paint()..color = v.secondaryColor);
    canvas.drawRect(roofRect, strokePaint);

    // Window pillars
    for (double px = 12; px < w - 24; px += 18) {
      canvas.drawLine(Offset(px, 5), Offset(px, 12), strokePaint);
    }

    // Passengers silhouettes inside
    final passengerPaint = Paint()..color = const Color(0xFF1C2833);
    for (double px = 18; px < w - 30; px += 20) {
      canvas.drawCircle(Offset(px, 8), 4, passengerPaint);
    }

    // Colorful side stripe
    final stripeRect = const Rect.fromLTWH(0, 16, w - 24, 5);
    canvas.drawRect(stripeRect, Paint()..color = Colors.yellowAccent);

    // Wheels (spinning animation)
    final wheelPaint = Paint()..color = const Color(0xFF212F3D);
    final rimPaint = Paint()..color = const Color(0xFFBDC3C7);

    final wheel1Center = Offset(v.directionRight ? w - 16 : 16, 28);
    final wheel2Center = Offset(v.directionRight ? 20 : w - 20, 28);

    for (final wc in [wheel1Center, wheel2Center]) {
      canvas.drawCircle(wc, 7, wheelPaint);
      canvas.drawCircle(wc, 7, strokePaint);
      canvas.drawCircle(wc, 3, rimPaint);
    }

    // Exhaust smoke puffs behind jeepney
    final exhaustX = v.directionRight ? -6.0 : w + 6.0;
    final smokePaint = Paint()
      ..color = Colors.white.withAlpha(70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(exhaustX, 24), 4, smokePaint);
    canvas.drawCircle(Offset(exhaustX - 8, 20), 5, smokePaint);
  }

  void _drawTricycle(Canvas canvas, PassingVehicle v) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Sidecar cabin
    final cabinRect = const Rect.fromLTWH(0, 4, 34, 20);
    canvas.drawRect(cabinRect, Paint()..color = v.primaryColor);
    canvas.drawRect(cabinRect, strokePaint);

    // Sidecar window
    final winRect = const Rect.fromLTWH(4, 7, 16, 9);
    canvas.drawRect(winRect, Paint()..color = const Color(0xFF85C1E9));
    canvas.drawRect(winRect, strokePaint);

    // Motorcycle part (attached)
    final bikeRect = const Rect.fromLTWH(34, 10, 18, 14);
    canvas.drawRect(bikeRect, Paint()..color = const Color(0xFF2C3E50));
    canvas.drawRect(bikeRect, strokePaint);

    // Driver in helmet
    canvas.drawCircle(const Offset(42, 6), 5, Paint()..color = v.secondaryColor);
    canvas.drawCircle(const Offset(42, 6), 5, strokePaint);

    // Wheels
    for (final wx in [10.0, 26.0, 46.0]) {
      canvas.drawCircle(Offset(wx, 24), 5, Paint()..color = Colors.black87);
    }
  }

  void _drawMotorcycle(Canvas canvas, PassingVehicle v) {
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Delivery box on the back
    final boxRect = const Rect.fromLTWH(2, 6, 14, 14);
    canvas.drawRect(boxRect, Paint()..color = v.secondaryColor); // e.g. Grab green or Foodpanda pink
    canvas.drawRect(boxRect, strokePaint);

    // Rider
    canvas.drawCircle(const Offset(22, 5), 5, Paint()..color = Colors.black87); // Helmet
    canvas.drawRect(const Rect.fromLTWH(18, 10, 8, 10), Paint()..color = v.primaryColor); // Jacket

    // Bike body
    final bikePath = Path()
      ..moveTo(8, 20)
      ..lineTo(36, 18)
      ..lineTo(28, 24)
      ..close();
    canvas.drawPath(bikePath, Paint()..color = Colors.redAccent);
    canvas.drawPath(bikePath, strokePaint);

    // Wheels
    canvas.drawCircle(const Offset(8, 22), 5, Paint()..color = Colors.black);
    canvas.drawCircle(const Offset(34, 22), 5, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant PassingTrafficPainter oldDelegate) => true;
}
