import 'package:flutter/material.dart';
import '../utils/vehicle_image_data.dart';

enum VehicleType {
  jeepney,
  tricycle,
  motorcycle,
}

class PixelRoadVehicle extends StatelessWidget {
  final VehicleType type;
  final bool movingRight;
  final double height;
  final int frame; // 0 or 1 for subtle engine/road vibration bounce

  const PixelRoadVehicle({
    super.key,
    required this.type,
    this.movingRight = true,
    this.height = 140,
    this.frame = 0,
  });

  String get _assetKey {
    switch (type) {
      case VehicleType.jeepney:
        return 'jeepney';
      case VehicleType.tricycle:
        return 'tricycle';
      case VehicleType.motorcycle:
        return 'motorcycle';
    }
  }

  /// Natural aspect ratio (width / height) of each tight-cropped sprite
  double get aspectRatio {
    switch (type) {
      case VehicleType.jeepney:
        return 2.45;
      case VehicleType.tricycle:
        return 1.48;
      case VehicleType.motorcycle:
        return 1.15;
    }
  }

  double get computedWidth => height * aspectRatio;

  @override
  Widget build(BuildContext context) {
    final bytes = VehicleImageData.getBytes(_assetKey);

    Widget sprite;
    if (bytes != null) {
      sprite = Image.memory(
        bytes,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none, // Sharp 16-bit retro pixel art
      );
    } else {
      sprite = Image.asset(
        'assets/images/vehicles/$_assetKey.png',
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        filterQuality: FilterQuality.none,
      );
    }

    // All generated sprites face RIGHT by default; flip horizontally when driving LEFT
    if (!movingRight) {
      sprite = Transform.flip(flipX: true, child: sprite);
    }

    // Subtle 1.5px road bounce while driving so the vehicle feels alive
    final bounceY = (frame == 0) ? 0.0 : -1.5;

    return Transform.translate(
      offset: Offset(0, bounceY),
      child: sprite,
    );
  }
}
