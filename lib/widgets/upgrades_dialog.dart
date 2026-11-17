import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import 'pixel_text.dart';
import 'pixel_button.dart';
import 'pixel_card.dart';

class UpgradesDialog extends StatefulWidget {
  final GameState gameState;

  const UpgradesDialog({super.key, required this.gameState});

  @override
  State<UpgradesDialog> createState() => _UpgradesDialogState();
}

class _UpgradesDialogState extends State<UpgradesDialog> {
  final List<Map<String, dynamic>> _upgrades = [
    {
      'id': 'neon_sign',
      'name': 'Glow Neon Signage',
      'icon': '💡',
      'cost': 350.0,
      'desc': 'Mas maraming customer tuwing gabi (+25% customers).',
    },
    {
      'id': 'refrigerator',
      'name': 'Palamig / Ref',
      'icon': '🧊',
      'cost': 800.0,
      'desc': 'Makatinda ng malamig na Softdrinks at Ice Candy!',
    },
    {
      'id': 'cctv_scanner',
      'name': 'Anti-Scam CCTV / Alarm',
      'icon': '📹',
      'cost': 500.0,
      'desc': 'Awtomatikong magpapakita ng babala kapag peke ang GCash!',
    },
    {
      'id': 'bench_tambayan',
      'name': 'Bangkong Tambayan',
      'icon': '🪵',
      'cost': 250.0,
      'desc': 'Tinatambayan ng mga kapitbahay, dagdag reputasyon (+10⭐).',
    },
  ];

  final Set<String> _unlockedUpgrades = {};

  void _buyUpgrade(Map<String, dynamic> upg) {
    final cost = upg['cost'] as double;
    final state = widget.gameState;

    if (state.money < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: PixelText('Kulang ang pera mo para sa upgrade na ito!', size: 10, color: Colors.white),
        ),
      );
      return;
    }

    setState(() {
      state.money -= cost;
      _unlockedUpgrades.add(upg['id'] as String);
    });
    SaveManager.saveGame(state);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF27AE60),
        content: PixelText('Nabilli ang ${upg['name']}! 🎉', size: 11, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: PixelCard(
        backgroundColor: const Color(0xFF1E272C),
        borderColor: const Color(0xFF43B662),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🔧', style: TextStyle(fontSize: 22)),
                    SizedBox(width: 8),
                    PixelText('UPGRADES NG TINDAHAN', size: 14, color: Color(0xFF43B662)),
                  ],
                ),
                PixelText('Pera: ₱${widget.gameState.money.toStringAsFixed(0)}', size: 12, color: Colors.amberAccent),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),

            // Upgrade list
            ..._upgrades.map((upg) {
              final isBought = _unlockedUpgrades.contains(upg['id']);
              final cost = upg['cost'] as double;
              final canAfford = widget.gameState.money >= cost;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF151D22),
                child: Row(
                  children: [
                    Text(upg['icon'] as String, style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PixelText(upg['name'] as String, size: 12, color: Colors.white),
                          const SizedBox(height: 2),
                          PixelText(upg['desc'] as String, size: 9, color: Colors.white70),
                          const SizedBox(height: 2),
                          PixelText('Halaga: ₱${cost.toStringAsFixed(0)}', size: 10, color: Colors.amberAccent),
                        ],
                      ),
                    ),
                    PixelButton(
                      label: isBought ? 'NABILI NA ✓' : 'BILHIN',
                      fontSize: 10,
                      height: 34,
                      width: 90,
                      color: isBought
                          ? Colors.grey.shade700
                          : (canAfford ? const Color(0xFF43B662) : Colors.grey),
                      enabled: !isBought && canAfford,
                      onPressed: isBought ? null : () => _buyUpgrade(upg),
                    ),
                  ],
                ),
              );
            }).toList(),

            const SizedBox(height: 12),
            PixelButton(
              label: 'ISARA',
              fontSize: 11,
              height: 38,
              color: const Color(0xFF34495E),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
