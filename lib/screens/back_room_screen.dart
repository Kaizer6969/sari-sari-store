import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/held_box_hud.dart';
import 'bodega_rack_screen.dart';
import 'supermarket_screen.dart';
import 'map_screen.dart';

/// Room 2: Likod ng Tindahan (Back Room with Glowing Glass-Door Refrigerator `REF` + Right Arrow to Storage Rack!)
class BackRoomScreen extends StatefulWidget {
  final GameState gameState;

  const BackRoomScreen({super.key, required this.gameState});

  @override
  State<BackRoomScreen> createState() => _BackRoomScreenState();
}

class _BackRoomScreenState extends State<BackRoomScreen> {
  int _lastSeenDeliveryVersion = 0;

  @override
  void initState() {
    super.initState();
    _lastSeenDeliveryVersion = widget.gameState.deliveryArrivalVersion;
    widget.gameState.addListener(_onGameStateChanged);
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    super.dispose();
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    if (widget.gameState.deliveryArrivalVersion != _lastSeenDeliveryVersion) {
      _lastSeenDeliveryVersion = widget.gameState.deliveryArrivalVersion;
      if (ModalRoute.of(context)?.isCurrent ?? true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFD68910),
            duration: Duration(milliseconds: 3000),
            content: PixelText(
              '🚚🎺 HONK! HONK! Dumating na ang delivery truck sa Garahe! Bumalik sa harap at pindutin ang 🚪 GARAHE!',
              size: 10.5,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  void _openBodegaRack() {
    Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => BodegaRackScreen(gameState: widget.gameState),
      ),
    ).then((result) {
      if (!mounted) return;
      if (result == 'go_front') {
        Navigator.pop(context);
      } else {
        setState(() {});
      }
    });
  }

  void _onRefTapped() {
    final state = widget.gameState;
    if (state.isHoldingBox &&
        (state.heldBoxItemId == 'softdrinks' ||
            state.heldBoxItemId == 'tubig')) {
      final itemId = state.heldBoxItemId!;
      final item = GameConstants.itemById(itemId)!;
      final res = state.restockOneFromHeldBox(itemId);
      setState(() {});
      SaveManager.saveGame(state);

      String msg;
      Color bg;
      switch (res) {
        case RestockResult.restocked:
          msg =
              '❄️ +1 ${item.name} sa Ref! (${state.getStock(itemId)}/${GameState.maxShelfCapacity}) • Box: ${state.heldBoxQty} natira';
          bg = const Color(0xFF2980B9);
          break;
        case RestockResult.restockedAndBoxEmpty:
          msg =
              '✅ +1 ${item.name} sa Ref! (${state.getStock(itemId)}/${GameState.maxShelfCapacity}) — Ubos na ang laman ng box!';
          bg = const Color(0xFF27AE60);
          break;
        case RestockResult.shelfFull:
          msg =
              '🧊 PUNO NA ang Ref para sa ${item.name}! (${GameState.maxShelfCapacity}/${GameState.maxShelfCapacity})';
          bg = const Color(0xFFD35400);
          break;
        default:
          return;
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: bg,
          duration: const Duration(milliseconds: 1200),
          content: PixelText(msg, size: 10, color: Colors.white),
        ),
      );
      return;
    }

    // Just viewing the Ref
    final soda = state.getStock('softdrinks');
    final water = state.getStock('tubig');
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1F618D),
        duration: const Duration(milliseconds: 1600),
        content: PixelText(
          '❄️ REF: Softdrinks ($soda/${GameState.maxShelfCapacity}) • Tubig ($water/${GameState.maxShelfCapacity}) — Buhatin ang box mula sa ➡️ Rack para mag-restock!',
          size: 9.5,
          color: Colors.white,
        ),
      ),
    );
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

  Widget _buildQuickPill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 5),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(1, 1)),
          ],
        ),
        child: PixelText(
          label,
          size: 8.5,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Renders cold pixel bottles lined up on a glass shelf inside the glowing Ref!
  Widget _buildRefBottleRow({
    required String itemId,
    required int count,
    required double shelfW,
    required double shelfH,
  }) {
    final bytes = ItemImageData.getBytes(itemId);
    if (bytes == null || count <= 0) return const SizedBox.shrink();

    final show = count.clamp(0, 5);
    final bottleH = shelfH * 0.86;
    final bottleW = bottleH * 0.44;

    return Stack(
      children: [
        for (int i = 0; i < show; i++)
          Positioned(
            left:
                (show == 1 ? 0.5 : (0.15 + (i / (show - 1)) * 0.70)) * shelfW -
                bottleW / 2,
            bottom: 2,
            width: bottleW,
            height: bottleH,
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.none,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final sodaStock = state.getStock('softdrinks');
    final waterStock = state.getStock('tubig');
    final holdingDrinkBox =
        state.isHoldingBox &&
        (state.heldBoxItemId == 'softdrinks' || state.heldBoxItemId == 'tubig');

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Glass door interior bounds in back_room_ref_bg.jpg (1376x768)
          final refLeft = w * 0.236;
          final refW = w * 0.146;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 16-BIT PIXEL ART BACK ROOM WITH REFRIGERATOR BACKGROUND
              Positioned.fill(
                child: Image.memory(
                  ItemImageData.backRoomRefBgBytes,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ),

              // 2. COLD BOTTLES INSIDE THE GLASS-DOOR REFRIGERATOR (REF)
              // Shelf 1 (Top): Softdrinks 🥤
              Positioned(
                left: refLeft,
                top: h * 0.342,
                width: refW,
                height: h * 0.112,
                child: _buildRefBottleRow(
                  itemId: 'softdrinks',
                  count: sodaStock,
                  shelfW: refW,
                  shelfH: h * 0.112,
                ),
              ),
              // Shelf 2 (Middle): Tubig 💧
              Positioned(
                left: refLeft,
                top: h * 0.456,
                width: refW,
                height: h * 0.110,
                child: _buildRefBottleRow(
                  itemId: 'tubig',
                  count: waterStock,
                  shelfW: refW,
                  shelfH: h * 0.110,
                ),
              ),
              // Shelf 3 (Lower): Overflow cold drinks if stock > 5
              Positioned(
                left: refLeft,
                top: h * 0.568,
                width: refW,
                height: h * 0.106,
                child: _buildRefBottleRow(
                  itemId: sodaStock > 5 ? 'softdrinks' : 'tubig',
                  count:
                      sodaStock > 5
                          ? (sodaStock - 5)
                          : (waterStock > 5 ? (waterStock - 5) : 0),
                  shelfW: refW,
                  shelfH: h * 0.106,
                ),
              ),

              // Interactive Clickable Ref Door Hotspot + Highlight when holding Drink Box!
              Positioned(
                left: w * 0.220,
                top: h * 0.220,
                width: w * 0.195,
                height: h * 0.650,
                child: GestureDetector(
                  onTap: _onRefTapped,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border:
                          holdingDrinkBox
                              ? Border.all(
                                color: const Color(0xFF2ECC71),
                                width: 3,
                              )
                              : null,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              holdingDrinkBox
                                  ? const Color(0xF027AE60)
                                  : const Color(0xD9154360),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color:
                                holdingDrinkBox
                                    ? Colors.white
                                    : const Color(0xFF85C1E9),
                            width: 1.4,
                          ),
                        ),
                        child: PixelText(
                          holdingDrinkBox
                              ? '❄️ +1 RESTOCK SA REF!'
                              : '❄️ REF • 🥤$sodaStock  💧$waterStock',
                          size: 8.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2B. CLICKABLE RETRO COMPUTER DESK HOTSPOT -> ORDER PANINDA ONLINE!
              Positioned(
                left: w * 0.485,
                top: h * 0.435,
                width: w * 0.180,
                height: h * 0.450,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SupermarketScreen(gameState: state),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF01B4F72),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFF5DADE2),
                          width: 1.8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const PixelText(
                        '💻 ORDER PC',
                        size: 9.5,
                        color: Color(0xFFAED6F1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 3. CLICKABLE RIGHT DOORWAY HOTSPOT -> RIGHT ARROW TO STORAGE RACK!
              Positioned(
                left: w * 0.810,
                top: h * 0.200,
                width: w * 0.155,
                height: h * 0.660,
                child: GestureDetector(
                  onTap: _openBodegaRack,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xEBF39C12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const PixelText(
                            'RACK ➡️',
                            size: 11,
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            hasShadow: false,
                          ),
                          if (state.totalBodegaBoxCount > 0) ...[
                            const SizedBox(height: 2),
                            PixelText(
                              '📦 ${state.totalBodegaBoxCount} Box',
                              size: 8.5,
                              color: const Color(0xFF4A2300),
                              fontWeight: FontWeight.bold,
                              hasShadow: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 4. TOP HUD BAR
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    _buildTopBadge(
                      text: 'LIKOD NG TINDAHAN',
                      icon: '❄️',
                      textColor: const Color(0xFF85C1E9),
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
                      text: 'BOXES: ${state.totalBodegaBoxCount}',
                      icon: '📦',
                      bgColor: const Color(0xFF1F618D),
                    ),
                  ],
                ),
              ),

              // 5. HELD BOX HUD BANNER (if carrying a box!)
              if (state.isHoldingBox)
                Positioned(
                  top: 48,
                  left: 60,
                  right: 60,
                  child: Center(
                    child: HeldBoxHudBanner(
                      gameState: state,
                      hintText:
                          holdingDrinkBox
                              ? 'Pindutin ang REF o bumalik sa harap!'
                              : 'Bumalik sa harap para i-restock sa estante!',
                    ),
                  ),
                ),

              // 6. TOP-RIGHT QUICK PILLS (Supermarket, Mapa, Tulog)
              Positioned(
                top: 50,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuickPill(
                      label: '🛒 SUPERMARKET',
                      color: const Color(0xFFE67E22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SupermarketScreen(gameState: state),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildQuickPill(
                      label: '🗺️ MAPA',
                      color: const Color(0xFF2980B9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(gameState: state),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildQuickPill(
                      label: '🛏️ TULOG',
                      color: const Color(0xFF8E44AD),
                      onTap: () {
                        setState(() {
                          state.startNewDay();
                        });
                        SaveManager.saveGame(state);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2C3E50),
                            content: PixelText(
                              'Magandang umaga! Araw ${state.day} - 6:00 AM ☀️',
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 7. BOTTOM NAVIGATION BAR: LEFT (Back to Front Store) | RIGHT (Arrow ➡️ to Storage Rack!)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label: '[ ⬅️ BALIK SA HARAP (COUNTER) ]',
                        color: const Color(0xFF2980B9),
                        height: 50,
                        fontSize: 12,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            state.totalBodegaBoxCount > 0
                                ? '[ RACK NG MGA BOX (${state.totalBodegaBoxCount}) ➡️ ]'
                                : '[ RACK NG MGA BOX ➡️ ]',
                        color: const Color(0xFFE67E22),
                        height: 50,
                        fontSize: 12,
                        onPressed: _openBodegaRack,
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
