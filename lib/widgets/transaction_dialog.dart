import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'pixel_text.dart';
import 'pixel_button.dart';
import 'pixel_card.dart';
import 'pixel_customer_sprite.dart';

class CustomerOrder {
  final CustomerPersona? persona;
  final String customerName;
  final String customerAvatar; // emoji or persona
  final Map<String, int> items; // itemId -> qty
  final double totalCost;
  final double paymentGiven; // money handed to player
  final bool isGCash;
  final bool isScammer;
  final String speechLine;

  CustomerOrder({
    this.persona,
    required this.customerName,
    required this.customerAvatar,
    required this.items,
    required this.totalCost,
    required this.paymentGiven,
    this.isGCash = false,
    this.isScammer = false,
    this.speechLine = 'Pabili po!',
  });

  double get expectedChange => (paymentGiven - totalCost).clamp(0.0, 99999.0);
}

class TransactionDialog extends StatefulWidget {
  final CustomerOrder order;
  final Function(double changeGiven) onCompleteSale;
  final VoidCallback onCancel;

  const TransactionDialog({
    super.key,
    required this.order,
    required this.onCompleteSale,
    required this.onCancel,
  });

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  double _changeTendered = 0.0;
  final Map<int, int> _denominationsGiven = {};
  String? _feedbackMessage;
  Color _feedbackColor = Colors.white;

  void _addMoney(int amount) {
    setState(() {
      _denominationsGiven[amount] = (_denominationsGiven[amount] ?? 0) + 1;
      _changeTendered += amount;
      _feedbackMessage = null;
    });
  }

  void _clearMoney() {
    setState(() {
      _denominationsGiven.clear();
      _changeTendered = 0.0;
      _feedbackMessage = null;
    });
  }

  void _submitChange() {
    final expected = widget.order.expectedChange;
    final diff = _changeTendered - expected;

    if (diff.abs() < 0.01) {
      setState(() {
        _feedbackMessage = 'Tama ang sukli! "Salamat po!" ✨';
        _feedbackColor = const Color(0xFF2ECC71);
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          widget.onCompleteSale(_changeTendered);
        }
      });
    } else if (diff < 0) {
      setState(() {
        _feedbackMessage = 'Kulang ang sukli mo ng ₱${diff.abs().toStringAsFixed(0)}! 😠';
        _feedbackColor = const Color(0xFFE74C3C);
      });
    } else {
      setState(() {
        _feedbackMessage = 'Sobra ang sukli mo ng ₱${diff.toStringAsFixed(0)}! Lugi ka! 💸';
        _feedbackColor = const Color(0xFFE67E22);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedChange = widget.order.expectedChange;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: PixelCard(
        backgroundColor: const Color(0xFF1E272C),
        borderColor: const Color(0xFFE67E22),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Customer
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34495E),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        widget.order.customerAvatar,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PixelText(
                          widget.order.customerName,
                          size: 15,
                          color: Colors.amberAccent,
                        ),
                        const SizedBox(height: 2),
                        const PixelText(
                          '"Pabili po ate/kuya!"',
                          size: 11,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),

              // Orders List
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF151D22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PixelText(
                      'MGA BINIBILI:',
                      size: 10,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 6),
                    ...widget.order.items.entries.map((entry) {
                      final item = GameConstants.itemById(entry.key);
                      if (item == null) return const SizedBox.shrink();
                      final subtotal = item.retailPrice * entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(item.emoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                PixelText(
                                  '${item.name} x${entry.value}',
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                            PixelText(
                              '₱${subtotal.toStringAsFixed(0)}',
                              size: 12,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Total & Payment Given Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF263238),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PixelText('Kabuuan (Total):', size: 12, color: Colors.white),
                        PixelText(
                          '₱${widget.order.totalCost.toStringAsFixed(0)}',
                          size: 16,
                          color: Colors.yellowAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PixelText('Inabot na Pera:', size: 12, color: Colors.white70),
                        PixelText(
                          '₱${widget.order.paymentGiven.toStringAsFixed(0)}',
                          size: 14,
                          color: Colors.cyanAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PixelText('Dapat na Sukli:', size: 12, color: Colors.orangeAccent),
                        PixelText(
                          '₱${expectedChange.toStringAsFixed(0)}',
                          size: 15,
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Sukli Counter Section
              Container(
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF0F171E),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PixelText('Sukling Ibibigay:', size: 11, color: Colors.white),
                        PixelText(
                          '₱${_changeTendered.toStringAsFixed(0)}',
                          size: 18,
                          color: _changeTendered == expectedChange
                              ? const Color(0xFF2ECC71)
                              : (_changeTendered > expectedChange
                                  ? Colors.redAccent
                                  : Colors.white),
                        ),
                      ],
                    ),
                    if (_feedbackMessage != null) ...[
                      const SizedBox(height: 4),
                      PixelText(
                        _feedbackMessage!,
                        size: 11,
                        color: _feedbackColor,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Denomination Buttons (Bills & Coins)
              const PixelText(
                'PUMILI NG SUKLI (Bills & Barya):',
                size: 9,
                color: Colors.grey,
              ),
              const SizedBox(height: 6),

              // Bills
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _denomButton(500, const Color(0xFFFFCC00), Colors.black),
                  _denomButton(200, const Color(0xFF27AE60), Colors.white),
                  _denomButton(100, const Color(0xFF8E44AD), Colors.white),
                  _denomButton(50, const Color(0xFFE74C3C), Colors.white),
                  _denomButton(20, const Color(0xFFE67E22), Colors.white),
                ],
              ),
              const SizedBox(height: 6),
              // Coins
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  _denomButton(10, const Color(0xFFBDC3C7), Colors.black, isCoin: true),
                  _denomButton(5, const Color(0xFFB0BEC5), Colors.black, isCoin: true),
                  _denomButton(1, const Color(0xFF90A4AE), Colors.black, isCoin: true),
                ],
              ),

              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: PixelButton(
                      label: 'Bawiin (Clear)',
                      fontSize: 10,
                      height: 38,
                      color: const Color(0xFF7F8C8D),
                      onPressed: _changeTendered > 0 ? _clearMoney : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PixelButton(
                      label: 'Iabot ang Sukli',
                      fontSize: 12,
                      height: 42,
                      color: const Color(0xFF27AE60),
                      onPressed: _submitChange,
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

  Widget _denomButton(int amount, Color bg, Color textCol, {bool isCoin = false}) {
    final count = _denominationsGiven[amount] ?? 0;
    return GestureDetector(
      onTap: () => _addMoney(amount),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCoin ? 8 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(isCoin ? 12 : 3),
          border: Border.all(color: Colors.white70, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelText(
              '₱$amount',
              size: 11,
              color: textCol,
              hasShadow: false,
            ),
            if (count > 0)
              PixelText(
                'x$count',
                size: 9,
                color: textCol,
                hasShadow: false,
              ),
          ],
        ),
      ),
    );
  }
}
