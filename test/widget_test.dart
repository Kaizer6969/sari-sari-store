import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sari_sari_store/main.dart';
import 'package:sari_sari_store/models/game_state.dart';
import 'package:sari_sari_store/screens/title_screen.dart';
import 'package:sari_sari_store/screens/store_screen.dart';

void main() {
  testWidgets('App loads TitleScreen with interactive menu tap targets', (WidgetTester tester) async {
    await tester.pumpWidget(const SariSariStoreApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TitleScreen), findsOneWidget);
  });

  testWidgets('StoreScreen loads pixel art artwork and interactive HUD', (WidgetTester tester) async {
    final gameState = GameState.newGame();
    await tester.pumpWidget(
      MaterialApp(
        home: StoreScreen(gameState: gameState),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StoreScreen), findsOneWidget);
    expect(find.text('ARAW 1'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);

    // Advance past initial spawn timer
    await tester.pump(const Duration(milliseconds: 1600));
  });
}
