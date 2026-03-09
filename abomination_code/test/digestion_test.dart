import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/room.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';

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
    gameState.setSpeed(GameSpeed.normal);
  });

  group('Digestion Logic', () {
    test('Digestion increases over time', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');
      final initialDigestion = npc.digestion;

      // Advance time by 1 hour (60 ticks)
      for (int i = 0; i < 60; i++) {
        gameState.tick();
      }

      final updatedNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(updatedNpc.digestion, greaterThan(initialDigestion));
    });

    test('Desperate need triggers toilet task', () {
      // Manually set digestion to 86%
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');
      gameState.updateNpc(npc.copyWith(digestion: 86.0, activeTaskId: null));

      gameState.tick(); // Process logic

      final updatedNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      // Should have a toilet task from intent system
      expect(updatedNpc.activeTaskId, contains("toilet"));
    });

    // ... (UBMI test is fine)

    test('UBMI occurs after 15 mins at 100%', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');
      gameState.updateNpc(
        npc.copyWith(digestion: 100.0, breakingPointMinutes: 0),
      );

      // Advance 14 minutes
      for (int i = 0; i < 14; i++) {
        gameState.tick();
      }

      var midNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(midNpc.digestion, greaterThanOrEqualTo(100.0));
      expect(midNpc.breakingPointMinutes, 14);

      // The 15th minute triggers the incident
      gameState.tick();

      final finalNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(finalNpc.digestion, 0.0);
      expect(finalNpc.satisfaction, lessThan(70.0));
      expect(finalNpc.currentThought, contains("humiliated"));

      // Room should be dirtied
      final room = gameState.rooms.firstWhere(
        (r) => r.id == finalNpc.currentRoomId,
      );
      expect(room.isRestored, false);
      expect(room.dirtiness, 1.0);
    });

    test('Toilet usage resets digestion and dirties room', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');
      final bathroom = gameState.rooms.firstWhere(
        (r) => r.type == RoomType.toilet,
      );
      final initialDirtiness = bathroom.dirtiness;

      gameState.updateNpc(npc.copyWith(digestion: 90.0));

      // Mock task assignment
      final task = GameTask(
        id: 'test_toilet',
        npcId: npc.id,
        type: TaskType.useToilet,
        targetId: bathroom.id,
        minutesRemaining: 1,
      );
      gameState.assignTask(task);

      // Advance time to complete task.
      // Movement (3 ticks) + Task Duration (1 tick)
      for (int i = 0; i < 15; i++) {
        gameState.tick();
      }

      final finalNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(finalNpc.digestion, lessThan(1.0));

      final finalBathroom = gameState.rooms.firstWhere(
        (r) => r.id == bathroom.id,
      );
      expect(finalBathroom.dirtiness, greaterThan(initialDirtiness));
    });
  });
}
