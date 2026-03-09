import 'package:flutter/material.dart';
import '../models/npc.dart';

import '../models/combat_stats.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/body_part.dart';

class CombatUnitFactory {
  static NPC createAlphonse() {
    return NPC(
      id: 'alphonse',
      name: 'Alphonse Frankenstein',
      role: 'Master',
      age: 25,
      gender: 'Male',
      specimenType: 'Human',
      isPlayer: true,
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(), // Should be customized later
      combatStats: const CombatStats(
        attack: 8,
        health: 300,
        maxHealth: 300,
        speed: 1.0,
        movement: 0.8,
        distance: 7.5, // Ranged (was 5.0)
        defense: 0,
        accuracy: 0.85,
        cost: 0,
      ),
      abilities: [
        const Ability(
          id: 'master_command',
          name: "Master's Command",
          type: AbilityType.special,
          description: 'Nearby allies gain +50% Attack Speed for 8 seconds.',
          chargeTime: 20.0,
          effectData: {
            'buff_speed': 1.0,
            'duration': 10.0,
            'range': 15.0,
          }, // Buffed speed and duration
        ),
      ],
    );
  }

  static NPC createFlaubert() {
    return NPC.initialButler().copyWith(
      combatStats: const CombatStats(
        attack: 45, // Heavy melee hitter
        health: 450, // Sturdy
        maxHealth: 450,
        speed: 1.5, // Slow attack
        movement: 0.8,
        distance: 1.8,
        defense: 5,
        accuracy: 0.85,
        cost: 6, // Elite cost
        radius: 3.5,
      ),
      abilities: [
        const Ability(
          id: 'execute_low_health',
          name: 'Execute',
          type: AbilityType.special,
          description:
              'Instantly kills an enemy unit with less than 50% health.',
          chargeTime: 7.0,
          effectData: {'threshold': 0.5, 'type': 'interrupt_kill'},
        ),
      ],
    );
  }

  static NPC createRatsUnit() {
    return NPC(
      id: 'rats_unit_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Rats (x4)',
      role: 'Swarm',
      age: 1,
      gender: 'N/A',
      specimenType: 'Rat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 12, // Low per-hit but swarm
        health: 25, // Fragile swarm
        maxHealth: 25,
        speed: 0.6, // Fast bites
        movement: 1.4, // Very fast
        distance: 0.5,
        defense: 0,
        accuracy: 0.7,
        cost: 3,
        radius: 1.2,
        swarmSize: 4,
      ),
      abilities: [
        const Ability(
          id: 'rats_plague',
          name: 'Vermin Plague',
          type: AbilityType.trait,
          description:
              'Each hit has a 20% chance to infect the target, reducing their health by 2 every second for 5s.',
          effectData: {
            'on_hit': true,
            'dot': 2.0,
            'duration': 5.0,
            'chance': 0.2,
          },
        ),
      ],
    );
  }

  static NPC createWingedRat() {
    return NPC(
      id: 'winged_rat_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Winged Rat',
      role: 'Flyer',
      age: 1,
      gender: 'N/A',
      specimenType: 'FlyingRat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.grey.shade300,
        hairColor: Colors.grey.shade600,
        outfitColor: Colors.blueGrey.shade800,
      ),
      combatStats: const CombatStats(
        attack: 15,
        health: 45, // Glass flyer
        maxHealth: 45,
        speed: 0.8,
        movement: 1.2,
        distance: 0.8,
        defense: 0,
        accuracy: 0.8,
        cost: 2,
        radius: 1.8,
        isFlying: true,
      ),
      abilities: [
        const Ability(
          id: 'ap_steal',
          name: 'Knell: AP Steal',
          type: AbilityType.knell,
          description: 'Steal up to 1 AP from the enemy.',
          effectData: {'steal_ap': 1.0},
        ),
      ],
    );
  }

  static NPC createGoon() {
    return NPC(
      id: 'goon_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Goon',
      role: 'Thug',
      age: 30,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.brown.shade800,
        hairStyle: HairStyle.short,
        hairColor: Colors.black87,
      ),
      combatStats: const CombatStats(
        attack: 22,
        health: 220,
        maxHealth: 220,
        speed: 1.2,
        movement: 0.7,
        distance: 0.6,
        defense: 2,
        accuracy: 0.8,
        cost: 3, // Increased cost for durability
      ),
      abilities: [
        const Ability(
          id: 'horn_heal',
          name: 'Horn: Heal',
          type: AbilityType.horn,
          description: 'Heal nearest friendly unit by 100.',
          effectData: {'heal': 100, 'range': 2.0},
        ),
      ],
    );
  }

  static NPC createSniper() {
    return NPC(
      id: 'sniper_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Sniper',
      role: 'Sharpshooter',
      age: 28,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.indigo.shade900,
        hairStyle: HairStyle.long,
        hairColor: Colors.black,
      ),
      combatStats: const CombatStats(
        attack: 38,
        health: 140,
        maxHealth: 140,
        speed: 2.8, // Very slow fire rate
        movement: 0.4,
        distance: 12.0, // Significant range
        defense: 0,
        accuracy: 0.9,
        cost: 5, // High value target
      ),
      abilities: [
        const Ability(
          id: 'accuracy_boost',
          name: 'Trait: Focus',
          type: AbilityType.trait,
          description:
              'Increase accuracy by 0.05 after each successful attack.',
          effectData: {'accuracy_inc': 0.05, 'on_hit': true},
        ),
      ],
    );
  }

  static NPC createBully() {
    return NPC(
      id: 'bully_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Bully',
      role: 'Bruiser',
      age: 22,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.orange.shade700,
        outfitColor: Colors.blueGrey.shade800,
      ),
      combatStats: const CombatStats(
        attack: 25,
        health: 350,
        maxHealth: 350,
        speed: 1.6,
        movement: 0.4,
        distance: 1.8,
        defense: 8,
        accuracy: 0.7,
        cost: 6, // Heavy tank
        radius: 4.5,
      ),
      abilities: [
        const Ability(
          id: 'bully_shove',
          name: 'Intimidating Shove',
          type: AbilityType.trait,
          description: 'Attacks have a 30% chance to knock enemies back.',
          effectData: {'on_hit': true, 'knockback': 2.0, 'chance': 0.3},
        ),
        const Ability(
          id: 'bully_knell',
          name: 'Desperate Grasp',
          type: AbilityType.knell,
          description: 'On death, deals 20 damage to the nearest enemy.',
          effectData: {'damage': 20.0, 'range': 3.0},
        ),
      ],
    );
  }

  static NPC createBatsUnit() {
    return NPC(
      id: 'bats_unit_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Bats (x3)',
      role: 'Swarm',
      age: 1,
      gender: 'N/A',
      specimenType: 'Bat',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
      combatStats: const CombatStats(
        attack: 20,
        health: 30,
        maxHealth: 30,
        speed: 0.8,
        movement: 1.0,
        distance: 0.125, // Near zero but slightly above (was 0.1)
        defense: 0,
        accuracy: 0.9,
        cost: 4,
        radius: 1.5,
        isFlying: true,
        swarmSize: 3,
      ),
      abilities: [
        const Ability(
          id: 'freeze_line',
          name: 'Special: Freeze Line',
          type: AbilityType.special,
          description: 'Freeze all enemies in a line for 2.5s.',
          chargeTime: 8.0,
          effectData: {'freeze_duration': 2.5, 'shape': 'line'},
        ),
      ],
    );
  }

  static NPC createMilitia() {
    return NPC(
      id: 'militia_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Militia',
      role: 'Soldier',
      age: 24,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.blueGrey.shade700,
        hairColor: Colors.brown,
      ),
      combatStats: const CombatStats(
        attack: 12,
        health: 120,
        maxHealth: 120,
        speed: 1.0,
        movement: 0.6,
        distance: 1.25, // Increased reach (was 1.0)
        defense: 5,
        accuracy: 0.85,
        cost: 3,
        radius: 1.8,
      ),
      abilities: [
        const Ability(
          id: 'militia_thrust',
          name: 'Spear Thrust',
          type: AbilityType.special,
          description: 'A quick piering strike that ignores 5 defense.',
          chargeTime: 6.0,
          effectData: {'ignore_defense': 5.0},
        ),
        const Ability(
          id: 'militia_discipline',
          name: 'Phalanx Discipline',
          type: AbilityType.trait,
          description: 'Nearby allies gain +3 Defense.',
          effectData: {'buff_defense': 3.0, 'range': 4.0},
        ),
      ],
    );
  }

  static NPC createBanditCaptain() {
    return NPC(
      id: 'captain_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Bandit Captain',
      role: 'Leader',
      age: 42,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.red.shade900,
        hairStyle: HairStyle.bob,
        facialHairStyle: FacialHairStyle.beard,
      ),
      combatStats: const CombatStats(
        attack: 32,
        health: 800, // True Boss/Leader stats
        maxHealth: 800,
        speed: 1.4,
        movement: 0.45,
        distance: 2.0,
        defense: 12,
        accuracy: 0.95,
        cost: 9, // Peak cost
      ),
      abilities: [
        const Ability(
          id: 'captain_strike',
          name: 'Tactical Strike',
          type: AbilityType.special,
          description:
              'Directs all allies to focus fire on the nearest enemy for 5 seconds.',
          chargeTime: 12.0,
          effectData: {'focus_fire': true, 'duration': 5.0},
        ),
        const Ability(
          id: 'captain_rally',
          name: 'Horn: Rally',
          type: AbilityType.horn,
          description: 'Nearby allies gain +25% Speed.',
          effectData: {'buff_speed': 0.25, 'range': 10.0},
        ),
      ],
    );
  }

  static NPC createPeasant() {
    return NPC(
      id: 'peasant_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Peasant',
      role: 'Laborer',
      age: 19,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.brown.shade400,
        hairStyle: HairStyle.long,
      ),
      combatStats: const CombatStats(
        attack: 12,
        health: 140,
        maxHealth: 140,
        speed: 1.0,
        movement: 1.1, // Fast commoner
        distance: 1.8,
        defense: 0,
        accuracy: 0.8,
        cost: 2,
        radius: 1.5,
      ),
      abilities: [
        const Ability(
          id: 'peasant_strength',
          name: 'Desperate Strength',
          type: AbilityType.trait,
          description: 'Attack increases as health decreases (up to +100%).',
          effectData: {'scaling_attack': true},
        ),
      ],
    );
  }

  static NPC createStitchedHorror() {
    return NPC(
      id: 'stitched_horror_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Stitched Horror',
      role: 'Tank',
      age: 0,
      gender: 'Other',
      specimenType: 'Abomination',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.green.shade900,
        outfitColor: Colors.brown.shade900,
      ),
      combatStats: const CombatStats(
        attack: 18,
        health: 600, // Massive Tank
        maxHealth: 600,
        speed: 2.0, // Slow
        movement: 0.35,
        distance: 2.2,
        defense: 20,
        accuracy: 0.8,
        cost: 7, // High end
        radius: 5.5,
      ),
      abilities: [
        const Ability(
          id: 'horror_stench',
          name: 'Grave Stench',
          type: AbilityType.trait,
          description: 'Passively slows nearby enemies by 20%.',
          effectData: {'slow': 0.2, 'range': 4.0},
        ),
        const Ability(
          id: 'horror_knell',
          name: 'Rotting Burst',
          type: AbilityType.knell,
          description: 'Explodes on death, dealing 40 damage in a large area.',
          effectData: {
            'damage': 120.0,
            'range': 8.0,
          }, // Buffed explosion damage
        ),
      ],
    );
  }

  static NPC createGalvanizedCorpse() {
    return NPC(
      id: 'galvanized_corpse_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Galvanized Corpse',
      role: 'Glass Cannon',
      age: 0,
      gender: 'Other',
      specimenType: 'Abomination',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.blueGrey.shade200,
        outfitColor: Colors.grey.shade800,
      ),
      combatStats: const CombatStats(
        attack: 35,
        health: 80,
        maxHealth: 80,
        speed: 0.8,
        movement: 1.1,
        distance: 1.875, // (was 1.5)
        defense: 0,
        accuracy: 0.9,
        cost: 5,
        radius: 2.2, // Increased from 1.2
      ),
      abilities: [
        const Ability(
          id: 'corpse_arc',
          name: 'Unstable Arc',
          type: AbilityType.special,
          description:
              'Releases a bolt of lightning dealing 60 damage to a target and 30 to nearby enemies.',
          chargeTime: 10.0,
          effectData: {
            'damage': 150.0,
            'aoe_damage': 80.0,
            'range': 8.0,
          }, // Buffed arc damage
        ),
      ],
    );
  }

  static NPC createChemicalSlinger() {
    return NPC(
      id: 'chemical_slinger_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Chemical Slinger',
      role: 'Artillery',
      age: 32,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.green.shade700,
        hairColor: Colors.black,
      ),
      combatStats: const CombatStats(
        attack: 22,
        health: 120,
        maxHealth: 120,
        speed: 2.2,
        movement: 0.6,
        distance: 9.0, // Ranged (was 6.0)
        defense: 2,
        accuracy: 0.7,
        cost: 4,
        radius: 1.5,
      ),
      abilities: [
        const Ability(
          id: 'slinger_cloud',
          name: 'Corrosive Cloud',
          type: AbilityType.trait,
          description:
              'Attacks leave a toxic cloud that deals 5 damage per second for 3s.',
          effectData: {'on_hit': true, 'dot': 5.0, 'duration': 3.0},
        ),
      ],
    );
  }

  static NPC createShadowCreeper() {
    return NPC(
      id: 'shadow_creeper_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Shadow Creeper',
      role: 'Assassin',
      age: 0,
      gender: 'Other',
      specimenType: 'Spectre',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.black54,
        outfitColor: Colors.black,
      ),
      combatStats: const CombatStats(
        attack: 25,
        health: 60,
        maxHealth: 60,
        speed: 0.6,
        movement: 1.5,
        distance: 2.25, // Stealthy reach (was 1.8)
        defense: 0,
        accuracy: 0.85,
        cost: 4,
        radius: 2.0, // Increased from 1.0
      ),
      abilities: [
        const Ability(
          id: 'creeper_phase',
          name: 'Phase Shift',
          type: AbilityType.trait,
          description: 'Passively avoids 25% of incoming physical attacks.',
          effectData: {'evasion': 0.25},
        ),
      ],
    );
  }

  static NPC createGravedigger() {
    return NPC(
      id: 'gravedigger_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Gravedigger',
      role: 'Brawler',
      age: 45,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.brown.shade600,
        facialHairStyle: FacialHairStyle.beard,
      ),
      combatStats: const CombatStats(
        attack: 18,
        health: 240,
        maxHealth: 240,
        speed: 1.5,
        movement: 0.7,
        distance: 1.875, // Shovel reach (was 1.5)
        defense: 8,
        accuracy: 0.8,
        cost: 5,
        radius: 1.8,
      ),
      abilities: [
        const Ability(
          id: 'digger_bury',
          name: 'Bury Alive',
          type: AbilityType.special,
          description: 'Stuns current target for 3s and deals 40 damage.',
          chargeTime: 12.0,
          effectData: {'stun': 5.0, 'damage': 120.0}, // Buffed stun and damage
        ),
      ],
    );
  }

  static NPC createPlagueMonk() {
    return NPC(
      id: 'plague_monk_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Plague Monk',
      role: 'Support',
      age: 50,
      gender: 'Male',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.purple.shade900,
        hairStyle: HairStyle.bald,
      ),
      combatStats: const CombatStats(
        attack: 12,
        health: 150,
        maxHealth: 150,
        speed: 1.8,
        movement: 0.9,
        distance: 2.5, // Ceremonial staff reach (was 2.0)
        defense: 5,
        accuracy: 0.75,
        cost: 5,
        swarmSize: 2,
        radius: 2.5, // Increased from 1.4
      ),
      abilities: [
        const Ability(
          id: 'monk_chant',
          name: 'Dark Chant',
          type: AbilityType.horn,
          description: 'Nearby allies gain +10% Speed.',
          effectData: {'buff_speed': 0.1, 'range': 6.0},
        ),
      ],
    );
  }

  static NPC createInquisitor() {
    return NPC(
      id: 'inquisitor_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Inquisitor',
      role: 'Marksman',
      age: 38,
      gender: 'Female',
      specimenType: 'Human',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        outfitColor: Colors.red.shade700,
        hairStyle: HairStyle.bob,
      ),
      combatStats: const CombatStats(
        attack: 28,
        health: 140,
        maxHealth: 140,
        speed: 2.0,
        movement: 0.7,
        distance: 10.5, // Long range (was 7.0)
        defense: 5,
        accuracy: 0.95,
        cost: 6,
        radius: 1.5,
      ),
      abilities: [
        const Ability(
          id: 'inq_smite',
          name: 'Divine Smite',
          type: AbilityType.special,
          description:
              'A powerful shot that deals 100 pure damage to the target.',
          chargeTime: 15.0,
          effectData: {
            'damage': 250.0,
            'ignore_defense': true,
          }, // Buffed pure damage
        ),
      ],
    );
  }

  static NPC createIronMaiden() {
    return NPC(
      id: 'iron_maiden_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Iron Maiden',
      role: 'Juggernaut',
      age: 0,
      gender: 'Female',
      specimenType: 'Construct',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.grey.shade400,
        outfitColor: Colors.blueGrey.shade900,
      ),
      combatStats: const CombatStats(
        attack: 20,
        health: 400,
        maxHealth: 400,
        speed: 2.5,
        movement: 0.2,
        distance: 1.75, // Spiked reach (was 1.4)
        defense: 25,
        accuracy: 0.7,
        cost: 6,
        radius: 5.0, // Increased from 3.0
      ),
      abilities: [
        const Ability(
          id: 'maiden_spikes',
          name: 'Spiked Carapace',
          type: AbilityType.trait,
          description:
              'Reflects 30% of incoming physical damage back to the attacker.',
          effectData: {'reflect': 0.3},
        ),
      ],
    );
  }

  static NPC createFleshHound() {
    return NPC(
      id: 'flesh_hound_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Flesh Hound',
      role: 'Chaser',
      age: 0,
      gender: 'N/A',
      specimenType: 'Hound',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.red.shade900,
        outfitColor: Colors.brown.shade800,
      ),
      combatStats: const CombatStats(
        attack: 25,
        health: 180, // Glass-ier chaser
        maxHealth: 180,
        speed: 0.6, // Very fast attacks
        movement: 1.8, // Elite speed
        distance: 1.5,
        defense: 0,
        accuracy: 0.85,
        cost: 4,
        radius: 1.4,
      ),
      abilities: [
        const Ability(
          id: 'hound_leap',
          name: 'Frenzied Leap',
          type: AbilityType.special,
          description:
              'Leaps to the farthest enemy, dealing 30 damage and stunning for 1s.',
          chargeTime: 8.0,
          effectData: {'leap': true, 'damage': 30.0, 'stun': 1.0},
        ),
      ],
    );
  }

  static NPC createAlchemicalGolem() {
    return NPC(
      id: 'alchemical_golem_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Alchemical Golem',
      role: 'Elite Tank',
      age: 0,
      gender: 'N/A',
      specimenType: 'Golemic',
      bodyParts: _defaultBodyParts(),
      schedule: NPCSchedule.visitor(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random().copyWith(
        bodyColor: Colors.blueGrey,
        outfitColor: Colors.indigo,
      ),
      combatStats: const CombatStats(
        attack: 30,
        health: 500,
        maxHealth: 500,
        speed: 1.8,
        movement: 0.3,
        distance: 4.5,
        defense: 15,
        accuracy: 0.9,
        cost: 8, // Elite Tank
        radius: 5.0,
      ),
      abilities: [
        const Ability(
          id: 'golem_slam',
          name: 'Alchemical Slam',
          type: AbilityType.special,
          description:
              'A massive area slam that deals 50 damage and knocks back nearby enemies.',
          chargeTime: 15.0,
          effectData: {'damage': 50.0, 'range': 8.0, 'knockback': 5.0},
        ),
        const Ability(
          id: 'golem_trait',
          name: 'Reinforced Core',
          type: AbilityType.trait,
          description: 'Reduces all incoming damage by 5.',
          effectData: {'damage_reduction': 5.0},
        ),
      ],
    );
  }

  static List<BodyPart> _defaultBodyParts() {
    return [
      BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
    ];
  }
}
