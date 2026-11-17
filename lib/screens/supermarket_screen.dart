import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';

class SupermarketScreen extends StatefulWidget {
  final GameState gameState;

  const SupermarketScreen({super.key, required this.gameState});

  @override
  State<SupermarketScreen> createState() => _SupermarketScreenState();
}

class _SupermarketScreenState extends State<SupermarketScreen> {
  final Map<String, int> _itemsToBuy = {};

  double get _totalBill {
    double sum = 0.0;
    _itemsToBuy.forEach((itemId, qty) {
      final item = GameConstants.itemById(itemId);
      if (item != null) {
        sum += item.wholesalePrice * qty;
      }
    });
    return sum;
  }

  void _adjustQty(String itemId, int delta) {
    setState(() {
      final current = _itemsToBuy[itemId] ?? 0;
      final updated = (current + delta).clamp(0, 99);
      if (updated == 0) {
        _itemsToBuy.remove(itemId);
      } else {
        _itemsToBuy[itemId] = updated;
      }
    });
  }

  void _checkout() {
    final total = _totalBill;
    if (total == 0) return;

    if (widget.gameState.money < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: PixelText(
            'Kulang ang pera mo! Magbawas ng bibilhin.',
            size: 11,
            color: Colors.white,
          ),
        ),
      );
      return;
    }

    // Process Purchase
    _itemsToBuy.forEach((itemId, qty) {
      widget.gameState.buyStock(itemId, qty);
    });

    SaveManager.saveGame(widget.gameState);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E272C),
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Color(0xFF27AE60), width: 3),
            ),
            title: const PixelText(
              'Matagumpay na Namili! 🎉',
              size: 15,
              color: Color(0xFF2ECC71),
            ),
            content: PixelText(
              'Nabayaran ang ₱${total.toStringAsFixed(0)}.\nNailagay na ang mga paninda sa iyong sari-sari store!',
              size: 12,
              color: Colors.white,
            ),
            actions: [
              PixelButton(
                label: 'OK',
                fontSize: 12,
                height: 38,
                color: const Color(0xFF27AE60),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _itemsToBuy.clear();
                  });
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final totalBill = _totalBill;
    final canAfford = state.money >= totalBill;

    return Scaffold(
      backgroundColor: const Color(0xFF141F2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A56),
        elevation: 0,
        title: const PixelText(
          '🛒 SUPERMARKET (Bultuhan)',
          size: 14,
          color: Colors.amberAccent,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: PixelText(
                'Pera: ₱${state.money.toStringAsFixed(0)}',
                size: 13,
                color: const Color(0xFF2ECC71),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Info Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFF0F1A24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const PixelText(
                    'Puhunan (Wholesale) bibilhin:',
                    size: 10,
                    color: Colors.white70,
                  ),
                  PixelText(
                    'Permit: ${state.hasPermit ? "MERON (OK) ✓" : "WALA PA ✗"}',
                    size: 10,
                    color:
                        state.hasPermit
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                  ),
                ],
              ),
            ),

            // Item List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: GameConstants.allItems.length,
                itemBuilder: (context, index) {
                  final item = GameConstants.allItems[index];
                  final isLocked = item.needsPermit && !state.hasPermit;
                  final currentStoreStock = state.getStock(item.id);
                  final qtyToBuy = _itemsToBuy[item.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color:
                          isLocked
                              ? const Color(0xFF22262B)
                              : const Color(0xFF1B2A38),
                      border: Border.all(
                        color:
                            isLocked
                                ? Colors.red.shade900
                                : const Color(0xFF2980B9),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Item Emoji
                        Container(
                          width: 44,
                          height: 44,
                          color:
                              isLocked
                                  ? Colors.black45
                                  : const Color(0xFF2C3E50),
                          child: Center(
                            child:
                                isLocked
                                    ? const Text(
                                      '🔒',
                                      style: TextStyle(fontSize: 20),
                                    )
                                    : Text(
                                      item.emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PixelText(
                                item.name,
                                size: 13,
                                color: isLocked ? Colors.grey : Colors.white,
                              ),
                              const SizedBox(height: 2),
                              PixelText(
                                'Puhunan: ₱${item.wholesalePrice.toStringAsFixed(0)} | Benta: ₱${item.retailPrice.toStringAsFixed(0)}',
                                size: 10,
                                color: Colors.amberAccent,
                              ),
                              const SizedBox(height: 2),
                              PixelText(
                                isLocked
                                    ? '⚠️ Kailangan ng Barangay Permit!'
                                    : 'Kasalukuyang Stock: $currentStoreStock piraso',
                                size: 9,
                                color:
                                    isLocked
                                        ? Colors.redAccent
                                        : Colors.cyanAccent,
                              ),
                            ],
                          ),
                        ),

                        // Buy Stepper
                        if (!isLocked) ...[
                          Row(
                            children: [
                              _stepperButton(
                                '-',
                                () => _adjustQty(item.id, -1),
                              ),
                              Container(
                                width: 34,
                                alignment: Alignment.center,
                                child: PixelText(
                                  '$qtyToBuy',
                                  size: 14,
                                  color:
                                      qtyToBuy > 0
                                          ? Colors.greenAccent
                                          : Colors.white,
                                ),
                              ),
                              _stepperButton('+', () => _adjustQty(item.id, 1)),
                              const SizedBox(width: 4),
                              _stepperButton(
                                '+5',
                                () => _adjustQty(item.id, 5),
                                width: 32,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            // Checkout Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1A24),
                border: Border(
                  top: BorderSide(color: Color(0xFF2980B9), width: 3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixelText(
                          'Kabuuang Babayaran:',
                          size: 10,
                          color: Colors.white70,
                        ),
                        const SizedBox(height: 2),
                        PixelText(
                          '₱${totalBill.toStringAsFixed(0)}',
                          size: 18,
                          color:
                              canAfford
                                  ? Colors.yellowAccent
                                  : Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                  PixelButton(
                    label: 'BAYARAN AT I-STOCK',
                    fontSize: 11,
                    height: 44,
                    color:
                        canAfford && totalBill > 0
                            ? const Color(0xFF27AE60)
                            : Colors.grey.shade700,
                    enabled: canAfford && totalBill > 0,
                    onPressed: _checkout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepperButton(String label, VoidCallback onTap, {double width = 28}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFF34495E),
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        alignment: Alignment.center,
        child: PixelText(
          label,
          size: 12,
          color: Colors.white,
          hasShadow: false,
        ),
      ),
    );
  }
}
