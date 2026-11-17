import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_card.dart';

class InventoryScreen extends StatelessWidget {
  final GameState gameState;

  const InventoryScreen({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141F2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2A38),
        elevation: 0,
        title: const PixelText(
          '📦 STOCK NG TINDAHAN',
          size: 14,
          color: Colors.amberAccent,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              color: const Color(0xFF0F171E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const PixelText('Kabuuang Bilang ng Paninda:', size: 9, color: Colors.white70),
                      const SizedBox(height: 2),
                      PixelText(
                        '${gameState.totalStockItems} piraso',
                        size: 13,
                        color: Colors.cyanAccent,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const PixelText('Halaga ng Paninda (Retail):', size: 9, color: Colors.white70),
                      const SizedBox(height: 2),
                      PixelText(
                        '₱${gameState.totalInventoryValue.toStringAsFixed(0)}',
                        size: 13,
                        color: Colors.greenAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Grid of Items
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.35,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: GameConstants.allItems.length,
                itemBuilder: (context, index) {
                  final item = GameConstants.allItems[index];
                  final stock = gameState.getStock(item.id);
                  final isOut = stock == 0;
                  final isLow = stock > 0 && stock <= 3;

                  return PixelCard(
                    backgroundColor: isOut
                        ? const Color(0xFF261D1D)
                        : const Color(0xFF1C2833),
                    borderColor: isOut
                        ? Colors.red.shade800
                        : (isLow ? Colors.amber.shade700 : const Color(0xFF34495E)),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 22)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              color: isOut
                                  ? Colors.red
                                  : (isLow ? Colors.amber : const Color(0xFF27AE60)),
                              child: PixelText(
                                isOut ? 'UBOS NA' : (isLow ? 'PAUBOS' : 'MAY STOCK'),
                                size: 8,
                                color: Colors.white,
                                hasShadow: false,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PixelText(
                              item.name,
                              size: 11,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            PixelText(
                              'Benta: ₱${item.retailPrice.toStringAsFixed(0)}',
                              size: 9,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const PixelText('Stock:', size: 9, color: Colors.grey),
                            PixelText(
                              '$stock piraso',
                              size: 12,
                              color: isOut ? Colors.redAccent : Colors.yellowAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
