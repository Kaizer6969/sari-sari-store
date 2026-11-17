import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';

class BarangayScreen extends StatefulWidget {
  final GameState gameState;

  const BarangayScreen({super.key, required this.gameState});

  @override
  State<BarangayScreen> createState() => _BarangayScreenState();
}

class _BarangayScreenState extends State<BarangayScreen> {
  void _buyPermit() {
    final state = widget.gameState;
    if (state.money < GameConstants.permitCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          content: PixelText(
            'Kulang ang pera mo! Kailangan mo ng ₱200.',
            size: 11,
            color: Colors.white,
          ),
        ),
      );
      return;
    }

    final success = state.obtainPermit();
    if (success) {
      SaveManager.saveGame(state);
      setState(() {});

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E272C),
          shape: const BeveledRectangleBorder(
            side: BorderSide(color: Color(0xFFF1C40F), width: 3),
          ),
          title: const PixelText(
            'LIGAL NA ANG TINDAHAN! 📜🎉',
            size: 15,
            color: Colors.yellowAccent,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFFFF9C4),
                child: const Column(
                  children: [
                    PixelText('BARANGAY BUSINESS PERMIT', size: 10, color: Colors.black87, hasShadow: false),
                    SizedBox(height: 4),
                    PixelText('OPISYAL AT APROBADO', size: 8, color: Colors.green, hasShadow: false),
                    SizedBox(height: 6),
                    Text('🎖️', style: TextStyle(fontSize: 32)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const PixelText(
                'Binabati kita! Pwede ka nang magbenta ng lahat ng paninda tulad ng Yosi atbp. sa Supermarket!',
                size: 11,
                color: Colors.white,
              ),
            ],
          ),
          actions: [
            PixelButton(
              label: 'SALAMAT KAP!',
              fontSize: 11,
              height: 38,
              color: const Color(0xFF27AE60),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final hasPermit = state.hasPermit;
    final canAfford = state.money >= GameConstants.permitCost;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C2248),
        elevation: 0,
        title: const PixelText(
          '🏛️ BARANGAY HALL',
          size: 15,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Character / Barangay Captain Pixel Frame
              PixelCard(
                backgroundColor: const Color(0xFF251B38),
                borderColor: const Color(0xFF8E44AD),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B2F55),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Center(
                        child: Text('👨‍💼', style: TextStyle(fontSize: 38)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const PixelText(
                            'Kapitan "Kap" Roger',
                            size: 14,
                            color: Colors.amberAccent,
                          ),
                          const SizedBox(height: 2),
                          const PixelText(
                            'Punong Barangay',
                            size: 10,
                            color: Colors.white70,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            color: const Color(0xFF27AE60),
                            child: const PixelText(
                              'Opisyal ng Barangay',
                              size: 8,
                              color: Colors.white,
                              hasShadow: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Dialogue Speech Bubble
              PixelCard(
                backgroundColor: const Color(0xFF161622),
                borderColor: Colors.blueGrey,
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PixelText(
                      'SABI NI KAPITAN:',
                      size: 9,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 6),
                    PixelText(
                      hasPermit
                          ? '"Magandang araw sa\'yo kapitbahay! Nakita ko ang iyong tindahan, kumpleto at ligal ang iyong Barangay Permit! Ipagpatuloy mo ang tapat na pagtitinda."'
                          : '"Magandang araw! Kung magbubukas ka ng sari-sari store dito sa ating barangay, kailangan mo ng Opisyal na Barangay Business Permit (₱200) para makapagtinda ka ng lahat ng klase ng produkto."',
                      size: 12,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Permit Status Certificate Card
              Expanded(
                child: PixelCard(
                  backgroundColor: hasPermit ? const Color(0xFF1B382B) : const Color(0xFF2B1A1E),
                  borderColor: hasPermit ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasPermit ? '📜' : '🔒',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 10),
                      PixelText(
                        hasPermit ? 'MAYROON KA NANG PERMIT' : 'WALA PANG BUSINESS PERMIT',
                        size: 14,
                        color: hasPermit ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      PixelText(
                        hasPermit
                            ? 'Lisensyado kang magtinda ng sigarilyo at lahat ng items!'
                            : 'Bayaran ang ₱200 registration fee para ma-unlock ang lahat ng paninda sa Supermarket.',
                        size: 10,
                        color: Colors.white70,
                        textAlign: TextAlign.center,
                      ),
                      if (!hasPermit) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: Colors.black45,
                          child: const PixelText(
                            'Halaga ng Permit: ₱200',
                            size: 13,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons
              if (!hasPermit) ...[
                PixelButton(
                  label: canAfford ? 'BAYARAN ANG PERMIT (₱200)' : 'KULANG ANG PERA (₱200)',
                  fontSize: 12,
                  height: 48,
                  color: canAfford ? const Color(0xFF27AE60) : Colors.grey.shade700,
                  enabled: canAfford,
                  onPressed: _buyPermit,
                ),
                const SizedBox(height: 10),
              ],

              PixelButton(
                label: '◀ BUMALIK SA TINDAHAN',
                fontSize: 12,
                height: 42,
                color: const Color(0xFF34495E),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
