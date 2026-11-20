import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_card.dart';
import '../widgets/raket_dialog.dart';
import 'supermarket_screen.dart';
import 'barangay_screen.dart';

class MapScreen extends StatelessWidget {
  final GameState gameState;

  const MapScreen({super.key, required this.gameState});

  void _openRaketDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RaketDialog(gameState: gameState, onJobCompleted: () {}),
    );
  }

  void _goToSupermarket(BuildContext context) {
    gameState.advanceTime(30); // 30 mins travel
    SaveManager.saveGame(gameState);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupermarketScreen(gameState: gameState),
      ),
    );
  }

  void _goToBarangay(BuildContext context) {
    gameState.advanceTime(20); // 20 mins travel
    SaveManager.saveGame(gameState);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BarangayScreen(gameState: gameState)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162521),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B382B),
        elevation: 0,
        title: const PixelText(
          '🗺️ MAPA NG BARANGAY',
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
                '₱${gameState.money.toStringAsFixed(0)}',
                size: 14,
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
              // Travel Time Note
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: const Color(0xFF111E1B),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PixelText(
                        'Oras Ngayon: ${gameState.formattedTime} (${gameState.timeOfDayPeriod})',
                        size: 11,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Map Canvas / Interactive Locations
              Expanded(
                child: PixelCard(
                  backgroundColor: const Color(0xFF2E4E3F), // Grass green
                  borderColor: const Color(0xFFD4AC0D),
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      // Pixel Dirt Roads / Paths
                      Positioned.fill(
                        child: CustomPaint(painter: _MapRoadsPainter()),
                      ),

                      // Location 1: SUPERMARKET (Top-Right)
                      Positioned(
                        top: 20,
                        right: 16,
                        child: _mapLocationTile(
                          icon: '🛒',
                          title: 'SUPERMARKET',
                          subtitle: 'Bilihan ng Stock',
                          badge: '30 mins lakad',
                          badgeColor: Colors.blueAccent,
                          color: const Color(0xFF2980B9),
                          onTap: () => _goToSupermarket(context),
                        ),
                      ),

                      // Location 2: SARI-SARI STORE (Center-Left)
                      Positioned(
                        top: 150,
                        left: 16,
                        child: _mapLocationTile(
                          icon: '🏪',
                          title: 'TINDAHAN MO',
                          subtitle: gameState.storeOpen ? 'Bukas' : 'Sarado',
                          badge: 'Nandito Ka',
                          badgeColor: const Color(0xFF27AE60),
                          color: const Color(0xFFE67E22),
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                      // Location 3: BARANGAY HALL (Bottom-Right)
                      Positioned(
                        bottom: 30,
                        right: 20,
                        child: _mapLocationTile(
                          icon: '🏛️',
                          title: 'BARANGAY HALL',
                          subtitle:
                              gameState.hasPermit
                                  ? 'May Permit Ka Na'
                                  : 'Kumuha ng Permit (₱200)',
                          badge: '20 mins lakad',
                          badgeColor:
                              gameState.hasPermit ? Colors.green : Colors.amber,
                          color: const Color(0xFF8E44AD),
                          onTap: () => _goToBarangay(context),
                        ),
                      ),

                      // Location 4: BARANGAY PLAZA (Bottom-Left: Raketan / Sidelines)
                      Positioned(
                        bottom: 30,
                        left: 16,
                        child: _mapLocationTile(
                          icon: '💼',
                          title: 'BARANGAY PLAZA',
                          subtitle: 'Mag-sideline para kumita',
                          badge: 'Kumita ng Puhunan',
                          badgeColor: const Color(0xFF27AE60),
                          color: const Color(0xFF1E8449),
                          onTap: () => _openRaketDialog(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Info note
              const Center(
                child: PixelText(
                  'Paalala: Lumilipas ang oras kapag naglalakbay ka!',
                  size: 10,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 8),

              PixelButton(
                label: '◀ BUMALIK SA TINDAHAN',
                fontSize: 12,
                height: 44,
                color: const Color(0xFF34495E),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapLocationTile({
    required String icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: PixelText(
                    title,
                    size: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            PixelText(subtitle, size: 9, color: Colors.white70),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: badgeColor,
              child: PixelText(
                badge,
                size: 8,
                color: Colors.white,
                hasShadow: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoadsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint =
        Paint()
          ..color = const Color(0xFF8B6F47) // Dirt road brown
          ..strokeWidth = 22
          ..style = PaintingStyle.stroke;

    final roadBorder =
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 26
          ..style = PaintingStyle.stroke;

    final path =
        Path()
          ..moveTo(size.width * 0.3, size.height * 0.5) // Store
          ..lineTo(size.width * 0.55, size.height * 0.45)
          ..lineTo(size.width * 0.7, size.height * 0.2) // Supermarket
          ..moveTo(size.width * 0.55, size.height * 0.45)
          ..lineTo(size.width * 0.65, size.height * 0.8); // Barangay

    canvas.drawPath(path, roadBorder);
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
