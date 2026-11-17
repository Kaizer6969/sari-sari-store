import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../services/save_manager.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_customer_sprite.dart';
import '../widgets/pixel_road_vehicle.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/scam_dialog.dart';
import 'map_screen.dart';
import 'inventory_screen.dart';
import 'title_screen.dart';

class StoreScreen extends StatefulWidget {
  final GameState gameState;

  const StoreScreen({super.key, required this.gameState});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  Timer? _inGameClockTimer;
  Timer? _customerSpawnTimer;
  Timer? _initSpawnTimer;
  Timer? _trafficTriggerTimer;
  CustomerOrder? _currentCustomer;
  String? _lastPersonaId;

  // Background Road Vehicle Animation
  late AnimationController _vehicleAnimController;
  VehicleType _currentVehicleType = VehicleType.jeepney;
  bool _vehicleMovingRight = true;
  bool _isVehicleActive = false;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    widget.gameState.storeOpen = true;

    // Vehicle Traffic Animation (moves across window in 5 seconds)
    _vehicleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4800),
    );

    _vehicleAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _isVehicleActive = false;
          });
        }
      }
    });

    _startTimers();

    // Spawn first customer after intro delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.gameState.storeOpen) {
        _initSpawnTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted &&
              widget.gameState.storeOpen &&
              _currentCustomer == null) {
            _spawnCustomer();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _initSpawnTimer?.cancel();
    _inGameClockTimer?.cancel();
    _customerSpawnTimer?.cancel();
    _trafficTriggerTimer?.cancel();
    _vehicleAnimController.dispose();
    super.dispose();
  }

  void _startTimers() {
    // In-game clock: 1 minute every 2.5 seconds
    _inGameClockTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      if (widget.gameState.storeOpen) {
        setState(() {
          widget.gameState.advanceTime(1);
        });
        SaveManager.saveGame(widget.gameState);
      }
    });

    // Customer arrival check every 5 seconds
    _customerSpawnTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (widget.gameState.storeOpen && _currentCustomer == null) {
        _checkCustomerArrival();
      }
    });

    // Background road traffic trigger every 11 seconds
    _trafficTriggerTimer = Timer.periodic(const Duration(seconds: 11), (_) {
      if (!mounted) return;
      if (!_isVehicleActive) {
        _triggerTraffic();
      }
    });
  }

  void _triggerTraffic() {
    if (!mounted) return;
    setState(() {
      _currentVehicleType =
          _rng.nextBool() ? VehicleType.jeepney : VehicleType.tricycle;
      _vehicleMovingRight = _rng.nextBool();
      _isVehicleActive = true;
    });
    _vehicleAnimController.forward(from: 0.0);
  }

  void _checkCustomerArrival() {
    final h = widget.gameState.hour;
    double chance = 0.50;
    if (h >= 6 && h <= 9) {
      chance = 0.85; // Morning rush
    } else if (h >= 11 && h <= 14) {
      chance = 0.65; // Lunch rush
    } else if (h >= 16 && h <= 18) {
      chance = 0.55; // Afternoon dismissal
    } else {
      chance = 0.30; // Night
    }

    if (_rng.nextDouble() < chance) {
      _spawnCustomer();
    }
  }

  void _spawnCustomer() {
    final inStockItems =
        widget.gameState.inventory.entries
            .where((entry) => entry.value > 0)
            .map((entry) => entry.key)
            .toList();

    if (inStockItems.isEmpty) return;

    // Filter out previous customer so customers never repeat consecutively
    final availablePersonas =
        CustomerPersona.allPersonas
            .where((p) => p.id != _lastPersonaId)
            .toList();
    final persona = availablePersonas[_rng.nextInt(availablePersonas.length)];
    _lastPersonaId = persona.id;

    final targetItem = persona.defaultItem;
    final itemId =
        inStockItems.contains(targetItem)
            ? targetItem
            : inStockItems[_rng.nextInt(inStockItems.length)];

    final currentStock = widget.gameState.getStock(itemId);
    final item = GameConstants.itemById(itemId);
    if (item == null || currentStock <= 0) return;

    final buyQty = (1 + _rng.nextInt(2)).clamp(1, currentStock);
    final totalBill = item.retailPrice * buyQty;

    final isNight = widget.gameState.hour >= 19 || widget.gameState.hour < 6;
    final isScammer =
        (persona.type == CustomerType.scammer) ||
        (_rng.nextDouble() < (isNight ? 0.30 : 0.10));
    final isGCash = isScammer || (_rng.nextDouble() < 0.25);

    double paymentGiven = totalBill;
    if (!isGCash) {
      final bills = [20, 50, 100, 200, 500, 1000];
      final valid = bills.where((b) => b >= totalBill).toList();
      paymentGiven = valid.isNotEmpty ? valid.first.toDouble() : totalBill;
    }

    String speech = persona.greeting;
    if (isGCash && !isScammer) {
      speech = 'Ate, bayad po ako sa GCash para bawas barya! 📱';
    }

    setState(() {
      _currentCustomer = CustomerOrder(
        persona: persona,
        customerName: persona.name,
        customerAvatar: _personaAvatar(persona.type),
        items: {itemId: buyQty},
        totalCost: totalBill,
        paymentGiven: paymentGiven,
        isGCash: isGCash,
        isScammer: isScammer,
        speechLine: speech,
      );
    });
  }

  String _personaAvatar(CustomerType type) {
    switch (type) {
      case CustomerType.customerGirl:
        return '👩';
      case CustomerType.mangBoy:
        return '👨';
      case CustomerType.bongbong:
        return '👦';
      case CustomerType.tinay:
        return '👧';
      case CustomerType.totoyTambay:
        return '🧢';
      case CustomerType.regularGuy:
        return '🧑';
      case CustomerType.scammer:
        return '🕶️';
      case CustomerType.lolaConching:
        return '👵';
      case CustomerType.alingNena:
        return '👩';
    }
  }

  void _serveCustomer() {
    if (_currentCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF34495E),
          duration: Duration(milliseconds: 1000),
          content: PixelText(
            'Walang customer sa bintana. Naghihintay ng bibili...',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
      return;
    }

    final customer = _currentCustomer!;
    if (customer.isGCash) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => ScamDialog(
              order: customer,
              fakeReason: 'Pending status at maling halaga ng pera!',
              onAccept: () {
                Navigator.pop(ctx);
                _handleGCashAccept(customer);
              },
              onReject: () {
                Navigator.pop(ctx);
                _handleGCashReject(customer);
              },
            ),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => TransactionDialog(
              order: customer,
              onCompleteSale: (changeGiven) {
                Navigator.pop(ctx);
                _completeCashSale(customer);
              },
              onCancel: () => Navigator.pop(ctx),
            ),
      );
    }
  }

  void _completeCashSale(CustomerOrder customer) {
    customer.items.forEach((itemId, qty) {
      widget.gameState.sellItem(itemId, qty);
    });
    widget.gameState.advanceTime(5);
    SaveManager.saveGame(widget.gameState);

    setState(() {
      _currentCustomer = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF27AE60),
        duration: const Duration(milliseconds: 1200),
        content: PixelText(
          'Salamat! Nabayaran ang ₱${customer.totalCost.toStringAsFixed(2)}',
          size: 11,
          color: Colors.white,
        ),
      ),
    );
  }

  void _handleGCashAccept(CustomerOrder customer) {
    if (customer.isScammer) {
      widget.gameState.recordScammed(customer.totalCost);
      customer.items.forEach((itemId, qty) {
        widget.gameState.sellItem(itemId, qty);
      });
      widget.gameState.advanceTime(5);
      SaveManager.saveGame(widget.gameState);

      setState(() {
        _currentCustomer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFC0392B),
          duration: Duration(milliseconds: 2500),
          content: PixelText(
            'NA-SCAM KA! Pekeng GCash pala! Nawala ang paninda at walang pumasok na pera!',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    } else {
      customer.items.forEach((itemId, qty) {
        widget.gameState.sellItem(itemId, qty);
      });
      widget.gameState.advanceTime(5);
      SaveManager.saveGame(widget.gameState);

      setState(() {
        _currentCustomer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2980B9),
          duration: const Duration(milliseconds: 1200),
          content: PixelText(
            'GCash Pumasok! +₱${customer.totalCost.toStringAsFixed(2)}',
            size: 11,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  void _handleGCashReject(CustomerOrder customer) {
    widget.gameState.advanceTime(3);
    if (customer.isScammer) {
      widget.gameState.recordScammerRejected();
      SaveManager.saveGame(widget.gameState);

      setState(() {
        _currentCustomer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFF39C12),
          duration: Duration(milliseconds: 2500),
          content: PixelText(
            'Galing mo! Nahuli mo ang scammer! +Reputasyon!',
            size: 11,
            color: Colors.white,
          ),
        ),
      );
    } else {
      SaveManager.saveGame(widget.gameState);

      setState(() {
        _currentCustomer = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF7F8C8D),
          duration: Duration(milliseconds: 1500),
          content: PixelText(
            'Tunay palang bayad pero tinanggihan. Umalis ang customer.',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  void _pleaseWaitCustomer() {
    if (_currentCustomer != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD35400),
          duration: const Duration(milliseconds: 1200),
          content: PixelText(
            'Sandali lang! Pinaghintay muna si ${_currentCustomer!.customerName}.',
            size: 10,
            color: Colors.white,
          ),
        ),
      );
    } else {
      // Toggle store open/close
      setState(() {
        widget.gameState.toggleStore();
        if (!widget.gameState.storeOpen) {
          _currentCustomer = null;
        }
      });
      SaveManager.saveGame(widget.gameState);
    }
  }

  void _openPauseMenu() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1E272C),
            shape: const BeveledRectangleBorder(
              side: BorderSide(color: Color(0xFFE84141), width: 3),
            ),
            title: const Center(
              child: PixelText(
                'TINDAHAN MENU',
                size: 16,
                color: Color(0xFFF1C40F),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Store Open/Close toggle
                PixelButton(
                  label:
                      widget.gameState.storeOpen
                          ? '🔴 ISARA ANG TINDAHAN'
                          : '🟢 BUKSAN ANG TINDAHAN',
                  fontSize: 11,
                  height: 42,
                  color:
                      widget.gameState.storeOpen
                          ? const Color(0xFFC0392B)
                          : const Color(0xFF27AE60),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      widget.gameState.toggleStore();
                      if (!widget.gameState.storeOpen) {
                        _currentCustomer = null;
                      }
                    });
                    SaveManager.saveGame(widget.gameState);
                  },
                ),
                const SizedBox(height: 10),

                // Open Map
                PixelButton(
                  label: '🗺️ BUKASAN ANG MAPA (Supermarket & Brgy)',
                  fontSize: 11,
                  height: 42,
                  color: const Color(0xFF2980B9),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(gameState: widget.gameState),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                const SizedBox(height: 10),

                // View Stock
                PixelButton(
                  label:
                      '📦 TINGNAN ANG PANINDA (${widget.gameState.totalStockItems})',
                  fontSize: 11,
                  height: 42,
                  color: const Color(0xFFD35400),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => InventoryScreen(gameState: widget.gameState),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                const SizedBox(height: 10),

                // Sleep
                PixelButton(
                  label: '🌙 MATULOG (Next Day 6:00 AM)',
                  fontSize: 11,
                  height: 42,
                  color: const Color(0xFF8E44AD),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentCustomer = null;
                      widget.gameState.startNewDay();
                    });
                    SaveManager.saveGame(widget.gameState);
                  },
                ),
                const SizedBox(height: 10),

                // Exit to Main Menu
                PixelButton(
                  label: '🚪 BALIK SA TITLE SCREEN',
                  fontSize: 11,
                  height: 42,
                  color: const Color(0xFF7F8C8D),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TitleScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  String _currentEncounterText() {
    if (!widget.gameState.storeOpen) {
      return 'SARADO ANG TINDAHAN (PAHINGA MUNA)';
    }
    final h = widget.gameState.hour;
    if (h >= 6 && h <= 9) {
      return 'RANDOM ENCOUNTER: MORNING RUSH';
    } else if (h >= 11 && h <= 14) {
      return 'RANDOM ENCOUNTER: TANGHALIAN & MERIENDA';
    } else if (h >= 16 && h <= 18) {
      return 'RANDOM ENCOUNTER: UWIAN NG ESTUDYANTE';
    } else {
      return 'NIGHT SHIFT: INGAT SA GCASH SCAMMER!';
    }
  }

  String _sunMoonIcon() {
    final h = widget.gameState.hour;
    if (h >= 6 && h < 17) return '☀️';
    if (h >= 17 && h < 19) return '🌇';
    return '🌙';
  }

  // Matching reference HUD Badge style
  Widget _buildTopBadge({
    required String text,
    String? icon,
    Color textColor = Colors.white,
    Color bgColor = const Color(0xFF2C3E50),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1B2631), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
          ],
          PixelText(
            text,
            size: 11.5,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(GameState state) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF1B2631), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, offset: Offset(1.5, 1.5)),
        ],
      ),
      child: Row(
        children: [
          const Text('❤️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (state.reputation / 100.0).clamp(0.0, 1.0),
                backgroundColor: const Color(0xFF1A1A1A),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE74C3C),
                ),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 4),
          PixelText('${state.reputation}%', size: 9, color: Colors.white),
        ],
      ),
    );
  }

  // Quick Action Shelf Pill
  Widget _buildShelfPill({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black45, offset: Offset(1, 1)),
          ],
        ),
        child: PixelText(
          label,
          size: 8.5,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.gameState;
    final hour = state.hour;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Window coordinates in 16-bit store art
          final windowLeft = w * 0.285;
          final windowTop = h * 0.315;
          final windowWidth = w * 0.365;
          final windowHeight = h * 0.405;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. BRAND NEW ORIGINAL 16-BIT PIXEL ART SARI-SARI STORE (Edge-to-Edge)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/own_pixel_store.png',
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none, // Crisp sharp pixel blocks
                ),
              ),

              // 2. OUTSIDE WINDOW SKY / DAY-NIGHT TINT LAYER
              Positioned(
                left: windowLeft,
                top: windowTop,
                width: windowWidth,
                height: windowHeight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Morning Sunrise Glow (6:00 AM - 7:59 AM)
                      if (hour >= 6 && hour < 8)
                        Positioned.fill(
                          child: Container(color: const Color(0x35FFB300)),
                        ),

                      // Golden Sunset / Afternoon Glow (4:30 PM - 6:30 PM)
                      if (hour >= 16 && hour < 18)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x65E65100), Color(0x40FF8F00)],
                              ),
                            ),
                          ),
                        ),

                      // Twilight / Dusk (6:30 PM - 7:30 PM)
                      if (hour >= 18 && hour < 19)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x751A237E), Color(0x554A148C)],
                              ),
                            ),
                          ),
                        ),

                      // Dark Night Sky with Twinkling Pixel Stars (7:30 PM - 5:30 AM)
                      if (hour >= 19 || hour < 6) ...[
                        Positioned.fill(
                          child: Container(color: const Color(0xB0050A1A)),
                        ),
                        // Twinkling Pixel Stars in night sky
                        Positioned(
                          left: windowWidth * 0.15,
                          top: windowHeight * 0.12,
                          child: const Text(
                            '✨',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                        Positioned(
                          left: windowWidth * 0.45,
                          top: windowHeight * 0.08,
                          child: const Text(
                            '⭐',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Positioned(
                          left: windowWidth * 0.75,
                          top: windowHeight * 0.15,
                          child: const Text(
                            '✨',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ),
                      ],

                      // 3. BACKGROUND ROAD TRAFFIC ANIMATION (Passing Jeepneys and Tricycles)
                      if (_isVehicleActive)
                        AnimatedBuilder(
                          animation: _vehicleAnimController,
                          builder: (context, child) {
                            final progress = _vehicleAnimController.value;
                            // Drive across window road
                            final startX =
                                _vehicleMovingRight
                                    ? -120.0
                                    : windowWidth + 20.0;
                            final endX =
                                _vehicleMovingRight
                                    ? windowWidth + 20.0
                                    : -120.0;
                            final currentX =
                                startX + (endX - startX) * progress;
                            final wheelFrame = ((progress * 30).toInt()) % 2;

                            return Positioned(
                              left: currentX,
                              top: windowHeight * 0.52,
                              child: PixelRoadVehicle(
                                type: _currentVehicleType,
                                movingRight: _vehicleMovingRight,
                                frame: wheelFrame,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // 4. OVERALL COZY STORE LIGHTING AT NIGHT
              if (hour >= 19 || hour < 6)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0.0, 0.1),
                          radius: 0.9,
                          colors: [Colors.transparent, Color(0x350A1128)],
                        ),
                      ),
                    ),
                  ),
                ),

              // 5. CUSTOMER AT WINDOW COUNTER (Standing right behind the counter sill)
              if (state.storeOpen && _currentCustomer != null) ...[
                () {
                  final custW = (w * 0.22).clamp(190.0, 310.0);
                  final custH = (h * 0.36).clamp(210.0, 350.0);
                  final custLeft = windowLeft + (windowWidth - custW) / 2;
                  final custTop = (windowTop + windowHeight) - custH + 8; // Anchor flush to wooden counter sill

                  return Positioned(
                    left: custLeft,
                    top: custTop,
                    child: PixelCustomerSprite(
                      persona: _currentCustomer!.persona ?? CustomerPersona.allPersonas.first,
                      isSpeaking: true,
                      speechText: _currentCustomer!.speechLine,
                      width: custW,
                      height: custH,
                      onTap: _serveCustomer,
                    ),
                  );
                }(),
              ],

              // 6. TOP UI HUD (MATCHING REFERENCE EXACTLY)
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    // [ DAY 1 / ARAW 1 ]
                    _buildTopBadge(
                      text: 'ARAW ${state.day}',
                      bgColor: const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: 8),

                    // [ 08:30 AM ☀️ ]
                    _buildTopBadge(
                      text: state.formattedTime,
                      icon: _sunMoonIcon(),
                      bgColor: const Color(0xFF2C3E50),
                    ),

                    const Spacer(),

                    // [ 🪙 ₱1,845.50 ]
                    _buildTopBadge(
                      text: '₱${state.money.toStringAsFixed(2)}',
                      icon: '🪙',
                      textColor: const Color(0xFFF1C40F),
                      bgColor: const Color(0xFF2C3E50),
                    ),
                    const SizedBox(width: 8),

                    // [ ❤️ Health / Reputation Bar ]
                    _buildHealthBar(state),
                  ],
                ),
              ),

              // 7. GOLDEN MARQUEE ENCOUNTER BANNER (Top Center)
              Positioned(
                top: 48,
                left: 90,
                right: 90,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF221C11),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFF1C40F),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        PixelText(
                          _currentEncounterText(),
                          size: 11,
                          color: const Color(0xFFF1C40F),
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(width: 8),
                        const Text('💡', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),

              // 8. QUICK ACCESS SHELF TABS (Top Right Shelf Area)
              Positioned(
                top: 50,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildShelfPill(
                      label: '🗺️ MAPA',
                      color: const Color(0xFF2980B9),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(gameState: state),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildShelfPill(
                      label: '📦 PANINDA (${state.totalStockItems})',
                      color: const Color(0xFFE67E22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoryScreen(gameState: state),
                          ),
                        ).then((_) => setState(() {}));
                      },
                    ),
                    _buildShelfPill(
                      label: '🌙 TULOG',
                      color: const Color(0xFF8E44AD),
                      onTap: () {
                        setState(() {
                          _currentCustomer = null;
                          state.startNewDay();
                        });
                        SaveManager.saveGame(state);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF2C3E50),
                            content: PixelText(
                              'Bagong araw na! Araw ${state.day} - 6:00 AM ☀️',
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildShelfPill(
                      label: '⚙️ MENU',
                      color: const Color(0xFF7F8C8D),
                      onTap: _openPauseMenu,
                    ),
                  ],
                ),
              ),

              // 9. STORE CLOSED NOTICE (If store is shut down)
              if (!state.storeOpen)
                Positioned(
                  left: windowLeft + (windowWidth - 280) / 2,
                  top: windowTop + windowHeight * 0.30,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xEE1E272C),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC0392B),
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black87, offset: Offset(3, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PixelText(
                          '🔒 NAKASARA ANG TINDAHAN',
                          size: 13,
                          color: Color(0xFFE74C3C),
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 5),
                        const PixelText(
                          'Pindutin ang [🔴 PLEASE WAIT] sa ibaba para magbukas muli!',
                          size: 10,
                          color: Colors.white70,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // 10. BOTTOM ACTION BUTTONS (MATCHING REFERENCE PHOTO EXACTLY)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // [ 🟢 SERVE CUSTOMER ]
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            _currentCustomer != null
                                ? '[ 🟢 SERVE CUSTOMER: ${_currentCustomer!.customerName.toUpperCase()} ]'
                                : '[ 🟢 SERVE CUSTOMER ]',
                        color: const Color(0xFF43A047),
                        height: 50,
                        fontSize: 12.5,
                        onPressed: _serveCustomer,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // [ 🔴 PLEASE WAIT ]
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            state.storeOpen
                                ? '[ 🔴 PLEASE WAIT ]'
                                : '[ 🟢 BUKSAN ANG TINDAHAN ]',
                        color:
                            state.storeOpen
                                ? const Color(0xFFE53935)
                                : const Color(0xFF2E7D32),
                        height: 50,
                        fontSize: 12.5,
                        onPressed: _pleaseWaitCustomer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
