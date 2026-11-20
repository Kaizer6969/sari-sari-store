import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/sound_service.dart';
import 'pixel_text.dart';
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

/// Placed item currently sitting on the wooden counter table
class PlacedMoneyItem {
  final int id;
  final int amount;
  final bool isCoin;
  final Offset position; // (x, y) relative to counter area
  final double rotation; // slight natural angle in radians

  PlacedMoneyItem({
    required this.id,
    required this.amount,
    required this.isCoin,
    required this.position,
    required this.rotation,
  });
}

/// Active flying animation when money is tapped from drawer to counter
class FlyingMoneyAnimation {
  final int id;
  final int amount;
  final bool isCoin;
  final Offset start;
  final Offset end;
  final double startRotation;
  final double endRotation;
  final AnimationController controller;
  final Animation<double> curved;

  FlyingMoneyAnimation({
    required this.id,
    required this.amount,
    required this.isCoin,
    required this.start,
    required this.end,
    required this.startRotation,
    required this.endRotation,
    required this.controller,
    required this.curved,
  });
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

class _TransactionDialogState extends State<TransactionDialog>
    with TickerProviderStateMixin {
  final List<PlacedMoneyItem> _placedMoney = [];
  final List<FlyingMoneyAnimation> _activeFlights = [];
  int _flightCounter = 0;

  double _changeTendered = 0.0;
  String? _statusFeedback;
  Color _statusFeedbackColor = const Color(0xFF2ECC71);
  bool _isSuccessAnimating = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // GlobalKeys for drawer slots to compute flight start coordinates
  final Map<int, GlobalKey> _billKeys = {
    20: GlobalKey(),
    50: GlobalKey(),
    100: GlobalKey(),
    500: GlobalKey(),
    1000: GlobalKey(),
  };

  final Map<int, GlobalKey> _coinKeys = {
    1: GlobalKey(),
    5: GlobalKey(),
    10: GlobalKey(),
    20: GlobalKey(),
  };

  final GlobalKey _counterAreaKey = GlobalKey();
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    for (final flight in _activeFlights) {
      flight.controller.dispose();
    }
    super.dispose();
  }

  /// Spawn flight animation from drawer slot to the wooden counter table
  void _addMoneyWithAnimation(int amount, bool isCoin) {
    if (_isSuccessAnimating) return;

    // Play tactile sound
    if (isCoin) {
      SoundService.playCoinSound();
    } else {
      SoundService.playBillSound();
    }

    final flightId = ++_flightCounter;

    // Find starting coordinates from slot widget
    final key = isCoin ? _coinKeys[amount] : _billKeys[amount];
    Offset startPos = const Offset(360, 420); // Fallback

    if (key != null && key.currentContext != null) {
      final box = key.currentContext!.findRenderObject() as RenderBox?;
      final counterBox =
          _counterAreaKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && counterBox != null) {
        final globalPos = box.localToGlobal(box.size.center(Offset.zero));
        startPos = counterBox.globalToLocal(globalPos);
      }
    }

    // Determine target location on the wooden counter table
    // Counter dimensions roughly: width ~480, height ~100
    double endX;
    double endY;

    if (!isCoin) {
      // Bills arranged neatly on the counter table
      final billCount = _placedMoney.where((m) => !m.isCoin).length;
      final baseCol = billCount % 4;
      final baseRow = (billCount ~/ 4) % 2;
      endX = 40.0 + (baseCol * 90.0) + (_rng.nextDouble() * 14 - 7);
      endY = 15.0 + (baseRow * 32.0) + (_rng.nextDouble() * 10 - 5);
    } else {
      // Coins grouped slightly to the right side of counter table
      final coinCount = _placedMoney.where((m) => m.isCoin).length;
      final col = coinCount % 3;
      final row = (coinCount ~/ 3) % 3;
      endX = 350.0 + (col * 36.0) + (_rng.nextDouble() * 8 - 4);
      endY = 18.0 + (row * 24.0) + (_rng.nextDouble() * 8 - 4);
    }

    final targetPos = Offset(endX, endY);
    final targetRot = (_rng.nextDouble() * 0.16) - 0.08; // -4.5 to +4.5 deg

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    final flight = FlyingMoneyAnimation(
      id: flightId,
      amount: amount,
      isCoin: isCoin,
      start: startPos,
      end: targetPos,
      startRotation: 0.0,
      endRotation: targetRot,
      controller: controller,
      curved: curved,
    );

    setState(() {
      _activeFlights.add(flight);
      _changeTendered += amount;
      _statusFeedback = null;
    });

    controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _activeFlights.removeWhere((f) => f.id == flightId);
        _placedMoney.add(
          PlacedMoneyItem(
            id: flightId,
            amount: amount,
            isCoin: isCoin,
            position: targetPos,
            rotation: targetRot,
          ),
        );
      });
      controller.dispose();
    });
  }

  /// Remove single money item from the counter and return to drawer
  void _removePlacedMoney(PlacedMoneyItem item) {
    if (_isSuccessAnimating) return;
    setState(() {
      _placedMoney.remove(item);
      _changeTendered = math.max(0.0, _changeTendered - item.amount);
      _statusFeedback = null;
    });
    if (item.isCoin) {
      SoundService.playCoinSound();
    } else {
      SoundService.playBillSound();
    }
  }

  /// Clear all money from the table
  void _clearAllMoney() {
    if (_placedMoney.isEmpty && _activeFlights.isEmpty) return;
    setState(() {
      _placedMoney.clear();
      _changeTendered = 0.0;
      _statusFeedback = null;
    });
    SoundService.playBillSound();
  }

  /// Validate tendered change and finalize sale
  void _submitChange() {
    if (_isSuccessAnimating) return;

    final expected = widget.order.expectedChange;
    final diff = _changeTendered - expected;

    if (diff.abs() < 0.01) {
      // EXACT CHANGE! "Ka-ching!"
      SoundService.playRegisterKaChing();
      setState(() {
        _isSuccessAnimating = true;
        _statusFeedback = 'TAMA ANG SUKLI! ✨';
        _statusFeedbackColor = const Color(0xFF2ECC71);
      });

      // Quick delay for visual satisfaction, then finish sale
      Future.delayed(const Duration(milliseconds: 750), () {
        if (mounted) {
          widget.onCompleteSale(_changeTendered);
        }
      });
    } else {
      SoundService.playErrorBuzz();
      _shakeController.forward(from: 0.0);

      if (diff < 0) {
        setState(() {
          _statusFeedback = 'KULANG NG ₱${diff.abs().toStringAsFixed(0)}! 😠';
          _statusFeedbackColor = const Color(0xFFE74C3C);
        });
      } else {
        setState(() {
          _statusFeedback = 'SOBRA NG ₱${diff.toStringAsFixed(0)}! LUGI KA! 💸';
          _statusFeedbackColor = const Color(0xFFE67E22);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expectedChange = widget.order.expectedChange;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Container(
            width: 860,
            height: 520,
            decoration: BoxDecoration(
              color: const Color(0xFF140F0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4A3420), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. TOP HALF: Window view with customer and wooden sill
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 220,
                  child: _buildWindowAndCustomerView(),
                ),

                // 2. BOTTOM HALF: Wooden Counter Table surface
                Positioned(
                  top: 200,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildWoodenCounterSurface(),
                ),

                // 3. LEFT: Vintage Cash Register & CRT Digital Monitor
                Positioned(
                  top: 90,
                  left: 12,
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: _buildCashRegisterMachine(expectedChange),
                  ),
                ),

                // 4. CENTER-BOTTOM: Open Cash Drawer (Kaha)
                Positioned(
                  bottom: 10,
                  left: 275,
                  width: 420,
                  height: 215,
                  child: _buildCashDrawer(),
                ),

                // 5. RIGHT: Action Button "GIVE CHANGE"
                Positioned(
                  bottom: 24,
                  right: 18,
                  child: _buildGiveChangeButton(expectedChange),
                ),

                // 6. TOP RIGHT: Close / Cancel Button
                Positioned(
                  top: 10,
                  right: 12,
                  child: _buildCloseButton(),
                ),

                // 7. FLYING MONEY ANIMATION OVERLAY LAYER
                Positioned.fill(
                  child: IgnorePointer(
                    child: Stack(
                      children: _activeFlights.map((flight) {
                        return AnimatedBuilder(
                          animation: flight.curved,
                          builder: (context, child) {
                            final progress = flight.curved.value;
                            // Convert relative counter coordinate to dialog coordinate
                            // Counter area starts at (200, 200) roughly
                            final curX = 275 +
                                flight.start.dx +
                                (flight.end.dx - flight.start.dx) * progress;
                            // Arc slightly upwards mid-flight
                            final arc = -math.sin(progress * math.pi) * 45;
                            final curY = 200 +
                                flight.start.dy +
                                (flight.end.dy - flight.start.dy) * progress +
                                arc;

                            final curRot = flight.startRotation +
                                (flight.endRotation - flight.startRotation) *
                                    progress;
                            final curScale = 0.85 +
                                math.sin(progress * math.pi) * 0.25;

                            return Positioned(
                              left: curX,
                              top: curY,
                              child: Transform.rotate(
                                angle: curRot,
                                child: Transform.scale(
                                  scale: curScale,
                                  child: flight.isCoin
                                      ? _buildCoinWidget(flight.amount, size: 28)
                                      : _buildBillWidget(
                                          flight.amount,
                                          width: 80,
                                          height: 42,
                                        ),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 1: WINDOW & CUSTOMER VIEW
  // ==========================================
  Widget _buildWindowAndCustomerView() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF1A252F),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background ambient street / store front glow
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.2, -0.2),
                    radius: 1.2,
                    colors: [Color(0xFFFFE082), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Security window iron bars (left & right)
          Positioned(
            left: 20,
            top: 0,
            bottom: 30,
            child: _buildWindowBars(count: 3),
          ),
          Positioned(
            right: 20,
            top: 0,
            bottom: 30,
            child: _buildWindowBars(count: 3),
          ),

          // Customer standing at the window sill
          Positioned(
            top: 15,
            left: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.order.persona != null)
                  PixelCustomerSprite(
                    persona: widget.order.persona!,
                    speechText: widget.order.speechLine,
                    width: 140,
                    height: 140,
                    onTap: () {},
                  )
                else
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFF34495E),
                      borderRadius: BorderRadius.circular(55),
                      border: Border.all(color: Colors.amber, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        widget.order.customerAvatar,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Customer Speech Bubble
          Positioned(
            top: 18,
            left: 510,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PixelText(
                    widget.order.customerName,
                    size: 11,
                    color: const Color(0xFFD35400),
                  ),
                  const SizedBox(width: 6),
                  PixelText(
                    '"${widget.order.speechLine}"',
                    size: 11,
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
          ),

          // Mini Order List Chip
          Positioned(
            top: 60,
            left: 510,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E272C).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🛒 ', style: TextStyle(fontSize: 11)),
                  PixelText(
                    widget.order.items.entries.map((e) {
                      final item = GameConstants.itemById(e.key);
                      return '${item?.name ?? e.key} x${e.value}';
                    }).join(', '),
                    size: 10,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),

          // Wooden Window Sill Ledge
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 28,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9C6635),
                border: const Border(
                  top: BorderSide(color: Color(0xFFC48B55), width: 3),
                  bottom: BorderSide(color: Color(0xFF5A3515), width: 3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    offset: Offset(0, 4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBars({required int count}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF4A4A4A),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFF2B2B2B), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }),
    );
  }

  // ==========================================
  // SECTION 2: WOODEN COUNTER TABLE SURFACE
  // ==========================================
  Widget _buildWoodenCounterSurface() {
    return Container(
      key: _counterAreaKey,
      decoration: const BoxDecoration(
        color: Color(0xFF7A4A24),
        border: Border(
          top: BorderSide(color: Color(0xFFB07945), width: 3),
        ),
      ),
      child: Stack(
        children: [
          // Wooden plank grain lines
          Positioned.fill(
            child: CustomPaint(
              painter: _WoodPlankPainter(),
            ),
          ),

          // Hint label on the counter surface
          Positioned(
            top: 8,
            left: 280,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.touch_app, size: 14, color: Color(0xFFE0C49F)),
                const SizedBox(width: 4),
                const PixelText(
                  'LAMESA NG SUKLI (I-tap ang pera sa lamesa para bawiin):',
                  size: 9,
                  color: Color(0xFFE0C49F),
                ),
                if (_placedMoney.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _clearAllMoney,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC0392B),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white70),
                      ),
                      child: const PixelText(
                        'BAWIIN LAHAT',
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Placed Money items resting on the counter table
          ..._placedMoney.map((item) {
            return Positioned(
              left: 275 + item.position.dx,
              top: item.position.dy,
              child: GestureDetector(
                onTap: () => _removePlacedMoney(item),
                child: Transform.rotate(
                  angle: item.rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          offset: const Offset(3, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: item.isCoin
                        ? _buildCoinWidget(item.amount, size: 28)
                        : _buildBillWidget(
                            item.amount,
                            width: 82,
                            height: 44,
                          ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ==========================================
  // SECTION 3: CASH REGISTER & CRT MONITOR
  // ==========================================
  Widget _buildCashRegisterMachine(double expectedChange) {
    return SizedBox(
      width: 256,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Electronic Cash Register Body (Ivory/Beige vintage look)
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFDDD3C4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8D8070), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  offset: Offset(3, 5),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Register Pole Display (VFD Green screen: customer payment)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B0F),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: const Color(0xFF2ECC71), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const PixelText('PAID: ',
                                size: 9, color: Color(0xFF85929E)),
                            PixelText(
                              '₱${widget.order.paymentGiven.toStringAsFixed(2)}',
                              size: 13,
                              color: const Color(0xFF2ECC71),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Paper receipt roll slot
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: PixelText('RECEIPT', size: 6, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Register Numeric Keypad Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRegisterKey('7'),
                    _buildRegisterKey('8'),
                    _buildRegisterKey('9'),
                    _buildRegisterKey('C', color: const Color(0xFFE74C3C)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRegisterKey('4'),
                    _buildRegisterKey('5'),
                    _buildRegisterKey('6'),
                    _buildRegisterKey('SUB'),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRegisterKey('1'),
                    _buildRegisterKey('2'),
                    _buildRegisterKey('3'),
                    _buildRegisterKey('₱', color: const Color(0xFF27AE60)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. CRT / LCD Terminal Monitor Box (like reference concept art)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B232A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF34495E), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  offset: Offset(3, 4),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLcdRow(
                  'TOTAL:',
                  '₱${widget.order.totalCost.toStringAsFixed(2)}',
                  const Color(0xFFF1C40F),
                ),
                const SizedBox(height: 4),
                _buildLcdRow(
                  'PAID:',
                  '₱${widget.order.paymentGiven.toStringAsFixed(2)}',
                  const Color(0xFF3498DB),
                ),
                const SizedBox(height: 4),
                _buildLcdRow(
                  'CHANGE:',
                  '₱${expectedChange.toStringAsFixed(2)}',
                  const Color(0xFF2ECC71),
                ),
                const Divider(color: Color(0xFF2ECC71), height: 10, thickness: 1),
                _buildLcdRow(
                  'GIVEN:',
                  '₱${_changeTendered.toStringAsFixed(2)}',
                  _changeTendered == expectedChange
                      ? const Color(0xFF2ECC71)
                      : (_changeTendered > expectedChange
                          ? const Color(0xFFE74C3C)
                          : const Color(0xFFF39C12)),
                  isBold: true,
                ),
                const SizedBox(height: 6),

                // Dynamic Status Readout
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: PixelText(
                    _statusFeedback ??
                        (_changeTendered == expectedChange
                            ? '> TAMA NA! IABOT MO NA ✨'
                            : (_changeTendered == 0
                                ? '> PUMILI NG SUKLI SA KAHA'
                                : '> SUKLI: ₱${_changeTendered.toStringAsFixed(0)} / ₱${expectedChange.toStringAsFixed(0)}')),
                    size: 9,
                    color: _statusFeedbackColor,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterKey(String label, {Color? color}) {
    return Container(
      width: 44,
      height: 18,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF4A4A4A),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black38),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Center(
        child: PixelText(
          label,
          size: 9,
          color: Colors.white,
          hasShadow: false,
        ),
      ),
    );
  }

  Widget _buildLcdRow(String label, String value, Color valColor,
      {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PixelText(
          label,
          size: isBold ? 13 : 11,
          color: const Color(0xFFBDC3C7),
        ),
        PixelText(
          value,
          size: isBold ? 15 : 12,
          color: valColor,
        ),
      ],
    );
  }

  // ==========================================
  // SECTION 4: OPEN CASH DRAWER (KAHA)
  // ==========================================
  Widget _buildCashDrawer() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262C33),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF161A1F), width: 4),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            offset: Offset(0, 8),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper Row: 5 Vertical Bill Trays with Chrome Spring Clips
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _buildBillCompartment(20, const Color(0xFFE67E22)),
                  const SizedBox(width: 3),
                  _buildBillCompartment(50, const Color(0xFFE74C3C)),
                  const SizedBox(width: 3),
                  _buildBillCompartment(100, const Color(0xFF8E44AD)),
                  const SizedBox(width: 3),
                  _buildBillCompartment(500, const Color(0xFFF1C40F)),
                  const SizedBox(width: 3),
                  _buildBillCompartment(1000, const Color(0xFF2980B9)),
                ],
              ),
            ),
          ),

          // Divider between bill trays and coin wells
          Container(
            height: 3,
            color: const Color(0xFF161A1F),
          ),

          // Lower Row: 4 Coin Trays (Mga Barya)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  _buildCoinCompartment(1, '₱1 Silver'),
                  const SizedBox(width: 4),
                  _buildCoinCompartment(5, '₱5 Silver'),
                  const SizedBox(width: 4),
                  _buildCoinCompartment(10, '₱10 Gold'),
                  const SizedBox(width: 4),
                  _buildCoinCompartment(20, '₱20 Bimetal'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bill Compartment with authentic metal spring clip
  Widget _buildBillCompartment(int amount, Color themeColor) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey('bill_$amount'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _addMoneyWithAnimation(amount, false),
        child: Container(
          key: _billKeys[amount],
          decoration: BoxDecoration(
            color: const Color(0xFF1E2228),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF101317), width: 1.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Stacked Bills Background (depth effect)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 64,
                  height: 95,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                child: Container(
                  width: 66,
                  height: 97,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              // Top visible bill
              Positioned(
                bottom: 0,
                child: _buildBillWidget(
                  amount,
                  width: 68,
                  height: 100,
                  isVertical: true,
                ),
              ),

              // 2. Chrome Spring Clip over bills (like real cash drawers!)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ChromeSpringClipPainter(),
                  ),
                ),
              ),

              // 3. Denomination Badge at top
              Positioned(
                top: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: themeColor, width: 1),
                  ),
                  child: PixelText(
                    '₱$amount',
                    size: 9,
                    color: Colors.white,
                    hasShadow: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Coin Compartment Well
  Widget _buildCoinCompartment(int amount, String label) {
    return Expanded(
      child: GestureDetector(
        key: ValueKey('coin_$amount'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _addMoneyWithAnimation(amount, true),
        child: Container(
          key: _coinKeys[amount],
          decoration: BoxDecoration(
            color: const Color(0xFF1B1F24),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF0F1316), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Overlapping coin stack
              Positioned(
                bottom: 6,
                child: SizedBox(
                  width: 44,
                  height: 28,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 2,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: -0.12,
                          child: _buildCoinWidget(amount, size: 24),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 0,
                        child: Transform.rotate(
                          angle: 0.15,
                          child: _buildCoinWidget(amount, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Coin denomination label
              Positioned(
                top: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: PixelText(
                    '₱$amount',
                    size: 9,
                    color: Colors.amberAccent,
                    hasShadow: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SECTION 5: ACTION BUTTON (GIVE CHANGE)
  // ==========================================
  Widget _buildGiveChangeButton(double expectedChange) {
    final isReady = (_changeTendered - expectedChange).abs() < 0.01;

    return GestureDetector(
      onTap: _submitChange,
      child: Container(
        width: 145,
        height: 64,
        decoration: BoxDecoration(
          color: isReady ? const Color(0xFF27AE60) : const Color(0xFF2ECC71),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isReady ? const Color(0xFF58D68D) : const Color(0xFF27AE60),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: isReady
                  ? const Color(0xFF2ECC71).withValues(alpha: 0.6)
                  : Colors.black45,
              offset: const Offset(3, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PixelText(
                  'GIVE',
                  size: 14,
                  color: Colors.white,
                ),
                const PixelText(
                  'CHANGE',
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(height: 2),
                PixelText(
                  '(IABOT SUKLI)',
                  size: 8,
                  color: Colors.white.withValues(alpha: 0.9),
                  hasShadow: false,
                ),
              ],
            ),
            // Hand pointer icon (matching concept art!)
            const Positioned(
              right: 6,
              bottom: 4,
              child: Text(
                '👉',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    return GestureDetector(
      onTap: widget.onCancel,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFC0392B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white70, width: 2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(2, 2)),
          ],
        ),
        child: const Center(
          child: PixelText('✕', size: 14, color: Colors.white),
        ),
      ),
    );
  }

  // ==========================================
  // CURRENCY PIXEL ART RENDERERS
  // ==========================================
  Widget _buildBillWidget(int amount,
      {required double width, required double height, bool isVertical = false}) {
    Color primaryColor;
    Color secondaryColor;

    switch (amount) {
      case 20:
        primaryColor = const Color(0xFFE67E22);
        secondaryColor = const Color(0xFFD35400);
        break;
      case 50:
        primaryColor = const Color(0xFFE74C3C);
        secondaryColor = const Color(0xFFC0392B);
        break;
      case 100:
        primaryColor = const Color(0xFF8E44AD);
        secondaryColor = const Color(0xFF6C3483);
        break;
      case 500:
        primaryColor = const Color(0xFFF1C40F);
        secondaryColor = const Color(0xFFD4AC0D);
        break;
      case 1000:
      default:
        primaryColor = const Color(0xFF2980B9);
        secondaryColor = const Color(0xFF1F618D);
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: secondaryColor, width: 2),
        gradient: LinearGradient(
          begin: isVertical ? Alignment.topCenter : Alignment.centerLeft,
          end: isVertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Inner banknote border frame
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
            ),
          ),
          // Watermark circle
          Center(
            child: Container(
              width: height * 0.45,
              height: height * 0.45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
          ),
          // Denomination numbers
          Positioned(
            top: 3,
            left: 4,
            child: PixelText(
              '₱$amount',
              size: isVertical ? 9 : 11,
              color: Colors.white,
              hasShadow: true,
            ),
          ),
          Positioned(
            bottom: 3,
            right: 4,
            child: PixelText(
              '$amount',
              size: isVertical ? 8 : 10,
              color: Colors.white70,
              hasShadow: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinWidget(int amount, {required double size}) {
    Color outerColor;
    Color? innerColor;

    switch (amount) {
      case 1:
        outerColor = const Color(0xFFBDC3C7);
        break;
      case 5:
        outerColor = const Color(0xFFCFD8DC);
        break;
      case 10:
        outerColor = const Color(0xFFB0BEC5);
        innerColor = const Color(0xFFF39C12); // Gold center
        break;
      case 20:
      default:
        outerColor = const Color(0xFFE67E22); // Brass outer
        innerColor = const Color(0xFFCFD8DC); // Nickel center
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outerColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black45,
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            offset: Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: innerColor != null
          ? Center(
              child: Container(
                width: size * 0.65,
                height: size * 0.65,
                decoration: BoxDecoration(
                  color: innerColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PixelText(
                    '$amount',
                    size: size * 0.42,
                    color: Colors.black87,
                    hasShadow: false,
                  ),
                ),
              ),
            )
          : Center(
              child: PixelText(
                '$amount',
                size: size * 0.45,
                color: Colors.black87,
                hasShadow: false,
              ),
            ),
    );
  }
}

/// Custom painter for wooden counter grain and plank planks
class _WoodPlankPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A3515).withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal plank lines
    for (double y = 40; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Wood grain lines
    final grainPaint = Paint()
      ..color = const Color(0xFF8E562A).withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    for (double y = 18; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the chrome spring hold-down clips in the cash drawer
class _ChromeSpringClipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final chromePaint = Paint()
      ..color = const Color(0xFFECEFF1)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black45
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;

    // Spring wishbone / clip arm path
    final path = Path();
    path.moveTo(cx - 10, 16);
    path.lineTo(cx - 6, 48);
    path.lineTo(cx, 72);
    path.lineTo(cx + 6, 48);
    path.lineTo(cx + 10, 16);

    // Shadow
    canvas.drawPath(path.shift(const Offset(1, 1.5)), shadowPaint);
    // Chrome body
    canvas.drawPath(path, chromePaint);

    // Spring top coil loops
    final coilPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(cx - 10, 16), 3.0, coilPaint);
    canvas.drawCircle(Offset(cx + 10, 16), 3.0, coilPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
