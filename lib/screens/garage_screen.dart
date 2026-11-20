import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/held_box_hud.dart';

/// Room 4: Garahe (Open-Gate Carport) — where all online Computer orders are delivered by truck!
class GarageScreen extends StatefulWidget {
  final GameState gameState;

  const GarageScreen({super.key, required this.gameState});

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  @override
  void initState() {
    super.initState();
    widget.gameState.addListener(_onGameStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.gameState.clearDeliveryAlert();
        SaveManager.saveGame(widget.gameState);
      }
    });
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    if (widget.gameState.hasNewDeliveryAlert) {
      widget.gameState.clearDeliveryAlert();
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF27AE60),
          duration: Duration(milliseconds: 2000),
          content: PixelText(
            '🚚 HONK! HONK! Dumating na ang delivery truck sa Garahe!',
            size: 10.5,
            color: Colors.white,
          ),
        ),
      );
    }
    setState(() {});
  }

  void _pickUpDeliveredBox(Item item) {
    final state = widget.gameState;
    if (state.pickUpGarageBox(item.id)) {
      SaveManager.saveGame(state);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(milliseconds: 1800),
          content: PixelText(
            '📦 Binuhat ang box ng ${item.name} (${state.heldBoxQty} laman)! Pumasok sa tindahan para i-restock o ilagay sa Rack!',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildTopBadge({
    required String text,
    String? icon,
    Color textColor = Colors.white,
    Color bgColor = const Color(0xFF2C3E50),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1B2631), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
          ],
          PixelText(
            text,
            size: 11,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredBoxWidget(Item item, int qty) {
    final bytes = ItemImageData.getBytes(item.id);
    final showStack = qty >= 6;

    return GestureDetector(
      onTap: () => _pickUpDeliveredBox(item),
      child: SizedBox(
        width: 112,
        height: 108,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Soft contact shadow on concrete driveway
            Positioned(
              left: 6,
              right: 6,
              bottom: 0,
              height: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Back stacked box if large order (>= 6 pcs)
            if (showStack)
              Positioned(
                left: 14,
                right: 14,
                bottom: 42,
                height: 46,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67242),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF3E240E),
                      width: 2,
                    ),
                  ),
                ),
              ),

            // Main Front Cardboard Delivery Box
            Positioned(
              left: 6,
              right: 6,
              bottom: 4,
              height: 76,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC88D55),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: const Color(0xFF3E240E),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    // Cardboard top flap with tape
                    Container(
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9A36B),
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFF5D3A1A),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 28,
                          color: const Color(0xAAFFE0B2),
                        ),
                      ),
                    ),
                    // Printed Shipping Label + 16-bit Pixel Product Icon
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xF5FFF8E7),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: const Color(0xFF5D3A1A),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (bytes != null)
                              Image.memory(
                                bytes,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                              )
                            else
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PixelText(
                                    item.name.split(' ').first,
                                    size: 8.5,
                                    color: const Color(0xFF3E2723),
                                    fontWeight: FontWeight.bold,
                                    hasShadow: false,
                                  ),
                                  PixelText(
                                    'x$qty',
                                    size: 11,
                                    color: const Color(0xFFC0392B),
                                    fontWeight: FontWeight.w900,
                                    hasShadow: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // "👆 BUHATIN" pill above box
            Positioned(
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xF027AE60),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1.4),
                ),
                child: const PixelText(
                  '👆 BUHATIN',
                  size: 8,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final deliveredEntries =
        state.garageBoxes.entries.where((e) => e.value > 0).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final safePadding = MediaQuery.of(context).padding;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 16-BIT PIXEL ART GARAGE WITH OPEN GATE BACKGROUND
              Positioned.fill(
                child: Image.memory(
                  ItemImageData.garageBgBytes,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ),

              // 2. CLICKABLE LEFT WOODEN DOOR BACK TO THE STORE
              Positioned(
                left: w * 0.115,
                top: h * 0.300,
                width: w * 0.085,
                height: h * 0.460,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEB2980B9),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const PixelText(
                        '🚪 PASOK',
                        size: 8.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. DELIVERED CARDBOARD BOXES ON THE GARAGE DRIVEWAY FLOOR
              Positioned(
                left: w * 0.21,
                right: w * 0.16,
                top: h * 0.56,
                bottom: 76,
                child:
                    deliveredEntries.isEmpty
                        ? Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC1B2631),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    state.hasIncomingDelivery
                                        ? const Color(0xFFF1C40F)
                                        : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: PixelText(
                              state.hasIncomingDelivery
                                  ? '🚚 Paparating na ang delivery truck sa gate... Hintayin ang busina!'
                                  : '📦 Walang delivery box sa garahe.\nUmorder muna sa 💻 Computer sa likod ng tindahan!',
                              size: 10.5,
                              color:
                                  state.hasIncomingDelivery
                                      ? const Color(0xFFF1C40F)
                                      : Colors.white70,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                        : Center(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 14,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children:
                                  deliveredEntries.map((entry) {
                                    final item = GameConstants.itemById(
                                      entry.key,
                                    );
                                    if (item == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return _buildDeliveredBoxWidget(
                                      item,
                                      entry.value,
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
              ),

              // 4. TOP HUD BAR
              Positioned(
                top: 10 + safePadding.top,
                left: 14 + safePadding.left,
                right: 14 + safePadding.right,
                child: Row(
                  children: [
                    _buildTopBadge(
                      text: 'GARAHE (DELIVERY AREA)',
                      icon: '🚚',
                      textColor: const Color(0xFFF1C40F),
                    ),
                    const SizedBox(width: 8),
                    _buildTopBadge(
                      text: 'ARAW ${state.day} • ${state.formattedTime}',
                    ),
                    const Spacer(),
                    _buildTopBadge(
                      text: '₱${state.money.toStringAsFixed(2)}',
                      icon: '🪙',
                      textColor: const Color(0xFFF1C40F),
                    ),
                    const SizedBox(width: 8),
                    _buildTopBadge(
                      text: 'DELIVERY: ${state.totalGarageBoxCount}',
                      icon: '📦',
                      bgColor: const Color(0xFF1F618D),
                    ),
                  ],
                ),
              ),

              // 5. HELD BOX BANNER (when carrying a box!)
              if (state.isHoldingBox)
                Positioned(
                  top: 48,
                  left: 60,
                  right: 60,
                  child: Center(
                    child: HeldBoxHudBanner(
                      gameState: state,
                      hintText: 'Dalhin sa loob ng tindahan o sa Rack!',
                      onPutDown: () {
                        setState(() => state.putDownHeldBoxToGarage());
                        SaveManager.saveGame(state);
                      },
                    ),
                  ),
                ),

              // 6. BOTTOM ACTION BAR
              Positioned(
                bottom: 12 + safePadding.bottom,
                left: 16 + safePadding.left,
                right: 16 + safePadding.right,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            state.isHoldingBox
                                ? '[ 🏪 PASOK SA TINDAHAN (DALHIN ANG BOX) ]'
                                : '[ 🚪 PASOK SA TINDAHAN ]',
                        color: const Color(0xFF27AE60),
                        height: 50,
                        fontSize: 12,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
