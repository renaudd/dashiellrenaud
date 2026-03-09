import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/room.dart';
import 'package:abomination/models/crop.dart';
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
    gameState.setSpeed(GameSpeed.normal);
  });

  group('Agricultural Logic', () {
    test('tillSoil increases room tilling progress', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      final initialTilled = field.tilledAmount;

      gameState.tillSoil(field.id);

      final updatedField = gameState.rooms.firstWhere((r) => r.id == field.id);
      expect(updatedField.tilledAmount, greaterThan(initialTilled));
    });

    test('plantCrops fails if soil is not tilled', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      // Ensure it's not tilled
      gameState.updateRoom(field.copyWith(tilledAmount: 0.0));

      // Ensure seeds are available
      gameState.setResource('seeds_cabbage', 10);

      final success = gameState.plantCrops(CropType.cabbage, field.id);
      expect(success, false);
      expect(gameState.crops.length, 0);
    });

    test('plantCrops fails if no seeds', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      // Ensure it is tilled
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0));

      // Ensure NO seeds are available
      gameState.setResource('seeds_cabbage', 0);

      final success = gameState.plantCrops(CropType.cabbage, field.id);
      expect(success, false);
      expect(gameState.crops.length, 0);
    });

    test('plantCrops succeeds if tilled and has seeds', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      // Ensure it is tilled
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0));

      // Ensure seeds are available
      gameState.setResource('seeds_cabbage', 10);

      final success = gameState.plantCrops(CropType.cabbage, field.id);
      expect(success, true);
      expect(gameState.crops.length, 1);

      // Tilling should be consumed slightly
      final updatedField = gameState.rooms.firstWhere((r) => r.id == field.id);
      expect(updatedField.tilledAmount, lessThan(1.0));
    });

    test('Crops growth and moisture decay over time', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0));
      gameState.setResource('seeds_cabbage', 1);
      gameState.plantCrops(CropType.cabbage, field.id);

      final initialCrop = gameState.crops[0];
      final initialMoisture = initialCrop.moistureLevel;

      // Tick 60 times (1 hour)
      for (int i = 0; i < 60; i++) {
        gameState.tick();
      }

      final updatedCrop = gameState.crops[0];
      expect(
        updatedCrop.growthProgress,
        greaterThan(initialCrop.growthProgress),
      );
      expect(updatedCrop.moistureLevel, lessThan(initialMoisture));
    });

    test('waterCrops resets moisture level', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      gameState.updateRoom(field.copyWith(tilledAmount: 1.0));
      gameState.setResource('seeds_cabbage', 1);
      gameState.plantCrops(CropType.cabbage, field.id);

      // Decay moisture
      for (int i = 0; i < 100; i++) {
        gameState.tick();
      }

      expect(gameState.crops[0].moistureLevel, lessThan(1.0));

      gameState.waterCrops(field.id);
      expect(gameState.crops[0].moistureLevel, 1.0);
    });

    test('fertilizeSoil increases room fertilization', () {
      final field = gameState.rooms.firstWhere((r) => r.type == RoomType.field);
      final initialFert = field.fertilizedAmount;

      gameState.fertilizeSoil(field.id);

      final updatedField = gameState.rooms.firstWhere((r) => r.id == field.id);
      expect(updatedField.fertilizedAmount, greaterThan(initialFert));
    });
  });
}
