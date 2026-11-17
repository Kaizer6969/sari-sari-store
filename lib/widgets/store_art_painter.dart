import 'dart:math';
import 'package:flutter/material.dart';
import 'pixel_customer_sprite.dart';

class StoreArtPainter extends CustomPainter {
  final int hour;
  final int minute;
  final bool storeOpen;
  final CustomerPersona? currentCustomer;
  final double animationVal;

  StoreArtPainter({
    required this.hour,
    this.minute = 0,
    required this.storeOpen,
    this.currentCustomer,
    this.animationVal = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Use a fixed virtual coordinate system (1024 x 576 ~ 16:9 widescreen)
    const virtualW = 1024.0;
    const virtualH = 576.0;

    canvas.save();
    canvas.scale(w / virtualW, h / virtualH);

    // 1. Outside World / Street View (seen through the window and gate)
    _drawOutsideSky(canvas, virtualW, virtualH);
    _drawOutsideScenery(canvas, virtualW, virtualH);
    _drawParkedTricycle(canvas, virtualW, virtualH);

    // 2. Store Structure (Walls, Roof, Grills)
    _drawRoofAndCeiling(canvas, virtualW, virtualH);
    _drawStoreWallsAndBeams(canvas, virtualW, virtualH);
    _drawWindowFrameAndGrills(canvas, virtualW, virtualH);

    // 3. Hanging Goods (Coffee, Shampoo, Chichirya)
    if (storeOpen) {
      _drawHangingGoods(canvas, virtualW, virtualH);
    }

    // 4. Side Shelves & Grocery Products (Canned sardines, tuna, soy sauce)
    _drawSideShelves(canvas, virtualW, virtualH);

    // 5. Customer at Counter (if present and store is open)
    if (storeOpen && currentCustomer != null) {
      _drawCustomerCharacter(canvas, virtualW, virtualH, currentCustomer!);
    }

    // 6. Countertop, Candy Jars, Egg Crate, Cash Register
    _drawCounterAndItems(canvas, virtualW, virtualH);

    // 7. Security Shutters (drawn over window if closed)
    if (!storeOpen) {
      _drawClosedSecurityShutters(canvas, virtualW, virtualH);
    }

    // 8. Hanging Light Bulb & Ambient Lighting
    _drawHangingLight(canvas, virtualW, virtualH);

    canvas.restore();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. OUTSIDE SKY & SCENERY
  // ──────────────────────────────────────────────────────────────────────────

  void _drawOutsideSky(Canvas canvas, double w, double h) {
    // Window opening bounds: x: 190 to 620, y: 110 to 390
    // Left gate bounds: x: 70 to 180, y: 110 to 450
    final windowRect = const Rect.fromLTWH(60, 90, 580, 320);

    Color skyTop;
    Color skyBottom;

    if (hour >= 5 && hour < 8) {
      // Early Morning Sunrise (Soft peach/orange into golden yellow)
      skyTop = const Color(0xFFE67E22);
      skyBottom = const Color(0xFFF9E79F);
    } else if (hour >= 8 && hour < 16) {
      // Daytime (Clear Pinoy blue sky)
      skyTop = const Color(0xFF4A90E2);
      skyBottom = const Color(0xFF85C1E9);
    } else if (hour >= 16 && hour < 18) {
      // Golden Hour Sunset (Warm crimson/orange gradient)
      skyTop = const Color(0xFF884EA0);
      skyBottom = const Color(0xFFF39C12);
    } else {
      // Night (Deep dark navy midnight)
      skyTop = const Color(0xFF0B101B);
      skyBottom = const Color(0xFF1B263B);
    }

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyBottom],
      ).createShader(windowRect);

    canvas.drawRect(windowRect, skyPaint);

    // Sun or Moon & Stars
    if (hour >= 6 && hour < 18) {
      // Daytime Sun
      final sunX = 280.0 + ((hour - 6) / 12.0) * 260.0;
      final sunY = 150.0 - sin(((hour - 6) / 12.0) * pi) * 45.0;

      // Sun halo
      canvas.drawCircle(Offset(sunX, sunY), 22, Paint()..color = const Color(0x33FFEB3B));
      // Sun body (pixelated circle)
      canvas.drawCircle(Offset(sunX, sunY), 14, Paint()..color = const Color(0xFFFFEB3B));
      canvas.drawCircle(Offset(sunX, sunY), 10, Paint()..color = const Color(0xFFFFF9C4));

      // Drifting Pixel Clouds
      final cloudOffset = (animationVal * 120) % 700;
      _drawPixelCloud(canvas, 100 + cloudOffset, 125, 60, 20);
      _drawPixelCloud(canvas, 420 - (cloudOffset * 0.7), 145, 75, 24);
    } else {
      // Starry Night with Crescent Moon
      final moonX = 520.0;
      final moonY = 140.0;

      // Crescent Moon
      canvas.drawCircle(Offset(moonX, moonY), 16, Paint()..color = const Color(0xFFF9E79F));
      canvas.drawCircle(Offset(moonX - 6, moonY - 4), 14, Paint()..color = skyTop);

      // Twinkling Stars
      final starPaint = Paint()..color = Colors.white;
      final stars = [
        const Offset(110, 115),
        const Offset(180, 135),
        const Offset(260, 120),
        const Offset(350, 140),
        const Offset(430, 115),
        const Offset(490, 155),
        const Offset(580, 125),
      ];
      for (int i = 0; i < stars.length; i++) {
        final twinkle = (sin(animationVal * 2 * pi + i) > 0.0) ? 3.0 : 2.0;
        canvas.drawRect(Rect.fromLTWH(stars[i].dx, stars[i].dy, twinkle, twinkle), starPaint);
      }
    }
  }

  void _drawPixelCloud(Canvas canvas, double x, double y, double w, double h) {
    final cloudPaint = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), const Radius.circular(8)), cloudPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 12, y - 8, w * 0.6, h), const Radius.circular(8)), cloudPaint);
  }

  void _drawOutsideScenery(Canvas canvas, double w, double h) {
    // Distant Coconut Trees & Houses
    final treePaint = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF14241B) : const Color(0xFF27533B);
    final trunkPaint = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF1A1713) : const Color(0xFF5D4037);

    // Palm tree 1 on left
    canvas.drawRect(const Rect.fromLTWH(135, 170, 8, 120), trunkPaint);
    _drawPalmLeaves(canvas, 139, 170, treePaint);

    // Palm tree 2 in center distance
    canvas.drawRect(const Rect.fromLTWH(265, 185, 7, 105), trunkPaint);
    _drawPalmLeaves(canvas, 268, 185, treePaint);

    // Distant Fence across the street (x: 80 to 620, y: 245 to 290)
    final fencePaint = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF2C241E) : const Color(0xFFD7CCC8);
    final fenceLine = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF1B1612) : const Color(0xFF8D6E63);

    // Horizontal rails
    canvas.drawRect(const Rect.fromLTWH(80, 252, 540, 5), fencePaint);
    canvas.drawRect(const Rect.fromLTWH(80, 275, 540, 5), fencePaint);

    // Vertical slats
    for (double fx = 90; fx < 620; fx += 16) {
      canvas.drawRect(Rect.fromLTWH(fx, 245, 6, 45), fencePaint);
      canvas.drawRect(Rect.fromLTWH(fx, 245, 6, 45), fenceLine..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // Street Asphalt Road (y: 290 to 390)
    final roadPaint = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF1F2429) : const Color(0xFF4A5568);
    canvas.drawRect(const Rect.fromLTWH(70, 290, 560, 100), roadPaint);

    // Concrete Sidewalk Curb (y: 288 to 294)
    final curbPaint = Paint()..color = (hour >= 18 || hour < 6) ? const Color(0xFF374151) : const Color(0xFFCBD5E0);
    canvas.drawRect(const Rect.fromLTWH(70, 288, 560, 6), curbPaint);

    // Dashed Yellow Road Markings (y: 345 to 350)
    final dashPaint = Paint()..color = const Color(0xFFF6E05E);
    for (double rx = 80; rx < 620; rx += 45) {
      canvas.drawRect(Rect.fromLTWH(rx, 345, 26, 4), dashPaint);
    }

    // Street Lamp Post on the curb (x: 215)
    _drawStreetLamp(canvas, 215, 200);
  }

  void _drawPalmLeaves(Canvas canvas, double cx, double cy, Paint paint) {
    for (int i = 0; i < 5; i++) {
      final angle = (i * 0.7) - 1.4;
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(angle);
      canvas.drawOval(const Rect.fromLTWH(-6, -28, 12, 34), paint);
      canvas.restore();
    }
  }

  void _drawStreetLamp(Canvas canvas, double x, double y) {
    final polePaint = Paint()..color = const Color(0xFF333333);
    // Pole
    canvas.drawRect(Rect.fromLTWH(x, y, 5, 90), polePaint);
    // Arm
    canvas.drawRect(Rect.fromLTWH(x - 14, y, 16, 4), polePaint);
    // Lamp Head
    canvas.drawRect(Rect.fromLTWH(x - 18, y + 2, 8, 6), Paint()..color = const Color(0xFF555555));

    // Glowing light at night
    if (hour >= 18 || hour < 6) {
      final glowPaint = Paint()
        ..color = const Color(0x66FFEB3B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(x - 14, y + 8), 16, glowPaint);
    }
  }

  void _drawParkedTricycle(Canvas canvas, double w, double h) {
    // The iconic Blue Filipino Tricycle parked on the road outside!
    // Positioned at x: 275, y: 300 (W: 105, H: 65)
    const tx = 275.0;
    const ty = 300.0;

    final bluePaint = Paint()..color = const Color(0xFF1E88E5);
    final darkBluePaint = Paint()..color = const Color(0xFF1565C0);
    final metalPaint = Paint()..color = const Color(0xFF90A4AE);
    final blackPaint = Paint()..color = const Color(0xFF212121);
    final wheelPaint = Paint()..color = const Color(0xFF37474F);

    // 1. Motorcycle Body & Front Wheel
    // Front Wheel
    canvas.drawCircle(const Offset(tx + 18, ty + 50), 12, wheelPaint);
    canvas.drawCircle(const Offset(tx + 18, ty + 50), 6, metalPaint);

    // Fork & Handlebars
    canvas.drawRect(const Rect.fromLTWH(tx + 16, ty + 24, 4, 26), metalPaint);
    canvas.drawRect(const Rect.fromLTWH(tx + 12, ty + 22, 12, 3), blackPaint);

    // Headlight (Yellow pixel)
    canvas.drawRect(const Rect.fromLTWH(tx + 10, ty + 27, 6, 6), Paint()..color = const Color(0xFFFFEE58));

    // Gas Tank & Seat
    canvas.drawRect(const Rect.fromLTWH(tx + 20, ty + 30, 20, 10), bluePaint);
    canvas.drawRect(const Rect.fromLTWH(tx + 25, ty + 26, 16, 6), blackPaint);

    // 2. Passenger Sidecar (Kabina)
    // Cabin base
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(tx + 36, ty + 22, 60, 32), const Radius.circular(5)),
      bluePaint,
    );
    canvas.drawRect(const Rect.fromLTWH(tx + 36, ty + 38, 60, 16), darkBluePaint);

    // Sidecar Windshield (Light cyan glass)
    canvas.drawRect(const Rect.fromLTWH(tx + 39, ty + 24, 18, 14), Paint()..color = const Color(0xFFB3E5FC));

    // Metal Roof & Pillars
    canvas.drawRect(const Rect.fromLTWH(tx + 34, ty + 12, 66, 6), metalPaint);
    canvas.drawRect(const Rect.fromLTWH(tx + 40, ty + 17, 3, 8), metalPaint);
    canvas.drawRect(const Rect.fromLTWH(tx + 90, ty + 17, 3, 8), metalPaint);

    // Sidecar Wheel
    canvas.drawCircle(const Offset(tx + 66, ty + 54), 11, wheelPaint);
    canvas.drawCircle(const Offset(tx + 66, ty + 54), 5, metalPaint);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. STORE STRUCTURE (WALLS, ROOF, WINDOW)
  // ──────────────────────────────────────────────────────────────────────────

  void _drawRoofAndCeiling(Canvas canvas, double w, double h) {
    // Corrugated Tin Roof (Yero) across the top (y: 0 to 95)
    final roofBase = Paint()..color = const Color(0xFF607D8B);
    final rustPaint = Paint()..color = const Color(0xFF8D6E63);
    final ridgeLight = Paint()..color = const Color(0xFF90A4AE);
    final ridgeDark = Paint()..color = const Color(0xFF455A64);

    // Main roof background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, 82), roofBase);

    // Corrugated vertical ridges
    for (double rx = 10; rx < w; rx += 22) {
      canvas.drawRect(Rect.fromLTWH(rx, 0, 8, 82), ridgeLight);
      canvas.drawRect(Rect.fromLTWH(rx + 8, 0, 4, 82), ridgeDark);
    }

    // A few authentic rust spots on the yero!
    canvas.drawRect(const Rect.fromLTWH(140, 20, 22, 12), rustPaint);
    canvas.drawRect(const Rect.fromLTWH(480, 35, 18, 14), rustPaint);
    canvas.drawRect(const Rect.fromLTWH(820, 15, 26, 16), rustPaint);

    // Wooden fascia rafter beam (y: 80 to 98)
    final beamPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawRect(Rect.fromLTWH(0, 80, w, 18), beamPaint);
    canvas.drawRect(Rect.fromLTWH(0, 95, w, 3), Paint()..color = const Color(0xFF271510));
  }

  void _drawStoreWallsAndBeams(Canvas canvas, double w, double h) {
    // Main Wooden Store Wall (Rustic warm cedar planks)
    final wallPaint = Paint()..color = const Color(0xFF795548);
    final plankLine = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2;

    // Left wall section (x: 0 to 65)
    canvas.drawRect(const Rect.fromLTWH(0, 98, 65, 478), wallPaint);
    // Divider post between gate and window (x: 180 to 200)
    canvas.drawRect(const Rect.fromLTWH(180, 98, 22, 380), Paint()..color = const Color(0xFF5D4037));
    // Right wall behind shelves (x: 630 to 1024)
    canvas.drawRect(Rect.fromLTWH(630, 98, w - 630, 478), wallPaint);

    // Wood plank horizontal lines
    for (double py = 115; py < h; py += 28) {
      canvas.drawLine(Offset(0, py), Offset(65, py), plankLine);
      canvas.drawLine(Offset(630, py), Offset(w, py), plankLine);
    }
  }

  void _drawWindowFrameAndGrills(Canvas canvas, double w, double h) {
    // Window opening: x: 202 to 625, y: 98 to 385
    // Heavy wooden window frame
    final frameBorder = Paint()..color = const Color(0xFF3E2723);
    final frameInner = Paint()..color = const Color(0xFF5D4037);

    // Frame outer border
    canvas.drawRect(const Rect.fromLTWH(200, 96, 430, 292), frameBorder);
    canvas.drawRect(const Rect.fromLTWH(206, 102, 418, 280), frameInner);

    // Left Security Gate with vertical rehas (x: 65 to 180, y: 98 to 478)
    final gateBorder = Paint()..color = const Color(0xFF2C3E50);
    final grillPaint = Paint()
      ..color = const Color(0xFF95A5A6)
      ..strokeWidth = 3;

    canvas.drawRect(const Rect.fromLTWH(65, 98, 115, 380), gateBorder..style = PaintingStyle.stroke..strokeWidth = 4);
    for (double gx = 75; gx < 175; gx += 16) {
      canvas.drawLine(Offset(gx, 100), Offset(gx, 475), grillPaint);
    }
    // Horizontal crossbars on gate
    canvas.drawLine(const Offset(65, 220), const Offset(180, 220), grillPaint);
    canvas.drawLine(const Offset(65, 340), const Offset(180, 340), grillPaint);

    // Metal Grills (Rehas) on the right side of the serving window
    if (storeOpen) {
      final winGrill = Paint()
        ..color = const Color(0xFFBDC3C7)
        ..strokeWidth = 2.5;

      // Rehas on the right side (x: 520 to 620)
      for (double rx = 525; rx < 620; rx += 18) {
        canvas.drawLine(Offset(rx, 102), Offset(rx, 380), winGrill);
      }
      // Horizontal crossbars
      canvas.drawLine(const Offset(520, 190), const Offset(624, 190), winGrill);
      canvas.drawLine(const Offset(520, 280), const Offset(624, 280), winGrill);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. HANGING MERCHANDISE (BITIN-BITIN PINOY STYLE!)
  // ──────────────────────────────────────────────────────────────────────────

  void _drawHangingGoods(Canvas canvas, double w, double h) {
    final stringPaint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 1.5;

    // String 1: Nescafe 3-in-1 Coffee Sachets (x: 225)
    canvas.drawLine(const Offset(230, 98), const Offset(230, 235), stringPaint);
    for (int i = 0; i < 5; i++) {
      final sy = 105.0 + (i * 26);
      final sachetRect = Rect.fromLTWH(218, sy, 24, 23);
      // Red/Brown Nescafe packet
      canvas.drawRect(sachetRect, Paint()..color = const Color(0xFF8D181B));
      canvas.drawRect(Rect.fromLTWH(220, sy + 3, 20, 6), Paint()..color = const Color(0xFFD4AC0D));
      canvas.drawRect(sachetRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // String 2: Kopiko Black Sachets (x: 255)
    canvas.drawLine(const Offset(260, 98), const Offset(260, 230), stringPaint);
    for (int i = 0; i < 5; i++) {
      final sy = 105.0 + (i * 25);
      final sachetRect = Rect.fromLTWH(248, sy, 24, 22);
      // Black & Gold Kopiko packet
      canvas.drawRect(sachetRect, Paint()..color = const Color(0xFF1B1B1B));
      canvas.drawRect(Rect.fromLTWH(250, sy + 4, 20, 5), Paint()..color = const Color(0xFFF39C12));
      canvas.drawRect(sachetRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // String 3: Sunsilk & Pantene Shampoo Sachets (x: 540)
    canvas.drawLine(const Offset(545, 98), const Offset(545, 235), stringPaint);
    for (int i = 0; i < 5; i++) {
      final sy = 105.0 + (i * 26);
      final sachetRect = Rect.fromLTWH(533, sy, 24, 23);
      // Green Sunsilk shampoo
      canvas.drawRect(sachetRect, Paint()..color = (i.isEven ? const Color(0xFF27AE60) : const Color(0xFF8E44AD)));
      canvas.drawRect(Rect.fromLTWH(535, sy + 4, 20, 5), Paint()..color = Colors.white);
      canvas.drawRect(sachetRect, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // String 4: Chichirya / Chips (x: 580)
    canvas.drawLine(const Offset(585, 98), const Offset(585, 245), stringPaint);
    for (int i = 0; i < 4; i++) {
      final sy = 108.0 + (i * 34);
      final bagRect = Rect.fromLTWH(571, sy, 28, 30);
      // Chippy / Piattos / Snack bag
      final bagColor = (i % 3 == 0)
          ? const Color(0xFFE74C3C)
          : (i % 3 == 1 ? const Color(0xFFF1C40F) : const Color(0xFFE67E22));
      canvas.drawRRect(RRect.fromRectAndRadius(bagRect, const Radius.circular(3)), Paint()..color = bagColor);
      canvas.drawRect(Rect.fromLTWH(574, sy + 6, 22, 10), Paint()..color = Colors.white70);
      canvas.drawRRect(RRect.fromRectAndRadius(bagRect, const Radius.circular(3)), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. SIDE SHELVES (CANNED GOODS, NOODLES, SOY SAUCE)
  // ──────────────────────────────────────────────────────────────────────────

  void _drawSideShelves(Canvas canvas, double w, double h) {
    // Wooden Shelves unit on the right side: x: 630 to 1010
    final shelfWood = Paint()..color = const Color(0xFF5D4037);
    final shelfShadow = Paint()..color = const Color(0xFF3E2723);

    final shelfY = [190.0, 275.0, 360.0, 445.0];

    for (final sy in shelfY) {
      // Horizontal shelf board
      canvas.drawRect(Rect.fromLTWH(635, sy, 380, 14), shelfWood);
      canvas.drawRect(Rect.fromLTWH(635, sy + 14, 380, 4), shelfShadow);
    }

    // Shelf 1 (Top): Canned Goods (Ligo Sardines & 555 Tuna)
    for (int i = 0; i < 11; i++) {
      final cx = 650.0 + (i * 32);
      final isRed = i % 2 == 0;
      final canColor = isRed ? const Color(0xFFC0392B) : const Color(0xFF2980B9);
      // Can body
      canvas.drawRect(Rect.fromLTWH(cx, 150, 24, 40), Paint()..color = canColor);
      // Can lid (silver)
      canvas.drawRect(Rect.fromLTWH(cx, 147, 24, 4), Paint()..color = const Color(0xFFBDC3C7));
      // Label stripe
      canvas.drawRect(Rect.fromLTWH(cx + 2, 162, 20, 14), Paint()..color = const Color(0xFFF1C40F));
      canvas.drawRect(Rect.fromLTWH(cx, 147, 24, 43), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // Shelf 2: Instant Noodles (Lucky Me Pancit Canton & Cup noodles)
    for (int i = 0; i < 10; i++) {
      final nx = 650.0 + (i * 35);
      final noodleColors = [const Color(0xFFF39C12), const Color(0xFFE74C3C), const Color(0xFF27AE60)];
      final nColor = noodleColors[i % noodleColors.length];
      // Noodle pillow pack
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(nx, 238, 28, 36), const Radius.circular(4)),
        Paint()..color = nColor,
      );
      canvas.drawRect(Rect.fromLTWH(nx + 4, 248, 20, 14), Paint()..color = Colors.white);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(nx, 238, 28, 36), const Radius.circular(4)),
        Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5,
      );
    }

    // Shelf 3: Soy Sauce & Vinegar Bottles (Toyo at Suka)
    for (int i = 0; i < 9; i++) {
      final bx = 655.0 + (i * 38);
      final isToyo = i % 2 == 0;
      // Bottle glass
      final glassColor = isToyo ? const Color(0xFF1C2833) : const Color(0xFFE5E7E9);
      canvas.drawRect(Rect.fromLTWH(bx, 312, 22, 48), Paint()..color = glassColor);
      // Bottle neck
      canvas.drawRect(Rect.fromLTWH(bx + 6, 298, 10, 14), Paint()..color = glassColor);
      // Cap (Red or Yellow)
      canvas.drawRect(Rect.fromLTWH(bx + 6, 294, 10, 4), Paint()..color = isToyo ? Colors.red : Colors.yellow);
      // Label
      canvas.drawRect(Rect.fromLTWH(bx + 2, 324, 18, 20), Paint()..color = isToyo ? const Color(0xFFD4AC0D) : const Color(0xFF27AE60));
      canvas.drawRect(Rect.fromLTWH(bx, 312, 22, 48), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    // Shelf 4 (Bottom): Soda 1.5L bottles (Coke, Sprite, Royal)
    for (int i = 0; i < 8; i++) {
      final sx = 660.0 + (i * 44);
      final sodaColors = [const Color(0xFF8B0000), const Color(0xFF1E8449), const Color(0xFFD35400)];
      final sColor = sodaColors[i % sodaColors.length];
      canvas.drawRect(Rect.fromLTWH(sx, 395, 26, 50), Paint()..color = sColor);
      canvas.drawRect(Rect.fromLTWH(sx + 8, 385, 10, 10), Paint()..color = sColor);
      canvas.drawRect(Rect.fromLTWH(sx + 7, 381, 12, 5), Paint()..color = Colors.red);
      canvas.drawRect(Rect.fromLTWH(sx, 395, 26, 50), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. CUSTOMER AT THE COUNTER (PIXEL ART CHARACTER)
  // ──────────────────────────────────────────────────────────────────────────

  void _drawCustomerCharacter(Canvas canvas, double w, double h, CustomerPersona persona) {
    // Center window customer position: x: 380, y: 260
    const custX = 370.0;
    const custY = 245.0;

    canvas.save();
    canvas.translate(custX, custY);

    // Draw the customer sprite
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final skin = Paint()..color = const Color(0xFFF3C299);
    final center = const Offset(60, 48);

    switch (persona.type) {
      case CustomerType.mangBoy:
        _drawMangBoy(canvas, center, skin, stroke);
        break;
      case CustomerType.bongbong:
        _drawBongbong(canvas, center, skin, stroke);
        break;
      case CustomerType.tinay:
        _drawTinay(canvas, center, skin, stroke);
        break;
      case CustomerType.totoyTambay:
        _drawTotoy(canvas, center, skin, stroke);
        break;
      case CustomerType.lolaConching:
        _drawLola(canvas, center, skin, stroke);
        break;
      case CustomerType.scammer:
        _drawScammer(canvas, center, skin, stroke);
        break;
      case CustomerType.alingNena:
      case CustomerType.customerGirl:
      case CustomerType.regularGuy:
        _drawAlingNena(canvas, center, skin, stroke);
        break;
    }

    canvas.restore();
  }

  void _drawMangBoy(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // Tricycle driver with blue polo and white towel
    final body = const Rect.fromLTWH(15, 75, 90, 60);
    canvas.drawRect(body, Paint()..color = const Color(0xFF2980B9));
    canvas.drawRect(body, stroke);
    // Good morning towel around neck
    canvas.drawRect(const Rect.fromLTWH(35, 70, 50, 14), Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(35, 70, 50, 14), stroke);
    // Head & Hair
    canvas.drawCircle(center, 26, skin);
    canvas.drawCircle(center, 26, stroke);
    final hair = Rect.fromCircle(center: Offset(center.dx, center.dy - 6), radius: 26);
    canvas.drawArc(hair, pi, pi, true, Paint()..color = const Color(0xFF1C2833));
    canvas.drawArc(hair, pi, pi, true, stroke);
    // Cap
    canvas.drawRect(Rect.fromLTWH(center.dx - 28, center.dy - 24, 56, 12), Paint()..color = Colors.red);
    canvas.drawRect(Rect.fromLTWH(center.dx + 10, center.dy - 16, 26, 6), Paint()..color = Colors.red);
    // Eyes & Mustache
    canvas.drawRect(Rect.fromLTWH(center.dx - 12, center.dy - 4, 4, 5), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(center.dx + 8, center.dy - 4, 4, 5), Paint()..color = Colors.black);
    canvas.drawRect(Rect.fromLTWH(center.dx - 12, center.dy + 8, 24, 6), Paint()..color = const Color(0xFF1C2833));
  }

  void _drawBongbong(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // Energetic kid in red shirt
    final kidCenter = Offset(center.dx, center.dy + 12);
    final body = const Rect.fromLTWH(24, 82, 72, 50);
    canvas.drawRect(body, Paint()..color = const Color(0xFFE74C3C));
    canvas.drawRect(body, stroke);
    // Head
    canvas.drawCircle(kidCenter, 22, skin);
    canvas.drawCircle(kidCenter, 22, stroke);
    // Spiky Black Hair
    final hair = Path()
      ..moveTo(kidCenter.dx - 22, kidCenter.dy - 6)
      ..lineTo(kidCenter.dx - 14, kidCenter.dy - 28)
      ..lineTo(kidCenter.dx, kidCenter.dy - 34)
      ..lineTo(kidCenter.dx + 14, kidCenter.dy - 28)
      ..lineTo(kidCenter.dx + 22, kidCenter.dy - 6)
      ..close();
    canvas.drawPath(hair, Paint()..color = Colors.black);
    canvas.drawPath(hair, stroke);
    // Big cheerful eyes
    canvas.drawCircle(Offset(kidCenter.dx - 8, kidCenter.dy - 2), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(kidCenter.dx + 8, kidCenter.dy - 2), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(kidCenter.dx - 7, kidCenter.dy - 3), 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(kidCenter.dx + 9, kidCenter.dy - 3), 1.5, Paint()..color = Colors.white);
    // Big open smile
    canvas.drawArc(Rect.fromCircle(center: Offset(kidCenter.dx, kidCenter.dy + 6), radius: 8), 0.1, 2.9, false, stroke);
  }

  void _drawTinay(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // School uniform
    final body = const Rect.fromLTWH(20, 75, 80, 58);
    canvas.drawRect(body, Paint()..color = Colors.white);
    canvas.drawRect(body, stroke);
    // Navy tie
    canvas.drawRect(const Rect.fromLTWH(55, 75, 10, 24), Paint()..color = const Color(0xFF1A5276));
    // Head & Pigtails
    canvas.drawCircle(center, 24, skin);
    canvas.drawCircle(center, 24, stroke);
    // Black Hair with bangs
    final hair = Rect.fromCircle(center: Offset(center.dx, center.dy - 4), radius: 24);
    canvas.drawArc(hair, pi, pi, true, Paint()..color = const Color(0xFF1B2631));
    canvas.drawArc(hair, pi, pi, true, stroke);
    // Pigtails
    canvas.drawCircle(Offset(center.dx - 26, center.dy + 4), 10, Paint()..color = const Color(0xFF1B2631));
    canvas.drawCircle(Offset(center.dx + 26, center.dy + 4), 10, Paint()..color = const Color(0xFF1B2631));
    // Eyes
    canvas.drawCircle(Offset(center.dx - 8, center.dy), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(center.dx + 8, center.dy), 3, Paint()..color = Colors.black);
  }

  void _drawTotoy(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // Tambay with white sando and sunglasses
    final body = const Rect.fromLTWH(18, 75, 84, 58);
    canvas.drawRect(body, Paint()..color = Colors.white);
    canvas.drawRect(body, stroke);
    // Sando straps
    canvas.drawRect(const Rect.fromLTWH(34, 75, 52, 14), skin);
    // Head
    canvas.drawCircle(center, 25, skin);
    canvas.drawCircle(center, 25, stroke);
    // Backwards Cap
    canvas.drawRect(Rect.fromLTWH(center.dx - 26, center.dy - 25, 52, 14), Paint()..color = const Color(0xFF27AE60));
    canvas.drawRect(Rect.fromLTWH(center.dx - 36, center.dy - 16, 16, 5), Paint()..color = const Color(0xFF27AE60));
    // Dark Cool Sunglasses
    final shades = Rect.fromLTWH(center.dx - 18, center.dy - 6, 36, 10);
    canvas.drawRect(shades, Paint()..color = Colors.black);
  }

  void _drawLola(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // Kind Lola with floral duster
    final body = const Rect.fromLTWH(16, 75, 88, 58);
    canvas.drawRect(body, Paint()..color = const Color(0xFFF5B7B1));
    canvas.drawRect(body, stroke);
    // Head
    canvas.drawCircle(center, 25, skin);
    canvas.drawCircle(center, 25, stroke);
    // Grey bun hair
    final hair = Rect.fromCircle(center: Offset(center.dx, center.dy - 6), radius: 25);
    canvas.drawArc(hair, pi, pi, true, Paint()..color = const Color(0xFFBDC3C7));
    canvas.drawCircle(Offset(center.dx, center.dy - 28), 12, Paint()..color = const Color(0xFFBDC3C7));
    // Eyeglasses
    final glassPaint = Paint()..color = Colors.brown..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(Offset(center.dx - 10, center.dy), 7, glassPaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy), 7, glassPaint);
    canvas.drawLine(Offset(center.dx - 3, center.dy), Offset(center.dx + 3, center.dy), glassPaint);
  }

  void _drawScammer(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // The GCash Scammer with dark hoodie and smartphone
    final body = const Rect.fromLTWH(15, 75, 90, 60);
    canvas.drawRect(body, Paint()..color = const Color(0xFF2C3E50));
    canvas.drawRect(body, stroke);
    // Hoodie over head
    final hood = Rect.fromCircle(center: Offset(center.dx, center.dy - 4), radius: 30);
    canvas.drawArc(hood, pi, pi, true, Paint()..color = const Color(0xFF2C3E50));
    canvas.drawArc(hood, pi, pi, true, stroke);
    // Face
    canvas.drawCircle(center, 22, skin);
    canvas.drawCircle(center, 22, stroke);
    // Dark sunglasses
    canvas.drawRect(Rect.fromLTWH(center.dx - 16, center.dy - 6, 32, 9), Paint()..color = Colors.black);
    // Smartphone in hand held up towards the counter!
    final phone = const Rect.fromLTWH(85, 55, 24, 38);
    canvas.drawRRect(RRect.fromRectAndRadius(phone, const Radius.circular(3)), Paint()..color = const Color(0xFF1C2833));
    // Blue GCash screen!
    canvas.drawRect(const Rect.fromLTWH(88, 60, 18, 26), Paint()..color = const Color(0xFF007DFE));
    canvas.drawRRect(RRect.fromRectAndRadius(phone, const Radius.circular(3)), stroke);
  }

  void _drawAlingNena(Canvas canvas, Offset center, Paint skin, Paint stroke) {
    // Aling Nena with floral shirt and hair curlers
    final body = const Rect.fromLTWH(16, 75, 88, 58);
    canvas.drawRect(body, Paint()..color = const Color(0xFFFF8A80));
    canvas.drawRect(body, stroke);
    // Head & Hair
    canvas.drawCircle(center, 26, skin);
    canvas.drawCircle(center, 26, stroke);
    final hair = Rect.fromCircle(center: Offset(center.dx, center.dy - 6), radius: 26);
    canvas.drawArc(hair, pi, pi, true, Paint()..color = const Color(0xFF212121));
    // Hair rollers (Pink & Green curlers)
    canvas.drawCircle(Offset(center.dx - 20, center.dy - 20), 6, Paint()..color = Colors.pinkAccent);
    canvas.drawCircle(Offset(center.dx, center.dy - 28), 6, Paint()..color = Colors.greenAccent);
    canvas.drawCircle(Offset(center.dx + 20, center.dy - 20), 6, Paint()..color = Colors.pinkAccent);
    // Eyes & Smile
    canvas.drawCircle(Offset(center.dx - 9, center.dy - 2), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(center.dx + 9, center.dy - 2), 3, Paint()..color = Colors.black);
    canvas.drawArc(Rect.fromCircle(center: Offset(center.dx, center.dy + 6), radius: 7), 0.2, 2.7, false, stroke);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 6. COUNTERTOP & COUNTER GOODS (CANDY JARS, SCALE, CASH REGISTER)
  // ──────────────────────────────────────────────────────────────────────────

  void _drawCounterAndItems(Canvas canvas, double w, double h) {
    const counterY = 385.0;

    // Heavy Hardwood Counter Table
    final counterBody = Paint()..color = const Color(0xFF4E342E);
    final counterLip = Paint()..color = const Color(0xFF6D4C41);
    final counterEdge = Paint()..color = const Color(0xFF271510);

    // Front apron wall under counter
    canvas.drawRect(Rect.fromLTWH(190, counterY + 22, 450, h - (counterY + 22)), counterBody);

    // Wood plank seams under counter
    for (double cy = counterY + 45; cy < h; cy += 32) {
      canvas.drawLine(Offset(190, cy), Offset(640, cy), counterEdge..strokeWidth = 2);
    }

    // Main Counter Surface / Table Lip (x: 185 to 645, y: 382 to 408)
    canvas.drawRect(const Rect.fromLTWH(185, counterY, 460, 24), counterLip);
    canvas.drawRect(const Rect.fromLTWH(185, counterY + 20, 460, 4), counterEdge);

    if (!storeOpen) return;

    // ── Item 1: Retro Cash Register (x: 215, y: 310) ────────────────────────
    const regX = 215.0;
    const regY = 320.0;
    final regBody = Paint()..color = const Color(0xFFD5D8DC);
    final regKeypad = Paint()..color = const Color(0xFF7F8C8D);
    final regBorder = Paint()..color = const Color(0xFF2C3E50)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Register Base & Drawer
    canvas.drawRect(const Rect.fromLTWH(regX, regY + 36, 75, 30), Paint()..color = const Color(0xFF95A5A6));
    canvas.drawRect(const Rect.fromLTWH(regX + 8, regY + 48, 59, 8), Paint()..color = const Color(0xFF566573));
    canvas.drawRect(const Rect.fromLTWH(regX, regY + 36, 75, 30), regBorder);

    // Register Upper Body / Slanted register head
    canvas.drawRect(const Rect.fromLTWH(regX + 6, regY, 63, 38), regBody);
    canvas.drawRect(const Rect.fromLTWH(regX + 6, regY, 63, 38), regBorder);

    // Green Digital Display
    canvas.drawRect(const Rect.fromLTWH(regX + 14, regY + 6, 47, 12), Paint()..color = const Color(0xFF1E8449));
    canvas.drawRect(const Rect.fromLTWH(regX + 18, regY + 8, 39, 8), Paint()..color = const Color(0xFF2ECC71));

    // Number Keys grid
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 4; c++) {
        canvas.drawRect(Rect.fromLTWH(regX + 14 + (c * 12), regY + 22 + (r * 6), 9, 5), regKeypad);
      }
    }
    // Paper receipt sticking out
    canvas.drawRect(const Rect.fromLTWH(regX + 46, regY - 10, 14, 12), Paint()..color = Colors.white);

    // ── Item 2: 3 Classic Glass Candy Jars (Garapon ng Kendi) ──────────────
    // Jar 1 (x: 320)
    _drawCandyJar(canvas, 315, 315, const [Color(0xFFE74C3C), Color(0xFFF39C12), Color(0xFFF1C40F)]);
    // Jar 2 (x: 360)
    _drawCandyJar(canvas, 360, 315, const [Color(0xFF3498DB), Color(0xFF9B59B6), Color(0xFF2ECC71)]);
    // Jar 3 (x: 405)
    _drawCandyJar(canvas, 405, 315, const [Color(0xFFE91E63), Color(0xFFFFEB3B), Color(0xFFFF5722)]);

    // ── Item 3: Egg Crate Tray (x: 460) ────────────────────────────────────
    const eggX = 460.0;
    const eggY = 352.0;
    // Grey cardboard crate
    canvas.drawRect(const Rect.fromLTWH(eggX, eggY, 65, 28), Paint()..color = const Color(0xFFBCAAA4));
    canvas.drawRect(const Rect.fromLTWH(eggX, eggY, 65, 28), Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Rows of fresh beige eggs!
    final eggPaint = Paint()..color = const Color(0xFFFFF8E1);
    final eggShadow = Paint()..color = const Color(0xFFFFE0B2);
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 4; c++) {
        final ex = eggX + 6 + (c * 14);
        final ey = eggY - 3 + (r * 12);
        canvas.drawOval(Rect.fromLTWH(ex, ey, 11, 14), eggShadow);
        canvas.drawOval(Rect.fromLTWH(ex + 1, ey + 1, 9, 12), eggPaint);
      }
    }

    // ── Item 4: Sako ng Bigas (Rice Sack) on left counter edge (x: 540) ────
    const sackX = 540.0;
    const sackY = 328.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(sackX, sackY, 70, 56), const Radius.circular(6)),
      Paint()..color = const Color(0xFFFFF9C4),
    );
    // Red brand banner on sack: "SINANDOMENG"
    canvas.drawRect(const Rect.fromLTWH(sackX + 6, sackY + 16, 58, 20), Paint()..color = const Color(0xFFC0392B));
    canvas.drawRect(const Rect.fromLTWH(sackX + 12, sackY + 22, 46, 8), Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(sackX, sackY, 70, 56), const Radius.circular(6)),
      Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2,
    );
  }

  void _drawCandyJar(Canvas canvas, double x, double y, List<Color> candyColors) {
    const w = 38.0;
    const h = 58.0;

    // Translucent glass body
    final glassPaint = Paint()..color = const Color(0x99E0F7FA);
    final glassBorder = Paint()..color = const Color(0xFF455A64)..style = PaintingStyle.stroke..strokeWidth = 2;

    // Jar body
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 10, w, h), const Radius.circular(6)), glassPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y + 10, w, h), const Radius.circular(6)), glassBorder);

    // Large Red Screw Cap
    canvas.drawRect(Rect.fromLTWH(x + 4, y, w - 8, 12), Paint()..color = const Color(0xFFC0392B));
    canvas.drawRect(Rect.fromLTWH(x + 4, y, w - 8, 12), glassBorder);

    // Candies inside the jar!
    final rand = Random(x.toInt());
    for (int i = 0; i < 9; i++) {
      final cx = x + 6 + (rand.nextDouble() * (w - 18));
      final cy = y + 16 + (rand.nextDouble() * (h - 18));
      final color = candyColors[i % candyColors.length];
      canvas.drawCircle(Offset(cx, cy), 4.5, Paint()..color = color);
      canvas.drawCircle(Offset(cx - 1, cy - 1), 1.5, Paint()..color = Colors.white);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 7. CLOSED SECURITY SHUTTERS
  // ──────────────────────────────────────────────────────────────────────────

  void _drawClosedSecurityShutters(Canvas canvas, double w, double h) {
    // Heavy wooden planks covering the window opening (x: 202 to 625, y: 98 to 385)
    final shutterBg = Paint()..color = const Color(0xFF3E2723);
    final plankBorder = Paint()..color = const Color(0xFF1B0000)..strokeWidth = 2.5;

    canvas.drawRect(const Rect.fromLTWH(204, 100, 420, 284), shutterBg);

    // Horizontal wooden shutter slats
    for (double sy = 100; sy < 384; sy += 24) {
      canvas.drawLine(Offset(204, sy), Offset(624, sy), plankBorder);
    }

    // Heavy iron cross-brace bar
    canvas.drawRect(const Rect.fromLTWH(204, 230, 420, 24), Paint()..color = const Color(0xFF212121));

    // Big Heavy Brass Padlock (Gitnang kandado)
    const lockX = 395.0;
    const lockY = 222.0;

    // Shackle
    final shacklePaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(const Rect.fromLTWH(lockX + 5, lockY - 14, 24, 22), pi, pi, false, shacklePaint);

    // Brass body
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(lockX, lockY, 34, 40), const Radius.circular(5)),
      Paint()..color = const Color(0xFFF1C40F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(lockX, lockY, 34, 40), const Radius.circular(5)),
      Paint()..color = const Color(0xFF7D6608)..style = PaintingStyle.stroke..strokeWidth = 2,
    );

    // Keyhole
    canvas.drawCircle(const Offset(lockX + 17, lockY + 16), 4, Paint()..color = Colors.black);
    canvas.drawRect(const Rect.fromLTWH(lockX + 15, lockY + 18, 4, 8), Paint()..color = Colors.black);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 8. HANGING TUNGSTEN LIGHT BULB
  // ──────────────────────────────────────────────────────────────────────────

  void _drawHangingLight(Canvas canvas, double w, double h) {
    const bulbX = 410.0;
    const roofY = 98.0;

    // Hanging wire
    canvas.drawLine(const Offset(bulbX, roofY), const Offset(bulbX, roofY + 45), Paint()..color = Colors.black..strokeWidth = 2);
    // Socket
    canvas.drawRect(const Rect.fromLTWH(bulbX - 5, roofY + 45, 10, 8), Paint()..color = const Color(0xFF424242));

    // Bulb
    final isNight = hour >= 18 || hour < 6;
    final bulbColor = (isNight && storeOpen) ? const Color(0xFFFFD54F) : const Color(0xFFCFD8DC);
    canvas.drawCircle(const Offset(bulbX, roofY + 58), 9, Paint()..color = bulbColor);

    // Warm tungsten filament glow at night
    if (isNight && storeOpen) {
      final glowPaint = Paint()
        ..color = const Color(0x33FFD54F)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(const Offset(bulbX, roofY + 58), 65, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant StoreArtPainter oldDelegate) {
    return oldDelegate.hour != hour ||
        oldDelegate.minute != minute ||
        oldDelegate.storeOpen != storeOpen ||
        oldDelegate.currentCustomer != currentCustomer ||
        oldDelegate.animationVal != animationVal;
  }
}
