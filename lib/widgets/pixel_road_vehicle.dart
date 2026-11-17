import 'package:flutter/material.dart';

enum VehicleType {
  jeepney,
  tricycle,
}

class PixelRoadVehicle extends StatelessWidget {
  final VehicleType type;
  final bool movingRight;
  final int frame; // 0 or 1 for wheel animation

  const PixelRoadVehicle({
    super.key,
    required this.type,
    this.movingRight = true,
    this.frame = 0,
  });

  @override
  Widget build(BuildContext context) {
    const double blockSize = 2.4;
    final size = type == VehicleType.jeepney
        ? const Size(44 * blockSize, 18 * blockSize)
        : const Size(32 * blockSize, 18 * blockSize);

    Widget sprite = CustomPaint(
      size: size,
      painter: _VehiclePixelPainter(
        type: type,
        frame: frame,
        blockSize: blockSize,
      ),
    );

    if (!movingRight) {
      sprite = Transform.flip(flipX: true, child: sprite);
    }

    return sprite;
  }
}

class _VehiclePixelPainter extends CustomPainter {
  final VehicleType type;
  final int frame;
  final double blockSize;

  _VehiclePixelPainter({
    required this.type,
    required this.frame,
    required this.blockSize,
  });

  void _px(Canvas canvas, double x, double y, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(x * blockSize, y * blockSize, blockSize, blockSize),
      Paint()..color = color,
    );
  }

  void _pxRect(Canvas canvas, double x, double y, double w, double h, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(x * blockSize, y * blockSize, w * blockSize, h * blockSize),
      Paint()..color = color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (type == VehicleType.jeepney) {
      _drawJeepney(canvas);
    } else {
      _drawTricycle(canvas);
    }
  }

  void _drawJeepney(Canvas canvas) {
    const silver = Color(0xFFBDC3C7);
    const darkSilver = Color(0xFF7F8C8D);
    const red = Color(0xFFC0392B);
    const yellow = Color(0xFFF39C12);
    const blue = Color(0xFF2980B9);
    const black = Color(0xFF17202A);
    const glass = Color(0xFF85C1E9);
    const headlight = Color(0xFFF9E79F);

    // 1. Roof rack and stainless roof
    _pxRect(canvas, 6, 1, 32, 1, yellow); // Roof rack
    _pxRect(canvas, 5, 2, 34, 2, silver); // Main roof
    _pxRect(canvas, 7, 3, 30, 1, blue);   // Roof decorative stripe

    // 2. Pillars and open windows / passengers
    _pxRect(canvas, 5, 4, 34, 4, glass);
    // Dark passenger silhouettes
    _pxRect(canvas, 10, 5, 3, 3, black);
    _pxRect(canvas, 17, 5, 3, 3, black);
    _pxRect(canvas, 24, 5, 3, 3, black);
    _pxRect(canvas, 31, 5, 3, 3, black);
    // Vertical chrome posts
    _pxRect(canvas, 5, 4, 2, 4, darkSilver);
    _pxRect(canvas, 14, 4, 2, 4, darkSilver);
    _pxRect(canvas, 21, 4, 2, 4, darkSilver);
    _pxRect(canvas, 28, 4, 2, 4, darkSilver);
    _pxRect(canvas, 37, 4, 2, 4, darkSilver);

    // 3. Lower Body (Stainless + Red Pin-striping)
    _pxRect(canvas, 3, 8, 38, 4, silver);
    _pxRect(canvas, 3, 9, 38, 2, red);
    _pxRect(canvas, 3, 10, 38, 1, yellow);

    // 4. Extended front hood and grille (Jeepney iconic snout)
    _pxRect(canvas, 38, 7, 5, 5, silver);
    _pxRect(canvas, 42, 9, 2, 3, darkSilver); // Grille
    _pxRect(canvas, 43, 8, 1, 1, headlight);  // Headlight
    _pxRect(canvas, 40, 6, 2, 1, yellow);     // Silver horse / chrome ornament

    // 5. Back entrance step
    _pxRect(canvas, 1, 9, 2, 4, darkSilver);

    // 6. Wheels (Front and Back) with rotating hub
    _drawWheel(canvas, 9, 12, black, silver, frame);
    _drawWheel(canvas, 34, 12, black, silver, frame);
  }

  void _drawTricycle(Canvas canvas) {
    const red = Color(0xFFE74C3C);
    const darkRed = Color(0xFF922B21);
    const yellow = Color(0xFFF1C40F);
    const silver = Color(0xFFBDC3C7);
    const darkSilver = Color(0xFF34495E);
    const black = Color(0xFF17202A);
    const glass = Color(0xFFAED6F1);
    const skin = Color(0xFFF5CBA7);

    // 1. Motorcycle driver (Left side)
    _pxRect(canvas, 7, 3, 3, 3, darkSilver); // Helmet
    _pxRect(canvas, 8, 4, 2, 2, skin);       // Face
    _pxRect(canvas, 6, 6, 4, 4, red);        // Driver shirt
    _pxRect(canvas, 5, 8, 2, 2, darkSilver); // Handlebars
    _pxRect(canvas, 4, 10, 6, 3, silver);    // Engine / exhaust

    // 2. Sidecar (Passenger cabin)
    _pxRect(canvas, 12, 4, 18, 2, yellow);   // Sidecar roof
    _pxRect(canvas, 13, 6, 4, 4, glass);     // Windshield
    _pxRect(canvas, 18, 6, 12, 4, darkRed);  // Side window opening
    _pxRect(canvas, 12, 10, 18, 3, red);     // Sidecar main body
    _pxRect(canvas, 12, 11, 18, 1, yellow);  // Decorative stripe
    _pxRect(canvas, 30, 10, 1, 2, yellow);   // Sidecar front light

    // 3. Wheels
    _drawWheel(canvas, 5, 12, black, silver, frame);  // Motorcycle back wheel
    _drawWheel(canvas, 24, 12, black, silver, frame); // Sidecar wheel
  }

  void _drawWheel(Canvas canvas, double cx, double cy, Color tire, Color rim, int f) {
    // 4x4 tire with 2x2 rim
    _pxRect(canvas, cx, cy, 4, 4, tire);
    if (f == 0) {
      _px(canvas, cx + 1, cy + 1, rim);
      _px(canvas, cx + 2, cy + 2, rim);
    } else {
      _px(canvas, cx + 2, cy + 1, rim);
      _px(canvas, cx + 1, cy + 2, rim);
    }
  }

  @override
  bool shouldRepaint(covariant _VehiclePixelPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.type != type ||
        oldDelegate.blockSize != blockSize;
  }
}
