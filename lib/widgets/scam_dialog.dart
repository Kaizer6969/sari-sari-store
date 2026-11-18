import 'package:flutter/material.dart';
import 'pixel_text.dart';
import 'pixel_button.dart';
import 'pixel_card.dart';
import 'transaction_dialog.dart';

class ScamDialog extends StatelessWidget {
  final CustomerOrder order;
  final String fakeReason; // Description of the flaw for scammers
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ScamDialog({
    super.key,
    required this.order,
    required this.fakeReason,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isScammer = order.isScammer;
    final total = order.totalCost;

    // Display values on fake phone
    final displayedAmount =
        isScammer ? (total * 0.1) : total; // scammer shows 10% or wrong amount
    final statusText = isScammer ? 'PROCESSING...' : 'PAYMENT SUCCESSFUL';
    final statusColor = isScammer ? Colors.amber : const Color(0xFF2ECC71);
    final refNumber = isScammer ? 'REF # DRAFT-992341' : 'REF # 9042 1882 3019';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: PixelCard(
        backgroundColor: const Color(0xFF1A1A24),
        borderColor: isScammer ? Colors.redAccent : const Color(0xFF007DFE),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C3E50),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Text(
                      order.customerAvatar,
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          order.customerName,
                          size: 14,
                          color: Colors.amberAccent,
                        ),
                        const SizedBox(height: 2),
                        const PixelText(
                          '"Ate/Kuya, nag-GCash na ako oh! Patingin naman!"',
                          size: 10,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // The Smartphone Screen Frame
              Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade600, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(2, 4),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Phone top speaker & notch
                    Container(
                      margin: const EdgeInsets.only(top: 6, bottom: 4),
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Phone screen content (GCash blue header)
                    Container(
                      color: const Color(0xFF007DFE), // GCash blue
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const PixelText(
                            'G-Pay App',
                            size: 9,
                            color: Colors.white,
                            hasShadow: false,
                          ),
                          Row(
                            children: [
                              if (isScammer)
                                const Icon(
                                  Icons.wifi_off,
                                  size: 10,
                                  color: Colors.white70,
                                )
                              else
                                const Icon(
                                  Icons.wifi,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              const SizedBox(width: 4),
                              const PixelText(
                                '100%',
                                size: 8,
                                color: Colors.white,
                                hasShadow: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Screen Body
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          // Status Icon
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isScammer
                                  ? Icons.hourglass_top
                                  : Icons.check_circle,
                              color: statusColor,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          PixelText(
                            statusText,
                            size: 11,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            hasShadow: false,
                          ),
                          const SizedBox(height: 8),

                          // Amount Displayed
                          PixelText(
                            'PHP ${displayedAmount.toStringAsFixed(2)}',
                            size: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            hasShadow: false,
                          ),
                          const SizedBox(height: 4),
                          const PixelText(
                            'Sent to: Sari-Sari Store',
                            size: 9,
                            color: Colors.black54,
                            hasShadow: false,
                          ),
                          const SizedBox(height: 8),

                          // Reference Number
                          Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.grey.shade100,
                            child: PixelText(
                              refNumber,
                              size: 8,
                              color:
                                  isScammer ? Colors.red : Colors.grey.shade700,
                              hasShadow: false,
                            ),
                          ),

                          if (isScammer) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              color: Colors.amber.shade100,
                              child: const PixelText(
                                '⚠️ [Hint: Tingnan ang Status & Amount!]',
                                size: 8,
                                color: Colors.brown,
                                hasShadow: false,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Phone bottom bezel
                    Container(height: 14, color: Colors.black),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Actual Cost Reminder
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                color: const Color(0xFF263238),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const PixelText(
                      'Dapat na Halaga (Total):',
                      size: 10,
                      color: Colors.white70,
                    ),
                    PixelText(
                      '₱${total.toStringAsFixed(0)}',
                      size: 13,
                      color: Colors.yellowAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Choices
              const PixelText(
                'Ano ang gagawin mo?',
                size: 11,
                color: Colors.white,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'Tanggihan! ✋\n(Huwag Ibigay)',
                      fontSize: 10,
                      height: 46,
                      color: const Color(0xFFC0392B),
                      onPressed: onReject,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PixelButton(
                      label: 'Tanggapin ✅\n(Ibigay Paninda)',
                      fontSize: 10,
                      height: 46,
                      color: const Color(0xFF27AE60),
                      onPressed: onAccept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
