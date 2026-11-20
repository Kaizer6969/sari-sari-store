import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../utils/item_image_data.dart';
import '../services/save_manager.dart';
import '../services/sound_service.dart';
import '../widgets/pixel_text.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_customer_sprite.dart';
import '../widgets/pixel_road_vehicle.dart';
import '../widgets/shelf_hotspot.dart';
import '../widgets/held_box_hud.dart';
import '../widgets/transaction_dialog.dart';
import '../widgets/scam_dialog.dart';
import 'map_screen.dart';
import 'inventory_screen.dart';
import 'back_room_screen.dart';
import 'garage_screen.dart';
import 'title_screen.dart';

class StoreScreen extends StatefulWidget {
  final GameState gameState;

  const StoreScreen({super.key, required this.gameState});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  static const int _maxCustomerSeconds = 40;

  Timer? _inGameClockTimer;
  Timer? _customerSpawnTimer;
  Timer? _initSpawnTimer;
  Timer? _initTrafficTimer;
  Timer? _trafficTriggerTimer;
  Timer? _customerPatienceTimer;
  Timer? _pickFeedbackTimer;
  CustomerOrder? _currentCustomer;
  String? _lastPersonaId;

  // Customer shopping list gathering & 40-second patience timer
  final Map<String, int> _pickedItems = {};
  int _customerTimeLeft = _maxCustomerSeconds;
  bool _isPausedForDialog = false;
  String? _lastPickedItemId;
  String? _lastRestockedItemId;
  String? _lastWrongItemId;

  int get _totalRequiredCount {
    final customer = _currentCustomer;
    if (customer == null) return 0;
    int sum = 0;
    for (final qty in customer.items.values) {
      sum += qty;
    }
    return sum;
  }

  int get _totalPickedCount {
    final customer = _currentCustomer;
    if (customer == null) return 0;
    int sum = 0;
    customer.items.forEach((itemId, needed) {
      sum += (_pickedItems[itemId] ?? 0).clamp(0, needed);
    });
    return sum;
  }

  bool get _allItemsPicked =>
      _currentCustomer != null &&
      _totalRequiredCount > 0 &&
      _totalPickedCount >= _totalRequiredCount;

  // Background Road Vehicle Animation
  late AnimationController _vehicleAnimController;
  VehicleType _currentVehicleType = VehicleType.jeepney;
  bool _vehicleMovingRight = true;
  bool _isVehicleActive = false;
  int _lastSeenDeliveryVersion = 0;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    widget.gameState.storeOpen = true;
    _lastSeenDeliveryVersion = widget.gameState.deliveryArrivalVersion;
    widget.gameState.addListener(_onGameStateChanged);

    // Vehicle Traffic Animation (smooth cruise across the street)
    _vehicleAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
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

    // Spawn first customer & first passing vehicle after intro delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.gameState.storeOpen) {
        _initSpawnTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted &&
              widget.gameState.storeOpen &&
              _currentCustomer == null) {
            _spawnCustomer();
          }
        });
        _initTrafficTimer = Timer(const Duration(milliseconds: 2800), () {
          if (mounted && !_isVehicleActive) {
            _triggerTraffic();
          }
        });
      }
    });
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    if (widget.gameState.deliveryArrivalVersion != _lastSeenDeliveryVersion) {
      _lastSeenDeliveryVersion = widget.gameState.deliveryArrivalVersion;
      if (ModalRoute.of(context)?.isCurrent ?? true) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD68910),
            duration: const Duration(milliseconds: 3000),
            content: PixelText(
              '🚚🎺 HONK! HONK! Dumating na ang delivery truck sa Garahe! Pindutin ang kaliwang pinto (🚪 GARAHE)!',
              size: 10.5,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.gameState.removeListener(_onGameStateChanged);
    _initSpawnTimer?.cancel();
    _initTrafficTimer?.cancel();
    _inGameClockTimer?.cancel();
    _customerSpawnTimer?.cancel();
    _trafficTriggerTimer?.cancel();
    _customerPatienceTimer?.cancel();
    _pickFeedbackTimer?.cancel();
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

    // Background road traffic trigger every 9 seconds
    _trafficTriggerTimer = Timer.periodic(const Duration(seconds: 9), (_) {
      if (!mounted) return;
      if (!_isVehicleActive) {
        _triggerTraffic();
      }
    });
  }

  void _triggerTraffic() {
    if (!mounted) return;
    const allVehicles = VehicleType.values;
    setState(() {
      _currentVehicleType = allVehicles[_rng.nextInt(allVehicles.length)];
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

  void _clearCurrentCustomer() {
    _customerPatienceTimer?.cancel();
    _pickFeedbackTimer?.cancel();
    _currentCustomer = null;
    _pickedItems.clear();
    _customerTimeLeft = _maxCustomerSeconds;
    _lastPickedItemId = null;
    _lastWrongItemId = null;
    _isPausedForDialog = false;
  }

  void _startCustomerPatienceTimer() {
    _customerPatienceTimer?.cancel();
    _customerTimeLeft = _maxCustomerSeconds;

    _customerPatienceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!widget.gameState.storeOpen ||
          _currentCustomer == null ||
          _isPausedForDialog) {
        return;
      }

      if (_customerTimeLeft <= 1) {
        _handleCustomerTimeout();
      } else {
        setState(() {
          _customerTimeLeft -= 1;
        });
      }
    });
  }

  void _handleCustomerTimeout() {
    final leavingName = _currentCustomer?.customerName ?? 'Customer';
    widget.gameState.recordCustomerTimeout();
    SaveManager.saveGame(widget.gameState);

    setState(() {
      _clearCurrentCustomer();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFC0392B),
        duration: const Duration(milliseconds: 2200),
        content: PixelText(
          '😤 Umalis si $leavingName! Naubos ang 40 segundo! (-5 Reputasyon)',
          size: 10.5,
          color: Colors.white,
        ),
      ),
    );
  }

  void _onShelfItemTapped(String itemId) {
    final state = widget.gameState;
    final item = GameConstants.itemById(itemId);
    if (item == null) return;

    // ── PRIORITY 1: RESTOCKING FROM HELD BOX (+1 per tap until full or empty!) ──
    if (state.isHoldingBox) {
      _pickFeedbackTimer?.cancel();
      if (state.heldBoxItemId == itemId) {
        final res = state.restockOneFromHeldBox(itemId);
        SaveManager.saveGame(state);

        if (res == RestockResult.restocked ||
            res == RestockResult.restockedAndBoxEmpty) {
          setState(() {
            _lastRestockedItemId = itemId;
            _lastPickedItemId = null;
            _lastWrongItemId = null;
          });
          _pickFeedbackTimer = Timer(const Duration(milliseconds: 350), () {
            if (mounted) {
              setState(() => _lastRestockedItemId = null);
            }
          });

          if (res == RestockResult.restockedAndBoxEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF27AE60),
                duration: const Duration(milliseconds: 1600),
                content: PixelText(
                  '✅ Ubos na ang laman ng box ng ${item.name}! (Stock: ${state.getStock(itemId)}/${GameState.maxShelfCapacity})',
                  size: 10.5,
                  color: Colors.white,
                ),
              ),
            );
          }
        } else if (res == RestockResult.shelfFull) {
          setState(() {
            _lastWrongItemId = itemId;
            _lastRestockedItemId = null;
          });
          _pickFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
            if (mounted) {
              setState(() => _lastWrongItemId = null);
            }
          });
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFD35400),
              duration: const Duration(milliseconds: 1500),
              content: PixelText(
                '📦 PUNO NA ang lalagyan ng ${item.name}! (${GameState.maxShelfCapacity}/${GameState.maxShelfCapacity}) Ilapag ang sobra sa Rack sa likod.',
                size: 10,
                color: Colors.white,
              ),
            ),
          );
        }
        return;
      } else if (!state.storeOpen || _currentCustomer == null) {
        // Holding another item's box while no customer is waiting
        final heldItem = GameConstants.itemById(state.heldBoxItemId!);
        final heldName = heldItem?.name ?? state.heldBoxItemId!;
        setState(() {
          _lastWrongItemId = itemId;
          _lastRestockedItemId = null;
        });
        _pickFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
          if (mounted) {
            setState(() => _lastWrongItemId = null);
          }
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD35400),
            duration: const Duration(milliseconds: 1300),
            content: PixelText(
              '📦 Hawak mo ang box ng $heldName! Pindutin ang lalagyan ng $heldName para mag-restock!',
              size: 10,
              color: Colors.white,
            ),
          ),
        );
        return;
      }
    }

    // ── PRIORITY 2: GRABBING ITEMS FOR WAITING CUSTOMER'S SHOPPING LIST ──
    if (!state.storeOpen || _currentCustomer == null) return;
    if (_allItemsPicked) {
      _serveCustomer();
      return;
    }

    final customer = _currentCustomer!;
    final needed = customer.items[itemId] ?? 0;
    final picked = _pickedItems[itemId] ?? 0;

    _pickFeedbackTimer?.cancel();

    if (needed > 0 && picked < needed) {
      setState(() {
        _pickedItems[itemId] = picked + 1;
        _lastPickedItemId = itemId;
        _lastWrongItemId = null;
      });

      _pickFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() {
            _lastPickedItemId = null;
          });
        }
      });

      if (_allItemsPicked) {
        _speakCustomer(customer, customText: 'Salamat! Magkano po lahat?');
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF27AE60),
            duration: const Duration(milliseconds: 1600),
            content: PixelText(
              '✅ Kumpleto na ang order ni ${customer.customerName}! Pindutin ang 🛍️ HANDA NA o ang customer para ibenta!',
              size: 10.5,
              color: Colors.white,
            ),
          ),
        );
      }
    } else {
      setState(() {
        _lastWrongItemId = itemId;
        _lastPickedItemId = null;
      });

      _pickFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() {
            _lastWrongItemId = null;
          });
        }
      });

      final msg =
          needed > 0
              ? 'Kumpleto na ang ${item.name} sa listahan!'
              : 'Hindi kasama ang ${item.name} sa listahan ni ${customer.customerName}!';

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD35400),
          duration: const Duration(milliseconds: 1100),
          content: PixelText(msg, size: 10, color: Colors.white),
        ),
      );
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

    // Build a multi-item shopping list (2 to 3 distinct items, or fewer if stock is low)
    final desiredKinds =
        inStockItems.length >= 3
            ? (2 + _rng.nextInt(2)) // 2 or 3 distinct items
            : inStockItems.length;

    final chosenIds = <String>[];
    if (inStockItems.contains(persona.defaultItem)) {
      chosenIds.add(persona.defaultItem);
    }

    final remainingPool =
        inStockItems.where((id) => !chosenIds.contains(id)).toList()
          ..shuffle(_rng);
    for (final id in remainingPool) {
      if (chosenIds.length >= desiredKinds) break;
      chosenIds.add(id);
    }

    final orderItems = <String, int>{};
    double totalBill = 0.0;
    final itemLabels = <String>[];

    for (final itemId in chosenIds) {
      final currentStock = widget.gameState.getStock(itemId);
      final item = GameConstants.itemById(itemId);
      if (item == null || currentStock <= 0) continue;

      // Allow qty 1-2 for small/cheap items, qty 1 for bulky items
      final isSmallItem =
          itemId == 'candy' || itemId == 'kape' || itemId == 'itlog';
      final qty =
          (isSmallItem && currentStock >= 2 && _rng.nextBool()) ? 2 : 1;

      orderItems[itemId] = qty;
      totalBill += item.retailPrice * qty;
      itemLabels.add(item.name.split(' ').first);
    }

    if (orderItems.isEmpty) return;

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

    final listPreview =
        itemLabels.length == 1
            ? itemLabels.first
            : '${itemLabels.sublist(0, itemLabels.length - 1).join(', ')} at ${itemLabels.last}';

    final String speech;
    if (isScammer) {
      speech = 'Pabili ng $listPreview — naka-GCash na! 📱';
    } else if (isGCash) {
      speech = 'Pabili pong $listPreview! GCash bayad 📱';
    } else {
      speech = 'Pabili po ng $listPreview! 📝';
    }

    setState(() {
      _pickedItems.clear();
      _lastPickedItemId = null;
      _lastWrongItemId = null;
      _isPausedForDialog = false;
      _currentCustomer = CustomerOrder(
        persona: persona,
        customerName: persona.name,
        customerAvatar: _personaAvatar(persona.type),
        items: orderItems,
        totalCost: totalBill,
        paymentGiven: paymentGiven,
        isGCash: isGCash,
        isScammer: isScammer,
        speechLine: speech,
      );
    });

    _startCustomerPatienceTimer();
    if (_currentCustomer != null) {
      _speakCustomer(_currentCustomer!);
    }
  }

  double _customerVoicePitch(CustomerType? type) {
    if (type == null) return 1.0;
    switch (type) {
      case CustomerType.bongbong:
        return 1.45;
      case CustomerType.tinay:
        return 1.35;
      case CustomerType.customerGirl:
        return 1.15;
      case CustomerType.mangBoy:
        return 0.85;
      case CustomerType.totoyTambay:
        return 1.05;
      case CustomerType.regularGuy:
        return 0.95;
      case CustomerType.scammer:
        return 1.25;
      case CustomerType.lolaConching:
        return 0.90;
      case CustomerType.alingNena:
        return 1.10;
    }
  }

  double _customerVoiceRate(CustomerType? type) {
    if (type == null) return 1.0;
    switch (type) {
      case CustomerType.scammer:
        return 1.20;
      case CustomerType.bongbong:
      case CustomerType.tinay:
        return 1.05;
      case CustomerType.lolaConching:
        return 0.85;
      case CustomerType.mangBoy:
        return 0.95;
      default:
        return 1.0;
    }
  }

  void _speakCustomer(CustomerOrder customer, {String? customText}) {
    final text = customText ?? customer.speechLine;
    final pitch = _customerVoicePitch(customer.persona?.type);
    final rate = _customerVoiceRate(customer.persona?.type);
    SoundService.speakCustomerText(text, pitch: pitch, rate: rate);
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

    // Must gather ALL items from the store shelves before selling!
    if (!_allItemsPicked) {
      if (_currentCustomer != null) {
        _speakCustomer(_currentCustomer!);
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFD35400),
          duration: const Duration(milliseconds: 1500),
          content: PixelText(
            '📦 Kunin muna lahat ng paninda sa estante! ($_totalPickedCount/$_totalRequiredCount pa lang)',
            size: 10.5,
            color: Colors.white,
          ),
        ),
      );
      return;
    }

    final customer = _currentCustomer!;
    setState(() {
      _isPausedForDialog = true;
    });

    if (customer.isGCash) {
      _speakCustomer(customer, customText: 'Naka GCash na po ako!');
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
      _speakCustomer(customer, customText: 'Magkano po lahat?');
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
              onCancel: () {
                Navigator.pop(ctx);
                if (mounted) {
                  setState(() {
                    _isPausedForDialog = false;
                  });
                }
              },
            ),
      );
    }
  }

  void _completeCashSale(CustomerOrder customer) {
    customer.items.forEach((itemId, qty) {
      widget.gameState.sellItem(itemId, qty);
    });
    widget.gameState.recordCustomerServed();
    widget.gameState.advanceTime(5);
    SaveManager.saveGame(widget.gameState);

    setState(() {
      _clearCurrentCustomer();
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
        _clearCurrentCustomer();
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
      widget.gameState.recordCustomerServed();
      widget.gameState.advanceTime(5);
      SaveManager.saveGame(widget.gameState);

      setState(() {
        _clearCurrentCustomer();
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
        _clearCurrentCustomer();
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
        _clearCurrentCustomer();
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

  void _goToBackRoom() {
    setState(() {
      _isPausedForDialog = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BackRoomScreen(gameState: widget.gameState),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _isPausedForDialog = false;
        if (!widget.gameState.storeOpen) {
          _clearCurrentCustomer();
        }
      });
    });
  }

  void _goToGarage() {
    setState(() {
      _isPausedForDialog = true;
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GarageScreen(gameState: widget.gameState),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() {
        _isPausedForDialog = false;
      });
    });
  }

  void _toggleStoreOpenClose() {
    setState(() {
      widget.gameState.toggleStore();
      if (!widget.gameState.storeOpen) {
        _clearCurrentCustomer();
      }
    });
    SaveManager.saveGame(widget.gameState);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            widget.gameState.storeOpen
                ? const Color(0xFF27AE60)
                : const Color(0xFFC0392B),
        duration: const Duration(milliseconds: 1100),
        content: PixelText(
          widget.gameState.storeOpen
              ? '🟢 Bukas na ang tindahan! Handa na sa mga bibili!'
              : '🔴 Nakasara muna ang tindahan.',
          size: 10.5,
          color: Colors.white,
        ),
      ),
    );
  }

  void _openPauseMenu() {
    setState(() {
      _isPausedForDialog = true;
    });
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
                        _clearCurrentCustomer();
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
                    setState(() => _isPausedForDialog = true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapScreen(gameState: widget.gameState),
                      ),
                    ).then((_) {
                      if (mounted) setState(() => _isPausedForDialog = false);
                    });
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
                    setState(() => _isPausedForDialog = true);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => InventoryScreen(gameState: widget.gameState),
                      ),
                    ).then((_) {
                      if (mounted) setState(() => _isPausedForDialog = false);
                    });
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
                      _clearCurrentCustomer();
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
    ).then((_) {
      if (mounted) {
        setState(() {
          _isPausedForDialog = false;
        });
      }
    });
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

          // Exact open window aperture in own_pixel_store.png (1376x768)
          // Left shutter inner edge: 480/1376, Right shutter inner edge: 893/1376
          // Top lintel bottom edge: 278/768, Wooden sill back edge: 553/768
          final windowLeft = w * 0.349;
          final windowTop = h * 0.362;
          final windowWidth = w * 0.300;
          final windowHeight = h * 0.358;

          // Customer standing outside behind the wooden window sill
          final activePersona =
              _currentCustomer?.persona ?? CustomerPersona.allPersonas.first;
          final isKid = activePersona.type == CustomerType.bongbong;
          final custH = windowHeight * (isKid ? 0.60 : 0.70);
          final custW = custH * 1.32;
          final custCenterX = windowWidth * 0.43;
          final custLeftInWindow = custCenterX - (custW / 2);
          final sillTuck = custH * 0.08;
          final visibleCustH = custH - sillTuck;
          final custHeadTopY = (windowTop + windowHeight) - visibleCustH;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 16-BIT PIXEL ART SARI-SARI STORE (Open Shutters vs Closed Bolted Shutters!)
              // Products are rendered dynamically on top based on live inventory!
              Positioned.fill(
                child: Image.memory(
                  state.storeOpen
                      ? ItemImageData.emptyStoreBgBytes
                      : ItemImageData.closedStoreBgBytes,
                  gaplessPlayback: true,
                  width: w,
                  height: h,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none, // Crisp sharp pixel blocks
                ),
              ),

              // 2. OUTSIDE WINDOW APERTURE (Only visible when window shutters are OPEN!)
              if (state.storeOpen)
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
                          child: Container(color: const Color(0x28FFB300)),
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

                      // 3. BACKGROUND ROAD TRAFFIC ANIMATION (16-Bit Jeepney, Tricycle & Delivery Motor)
                      // Sized & grounded to match the blue tricycle in own_pixel_store.png (height ~53% of window, tires near bottom sill)
                      if (_isVehicleActive)
                        AnimatedBuilder(
                          animation: _vehicleAnimController,
                          builder: (context, child) {
                            final progress = _vehicleAnimController.value;

                            // Match exact scale of the parked blue tricycle (0.531 * windowHeight)
                            final double vehicleH;
                            final double roadBottomOffset;
                            switch (_currentVehicleType) {
                              case VehicleType.jeepney:
                                vehicleH = windowHeight * 0.56;
                                roadBottomOffset = windowHeight * 0.04;
                                break;
                              case VehicleType.tricycle:
                                vehicleH = windowHeight * 0.51;
                                roadBottomOffset = windowHeight * 0.05;
                                break;
                              case VehicleType.motorcycle:
                                vehicleH = windowHeight * 0.44;
                                roadBottomOffset = windowHeight * 0.06;
                                break;
                            }

                            final wheelFrame = ((progress * 26).toInt()) % 2;
                            final vehicleWidget = PixelRoadVehicle(
                              type: _currentVehicleType,
                              movingRight: _vehicleMovingRight,
                              height: vehicleH,
                              frame: wheelFrame,
                            );
                            final vehicleW = vehicleWidget.computedWidth;

                            // Smoothly enter from outside one shutter edge and exit past the other
                            final startX =
                                _vehicleMovingRight
                                    ? -vehicleW - 12.0
                                    : windowWidth + 12.0;
                            final endX =
                                _vehicleMovingRight
                                    ? windowWidth + 12.0
                                    : -vehicleW - 12.0;
                            final currentX =
                                startX + (endX - startX) * progress;

                            return Positioned(
                              left: currentX,
                              bottom: roadBottomOffset,
                              child: vehicleWidget,
                            );
                          },
                        ),

                      // 4. CUSTOMER STANDING OUTSIDE BEHIND THE WOODEN WINDOW SILL
                      if (state.storeOpen && _currentCustomer != null) ...[
                        Positioned(
                          left: custLeftInWindow,
                          bottom: -sillTuck,
                          child: PixelCustomerSprite(
                            persona: activePersona,
                            isSpeaking:
                                false, // Speech bubble rendered cleanly above window clip
                            speechText: _currentCustomer!.speechLine,
                            width: custW,
                            height: custH,
                            onTap: _serveCustomer,
                          ),
                        ),
                        // Subtle sill contact shadow so customer sits naturally behind the wooden sill
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          height: 7,
                          child: IgnorePointer(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0x55000000),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 5. DYNAMIC LIVE INVENTORY ON SHELVES, HANGING ROD & COUNTER
              // Only items you currently have in stock appear (plus active restock target when holding a box!)
              for (final zone in ShelfHotspotZone.allZones)
                () {
                  final item = GameConstants.itemById(zone.itemId);
                  if (item == null) return const SizedBox.shrink();

                  final totalStock = state.getStock(zone.itemId);
                  final picked = _pickedItems[zone.itemId] ?? 0;
                  final visibleStock = (totalStock - picked).clamp(0, 999);
                  final isRestockTarget =
                      state.isHoldingBox && state.heldBoxItemId == zone.itemId;
                  final isPicking =
                      state.storeOpen &&
                      _currentCustomer != null &&
                      !_allItemsPicked;
                  final needed = _currentCustomer?.items[zone.itemId] ?? 0;
                  final stillNeedsThis = needed > 0 && picked < needed;
                  final showUrgentHint =
                      isPicking && stillNeedsThis && _customerTimeLeft <= 12;

                  return Positioned(
                    left: w * zone.leftFrac,
                    top: h * zone.topFrac,
                    width: w * zone.widthFrac,
                    height: h * zone.heightFrac,
                    child: DynamicShelfStockWidget(
                      zone: zone,
                      item: item,
                      visibleStock: visibleStock,
                      maxCapacity: GameState.maxShelfCapacity,
                      screenHeight: h,
                      isInteractive: isPicking || state.isHoldingBox,
                      isRestockTarget: isRestockTarget,
                      showUrgentHint: showUrgentHint,
                      justPicked: _lastPickedItemId == zone.itemId,
                      justRestocked: _lastRestockedItemId == zone.itemId,
                      justWrong: _lastWrongItemId == zone.itemId,
                      onTap: () => _onShelfItemTapped(zone.itemId),
                    ),
                  );
                }(),

              // 5A. CLICKABLE LEFT WOODEN DOOR -> OPENS GARAGE (GARAHE) FOR DELIVERIES!
              Positioned(
                left: 0,
                top: h * 0.12,
                width: w * 0.135,
                height: h * 0.80,
                child: GestureDetector(
                  onTap: _goToGarage,
                  behavior: HitTestBehavior.opaque,
                  child: Align(
                    alignment: const Alignment(0.0, 0.25),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (state.hasNewDeliveryAlert ||
                                    state.totalGarageBoxCount > 0)
                                ? const Color(0xF5D68910)
                                : const Color(0xD93E2723),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color:
                              (state.hasNewDeliveryAlert ||
                                      state.totalGarageBoxCount > 0)
                                  ? const Color(0xFFFFF176)
                                  : const Color(0xFFD7CCC8),
                          width:
                              (state.hasNewDeliveryAlert ||
                                      state.totalGarageBoxCount > 0)
                                  ? 2.2
                                  : 1.4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PixelText(
                            state.totalGarageBoxCount > 0
                                ? '🚚 GARAHE'
                                : '🚪 GARAHE',
                            size: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          if (state.totalGarageBoxCount > 0) ...[
                            const SizedBox(height: 2),
                            PixelText(
                              '📦 ${state.totalGarageBoxCount} Box!',
                              size: 8.5,
                              color: const Color(0xFFFFF176),
                              fontWeight: FontWeight.bold,
                            ),
                          ] else if (state.hasIncomingDelivery) ...[
                            const SizedBox(height: 2),
                            const PixelText(
                              '🚚 Paparating...',
                              size: 7.5,
                              color: Color(0xFFFFE082),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 5B. OVERALL COZY STORE LIGHTING AT NIGHT (IgnorePointer so shelves stay tappable!)
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

              // 6B. PACKED ORDER BAG ON COUNTER (Once all items are gathered, ready to sell!)
              if (state.storeOpen &&
                  _currentCustomer != null &&
                  _allItemsPicked)
                Positioned(
                  left: w * 0.380,
                  top: h * 0.67,
                  child: GestureDetector(
                    onTap: _serveCustomer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xF027AE60),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black87,
                            offset: Offset(2, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🛍️', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 5),
                          PixelText(
                            'HANDA NA! IBENTA ▶',
                            size: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 6C. CUSTOMER SPEECH BUBBLE (Floating cleanly above customer's head)
              if (state.storeOpen && _currentCustomer != null)
                Positioned(
                  left: (windowLeft + custCenterX - 110).clamp(12.0, w - 232.0),
                  width: 220,
                  bottom: (h - custHeadTopY + 4).clamp(12.0, h - 80.0),
                  child: Center(
                    child: PixelSpeechBubble(
                      text:
                          _allItemsPicked
                              ? 'Salamat! Magkano po lahat? 💵'
                              : _currentCustomer!.speechLine,
                      onTap: _serveCustomer,
                    ),
                  ),
                ),

              // 6D. CUSTOMER ORDER CHECKLIST + 40s PATIENCE TIMER CARD (Left side over rehas)
              if (state.storeOpen && _currentCustomer != null)
                Positioned(
                  left: 12,
                  top: 94,
                  child: CustomerOrderChecklistCard(
                    customerName: _currentCustomer!.customerName,
                    requiredItems: _currentCustomer!.items,
                    pickedItems: _pickedItems,
                    secondsLeft: _customerTimeLeft,
                    maxSeconds: _maxCustomerSeconds,
                    allPicked: _allItemsPicked,
                    onServeTap: _serveCustomer,
                  ),
                ),

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
                        setState(() => _isPausedForDialog = true);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MapScreen(gameState: state),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() => _isPausedForDialog = false);
                          }
                        });
                      },
                    ),
                    _buildShelfPill(
                      label: '📦 PANINDA (${state.totalStockItems})',
                      color: const Color(0xFFE67E22),
                      onTap: () {
                        setState(() => _isPausedForDialog = true);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoryScreen(gameState: state),
                          ),
                        ).then((_) {
                          if (mounted) {
                            setState(() => _isPausedForDialog = false);
                          }
                        });
                      },
                    ),
                    _buildShelfPill(
                      label: '🌙 TULOG',
                      color: const Color(0xFF8E44AD),
                      onTap: () {
                        setState(() {
                          _clearCurrentCustomer();
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
                          'Pindutin ang [🟢 BUKSAN ANG TINDAHAN] sa ibaba para magbukas muli!',
                          size: 10,
                          color: Colors.white70,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // 10. BOTTOM ACTION BUTTONS (LEFT: Arrow to Back Room | RIGHT: Close / Open Store)
              // 9B. HELD BOX FLOATING HUD (When carrying a box from the Storage Rack to restock!)
              if (state.isHoldingBox)
                Positioned(
                  bottom: 68,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: HeldBoxHudBanner(
                      gameState: state,
                      hintText: 'Pindutin ang berdeng estante (+1 kada pindot)!',
                    ),
                  ),
                ),

              // 10. BOTTOM ACTION BUTTONS (LEFT: Arrow to Back Room | RIGHT: Close / Open Store)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // LEFT BUTTON: Arrow going to the back of the store (Ref & Storage Rack)
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            state.totalBodegaBoxCount > 0
                                ? '[ ⬅️ PUNTA SA LIKOD (📦 ${state.totalBodegaBoxCount}) ]'
                                : '[ ⬅️ PUNTA SA LIKOD ]',
                        color: const Color(0xFF2980B9),
                        height: 50,
                        fontSize: 12.5,
                        onPressed: _goToBackRoom,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // RIGHT BUTTON: Close or Open the Store
                    Expanded(
                      flex: 1,
                      child: PixelButton(
                        label:
                            state.storeOpen
                                ? '[ 🔴 ISARA ANG TINDAHAN ]'
                                : '[ 🟢 BUKSAN ANG TINDAHAN ]',
                        color:
                            state.storeOpen
                                ? const Color(0xFFE53935)
                                : const Color(0xFF2E7D32),
                        height: 50,
                        fontSize: 12.5,
                        onPressed: _toggleStoreOpenClose,
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
