import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/state/game_state.dart';

void main() {
  late GameState gameState;

  setUp(() {
    gameState = GameState();
    gameState.initializeNewGame(
      firstName: "Test",
      lastName: "Master",
      estateName: "Test Manor",
      deathCause: DeathCause.trainCrash,
      age: 30,
      gilesTrait: GilesTrait.silent,
      objective: LifeObjective.science,
    );
  });

  group('World Travel & Hiring Logic', () {
    test('Hired NPC joins the party at the destination', () {
      // 1. Send player to Hamlet
      gameState.startJourney('player', 'hamlet', {'funds': 50}, []);

      final playerIndex = gameState.npcs.indexWhere((n) => n.id == 'player');
      gameState.updateNpc(
        gameState.npcs[playerIndex].copyWith(worldTravelProgress: 1.0),
      );

      // 2. Prepare recruitable NPC
      gameState.refreshHamletNpcs();
      final targetNpc = gameState.availableHamletNpcs.first;

      // 3. Hire
      gameState.hireNpc(targetNpc);

      // Verify hired NPC is in the world at Hamlet
      final hired = gameState.npcs.firstWhere((n) => n.id == targetNpc.id);
      expect(hired.worldDestinationId, equals('hamlet'));
      expect(hired.worldTravelProgress, equals(1.0));
      expect(hired.isResident, isTrue);

      // Verify player's lastEscortIds (combat deck) was updated
      final master = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(master.lastEscortIds, contains(hired.id));
    });

    test('returnToManor groups all units at the destination', () {
      // 1. Setup: Player and two others at Hamlet
      final butlerIndex = gameState.npcs.indexWhere((n) => n.id == 'butler');
      final butlerId = gameState.npcs[butlerIndex].id;

      gameState.startJourney('player', 'hamlet', {'funds': 50}, [butlerId]);

      // Force arrival
      for (var id in ['player', butlerId]) {
        final idx = gameState.npcs.indexWhere((n) => n.id == id);
        gameState.updateNpc(
          gameState.npcs[idx].copyWith(worldTravelProgress: 1.0),
        );
      }

      // 2. Trigger Return
      gameState.returnToManor('player');

      // 3. Verify ALL units at hamlet are now traveling to manor
      final traveling = gameState.npcs
          .where((n) => n.worldDestinationId == 'manor')
          .toList();
      expect(traveling.length, greaterThanOrEqualTo(2));
      expect(traveling.any((n) => n.id == 'player'), isTrue);
      expect(traveling.any((n) => n.id == butlerId), isTrue);
      expect(traveling.every((n) => n.worldTravelProgress == 0.0), isTrue);
    });

    test('_processNpcTravel correctly handles arrival at manor', () {
      // 1. Setup: Player arrives at hamlet, then starts return
      gameState.startJourney('player', 'hamlet', {'funds': 50}, []);

      final playerIndex = gameState.npcs.indexWhere((n) => n.id == 'player');
      gameState.updateNpc(
        gameState.npcs[playerIndex].copyWith(worldTravelProgress: 1.0),
      );

      gameState.returnToManor('player');

      final playerStartingReturn = gameState.npcs.firstWhere(
        (n) => n.id == 'player',
      );
      expect(playerStartingReturn.worldDestinationId, equals('manor'));

      // Set to 239/240 progress so one more tick triggers arrival
      gameState.updateNpc(
        playerStartingReturn.copyWith(worldTravelProgress: 239.0 / 240.0),
      );

      // 2. Trigger one tick of travel
      gameState.tick();

      // 3. Verify player has 'arrived' and is in the manor (worldDestinationId is null)
      final player = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(
        player.worldDestinationId,
        isNull,
        reason: "worldDestinationId should be null after arrival at manor",
      );
      expect(
        player.worldTravelProgress,
        0.0,
        reason: "worldTravelProgress should reset after arrival at manor",
      );
      expect(
        player.currentRoomId,
        equals('road'),
        reason: "NPC should be on the road leading into the manor",
      );
    });
  });
}
