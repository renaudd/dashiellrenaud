import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/services/combat_manager.dart';
import 'package:abomination/services/combat_unit_factory.dart';

void main() {
  group('CombatManager Logging Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      // Ensure we have enough AP for any unit in tests
      manager.update(100.0);
      manager.startCombat();
    });

    test('Log is generated when an attack occurs', () {
      final alphonse = CombatUnitFactory.createAlphonse();
      final attackerNPC = CombatUnitFactory.createFlaubert();
      final targetNPC = CombatUnitFactory.createGoon();

      manager.spawnUnit(alphonse, CombatSide.player, x: 0.0, y: 0.5);
      manager.spawnUnit(attackerNPC, CombatSide.player, x: 1.0, y: 0.5);
      manager.spawnUnit(targetNPC, CombatSide.enemy, x: 2.0, y: 0.5);

      // Verify log is empty initially
      expect(manager.logs, isEmpty);

      // Manually trigger updates in small steps to simulate passage of time
      for (int i = 0; i < 100; i++) {
        manager.update(0.1);
      }

      expect(manager.logs.isNotEmpty, isTrue);
      expect(
        manager.logs.any(
          (l) => l.message.contains('hit') || l.message.contains('missed'),
        ),
        isTrue,
      );
    });

    test('Log records death', () {
      final alphonse = CombatUnitFactory.createAlphonse();
      final attackerNPC = CombatUnitFactory.createFlaubert().copyWith(
        combatStats: CombatUnitFactory.createFlaubert().combatStats!.copyWith(
          attack: 100,
          accuracy: 1.0,
        ),
      );
      final targetNPC = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 1,
        ),
      );

      manager.spawnUnit(alphonse, CombatSide.player, x: 0.0, y: 0.5);
      manager.spawnUnit(attackerNPC, CombatSide.player, x: 1.0, y: 0.5);
      manager.spawnUnit(targetNPC, CombatSide.enemy, x: 1.2, y: 0.5);

      for (int i = 0; i < 50; i++) {
        manager.update(0.1);
      }

      expect(manager.logs.any((l) => l.message.contains('defeated')), isTrue);
    });
  });
}
