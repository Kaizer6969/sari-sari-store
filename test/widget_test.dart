import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sari_sari_store/main.dart';
import 'package:sari_sari_store/models/game_state.dart';
import 'package:sari_sari_store/screens/title_screen.dart';
import 'package:sari_sari_store/screens/store_screen.dart';
import 'package:sari_sari_store/widgets/shelf_hotspot.dart';
import 'package:sari_sari_store/widgets/transaction_dialog.dart';

void main() {
  testWidgets('App loads TitleScreen with interactive menu tap targets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SariSariStoreApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('StoreScreen loads pixel art artwork and interactive HUD', (
    WidgetTester tester,
  ) async {
    final gameState = GameState.newGame();
    gameState.inventory['kape'] = 5;
    gameState.inventory['noodles'] = 5;
    gameState.inventory['tubig'] = 5;
    await tester.pumpWidget(
      MaterialApp(home: StoreScreen(gameState: gameState)),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StoreScreen), findsOneWidget);
    expect(find.text('ARAW 1'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Advance past initial spawn timer
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byType(CustomerOrderChecklistCard), findsOneWidget);
    expect(find.byType(DynamicShelfStockWidget), findsWidgets);
    expect(find.text('⏱️ 40s'), findsOneWidget);
  });

  testWidgets('Customer leaves when 40-second timer runs out', (
    WidgetTester tester,
  ) async {
    final gameState = GameState.newGame();
    gameState.inventory['kape'] = 5;
    gameState.inventory['noodles'] = 5;
    final initialRep = gameState.reputation;

    await tester.pumpWidget(
      MaterialApp(home: StoreScreen(gameState: gameState)),
    );
    // Spawn first customer at 1.5s
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byType(CustomerOrderChecklistCard), findsOneWidget);

    // Advance 40 seconds so customer times out and leaves
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byType(CustomerOrderChecklistCard), findsNothing);
    expect(gameState.reputation, initialRep - 5);
  });

  testWidgets(
    '2-View Turn Around: Tapping floor arrow turns to back shelves and back to front',
    (WidgetTester tester) async {
      final gameState = GameState.newGame();

      await tester.pumpWidget(
        MaterialApp(home: StoreScreen(gameState: gameState)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Initially in Harap view: floor arrow to turn around exists
      expect(find.text('LUMINGON SA LIKOD'), findsOneWidget);
      expect(
        find.text('[ ⬇️ LUMINGON SA LIKOD (PANINDA 📦) ]'),
        findsOneWidget,
      );

      // Tap the floor arrow to turn around to the back
      await tester.tap(find.text('LUMINGON SA LIKOD'));
      await tester.pump();

      // Now in Likod view: shows back shelf indicator and return arrow
      expect(find.text('ESTANTE SA LIKOD (KUNIN ANG ORDER)'), findsOneWidget);
      expect(find.text('HARAP SA BINTANA'), findsOneWidget);
      expect(find.text('[ ⬆️ HARAP SA BINTANA (CUSTOMER) ]'), findsOneWidget);

      // Tap return arrow to turn back to front window
      await tester.tap(find.text('HARAP SA BINTANA'));
      await tester.pump();

      // Back in Harap view
      expect(find.text('LUMINGON SA LIKOD'), findsOneWidget);
    },
  );

  testWidgets(
    'TransactionDialog: Renders cash drawer, handles animated bill tap and exact change',
    (WidgetTester tester) async {
      double completedChange = -1;

      final order = CustomerOrder(
        customerName: 'Ken',
        customerAvatar: '👦',
        items: {'tubig': 1, 'bigas': 1},
        totalCost: 55.0,
        paymentGiven: 100.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionDialog(
              order: order,
              onCompleteSale: (changeGiven) {
                completedChange = changeGiven;
              },
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify retro register LCD text shows TOTAL, PAID, CHANGE
      expect(find.text('TOTAL:'), findsOneWidget);
      expect(find.text('₱55.00'), findsOneWidget);
      expect(find.text('PAID:'), findsOneWidget);
      expect(find.text('₱100.00'), findsWidgets);
      expect(find.text('CHANGE:'), findsOneWidget);
      expect(find.text('₱45.00'), findsOneWidget);

      // Verify drawer bill and coin trays exist
      expect(find.text('₱20'), findsWidgets);
      expect(find.text('₱5'), findsWidgets);
      expect(find.text('GIVE'), findsOneWidget);

      // Tap ₱20 bill twice, then ₱5 coin once to make ₱45 exact change
      // Tap ₱20 in drawer
      await tester.tap(find.byKey(const ValueKey('bill_20')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const ValueKey('bill_20')));
      await tester.pump(const Duration(milliseconds: 350));

      // Tap ₱5 in drawer
      await tester.tap(find.byKey(const ValueKey('coin_5')));
      await tester.pump(const Duration(milliseconds: 350));

      // Given should now be ₱45.00
      expect(find.text('₱45.00'), findsWidgets);
      expect(find.text('> TAMA NA! IABOT MO NA ✨'), findsOneWidget);

      // Tap GIVE CHANGE
      await tester.tap(find.text('GIVE'));
      await tester.pump(const Duration(milliseconds: 850));

      expect(completedChange, 45.0);
    },
  );
}
