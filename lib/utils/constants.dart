import 'package:flutter/material.dart';

class Item {
  final String id;
  final String name;
  final String emoji;
  final double retailPrice;
  final double wholesalePrice;
  final bool needsPermit;
  final Color primaryColor;
  final Color secondaryColor;

  const Item({
    required this.id,
    required this.name,
    required this.emoji,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.needsPermit,
    required this.primaryColor,
    required this.secondaryColor,
  });
}

class GameConstants {
  GameConstants._();

  // ── Rendering ──────────────────────────────────────────────────────
  static const double kPixelSize = 4.0;

  // ── Economy ────────────────────────────────────────────────────────
  static const double startingMoney = 500.0;
  static const double permitCost = 200.0;
  static const double scammerProbability = 0.15;

  // ── Denominations ──────────────────────────────────────────────────
  static const List<int> billDenominations = [1000, 500, 200, 100, 50, 20];
  static const List<int> coinDenominations = [10, 5, 1];

  // ── Customer spawn rates (customers per in-game hour) ──────────────
  /// Returns expected customers for a given hour (6-23).
  static double customerSpawnRate(int hour) {
    if (hour >= 6 && hour <= 9) return 5.0;   // high – morning rush
    if (hour >= 10 && hour <= 14) return 3.0;  // medium – midday
    if (hour >= 15 && hour <= 18) return 2.5;  // medium-low – afternoon
    return 1.5;                                 // low – evening
  }

  // ── Store Items ────────────────────────────────────────────────────
  static const List<Item> allItems = [
    Item(
      id: 'yosi',
      name: 'Yosi',
      emoji: '🚬',
      retailPrice: 10,
      wholesalePrice: 7,
      needsPermit: true,
      primaryColor: Color(0xFFD4A373),
      secondaryColor: Color(0xFF8B5E3C),
    ),
    Item(
      id: 'kape',
      name: 'Kape',
      emoji: '☕',
      retailPrice: 8,
      wholesalePrice: 5,
      needsPermit: false,
      primaryColor: Color(0xFF6F4E37),
      secondaryColor: Color(0xFF3B2F2F),
    ),
    Item(
      id: 'shampoo',
      name: 'Shampoo',
      emoji: '🧴',
      retailPrice: 7,
      wholesalePrice: 4,
      needsPermit: false,
      primaryColor: Color(0xFF5B9BD5),
      secondaryColor: Color(0xFF2E75B6),
    ),
    Item(
      id: 'sabon',
      name: 'Sabon',
      emoji: '🧼',
      retailPrice: 15,
      wholesalePrice: 10,
      needsPermit: false,
      primaryColor: Color(0xFFA8D8EA),
      secondaryColor: Color(0xFF6EC1E4),
    ),
    Item(
      id: 'bigas',
      name: 'Bigas per kilo',
      emoji: '🍚',
      retailPrice: 45,
      wholesalePrice: 35,
      needsPermit: false,
      primaryColor: Color(0xFFFFFDD0),
      secondaryColor: Color(0xFFE8E4C9),
    ),
    Item(
      id: 'itlog',
      name: 'Itlog',
      emoji: '🥚',
      retailPrice: 9,
      wholesalePrice: 6,
      needsPermit: false,
      primaryColor: Color(0xFFFFF4E0),
      secondaryColor: Color(0xFFE8C87A),
    ),
    Item(
      id: 'de_lata',
      name: 'De Lata',
      emoji: '🥫',
      retailPrice: 25,
      wholesalePrice: 18,
      needsPermit: false,
      primaryColor: Color(0xFFC0392B),
      secondaryColor: Color(0xFF922B21),
    ),
    Item(
      id: 'softdrinks',
      name: 'Softdrinks',
      emoji: '🥤',
      retailPrice: 20,
      wholesalePrice: 14,
      needsPermit: false,
      primaryColor: Color(0xFFE74C3C),
      secondaryColor: Color(0xFF7D3C98),
    ),
    Item(
      id: 'candy',
      name: 'Candy',
      emoji: '🍬',
      retailPrice: 2,
      wholesalePrice: 1,
      needsPermit: false,
      primaryColor: Color(0xFFFF69B4),
      secondaryColor: Color(0xFFFF1493),
    ),
    Item(
      id: 'chichirya',
      name: 'Chichirya',
      emoji: '🍿',
      retailPrice: 15,
      wholesalePrice: 10,
      needsPermit: false,
      primaryColor: Color(0xFFF39C12),
      secondaryColor: Color(0xFFE67E22),
    ),
    Item(
      id: 'tubig',
      name: 'Tubig',
      emoji: '💧',
      retailPrice: 10,
      wholesalePrice: 7,
      needsPermit: false,
      primaryColor: Color(0xFF3498DB),
      secondaryColor: Color(0xFF2980B9),
    ),
    Item(
      id: 'noodles',
      name: 'Noodles',
      emoji: '🍜',
      retailPrice: 12,
      wholesalePrice: 8,
      needsPermit: false,
      primaryColor: Color(0xFFFFD700),
      secondaryColor: Color(0xFFDAA520),
    ),
  ];

  // ── Starting inventory (5 of each basic item) ─────────────────────
  static Map<String, int> get startingInventory {
    final inv = <String, int>{};
    for (final item in allItems) {
      // Start with 5 of everything except items that need a permit
      inv[item.id] = item.needsPermit ? 0 : 5;
    }
    return inv;
  }

  /// Look up an item by its id. Returns null if not found.
  static Item? itemById(String id) {
    for (final item in allItems) {
      if (item.id == id) return item;
    }
    return null;
  }
}
