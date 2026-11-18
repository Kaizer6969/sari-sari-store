import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/held_box_hud.dart';
import 'supermarket_screen.dart';

/// Room 3: Storage Rack Room — holds sealed cardboard boxes bought from the Supermarket!
/// Tap any box on the rack to pick it up and bring it to the front store (or Ref) to restock!
class BodegaRackScreen extends StatefulWidget {
  final GameState gameState;

  const BodegaRackScreen({super.key, required this.gameState});

  @override
  State<BodegaRackScreen> createState() => _BodegaRackScreenState();
}

class _BodegaRackScreenState extends State<BodegaRackScreen> {
  static const List<List<String>> _rackGrid = [
    ['kape', 'shampoo', 'sabon', 'chichirya'],
    ['candy', 'itlog', 'yosi', 'bigas'],
    ['de_lata', 'noodles', 'softdrinks', 'tubig'],
  ];

  // Exact normalized bounds matching bodega_rack_bg.jpg (1376x768)
  static const List<double> _colLefts = [0.122, 0.314, 0.508, 0.702];
  static const List<double> _colWidths = [0.176, 0.178, 0.178, 0.176];
  static const List<double> _rowTops = [0.326, 0.496, 0.662];
  static const List<double> _rowHeights = [0.156, 0.152, 0.156];

  void _onRackSlotTapped(Item item) {
    final state = widget.gameState;
    final boxQty = state.getBoxStock(item.id);

    if (boxQty > 0) {
      setState(() {
        state.pickUpBox(item.id);
      });
      SaveManager.saveGame(state);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF27AE60),
          duration: const Duration(milliseconds: 2000),
          content: PixelText(
            '📦 Binuhat ang box ng ${item.name} (${state.heldBoxQty} laman)! Dalhin sa tindahan para mag-restock!',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    } else if (state.isHoldingBox && state.heldBoxItemId == item.id) {
      // Put held box back down on its rack slot
      setState(() {
        state.putDownHeldBox();
      });
      SaveManager.saveGame(state);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF34495E),
          duration: const Duration(milliseconds: 1200),
          content: PixelText(
            '📥 Ibinalik sa rack ang box ng ${item.name}.',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF5D6D7E),
          duration: const Duration(milliseconds: 1200),
          content: PixelText(
            'Walang box ng ${item.name} sa rack. Bumili muna sa Supermarket! 🛒',
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

  /// Renders a sealed wholesale cardboard box with the product's 16-bit icon printed on it!
  Widget _buildCardboardBox({
    required Item item,
    required int boxQty,
    required bool isHeldSlot,
    required double cw,
    required double ch,
  }) {
    final bytes = ItemImageData.getBytes(item.id);
    final hasBox = boxQty > 0;
    // Show 2 stacked boxes visually if quantity >= 6!
    final showDoubleBox = boxQty >= 6;

    return GestureDetector(
      onTap: () => _onRackSlotTapped(item),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Cardboard Box Visual (only when boxQty > 0!)
          if (hasBox) ...[
            // Optional second box behind/stacked for large wholesale orders
            if (showDoubleBox)
              Positioned(
                left: cw * 0.16,
                right: cw * 0.16,
                bottom: ch * 0.36,
                height: ch * 0.48,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFA67242),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: const Color(0xFF3E240E),
                      width: 2,
                    ),
                  ),
                ),
              ),

            // Main Front Cardboard Delivery Box sitting solidly on the wooden plank
            Positioned(
              left: cw * 0.12,
              right: cw * 0.12,
              bottom: ch * 0.12,
              height: ch * 0.64,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFC88D55),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF3E240E),
                    width: 2.2,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black87, offset: Offset(2, 3)),
                  ],
                ),
                child: Stack(
                  children: [
                    // Cardboard top flap seam & packing tape strip
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: ch * 0.13,
                      child: Container(
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
                            width: cw * 0.24,
                            height: double.infinity,
                            color: const Color(0xAAFFE0B2),
                          ),
                        ),
                      ),
                    ),

                    // Printed White Shipping Label + 16-Bit Product Sprite inside!
                    Positioned.fill(
                      top: ch * 0.14,
                      bottom: 4,
                      left: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xEEFFF8E7),
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
                                width: ch * 0.34,
                                height: ch * 0.34,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.none,
                              )
                            else
                              Text(
                                item.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: PixelText(
                                  'x$boxQty',
                                  size: 11,
                                  color: const Color(0xFF2C1810),
                                  fontWeight: FontWeight.w900,
                                  hasShadow: false,
                                ),
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

            // "👆 BUHATIN" pill badge on top of box
            Positioned(
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0xEB27AE60),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.black, width: 1.2),
                ),
                child: const PixelText(
                  '👆 BUHATIN',
                  size: 7.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (isHeldSlot) ...[
            // Subtle dashed/highlighted slot when player is holding this box
            Positioned(
              left: cw * 0.14,
              right: cw * 0.14,
              bottom: ch * 0.16,
              height: ch * 0.50,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0x28F1C40F),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFF1C40F),
                    width: 1.8,
                  ),
                ),
                child: const Center(
                  child: PixelText(
                    '📥 ILAPAG DITO',
                    size: 8,
                    color: Color(0xFFFFF176),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],

          // 2. Shelf Slot Label Tag at bottom plank
          Positioned(
            left: 4,
            right: 4,
            bottom: -4,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      hasBox
                          ? const Color(0xEB1B2631)
                          : const Color(0xB81B2631),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: hasBox ? const Color(0xFFF1C40F) : Colors.white24,
                    width: 1.2,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PixelText(
                    hasBox
                        ? '📦 ${item.name.split(' ').first} ($boxQty)'
                        : '${item.name.split(' ').first} • Bakante',
                    size: 8.5,
                    color: hasBox ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 16-BIT PIXEL ART BODEGA STORAGE RACK BACKGROUND
              Positioned.fill(
                child: Image.memory(
                  ItemImageData.bodegaBgBytes,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                ),
              ),

              // 2. ALL 12 RACK CUBBIES SHOWING SEALED SUPERMARKET BOXES
              for (int row = 0; row < 3; row++)
                for (int col = 0; col < 4; col++)
                  () {
                    final itemId = _rackGrid[row][col];
                    final item = GameConstants.itemById(itemId);
                    if (item == null) return const SizedBox.shrink();

                    final cubbyW = w * _colWidths[col];
                    final cubbyH = h * _rowHeights[row];
                    final boxQty = state.getBoxStock(itemId);
                    final isHeldSlot =
                        state.isHoldingBox && state.heldBoxItemId == itemId;

                    return Positioned(
                      left: w * _colLefts[col],
                      top: h * _rowTops[row],
                      width: cubbyW,
                      height: cubbyH,
                      child: _buildCardboardBox(
                        item: item,
                        boxQty: boxQty,
                        isHeldSlot: isHeldSlot,
                        cw: cubbyW,
                        ch: cubbyH,
                      ),
                    );
                  }(),

              // 3. TOP HUD BAR
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    _buildTopBadge(
                      text: 'RACK NG MGA BOX',
                      icon: '📦',
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
                      text: 'BOXES: ${state.totalBodegaBoxCount}',
                      icon: '📦',
                      bgColor: const Color(0xFF1F618D),
                    ),
                  ],
                ),
              ),

              // 4. INSTRUCTION MARQUEE OR HELD BOX BANNER (Top Center)
              Positioned(
                top: 48,
                left: 60,
                right: 60,
                child: Center(
                  child:
                      state.isHoldingBox
                          ? HeldBoxHudBanner(
                            gameState: state,
                            hintText: 'Dalhin sa harap/ref para i-restock!',
                            onPutDown: () {
                              setState(() => state.putDownHeldBox());
                              SaveManager.saveGame(state);
                            },
                          )
                          : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xEB221C11),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFF1C40F),
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: PixelText(
                              state.totalBodegaBoxCount > 0
                                  ? '📦 PINDUTIN ANG BOX PARA BUHATIN AT I-RESTOCK SA TINDAHAN!'
                                  : '🛒 WALANG BOX SA RACK • BUMILI MUNA SA SUPERMARKET!',
                              size: 10,
                              color: const Color(0xFFF1C40F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),

              // 5. BOTTOM NAVIGATION BAR
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Back to Back Room (Ref)
                    Expanded(
                      flex: 2,
                      child: PixelButton(
                        label: '[ ⬅️ BALIK SA REF ]',
                        color: const Color(0xFF2980B9),
                        height: 50,
                        fontSize: 11.5,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Direct shortcut straight to front counter (super handy when carrying a box!)
                    Expanded(
                      flex: 2,
                      child: PixelButton(
                        label:
                            state.isHoldingBox
                                ? '[ 🏪 DALHIN SA HARAP ▶ ]'
                                : '[ 🏪 BALIK SA HARAP ]',
                        color: const Color(0xFF27AE60),
                        height: 50,
                        fontSize: 11.5,
                        onPressed: () {
                          // Pop both BodegaRackScreen and BackRoomScreen back to StoreScreen!
                          Navigator.pop(context, 'go_front');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Go to Supermarket to buy more wholesale boxes
                    Expanded(
                      flex: 2,
                      child: PixelButton(
                        label: '[ 🛒 SUPERMARKET ]',
                        color: const Color(0xFFE67E22),
                        height: 50,
                        fontSize: 11.5,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => SupermarketScreen(gameState: state),
                            ),
                          ).then((_) => setState(() {}));
                        },
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
