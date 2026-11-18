import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import 'pixel_text.dart';

enum ShelfDisplayStyle {
  hangingStrip,  // Dangles in neat strips from the ceiling metal rod
  shelfBottles,  // Bottles stand upright side-by-side along exact perspective shelf slope (never stacked on caps!)
  shelfStacked,  // Cans / noodles / sacks sit along exact perspective slope & stack cleanly 2-high
  counterRow,    // Sits neatly on the dark wooden counter
  counterEggTray, // Realistic-sized eggs nestled in a 2-row brown egg carton on the counter
}

/// Represents a physical shelf/rod/counter slot mapped to own_pixel_store_empty.jpg (1376x768)
class ShelfHotspotZone {
  final String itemId;
  final double leftFrac;
  final double topFrac;
  final double widthFrac;
  final double heightFrac;
  final ShelfDisplayStyle displayStyle;
  final int maxVisible;
  final int maxPerRow;

  /// For perspective right-wall shelves: exact normalized floor Y at left & right edges of the cubby
  final double floorLeftFrac;
  final double floorRightFrac;
  final double itemHeightFrac;

  const ShelfHotspotZone({
    required this.itemId,
    required this.leftFrac,
    required this.topFrac,
    required this.widthFrac,
    required this.heightFrac,
    required this.displayStyle,
    this.maxVisible = 6,
    this.maxPerRow = 3,
    this.floorLeftFrac = 0.0,
    this.floorRightFrac = 0.0,
    this.itemHeightFrac = 0.11,
  });

  /// Exact normalized locations & perspective plank slopes matching own_pixel_store_empty.jpg (1376x768)
  static const List<ShelfHotspotZone> allZones = [
    // ── Ceiling Hanging Rod (metal rod at y = 0.132) ────────────────────
    ShelfHotspotZone(
      itemId: 'kape',
      leftFrac: 0.185,
      topFrac: 0.132,
      widthFrac: 0.090,
      heightFrac: 0.275,
      displayStyle: ShelfDisplayStyle.hangingStrip,
      maxVisible: 6,
      maxPerRow: 2,
    ),
    ShelfHotspotZone(
      itemId: 'shampoo',
      leftFrac: 0.282,
      topFrac: 0.132,
      widthFrac: 0.084,
      heightFrac: 0.230,
      displayStyle: ShelfDisplayStyle.hangingStrip,
      maxVisible: 6,
      maxPerRow: 2,
    ),
    ShelfHotspotZone(
      itemId: 'sabon',
      leftFrac: 0.378,
      topFrac: 0.132,
      widthFrac: 0.092,
      heightFrac: 0.175,
      displayStyle: ShelfDisplayStyle.hangingStrip,
      maxVisible: 6,
      maxPerRow: 2,
    ),
    ShelfHotspotZone(
      itemId: 'chichirya',
      leftFrac: 0.592,
      topFrac: 0.132,
      widthFrac: 0.158,
      heightFrac: 0.265,
      displayStyle: ShelfDisplayStyle.hangingStrip,
      maxVisible: 6,
      maxPerRow: 3,
    ),

    // ── Polished Dark Wooden Counter (counter floor at y = 0.868) ───────
    ShelfHotspotZone(
      itemId: 'candy',
      leftFrac: 0.145,
      topFrac: 0.725,
      widthFrac: 0.150,
      heightFrac: 0.148,
      displayStyle: ShelfDisplayStyle.counterRow,
      maxVisible: 5,
      maxPerRow: 3,
      itemHeightFrac: 0.115,
    ),
    ShelfHotspotZone(
      itemId: 'itlog',
      leftFrac: 0.315,
      topFrac: 0.775,
      widthFrac: 0.125,
      heightFrac: 0.095,
      displayStyle: ShelfDisplayStyle.counterEggTray,
      maxVisible: 6,
      maxPerRow: 3,
      itemHeightFrac: 0.048,
    ),
    ShelfHotspotZone(
      itemId: 'yosi',
      leftFrac: 0.525,
      topFrac: 0.775,
      widthFrac: 0.105,
      heightFrac: 0.095,
      displayStyle: ShelfDisplayStyle.counterRow,
      maxVisible: 5,
      maxPerRow: 3,
      itemHeightFrac: 0.072,
    ),

    // ── Right Wall Wooden Grocery Shelves (exact measured perspective planks!) ──
    // Back-top cubby: plank floor slopes UP 0.436 (left) -> 0.402 (right)
    ShelfHotspotZone(
      itemId: 'bigas',
      leftFrac: 0.785,
      topFrac: 0.235,
      widthFrac: 0.085,
      heightFrac: 0.210,
      displayStyle: ShelfDisplayStyle.shelfStacked,
      maxVisible: 4,
      maxPerRow: 2,
      floorLeftFrac: 0.436,
      floorRightFrac: 0.402,
      itemHeightFrac: 0.108,
    ),
    // Back-middle cubby: plank floor slopes gently DOWN 0.596 (left) -> 0.608 (right)
    ShelfHotspotZone(
      itemId: 'tubig',
      leftFrac: 0.785,
      topFrac: 0.440,
      widthFrac: 0.085,
      heightFrac: 0.178,
      displayStyle: ShelfDisplayStyle.shelfBottles,
      maxVisible: 4,
      maxPerRow: 4,
      floorLeftFrac: 0.596,
      floorRightFrac: 0.608,
      itemHeightFrac: 0.120,
    ),
    // Front-top cubby: plank floor slopes UP 0.392 (left) -> 0.352 (right)
    ShelfHotspotZone(
      itemId: 'de_lata',
      leftFrac: 0.888,
      topFrac: 0.165,
      widthFrac: 0.104,
      heightFrac: 0.235,
      displayStyle: ShelfDisplayStyle.shelfStacked,
      maxVisible: 6,
      maxPerRow: 3,
      floorLeftFrac: 0.392,
      floorRightFrac: 0.352,
      itemHeightFrac: 0.095,
    ),
    // Front-middle cubby: plank floor slopes DOWN 0.614 (left) -> 0.630 (right)
    ShelfHotspotZone(
      itemId: 'noodles',
      leftFrac: 0.888,
      topFrac: 0.415,
      widthFrac: 0.104,
      heightFrac: 0.222,
      displayStyle: ShelfDisplayStyle.shelfStacked,
      maxVisible: 6,
      maxPerRow: 3,
      floorLeftFrac: 0.614,
      floorRightFrac: 0.630,
      itemHeightFrac: 0.098,
    ),
    // Front-bottom cubby: plank floor slopes DOWN 0.820 (left) -> 0.886 (right)
    ShelfHotspotZone(
      itemId: 'softdrinks',
      leftFrac: 0.888,
      topFrac: 0.640,
      widthFrac: 0.104,
      heightFrac: 0.255,
      displayStyle: ShelfDisplayStyle.shelfBottles,
      maxVisible: 5,
      maxPerRow: 5,
      floorLeftFrac: 0.820,
      floorRightFrac: 0.886,
      itemHeightFrac: 0.148,
    ),
  ];
}

/// Renders the ACTUAL live pixel-art stock on a shelf/rod/counter and handles tapping to grab OR restock 1 item!
class DynamicShelfStockWidget extends StatelessWidget {
  final ShelfHotspotZone zone;
  final Item item;
  final int visibleStock; // Live stock minus already-picked items for current customer
  final int maxCapacity;
  final double screenHeight;
  final bool isInteractive; // True while customer is waiting for items OR player is holding a box
  final bool isRestockTarget; // True when player is holding THIS item's box to restock!
  final bool showUrgentHint;
  final bool justPicked;
  final bool justRestocked;
  final bool justWrong;
  final VoidCallback onTap;

  const DynamicShelfStockWidget({
    super.key,
    required this.zone,
    required this.item,
    required this.visibleStock,
    this.maxCapacity = 10,
    required this.screenHeight,
    required this.isInteractive,
    this.isRestockTarget = false,
    required this.showUrgentHint,
    required this.justPicked,
    this.justRestocked = false,
    required this.justWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = ItemImageData.getBytes(item.id);
    final displayCount = visibleStock.clamp(0, zone.maxVisible);

    // If completely out of stock AND NOT a restock target AND no feedback flash, leave the wooden shelf cleanly empty!
    if (visibleStock <= 0 && !isRestockTarget && !justPicked && !justRestocked && !justWrong) {
      return const SizedBox.shrink();
    }

    final isFull = visibleStock >= maxCapacity;

    final Color borderColor = (justPicked || justRestocked)
        ? const Color(0xFF2ECC71)
        : justWrong
            ? const Color(0xFFE74C3C)
            : isRestockTarget
                ? (isFull ? const Color(0xFFE67E22) : const Color(0xFF2ECC71))
                : (isInteractive && showUrgentHint)
                    ? const Color(0xFFF1C40F)
                    : Colors.transparent;

    final Color bgTint = (justPicked || justRestocked)
        ? const Color(0x402ECC71)
        : justWrong
            ? const Color(0x38E74C3C)
            : isRestockTarget
                ? (isFull ? const Color(0x28E67E22) : const Color(0x2E2ECC71))
                : (isInteractive && showUrgentHint)
                    ? const Color(0x28F1C40F)
                    : Colors.transparent;

    final canTap = isRestockTarget || (isInteractive && visibleStock > 0);

    return GestureDetector(
      onTap: canTap ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final zw = constraints.maxWidth;
          final zh = constraints.maxHeight;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: bgTint,
              borderRadius: BorderRadius.circular(5),
              border: borderColor != Colors.transparent
                  ? Border.all(color: borderColor, width: isRestockTarget ? 2.6 : 2.2)
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. PHYSICAL 16-BIT PIXEL ART ITEMS ARRANGED BY REAL STOCK & PERSPECTIVE
                if (displayCount > 0 && bytes != null)
                  ..._buildPhysicalItemSprites(
                    bytes: bytes,
                    count: displayCount,
                    zw: zw,
                    zh: zh,
                  ),

                // 2. COMPACT SHELF LABEL + LIVE STOCK / RESTOCK COUNTER
                if (isRestockTarget || isInteractive || justPicked || justRestocked || justWrong)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: (justPicked || justRestocked)
                              ? const Color(0xF527AE60)
                              : justWrong
                                  ? const Color(0xF0C0392B)
                                  : isRestockTarget
                                      ? (isFull
                                          ? const Color(0xF0D35400)
                                          : const Color(0xF01E8449))
                                      : showUrgentHint
                                          ? const Color(0xF0B7950B)
                                          : const Color(0xD917202A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isRestockTarget
                                ? Colors.white
                                : showUrgentHint
                                    ? const Color(0xFFFFF176)
                                    : Colors.black87,
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, offset: Offset(1, 1)),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: PixelText(
                            justRestocked
                                ? '+1 📦 ($visibleStock/$maxCapacity)'
                                : justPicked
                                    ? '-1 ✅ (x$visibleStock)'
                                    : isRestockTarget
                                        ? (isFull
                                            ? '✅ PUNO ($visibleStock/$maxCapacity)'
                                            : '+1 ${item.name.split(' ').first} ($visibleStock/$maxCapacity)')
                                        : '${item.name.split(' ').first} x$visibleStock',
                            size: 8.5,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Helper: local Y inside this zone corresponding to the exact slanted wooden plank floor at normalized x t in [0..1]
  double _localFloorY(double t) {
    final globalFloorFrac =
        zone.floorLeftFrac + (zone.floorRightFrac - zone.floorLeftFrac) * t;
    return (globalFloorFrac - zone.topFrac) * screenHeight;
  }

  List<Widget> _buildPhysicalItemSprites({
    required dynamic bytes,
    required int count,
    required double zw,
    required double zh,
  }) {
    final widgets = <Widget>[];

    // ── A. HANGING CEILING STRIPS (Kape, Shampoo, Sabon, Chichirya) ──────
    if (zone.displayStyle == ShelfDisplayStyle.hangingStrip) {
      final cols = zone.maxPerRow;
      final rowsPerCol = (zone.maxVisible / cols).ceil();
      final itemW = (zw / cols) * 0.90;
      final itemH = (zh / rowsPerCol) * 0.92;
      final rowStep = itemH * 0.84;

      // Draw thin hanging string ONLY as far down as the items actually present in each column!
      for (int c = 0; c < cols; c++) {
        // Count how many items exist in column c
        int colItems = 0;
        for (int i = 0; i < count; i++) {
          if (i % cols == c) colItems++;
        }
        if (colItems <= 0) continue;

        final cx = (c + 0.5) * (zw / cols);
        final stringH = (colItems - 1) * rowStep + itemH * 0.55;
        widgets.add(
          Positioned(
            left: cx - 1,
            top: 0,
            width: 2,
            height: stringH,
            child: Container(color: const Color(0xBB3E2723)),
          ),
        );
      }

      for (int i = 0; i < count; i++) {
        final col = i % cols;
        final row = i ~/ cols;
        final left = col * (zw / cols) + ((zw / cols) - itemW) / 2;
        final top = row * rowStep;

        widgets.add(
          Positioned(
            left: left,
            top: top,
            width: itemW,
            height: itemH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }
      return widgets;
    }

    // ── B. RIGHT-WALL PERSPECTIVE BOTTLES (Softdrinks, Tubig) ────────────
    // Bottles ALWAYS stand upright side-by-side following the exact plank slant (never stacked on caps!)
    if (zone.displayStyle == ShelfDisplayStyle.shelfBottles) {
      final slots = count < 3 ? 3 : count;
      final baseH = screenHeight * zone.itemHeightFrac;

      for (int i = 0; i < count; i++) {
        // Normalized horizontal position along the shelf plank (0.12 .. 0.88)
        final t = slots == 1 ? 0.5 : (0.12 + (i / (slots - 1)) * 0.76);
        // Subtle 1-point perspective scaling: closer to right edge = slightly bigger!
        final perspScale = 0.90 + t * 0.18;
        final itemH = baseH * perspScale;
        final itemW = itemH * 0.44;
        final floorY = _localFloorY(t);
        final centerX = t * zw;

        widgets.add(
          Positioned(
            left: centerX - itemW / 2,
            top: floorY - itemH,
            width: itemW,
            height: itemH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }
      return widgets;
    }

    // ── C. RIGHT-WALL PERSPECTIVE STACKED GOODS (De Lata, Noodles, Bigas) ─
    // Bottom row stands squarely on the exact slanted wooden plank; overflow stacks cleanly on top (grocery pyramid!)
    if (zone.displayStyle == ShelfDisplayStyle.shelfStacked) {
      final perRow = zone.maxPerRow;
      final bottomCount = count > perRow ? perRow : count;
      final topCount = count > perRow ? (count - perRow) : 0;
      final baseH = screenHeight * zone.itemHeightFrac;

      // 1. Bottom row sitting directly on the slanted wooden plank
      for (int i = 0; i < bottomCount; i++) {
        final t = perRow == 1 ? 0.5 : (0.17 + (i / (perRow - 1)) * 0.66);
        final perspScale = 0.90 + t * 0.16;
        final itemH = baseH * perspScale;
        final itemW = (zw / perRow) * 0.96;
        final floorY = _localFloorY(t);
        final centerX = t * zw;

        widgets.add(
          Positioned(
            left: centerX - itemW / 2,
            top: floorY - itemH,
            width: itemW,
            height: itemH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }

      // 2. Top stacked row resting cleanly ON TOP of the bottom items (following the same shelf angle!)
      for (int i = 0; i < topCount; i++) {
        // Stagger nicely above bottom items
        final t = topCount == 1
            ? 0.50
            : (0.22 + (i / (topCount - 1)) * 0.56);
        final perspScale = 0.88 + t * 0.16;
        final itemH = baseH * perspScale;
        final itemW = (zw / perRow) * 0.92;
        final floorY = _localFloorY(t) - (itemH * 0.86);
        final centerX = t * zw;

        widgets.add(
          Positioned(
            left: centerX - itemW / 2,
            top: floorY - itemH,
            width: itemW,
            height: itemH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }
      return widgets;
    }

    // ── D. REALISTIC COUNTER EGG TRAY (Itlog) ────────────────────────────
    if (zone.displayStyle == ShelfDisplayStyle.counterEggTray) {
      final eggH = screenHeight * zone.itemHeightFrac;
      final eggW = eggH * 0.82;
      final backCount = count > 3 ? (count - 3) : 0;
      final frontCount = count > 3 ? 3 : count;

      // Brown molded egg carton base resting on the counter
      widgets.add(
        Positioned(
          left: zw * 0.08,
          right: zw * 0.08,
          bottom: 2,
          height: eggH * 0.72,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF9E8B76),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF4A3B2C), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),
      );

      // Back row of eggs nestled higher inside the tray
      for (int i = 0; i < backCount; i++) {
        final cx = zw * (0.24 + i * 0.26);
        widgets.add(
          Positioned(
            left: cx - eggW / 2,
            bottom: eggH * 0.50,
            width: eggW * 0.92,
            height: eggH * 0.92,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }

      // Front row of eggs nestled in the tray
      for (int i = 0; i < frontCount; i++) {
        final cx = zw * (0.24 + i * 0.26);
        widgets.add(
          Positioned(
            left: cx - eggW / 2,
            bottom: eggH * 0.22,
            width: eggW,
            height: eggH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        );
      }

      // Front carton lip slightly overlapping bottom of front eggs for authentic tray look!
      widgets.add(
        Positioned(
          left: zw * 0.08,
          right: zw * 0.08,
          bottom: 2,
          height: eggH * 0.34,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF8C7964),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              border: Border.all(color: const Color(0xFF4A3B2C), width: 1.8),
            ),
          ),
        ),
      );

      return widgets;
    }

    // ── E. COUNTER ROW (Candy Garapons, Yosi Packs) ──────────────────────
    final perRow = zone.maxPerRow;
    final frontCount = count > perRow ? perRow : count;
    final backCount = count > perRow ? (count - perRow) : 0;
    final itemH = screenHeight * zone.itemHeightFrac;
    final itemW = (zw / perRow) * 0.94;

    // Staggered back row tucked neatly behind gaps of front row
    for (int i = 0; i < backCount; i++) {
      final slotW = zw / perRow;
      final left = (i + 0.5) * slotW + (slotW - itemW) / 2;
      widgets.add(
        Positioned(
          left: left.clamp(0.0, (zw - itemW).clamp(0.0, zw)),
          bottom: itemH * 0.16,
          width: itemW * 0.88,
          height: itemH * 0.88,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0x28000000),
              BlendMode.srcATop,
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
        ),
      );
    }

    // Front row sitting solidly on the wooden counter
    for (int i = 0; i < frontCount; i++) {
      final slotW = zw / perRow;
      final left = i * slotW + (slotW - itemW) / 2;
      widgets.add(
        Positioned(
          left: left,
          bottom: 2,
          width: itemW,
          height: itemH,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.none,
          ),
        ),
      );
    }

    return widgets;
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

          // Requested Item Rows (with actual mini pixel item icon!)
          ...requiredItems.entries.map((entry) {
            final item = GameConstants.itemById(entry.key);
            if (item == null) return const SizedBox.shrink();
            final needed = entry.value;
            final picked = (pickedItems[entry.key] ?? 0).clamp(0, needed);
            final done = picked >= needed;
            final iconBytes = ItemImageData.getBytes(item.id);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.5),
              child: Row(
                children: [
                  if (done)
                    const Text('✅', style: TextStyle(fontSize: 13))
                  else if (iconBytes != null)
                    Image.memory(
                      iconBytes,
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    )
                  else
                    Text(item.emoji, style: const TextStyle(fontSize: 12)),
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
