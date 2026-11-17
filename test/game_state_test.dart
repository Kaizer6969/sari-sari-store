import 'package:flutter_test/flutter_test.dart';
import 'package:sari_sari_store/models/game_state.dart';
import 'package:sari_sari_store/utils/constants.dart';

void main() {
  group('Sari-Sari Store GameState Tests', () {
    test('Bagong Laro starts with Day 1, 6:00 AM, initial money and stock', () {
      final state = GameState.newGame();

      expect(state.day, 1);
      expect(state.hour, 6);
      expect(state.minute, 0);
      expect(state.money, GameConstants.startingMoney);
      expect(state.storeOpen, false);
      expect(state.hasPermit, false);
      expect(state.getStock('kape'), 5);
      expect(state.getStock('yosi'), 0); // Yosi needs permit, starts at 0
    });

    test('Selling items decreases inventory and increases money', () {
      final state = GameState.newGame();
      final initialMoney = state.money;
      final kapeStock = state.getStock('kape');

      final success = state.sellItem('kape', 2);

      expect(success, true);
      expect(state.getStock('kape'), kapeStock - 2);
      expect(state.money, initialMoney + (8.0 * 2)); // ₱8 retail price
      expect(state.totalSales, 2);
    });

    test('Cannot buy permit-required items without a Barangay Permit', () {
      final state = GameState.newGame();

      // Attempt to buy Yosi wholesale without permit
      final bought = state.buyStock('yosi', 5);
      expect(bought, false);
      expect(state.getStock('yosi'), 0);

      // Now get permit
      state.obtainPermit();
      expect(state.hasPermit, true);
      expect(state.money, GameConstants.startingMoney - GameConstants.permitCost);

      // Now can buy Yosi
      final boughtWithPermit = state.buyStock('yosi', 5);
      expect(boughtWithPermit, true);
      expect(state.getStock('yosi'), 5);
    });

    test('Scammer mechanics: getting scammed penalizes reputation, rejecting rewards', () {
      final state = GameState.newGame();
      final initRep = state.reputation;

      // Got scammed
      state.gotScammed(100.0);
      expect(state.scammedCount, 1);
      expect(state.reputation, initRep - 15);

      // Caught scammer
      state.rejectedScammer();
      expect(state.scammersRejected, 1);
      expect(state.reputation, initRep - 15 + 5);
    });

    test('Time advance wraps minutes and auto-closes store at midnight', () {
      final state = GameState.newGame();
      state.storeOpen = true;

      state.advanceTime(70); // +1 hr 10 min -> 7:10 AM
      expect(state.hour, 7);
      expect(state.minute, 10);

      // Advance to midnight
      state.advanceTime(17 * 60); // +17 hrs -> 24:10
      expect(state.storeOpen, false); // Auto-closed
    });

    test('Serialization and Deserialization preserve game state', () {
      final original = GameState.newGame();
      original.money = 1250.0;
      original.day = 4;
      original.hasPermit = true;
      original.sellItem('kape', 3);

      final jsonString = original.serialize();
      final restored = GameState.deserialize(jsonString);

      expect(restored.money, original.money);
      expect(restored.day, 4);
      expect(restored.hasPermit, true);
      expect(restored.getStock('kape'), original.getStock('kape'));
    });
  });
}
