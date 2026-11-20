import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/save_manager.dart';
import 'pixel_text.dart';
import 'pixel_button.dart';

class RaketJob {
  final String id;
  final String title;
  final String description;
  final String icon;
  final double payout;
  final int minutesDuration;

  const RaketJob({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.payout,
    required this.minutesDuration,
  });
}

class RaketDialog extends StatelessWidget {
  final GameState gameState;
  final VoidCallback onJobCompleted;

  const RaketDialog({
    super.key,
    required this.gameState,
    required this.onJobCompleted,
  });

  static const List<RaketJob> allJobs = [
    RaketJob(
      id: 'walis_plaza',
      title: 'Magwalis sa Barangay Plaza',
      description: 'Linisin ang plaza pagkatapos ng basketball game.',
      icon: '🧹',
      payout: 60.0,
      minutesDuration: 30,
    ),
    RaketJob(
      id: 'deliver_tubig',
      title: 'Mag-deliver ng Tubig sa Kapitbahay',
      description: 'Magbuhat at maghatid ng mga galon ng mineral water.',
      icon: '🛵',
      payout: 90.0,
      minutesDuration: 45,
    ),
    RaketJob(
      id: 'kargador_palengke',
      title: 'Kargador sa Bagsakan ng Gulay',
      description: 'Tumulong magbaba ng mga sako ng gulay at bigas.',
      icon: '📦',
      payout: 150.0,
      minutesDuration: 60,
    ),
    RaketJob(
      id: 'carwash_tricycle',
      title: 'Carwash ng Tricycle sa Toda',
      description: 'Magsabon at magbanlaw ng mga tricycle sa terminal.',
      icon: '🚗',
      payout: 80.0,
      minutesDuration: 40,
    ),
    RaketJob(
      id: 'bote_dyaryo',
      title: 'Magkolekta ng Recyclables',
      description: 'Mangalakal ng bote at dyaryo sa mga bahay-bahay.',
      icon: '🗑️',
      payout: 50.0,
      minutesDuration: 25,
    ),
  ];

  void _doJob(BuildContext context, RaketJob job) {
    gameState.money += job.payout;
    gameState.advanceTime(job.minutesDuration);
    SaveManager.saveGame(gameState);

    Navigator.pop(context);
    onJobCompleted();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF27AE60),
        duration: const Duration(seconds: 3),
        content: PixelText(
          '✅ Natapos ang raket: "${job.title}"! Kumita ka ng ₱${job.payout.toStringAsFixed(0)}! Pwede ka nang bumili ng paninda!',
          size: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        decoration: BoxDecoration(
          color: const Color(0xFF1B2631),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF1C40F), width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black87, offset: Offset(3, 4), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Row(
                children: [
                  const Text('💼', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          'RAKET SA BARANGAY',
                          size: 14,
                          color: Color(0xFFF1C40F),
                          fontWeight: FontWeight.bold,
                        ),
                        PixelText(
                          'Mag-sideline para kumita ng puhunan pambili ng paninda!',
                          size: 9,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B110B),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFF1C40F)),
                    ),
                    child: PixelText(
                      '₱${gameState.money.toStringAsFixed(0)}',
                      size: 12,
                      color: const Color(0xFF2ECC71),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Job List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: allJobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, index) {
                  final job = allJobs[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF243342),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        Text(job.icon, style: const TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PixelText(
                                job.title,
                                size: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(height: 2),
                              PixelText(
                                job.description,
                                size: 8.5,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  PixelText(
                                    'Sahod: +₱${job.payout.toStringAsFixed(0)}',
                                    size: 9.5,
                                    color: const Color(0xFF2ECC71),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  const SizedBox(width: 8),
                                  PixelText(
                                    'Oras: ${job.minutesDuration} mins',
                                    size: 9,
                                    color: const Color(0xFFF39C12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PixelButton(
                          label: 'TUMANGGAP',
                          fontSize: 9.5,
                          height: 34,
                          width: 85,
                          color: const Color(0xFF27AE60),
                          onPressed: () => _doJob(context, job),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(12),
              child: PixelButton(
                label: '✖ ISARA',
                fontSize: 11,
                height: 38,
                color: const Color(0xFF7F8C8D),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
