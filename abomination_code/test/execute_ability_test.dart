import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/services/combat_manager.dart';
import 'package:abomination/services/combat_unit_factory.dart';

void main() {
  group('Giles Execute Ability Tests', () {
    late CombatManager manager;

    setUp(() {
      manager = CombatManager();
      manager.startCombat();
    });

    test('Execute is unavailable if target health > 50%', () {
      final giles = CombatUnitFactory.createFlaubert();
      // Force charge to 100%
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 200, // 200/220 > 50%
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 55.0,
        y: 42.5,
      ); // Close range

      expect(manager.canExecuteSpecial('butler'), isFalse);
    });

    test('Execute is available if target health <= 50% and in range', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 100, // < 50%
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 58.0,
        y: 42.5,
      ); // Centers are 8ft apart

      // Giles radius: 3.5, Goon radius: 1.5.
      // Distance between centers = 8.0.
      // Edge-to-edge = 8.0 - 3.5 - 1.5 = 3.0ft.
      // 3.0ft <= 12.0ft range.

      expect(manager.canExecuteSpecial('butler'), isTrue);
    });

    test('Execute is unavailable if target is out of range', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50,
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(
        enemy,
        CombatSide.enemy,
        x: 70.0,
        y: 42.5,
      ); // Centers 20ft apart

      // Edge-to-edge: 20 - 3.5 - 1.5 = 15ft > 12ft range.
      expect(manager.canExecuteSpecial('butler'), isFalse);
    });

    test('Execute resets special charge after use', () {
      final giles = CombatUnitFactory.createFlaubert();
      final chargedGiles = giles.copyWith(specialCharge: 1.0);

      final enemy = CombatUnitFactory.createGoon().copyWith(
        id: 'target_enemy',
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50,
          maxHealth: 220,
        ),
      );

      manager.spawnUnit(chargedGiles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 42.5);

      expect(manager.canExecuteSpecial('butler'), isTrue);

      manager.executeSpecial('butler');

      final gilesCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id == 'butler',
      );
      expect(gilesCombatant.npc.specialCharge, 0.0);
    });

    test('Execute treats low-health Giles as a valid user', () {
      final giles = CombatUnitFactory.createFlaubert().copyWith(
        combatStats: CombatUnitFactory.createFlaubert().combatStats!.copyWith(
          health: 10.0, // Giles is near death
        ),
        specialCharge: 1.0,
      );

      final enemy = CombatUnitFactory.createGoon().copyWith(
        combatStats: CombatUnitFactory.createGoon().combatStats!.copyWith(
          health: 50, // Enemy is < 50%
        ),
      );

      manager.spawnUnit(giles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(enemy, CombatSide.enemy, x: 55.0, y: 42.5);

      expect(manager.canExecuteSpecial('butler'), isTrue);
    });

    test('Ground Melee (Giles) cannot target Flying Rat', () {
      final giles = CombatUnitFactory.createFlaubert();
      final rat = CombatUnitFactory.createRatsUnit(); // Now isFlying: true

      manager.spawnUnit(giles, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      // Give it a few ticks to try and find a target
      manager.update(0.1);

      final gilesCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id == 'butler',
      );
      expect(gilesCombatant.targetId, isNull); // Should not find the rat
    });

    test('Sniper (Ranged) CAN target Flying Rat', () {
      final sniper = CombatUnitFactory.createSniper();
      final rat = CombatUnitFactory.createRatsUnit();

      manager.spawnUnit(sniper, CombatSide.player, x: 10.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      manager.update(0.1);

      final sniperCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id.contains('sniper'),
      );
      expect(sniperCombatant.targetId, isNotNull);
    });

    test('Bat (Flyer) CAN target Flying Rat', () {
      final bat = CombatUnitFactory.createBatsUnit();
      final rat = CombatUnitFactory.createRatsUnit();

      manager.spawnUnit(bat, CombatSide.player, x: 50.0, y: 42.5);
      manager.spawnUnit(rat, CombatSide.enemy, x: 55.0, y: 42.5);

      manager.update(0.1);

      final batCombatant = manager.combatants.firstWhere(
        (c) => c.npc.id.contains('bats_unit'),
      );
      expect(batCombatant.targetId, isNotNull);
    });

    test('Cards stay out of deck/hand while unit is alive on field', () {
      final unitA = CombatUnitFactory.createGoon().copyWith(id: 'unit_a');
      final unitB = CombatUnitFactory.createGoon().copyWith(id: 'unit_b');

      manager.prepareDeck([unitA, unitB]);
      // hand size is maxHandSize (5) by default, here 2
      expect(manager.hand.length, 2);

      // Spawn unitA
      manager.spawnUnit(unitA, CombatSide.player, x: 50, y: 40);
      expect(manager.hand.length, 1);
      expect(manager.hand.any((u) => u.id == 'unit_b'), isTrue);

      // Try to draw again (should fail because unitA is on field and unitB is in hand)
      manager.drawCard();
      expect(manager.hand.length, 1);

      // Kill unitA
      final combatantA = manager.combatants.firstWhere(
        (c) => c.npc.id == 'unit_a',
      );
      combatantA.npc = combatantA.npc.copyWith(
        combatStats: combatantA.npc.combatStats!.copyWith(health: 0),
      );
      combatantA.isDead = true; // MUST set this for cleanup
      manager.update(0.1); // Process cleanup

      // Now it should be drawn back
      manager.drawCard();
      expect(manager.hand.length, 2);
      expect(manager.hand.any((u) => u.id == 'unit_a'), isTrue);
    });
  });
}
