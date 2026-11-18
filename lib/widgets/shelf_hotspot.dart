import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'pixel_text.dart';

/// Represents a clickable shelf/counter location mapped to own_pixel_store.png
class ShelfHotspotZone {
  final String itemId;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;

  const ShelfHotspotZone({
    required this.itemId,
    required this.leftFrac,
    required this.topFrac,
    required this.widthFrac,
    required this.heightFrac,
  });

  /// Exact normalized locations matching own_pixel_store.png (1376x768)
  static const List<ShelfHotspotZone> allZones = [
    // Ceiling hanging sachets & chips
    ShelfHotspotZone(itemId: 'kape', leftFrac: 0.195, topFrac: 0.13, widthFrac: 0.095, heightFrac: 0.30),
    ShelfHotspotZone(itemId: 'shampoo', leftFrac: 0.295, topFrac: 0.13, widthFrac: 0.075, heightFrac: 0.22),
    ShelfHotspotZone(itemId: 'sabon', leftFrac: 0.372, topFrac: 0.13, widthFrac: 0.086, heightFrac: 0.19),
    ShelfHotspotZone(itemId: 'chichirya', leftFrac: 0.595, topFrac: 0.13, widthFrac: 0.170, heightFrac: 0.27),

    // Countertop items
    ShelfHotspotZone(itemId: 'candy', leftFrac: 0.165, topFrac: 0.66, widthFrac: 0.140, heightFrac: 0.21),
    ShelfHotspotZone(itemId: 'itlog', leftFrac: 0.305, topFrac: 0.77, widthFrac: 0.095, heightFrac: 0.10),
    ShelfHotspotZone(itemId: 'yosi', leftFrac: 0.555, topFrac: 0.80, widthFrac: 0.100, heightFrac: 0.085),

    // Right wall wooden grocery shelves (top to bottom)
    ShelfHotspotZone(itemId: 'bigas', leftFrac: 0.785, topFrac: 0.11, widthFrac: 0.205, heightFrac: 0.10),
    ShelfHotspotZone(itemId: 'de_lata', leftFrac: 0.780, topFrac: 0.22, widthFrac: 0.210, heightFrac: 0.21),
    ShelfHotspotZone(itemId: 'noodles', leftFrac: 0.780, topFrac: 0.44, widthFrac: 0.210, heightFrac: 0.18),
    ShelfHotspotZone(itemId: 'softdrinks', leftFrac: 0.780, topFrac: 0.63, widthFrac: 0.210, heightFrac: 0.18),
    ShelfHotspotZone(itemId: 'tubig', leftFrac: 0.780, topFrac: 0.82, widthFrac: 0.210, heightFrac: 0.095),
  ];
}

/// Interactive shelf hotspot overlay button
class ShelfHotspotButton extends StatelessWidget {
  final Item item;
  final int stock;
  final bool showUrgentHint;
  final bool justPicked;
  final bool justWrong;
  final VoidCallback onTap;

  const ShelfHotspotButton({
    super.key,
    required this.item,
    required this.stock,
    required this.showUrgentHint,
    required this.justPicked,
    required this.justWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = justPicked
        ? const Color(0xFF2ECC71)
        : justWrong
            ? const Color(0xFFE74C3C)
            : showUrgentHint
                ? const Color(0xFFF1C40F)
                : Colors.white30;

    final Color bgTint = justPicked
        ? const Color(0x452ECC71)
        : justWrong
            ? const Color(0x45E74C3C)
            : showUrgentHint
                ? const Color(0x30F1C40F)
                : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
            width: (justPicked || justWrong || showUrgentHint) ? 2.5 : 1.0,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: justPicked
                  ? const Color(0xEE27AE60)
                  : justWrong
                      ? const Color(0xEEC0392B)
                      : showUrgentHint
                          ? const Color(0xEEB7950B)
                          : const Color(0xCC1B2631),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: showUrgentHint ? const Color(0xFFFFF176) : Colors.black87,
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, offset: Offset(1, 1)),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    justPicked ? '✅' : item.emoji,
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 3),
                  PixelText(
                    justPicked ? '+1!' : item.name.split(' ').first,
                    size: 8.5,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Retro Pixel Shopping List + 40-Second Patience Timer Card
class CustomerOrderChecklistCard extends StatelessWidget {
  final String customerName;
  final Map<String, int> requiredItems;
  final Map<String, int> pickedItems;
  final int secondsLeft;
  final int maxSeconds;
  final bool allPicked;
  final VoidCallback onServeTap;

  const CustomerOrderChecklistCard({
    super.key,
    required this.customerName,
    required this.requiredItems,
    required this.pickedItems,
    required this.secondsLeft,
    this.maxSeconds = 40,
    required this.allPicked,
    required this.onServeTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (secondsLeft / maxSeconds).clamp(0.0, 1.0);
    final Color timerColor = secondsLeft > 20
        ? const Color(0xFF2ECC71)
        : secondsLeft > 10
            ? const Color(0xFFF39C12)
            : const Color(0xFFE74C3C);

    return Container(
      width: 196,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xEB1B242B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: allPicked
              ? const Color(0xFF2ECC71)
              : secondsLeft <= 10
                  ? const Color(0xFFE74C3C)
                  : const Color(0xFFF1C40F),
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black87, offset: Offset(3, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header + Countdown Badge
          Row(
            children: [
              const Text('📝', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Expanded(
                child: PixelText(
                  'LISTAHAN',
                  size: 10,
                  color: const Color(0xFFF1C40F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: timerColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: timerColor, width: 1.2),
                ),
                child: PixelText(
                  '⏱️ ${secondsLeft}s',
                  size: 9.5,
                  color: timerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Patience Countdown Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.black54,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 5),

          // Requested Item Rows
          ...requiredItems.entries.map((entry) {
            final item = GameConstants.itemById(entry.key);
            if (item == null) return const SizedBox.shrink();
            final needed = entry.value;
            final picked = (pickedItems[entry.key] ?? 0).clamp(0, needed);
            final done = picked >= needed;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  Text(done ? '✅' : item.emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: PixelText(
                      item.name.split(' ').first,
                      size: 9.5,
                      color: done ? const Color(0xFF2ECC71) : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: done ? const Color(0xFF1E8449) : const Color(0xFF2C3E50),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: PixelText(
                      '$picked/$needed',
                      size: 9,
                      color: done ? Colors.white : const Color(0xFFF1C40F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          if (allPicked)
            GestureDetector(
              onTap: onServeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white70, width: 1.2),
                ),
                child: const PixelText(
                  '✅ KUMPLETO! IBENTA NA ▶',
                  size: 8.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(4),
              ),
              child: PixelText(
                secondsLeft <= 12
                    ? '⚡ BILIS! Pindutin ang dilaw na estante!'
                    : '👆 Kunin sa estante/counter!',
                size: 8,
                color: secondsLeft <= 12 ? const Color(0xFFFFD54F) : Colors.white70,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
