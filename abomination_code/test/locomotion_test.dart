import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/npc_intent.dart';

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

  group('Locomotion & Pathfinding', () {
    test('NPC moving from Attic to Exterior passes through hubs', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Force start in Attic
      gameState.updateNpc(
        npc.copyWith(
          currentRoomId: 'attic_1',
          targetRoomId: null,
          movementPath: [],
        ),
      );

      // Assign a task in the Vegetable Garden
      final gardenTask = GameTask(
        id: 'garden_task',
        npcId: 'player',
        priority: IntentPriority.normal,
        type: TaskType.rest,
        targetId: 'vegetable_garden',
        minutesRemaining: 60,
      );

      gameState.assignTask(gardenTask);

      final updatedNpc = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Expected sequence: Master Bedroom (Stairs from Attic 1) -> Bed 2 -> Bed 3 -> Bath Up -> Entryway (Main Stairs) -> Road -> Veg Garden
      // First step: master_bedroom
      // Expected sequence: Master Bedroom or Bed 2 (Stairs from Attic 1) -> sequential traversal -> Entryway -> Road -> Veg Garden
      final firstStep = updatedNpc.targetRoomId;
      expect(firstStep, anyOf(equals('master_bedroom'), equals('bedroom_2')));

      expect(
        updatedNpc.movementPath,
        containsAll(['entryway', 'road', 'vegetable_garden']),
      );
    });

    test('NPC moving from Basement to Ground Floor hub', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');

      gameState.updateNpc(
        npc.copyWith(
          currentRoomId: 'basement_1',
          targetRoomId: null,
          movementPath: [],
        ),
      );

      final kitchenTask = GameTask(
        id: 'kitchen_task',
        npcId: 'player',
        priority: IntentPriority.normal,
        type: TaskType.eat,
        targetId: 'kitchen',
        minutesRemaining: 30,
      );

      gameState.assignTask(kitchenTask);

      final updatedNpc = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Path: Basement 2 (via stairs) -> Unused Wing -> Entryway -> Kitchen
      expect(updatedNpc.targetRoomId, equals('basement_2'));
      expect(
        updatedNpc.movementPath,
        containsAllInOrder(['unused_1f', 'entryway', 'kitchen']),
      );
    });

    test('Locomotion progresses through the direct path', () {
      final npc = gameState.npcs.firstWhere((n) => n.id == 'player');

      // Start in Attic 1
      gameState.updateNpc(
        npc.copyWith(
          currentRoomId: 'attic_1',
          targetRoomId: null,
          movementProgress: 0.0,
          movementPath: [],
        ),
      );

      // Assign task in Master Bedroom (requires one stair climb)
      gameState.assignNpcToTask('player', TaskType.eat, 'master_bedroom');

      // assignNpcToTask already popped 'master_bedroom' as targetRoomId

      // Advance until arrives at master_bedroom
      // Minute 1: 0.35, Minute 2: 0.70, Minute 3: 1.05 -> Arrived
      for (int i = 0; i < 3; i++) {
        gameState.tick();
      }

      final currentNpc = gameState.npcs.firstWhere((n) => n.id == 'player');
      expect(currentNpc.currentRoomId, equals('master_bedroom'));
      expect(currentNpc.targetRoomId, isNull);
    });
  });

  group('Initial Room States', () {
    test('Attic and Basement rooms start in disrepair', () {
      final attic1 = gameState.rooms.firstWhere((r) => r.id == 'attic_1');
      final basement1 = gameState.rooms.firstWhere((r) => r.id == 'basement_1');

      expect(attic1.isRestored, isFalse);
      expect(basement1.isRestored, isFalse);
    });
  });
}
