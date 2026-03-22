import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/state/game_state.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/models/npc_intent.dart';
import 'package:abomination/models/game_item.dart';

void main() {
  group('Study & Science Mechanics', () {
    late GameState gameState;

    setUp(() {
      gameState = GameState();
      gameState.initializeNewGame(
        firstName: "Science",
        lastName: "Tester",
        estateName: "Lab Estate",
        deathCause: DeathCause.disease,
        age: 40,
        gilesTrait: GilesTrait.sage,
        objective: LifeObjective.science,
      );
    });

    test('Generic meat recipes work in Kitchen', () {
      // Add rat meat and generic meat
      final ratMeat = GameItem.create(
        name: 'Rat Meat',
        type: 'meat_rat',
        category: ItemCategory.food,
        quantity: 2,
      );

      gameState.addItemToRoom('kitchen', ratMeat);

      // Ensure we have other ingredients for "Stew of Unknown Protein"
      // Recipe: meat: 1, potato: 1, salt: 1
      gameState.updateResource('potato', 5);
      gameState.updateResource('salt', 5);

      // Cook it
      final cookTask = GameTask(
        id: 'cook_stew',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.cook,
        targetId: 'kitchen',
        recipeId: 'protein_mistery_stew',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(gameState.npcs.first.id, cookTask);

      // Verify meat was consumed and meals produced
      final updatedKitchen = gameState.rooms.firstWhere(
        (r) => r.id == 'kitchen',
      );
      expect(
        updatedKitchen.inventory.any(
          (i) => i.type == 'meat_rat' && i.quantity == 1,
        ),
        isTrue,
      );
      // Meals are added to resources or pantry
      expect(gameState.resources['meals']! > 0, isTrue);
    });

    test('Dissection consumes specimen and produces notes and meat', () {
      // Add rat specimen to study
      final ratSpecimen = GameItem.create(
        name: 'Dead Rat',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      gameState.addItemToRoom('study', ratSpecimen);

      final dissectTask = GameTask(
        id: 'dissect_rat',
        npcId: gameState.npcs.first.id,
        priority: IntentPriority.normal,
        type: TaskType.dissect,
        targetId: 'study',
        recipeId: 'small_dissection',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(gameState.npcs.first.id, dissectTask);

      // Verify specimen consumed
      final study = gameState.rooms.firstWhere((r) => r.id == 'study');
      expect(study.inventory.any((i) => i.type == 'rat_specimen'), isFalse);

      // Verify notes and meat produced in global inventory
      expect(
        gameState.inventory.any((i) => i.type == 'research_notes'),
        isTrue,
      );
      expect(gameState.inventory.any((i) => i.type == 'meat_generic'), isTrue);
    });

    test('Vivisection corrupts worker', () {
      final rat = GameItem.create(
        name: 'Live Rat',
        type: 'rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      gameState.addItemToRoom('study', rat);

      final worker = gameState.npcs.first;
      final initialSatisfaction = worker.satisfaction;

      final vivisectionTask = GameTask(
        id: 'vivisect_rat',
        npcId: worker.id,
        priority: IntentPriority.normal,
        type: TaskType.vivisection,
        targetId: 'study',
        recipeId: 'small_vivisection',
        minutesRemaining: 1,
      );

      gameState.completeTaskManually(worker.id, vivisectionTask);

      expect(gameState.npcs.first.satisfaction < initialSatisfaction, isTrue);
    });
  });
}
