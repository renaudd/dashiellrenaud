import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/ui/screens/study_screen.dart';
import 'package:abomination/models/game_item.dart';

void main() {
  testWidgets('StudyScreen should not have overflow with many items', (
    WidgetTester tester,
  ) async {
    final gameState = GameState();

    // Add many items to inventory to force a long list
    for (int i = 0; i < 20; i++) {
      gameState.inventory.add(
        GameItem.create(
          name: 'Specimen $i',
          type: 'specimen',
          category: ItemCategory.specimen,
        ),
      );
    }

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: gameState,
        child: const MaterialApp(home: StudyScreen()),
      ),
    );

    // Verify no overflow errors were thrown
    expect(tester.takeException(), isNull);

    // Verify we can find some of the items (scrolling might be needed to see all, but here we just check render)
    expect(find.text('SPECIMEN 1'), findsOneWidget);
  });
}
