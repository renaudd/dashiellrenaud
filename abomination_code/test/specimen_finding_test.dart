import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/npc.dart';
import 'package:abomination/services/task_service.dart';
import 'package:abomination/services/task_result_generator.dart';
import 'package:abomination/util/manor_layout.dart';

void main() {
  group('Manor Layout Refinement', () {
    test('Toolshed and Chicken Coop are shifted left', () {
      final coop = ManorLayout.grid['chicken_coop'];
      final shed = ManorLayout.grid['toolshed'];

      expect(coop?.$1, equals(3.9));
      expect(shed?.$1, equals(3.9));
    });
  });

  group('Specimen Finding Logic', () {
    final worker = NPC.initialButler();

    test('Finding Rats in Bedroom (Cleaning)', () {
      int ratsFound = 0;
      for (int i = 0; i < 1000; i++) {
        final result = TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Master Bedroom',
          worker,
          targetId: 'master_bedroom',
        );
        if (result.itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsFound++;
        }
      }
      // Chance is 25%, expect around 250
      expect(ratsFound, greaterThan(150));
      expect(ratsFound, lessThan(350));
    });

    test('Finding Bats in Attic (Cleaning)', () {
      int batsFound = 0;
      for (int i = 0; i < 1000; i++) {
        final result = TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Attic',
          worker,
          targetId: 'attic',
        );
        if (result.itemsFound.any((item) => item.type == 'bat_specimen')) {
          batsFound++;
        }
      }
      // Chance is 20%, expect around 200
      expect(batsFound, greaterThan(100));
      expect(batsFound, lessThan(300));
    });

    test('Restoration has higher chances', () {
      int ratsCleaning = 0;
      int ratsRestoring = 0;
      for (int i = 0; i < 1000; i++) {
        if (TaskResultGenerator.generate(
          TaskType.cleanRoom,
          'Room',
          worker,
          targetId: 'other',
        ).itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsCleaning++;
        }
        if (TaskResultGenerator.generate(
          TaskType.restoreRoom,
          'Room',
          worker,
          targetId: 'other',
        ).itemsFound.any((item) => item.type == 'rat_specimen')) {
          ratsRestoring++;
        }
      }
      // Cleaning: 25%, Restoring: 40%
      expect(ratsRestoring, greaterThan(ratsCleaning));
    });
  });
}
