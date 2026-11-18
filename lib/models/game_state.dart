import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class GameState extends ChangeNotifier {
  double money;
  int day;
  int hour; // 6 to 23
  int minute; // 0 to 59
  bool storeOpen;
  bool hasPermit;
  Map<String, int> inventory;
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
    required this.reputation,
    required this.totalSales,
    required this.totalEarned,
    required this.scammersRejected,
    required this.scammedCount,
  });

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

  /// Bumili ng paninda sa supermarket (Wholesale)
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
    notifyListeners();
    return true;
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
