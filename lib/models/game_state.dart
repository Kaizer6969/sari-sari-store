import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/sound_service.dart';

enum RestockResult {
  restocked,
  restockedAndBoxEmpty,
  shelfFull,
  wrongShelf,
  noBoxHeld,
}

class GameState extends ChangeNotifier {
  static const int maxShelfCapacity = 10;

  double money;
  int day;
  int hour; // 6 to 23
  int minute; // 0 to 59
  bool storeOpen;
  bool hasPermit;
  Map<String, int> inventory; // Live stock currently placed on store shelves
  Map<String, int> bodegaBoxes; // Sealed boxes stored on the back-room rack
  Map<String, int> garageBoxes; // Delivered boxes waiting on the Garage floor!
  Map<String, int> incomingDeliveryBoxes; // Boxes currently on the delivery truck
  Map<String, int> supermarketBought; // Cumulative stock bought from Supermarket/PC
  String? heldBoxItemId; // Item inside the box currently held by the player
  int heldBoxQty; // Remaining pcs inside the held box
  bool hasNewDeliveryAlert; // Pulses garage door when truck honks & delivers!
  int deliveryArrivalVersion; // Increments every time a delivery truck arrives
  Timer? _deliveryTimer;
  int reputation; // 0 to 100
  int totalSales;
  double totalEarned;
  int scammersRejected;
  int scammedCount;

  GameState({
    required this.money,
    required this.day,
    required this.hour,
    required this.minute,
    required this.storeOpen,
    required this.hasPermit,
    required this.inventory,
    Map<String, int>? bodegaBoxes,
    Map<String, int>? garageBoxes,
    Map<String, int>? incomingDeliveryBoxes,
    Map<String, int>? supermarketBought,
    this.heldBoxItemId,
    this.heldBoxQty = 0,
    this.hasNewDeliveryAlert = false,
    this.deliveryArrivalVersion = 0,
    required this.reputation,
    required this.totalSales,
    required this.totalEarned,
    required this.scammersRejected,
    required this.scammedCount,
  }) : bodegaBoxes = bodegaBoxes ?? {},
       garageBoxes = garageBoxes ?? {},
       incomingDeliveryBoxes = incomingDeliveryBoxes ?? {},
       supermarketBought = supermarketBought ?? {};

  /// Bagong Laro (New Game) constructor
  factory GameState.newGame() {
    return GameState(
      money: GameConstants.startingMoney,
      day: 1,
      hour: 6, // 6:00 AM start on Day 1
      minute: 0,
      storeOpen: false, // Player can open store using the sign
      hasPermit: false,
      inventory: GameConstants.startingInventory,
      reputation: 80, // Start with a decent neighborhood reputation
      totalSales: 0,
      totalEarned: 0.0,
      scammersRejected: 0,
      scammedCount: 0,
    );
  }

  // ── Helper Getters ──────────────────────────────────────────────────
  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  String get timeOfDayPeriod {
    if (hour >= 6 && hour < 11) return 'Umaga 🌅';
    if (hour >= 11 && hour < 14) return 'Tanghali ☀️';
    if (hour >= 14 && hour < 18) return 'Hapon 🌇';
    return 'Gabi 🌙';
  }

  int getStock(String itemId) {
    return inventory[itemId] ?? 0;
  }

  int getBoxStock(String itemId) {
    return bodegaBoxes[itemId] ?? 0;
  }

  int getGarageBoxStock(String itemId) {
    return garageBoxes[itemId] ?? 0;
  }

  bool get isHoldingBox => heldBoxItemId != null && heldBoxQty > 0;

  bool get hasIncomingDelivery =>
      incomingDeliveryBoxes.values.any((qty) => qty > 0);

  int get totalGarageBoxCount {
    int count = 0;
    for (final qty in garageBoxes.values) {
      if (qty > 0) count++;
    }
    return count;
  }

  int get totalGarageBoxItems {
    int total = 0;
    for (final qty in garageBoxes.values) {
      total += qty;
    }
    return total;
  }

  int get totalBodegaBoxItems {
    int total = 0;
    for (final qty in bodegaBoxes.values) {
      total += qty;
    }
    return total;
  }

  int get totalBodegaBoxCount {
    int count = 0;
    for (final qty in bodegaBoxes.values) {
      if (qty > 0) count++;
    }
    return count;
  }

  double get totalInventoryValue {
    double total = 0.0;
    inventory.forEach((itemId, qty) {
      final item = GameConstants.itemById(itemId);
      if (item != null) {
        total += item.retailPrice * qty;
      }
    });
    return total;
  }

  int get totalStockItems {
    int total = 0;
    inventory.values.forEach((qty) => total += qty);
    return total;
  }

  // ── Actions ─────────────────────────────────────────────────────────

  /// Pindutin ang signage para mag-open o close
  void toggleStore() {
    storeOpen = !storeOpen;
    notifyListeners();
  }

  /// Advance clock
  void advanceTime(int minutesToAdd) {
    minute += minutesToAdd;
    while (minute >= 60) {
      minute -= 60;
      hour += 1;
    }

    // Kung lumampas sa hatinggabi (12 AM)
    if (hour >= 24) {
      hour = 23;
      minute = 59;
      // Auto-close store at midnight
      if (storeOpen) {
        storeOpen = false;
      }
    }
    notifyListeners();
  }

  /// Bumili ng paninda sa supermarket (Direct stock add - kept for unit tests)
  bool buyStock(String itemId, int qty) {
    final item = GameConstants.itemById(itemId);
    if (item == null || qty <= 0) return false;

    // Check permit restriction
    if (item.needsPermit && !hasPermit) {
      return false;
    }

    final totalCost = item.wholesalePrice * qty;
    if (money < totalCost) return false;

    money -= totalCost;
    inventory[itemId] = (inventory[itemId] ?? 0) + qty;
    supermarketBought[itemId] = (supermarketBought[itemId] ?? 0) + qty;
    notifyListeners();
    return true;
  }

  /// Bumili ng bultuhang BOX sa supermarket -> mailalagay muna sa Storage Rack sa likod!
  bool buyWholesaleBox(String itemId, int qty) {
    final item = GameConstants.itemById(itemId);
    if (item == null || qty <= 0) return false;

    if (item.needsPermit && !hasPermit) {
      return false;
    }

    final totalCost = item.wholesalePrice * qty;
    if (money < totalCost) return false;

    money -= totalCost;
    bodegaBoxes[itemId] = (bodegaBoxes[itemId] ?? 0) + qty;
    supermarketBought[itemId] = (supermarketBought[itemId] ?? 0) + qty;
    notifyListeners();
    return true;
  }

  /// Umorder sa Computer -> Idideliver ng truck sa Garahe pagkatapos ng maikling sandali at bubusina ang truck!
  bool orderOnlineFromComputer(
    Map<String, int> cart, {
    Duration deliveryDelay = const Duration(seconds: 5),
    VoidCallback? onArrived,
  }) {
    if (cart.isEmpty) return false;

    double totalCost = 0.0;
    for (final entry in cart.entries) {
      final item = GameConstants.itemById(entry.key);
      if (item == null || entry.value <= 0) return false;
      if (item.needsPermit && !hasPermit) return false;
      totalCost += item.wholesalePrice * entry.value;
    }

    if (money < totalCost) return false;

    money -= totalCost;
    cart.forEach((itemId, qty) {
      incomingDeliveryBoxes[itemId] =
          (incomingDeliveryBoxes[itemId] ?? 0) + qty;
      supermarketBought[itemId] = (supermarketBought[itemId] ?? 0) + qty;
    });
    notifyListeners();

    _deliveryTimer?.cancel();
    if (deliveryDelay == Duration.zero) {
      deliverIncomingNow();
      onArrived?.call();
    } else {
      _deliveryTimer = Timer(deliveryDelay, () {
        deliverIncomingNow();
        onArrived?.call();
      });
    }
    return true;
  }

  /// Dumating na ang delivery truck sa Garahe -> bubusina ang truck at ilalapag lahat ng boxes sa Garahe!
  void deliverIncomingNow() {
    _deliveryTimer?.cancel();
    if (incomingDeliveryBoxes.isEmpty) return;

    incomingDeliveryBoxes.forEach((itemId, qty) {
      if (qty > 0) {
        garageBoxes[itemId] = (garageBoxes[itemId] ?? 0) + qty;
      }
    });
    incomingDeliveryBoxes.clear();
    hasNewDeliveryAlert = true;
    deliveryArrivalVersion += 1;

    // 🎺 Play real delivery truck air horn sound!
    SoundService.playTruckHorn();
    notifyListeners();
  }

  /// Linisin ang delivery alert badge kapag nakapasok na ang player sa Garahe
  void clearDeliveryAlert() {
    if (!hasNewDeliveryAlert) return;
    hasNewDeliveryAlert = false;
    notifyListeners();
  }

  /// Buhatin ang delivery box mula sa sahig ng Garahe
  bool pickUpGarageBox(String itemId) {
    final available = garageBoxes[itemId] ?? 0;
    if (available <= 0) return false;

    // Kung may hawak na ibang box, ibalik muna ito nang maayos sa Garahe
    if (isHoldingBox && heldBoxItemId != itemId) {
      garageBoxes[heldBoxItemId!] =
          (garageBoxes[heldBoxItemId!] ?? 0) + heldBoxQty;
      heldBoxItemId = null;
      heldBoxQty = 0;
    }

    if (heldBoxItemId == itemId) {
      heldBoxQty += available;
    } else {
      heldBoxItemId = itemId;
      heldBoxQty = available;
    }
    garageBoxes.remove(itemId);
    hasNewDeliveryAlert = false;
    notifyListeners();
    return true;
  }

  /// Ilapag pabalik sa sahig ng Garahe ang hawak na box
  void putDownHeldBoxToGarage() {
    if (!isHoldingBox) return;
    final id = heldBoxItemId!;
    garageBoxes[id] = (garageBoxes[id] ?? 0) + heldBoxQty;
    heldBoxItemId = null;
    heldBoxQty = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _deliveryTimer?.cancel();
    super.dispose();
  }

  /// Kunin / Buhatin ang box mula sa Storage Rack
  bool pickUpBox(String itemId) {
    final available = bodegaBoxes[itemId] ?? 0;
    if (available <= 0) return false;

    // Kung may hawak na ibang box, ibalik muna ito nang maayos sa rack
    if (isHoldingBox && heldBoxItemId != itemId) {
      bodegaBoxes[heldBoxItemId!] =
          (bodegaBoxes[heldBoxItemId!] ?? 0) + heldBoxQty;
      heldBoxItemId = null;
      heldBoxQty = 0;
    }

    if (heldBoxItemId == itemId) {
      heldBoxQty += available;
    } else {
      heldBoxItemId = itemId;
      heldBoxQty = available;
    }
    bodegaBoxes.remove(itemId);
    notifyListeners();
    return true;
  }

  /// Ilapag pabalik sa Storage Rack ang hawak na box
  void putDownHeldBox() {
    if (!isHoldingBox) return;
    final id = heldBoxItemId!;
    bodegaBoxes[id] = (bodegaBoxes[id] ?? 0) + heldBoxQty;
    heldBoxItemId = null;
    heldBoxQty = 0;
    notifyListeners();
  }

  /// Mag-restock ng 1 piraso mula sa hawak na box papunta sa tamang estante (ulit-ulitin hanggang mapuno!)
  RestockResult restockOneFromHeldBox(String targetItemId) {
    if (!isHoldingBox) return RestockResult.noBoxHeld;
    if (heldBoxItemId != targetItemId) return RestockResult.wrongShelf;

    final current = getStock(targetItemId);
    if (current >= maxShelfCapacity) return RestockResult.shelfFull;

    inventory[targetItemId] = current + 1;
    heldBoxQty -= 1;

    if (heldBoxQty <= 0) {
      heldBoxItemId = null;
      heldBoxQty = 0;
      notifyListeners();
      return RestockResult.restockedAndBoxEmpty;
    }

    notifyListeners();
    return RestockResult.restocked;
  }

  /// Magbenta sa customer (Retail)
  bool sellItem(String itemId, int qty) {
    final currentQty = inventory[itemId] ?? 0;
    if (currentQty < qty) return false;

    final item = GameConstants.itemById(itemId);
    if (item == null) return false;

    inventory[itemId] = currentQty - qty;
    final revenue = item.retailPrice * qty;
    money += revenue;
    totalEarned += revenue;
    totalSales += qty;
    notifyListeners();
    return true;
  }

  /// Kumuha ng permit sa Barangay Hall
  bool obtainPermit() {
    if (hasPermit) return true;
    if (money < GameConstants.permitCost) return false;

    money -= GameConstants.permitCost;
    hasPermit = true;
    reputation = (reputation + 10).clamp(0, 100);
    notifyListeners();
    return true;
  }

  /// Na-scam ng pekeng GCash
  void gotScammed(double amount) {
    scammedCount += 1;
    reputation = (reputation - 15).clamp(0, 100);
    notifyListeners();
  }

  void recordScammed(double amount) => gotScammed(amount);

  /// Nahuli o tinanggihan ang scammer
  void rejectedScammer() {
    scammersRejected += 1;
    reputation = (reputation + 5).clamp(0, 100);
    notifyListeners();
  }

  void recordScammerRejected() => rejectedScammer();

  /// Umalis ang customer dahil naubos ang 40-second timer
  void recordCustomerTimeout() {
    reputation = (reputation - 5).clamp(0, 100);
    notifyListeners();
  }

  /// Matagumpay na naasikaso ang customer bago maubos ang oras
  void recordCustomerServed() {
    reputation = (reputation + 1).clamp(0, 100);
    notifyListeners();
  }

  /// Simulan ang susunod na araw
  void startNewDay() {
    day += 1;
    hour = 6; // Starts at 6:00 AM everyday
    minute = 0;
    storeOpen = false;
    notifyListeners();
  }

  // ── JSON Serialization for Local Storage ────────────────────────────
  Map<String, dynamic> toJson() {
    return {
      'money': money,
      'day': day,
      'hour': hour,
      'minute': minute,
      'storeOpen': storeOpen,
      'hasPermit': hasPermit,
      'inventory': inventory,
      'bodegaBoxes': bodegaBoxes,
      'garageBoxes': {
        ...garageBoxes,
        for (final e in incomingDeliveryBoxes.entries)
          e.key: (garageBoxes[e.key] ?? 0) + e.value,
      },
      'supermarketBought': supermarketBought,
      'heldBoxItemId': heldBoxItemId,
      'heldBoxQty': heldBoxQty,
      'hasNewDeliveryAlert': hasNewDeliveryAlert,
      'reputation': reputation,
      'totalSales': totalSales,
      'totalEarned': totalEarned,
      'scammersRejected': scammersRejected,
      'scammedCount': scammedCount,
    };
  }

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      money: (json['money'] as num?)?.toDouble() ?? GameConstants.startingMoney,
      day: json['day'] as int? ?? 1,
      hour: json['hour'] as int? ?? 6,
      minute: json['minute'] as int? ?? 0,
      storeOpen: json['storeOpen'] as bool? ?? false,
      hasPermit: json['hasPermit'] as bool? ?? false,
      inventory: (json['inventory'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          GameConstants.startingInventory,
      bodegaBoxes: (json['bodegaBoxes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      garageBoxes: (json['garageBoxes'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      supermarketBought: (json['supermarketBought'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      heldBoxItemId: json['heldBoxItemId'] as String?,
      heldBoxQty: json['heldBoxQty'] as int? ?? 0,
      hasNewDeliveryAlert: json['hasNewDeliveryAlert'] as bool? ?? false,
      reputation: json['reputation'] as int? ?? 80,
      totalSales: json['totalSales'] as int? ?? 0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      scammersRejected: json['scammersRejected'] as int? ?? 0,
      scammedCount: json['scammedCount'] as int? ?? 0,
    );
  }

  String serialize() => jsonEncode(toJson());

  static GameState deserialize(String jsonStr) {
    return GameState.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}
