import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import 'pixel_text.dart';

/// Floating retro HUD showing the cardboard delivery box currently held in the player's hands!
class HeldBoxHudBanner extends StatelessWidget {
  final GameState gameState;
  final String hintText;
  final VoidCallback? onPutDown;

  const HeldBoxHudBanner({
    super.key,
    required this.gameState,
    required this.hintText,
    this.onPutDown,
  });

  @override
  Widget build(BuildContext context) {
    if (!gameState.isHoldingBox) return const SizedBox.shrink();
    final item = GameConstants.itemById(gameState.heldBoxItemId!);
    if (item == null) return const SizedBox.shrink();

    final bytes = ItemImageData.getBytes(item.id);
    final shelfStock = gameState.getStock(item.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xF23E2723),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1C40F), width: 2.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, offset: Offset(2, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cardboard Box Thumbnail with Product Sprite Printed on Front
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFC68B59),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF4E342E), width: 2),
            ),
            child:
                bytes != null
                    ? Image.memory(
                      bytes,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    )
                    : Center(
                      child: Text(
                        item.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PixelText(
                  '📦 HAWAK NA BOX: ${item.name.split(' ').first.toUpperCase()} (${gameState.heldBoxQty} laman)',
                  size: 10,
                  color: const Color(0xFFF1C40F),
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 2),
                PixelText(
                  '$hintText • Estante: $shelfStock/${GameState.maxShelfCapacity}',
                  size: 8.5,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          if (onPutDown != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onPutDown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFC0392B),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: const PixelText(
                  '📥 ILAPAG',
                  size: 8.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
