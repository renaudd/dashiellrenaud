import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/npc.dart';
import '../models/body_part.dart';
import '../models/schedule.dart';
import '../models/diet.dart';
import '../models/combat_stats.dart';

class NPCGenerator {
  static final _random = Random();
  static final _uuid = Uuid();

  static NPC generateRefugee() {
    final gender = _random.nextBool() ? 'Male' : 'Female';
    final age = _generateAge();
    final name = _generateName(gender);
    final group = _generateOrgGroup();
    final nationality = _pickOne(
      ['Swiss', 'French', 'German', 'Italian', 'Austrian'],
      weights: [50, 20, 15, 10, 5],
    );
    final religion = _pickOne(
      ['Protestant', 'Catholic', 'Jewish', 'Atheist', 'Agnostic', 'Calvinist'],
      weights: [40, 30, 5, 10, 10, 5],
    );

    final stats = _generateStats(age);
    final traits = _generateTraits(age);
    final bodyParts = _generateBodyParts();
    final profession = _generateProfession(gender, age);
    final appearance = _generateAppearance(gender, age);
    final orientation = _generateOrientation(gender);

    return NPC(
      id: _uuid.v4(),
      name: name,
      role: profession,
      age: age,
      specimenType: 'Human',
      gender: gender,
      group: group,
      nationality: nationality,
      religion: religion,
      stats: stats,
      traits: traits,
      bodyParts: bodyParts,
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      status: NPCStatus.idle,
      disposition: NPCDisposition.voluntary,
      sexualOrientation: orientation,
      appearance: appearance,
      isResident: true,
      chefStats: ChefSkills(
        knifeSkills: 10 + _random.nextInt(40),
        fireSkills: 10 + _random.nextInt(40),
        sanitation: 10 + _random.nextInt(40),
        nose: 10 + _random.nextInt(40),
      ),
      bio: _generateBio(name, profession, age),
      hometown: _pickOne([
        'Zürich',
        'Bern',
        'Geneva',
        'Basel',
        'Lausanne',
        'Lucerne',
      ]),
      background: _pickOne([
        'Noble',
        'Merchant',
        'Peasant',
        'Scholar',
        'Soldier',
        'Criminal',
      ]),
      combatStats: _generateCombatStats(profession, age),
      abilities: _generateRefugeeAbilities(profession),
    );
  }

  static NPCAppearance _generateAppearance(String gender, int age) {
    final skinTones = [
      const Color(0xFFFFDBAC),
      const Color(0xFFF1C27D),
      const Color(0xFFE0AC69),
      const Color(0xFF8D5524),
      const Color(0xFFC68642),
    ];

    final hairColors = [
      const Color(0xFF4B3621), // Brown
      const Color(0xFF090806), // Black
      const Color(0xFFE6BE8A), // Blonde
      const Color(0xFFA52A2A), // Red
      const Color(0xFFE8E8E8), // Grey
    ];

    final eyeColors = [
      Colors.brown,
      Colors.blue,
      Colors.blueGrey,
      Colors.green,
    ];

    final outfitColors = [
      Colors.brown.shade800,
      Colors.blueGrey.shade700,
      Colors.green.shade900,
      Colors.grey.shade800,
      const Color(0xFF4A4E69),
    ];

    HairStyle hairStyle = HairStyle.short;
    if (age > 60) {
      hairStyle = _pickOne([HairStyle.bald, HairStyle.short, HairStyle.messy]);
    } else {
      hairStyle = _pickOne(
        HairStyle.values.where((s) => s != HairStyle.none).toList(),
      );
    }

    FacialHairStyle facialHairStyle = FacialHairStyle.none;
    if (gender == 'Male' && age > 18) {
      facialHairStyle = _pickOne(
        FacialHairStyle.values,
        weights: [50, 15, 15, 10, 10],
      );
    }

    Color hairColor = _pickOne(hairColors);
    if (age > 55) hairColor = const Color(0xFFE8E8E8); // Go grey

    return NPCAppearance(
      hairStyle: hairStyle,
      facialHairStyle: facialHairStyle,
      bodyColor: _pickOne(skinTones),
      hairColor: hairColor,
      outfitColor: _pickOne(outfitColors),
      eyeColor: _pickOne(eyeColors),
    );
  }

  static int _generateAge() {
    double r = _random.nextDouble();
    if (r < 0.1) return 10 + _random.nextInt(6); // 10-15
    if (r < 0.5) return 16 + _random.nextInt(15); // 16-30
    if (r < 0.9) return 31 + _random.nextInt(30); // 31-60
    return 61 + _random.nextInt(20); // 61-80
  }

  static NPCOrgGroup _generateOrgGroup() {
    return _pickOne(
      [NPCOrgGroup.A, NPCOrgGroup.B, NPCOrgGroup.C, NPCOrgGroup.D],
      weights: [20, 30, 40, 10],
    );
  }

  static Map<String, int> _generateStats(int age) {
    int strength = 30 + _random.nextInt(40);
    int endurance = 30 + _random.nextInt(40);
    int adaptability = 30 + _random.nextInt(40);
    int dexterity = 30 + _random.nextInt(40);
    int intelligence = 30 + _random.nextInt(40);
    int perception = 30 + _random.nextInt(40);
    int judgment = 30 + _random.nextInt(40);
    int temperament = 30 + _random.nextInt(40);
    int leadership = 20 + _random.nextInt(40);
    int courage = 30 + _random.nextInt(40);
    int hygiene = 40 + _random.nextInt(50);
    int beauty = 20 + _random.nextInt(60);

    if (age < 16) {
      strength -= 15;
      endurance += 5;
    } else if (age > 60) {
      intelligence += 15;
      strength -= 20;
      endurance -= 20;
    }

    return {
      'strength': strength.clamp(0, 100),
      'endurance': endurance.clamp(0, 100),
      'adaptability': adaptability.clamp(0, 100),
      'dexterity': dexterity.clamp(0, 100),
      'intelligence': intelligence.clamp(0, 100),
      'perception': perception.clamp(0, 100),
      'judgment': judgment.clamp(0, 100),
      'temperament': temperament.clamp(0, 100),
      'leadership': leadership.clamp(0, 100),
      'courage': courage.clamp(0, 100),
      'hygiene': hygiene.clamp(0, 100),
      'beauty': beauty.clamp(0, 100),
      'walkSpeed': 10,
    };
  }

  static SexualOrientation _generateOrientation(String gender) {
    if (gender == 'Male') {
      return _pickOne(
        [
          SexualOrientation.straight,
          SexualOrientation.gay,
          SexualOrientation.bisexual,
          SexualOrientation.asexual,
        ],
        weights: [85, 5, 5, 5],
      );
    } else {
      return _pickOne(
        [
          SexualOrientation.straight,
          SexualOrientation.lesbian,
          SexualOrientation.bisexual,
          SexualOrientation.asexual,
        ],
        weights: [85, 5, 5, 5],
      );
    }
  }

  static List<NPCTrait> _generateTraits(int age) {
    final traits = <NPCTrait>[];
    traits.addAll(
      _pickTraits('character', _randomSelection([0, 1, 2, 3], [15, 55, 25, 5])),
    );
    traits.addAll(
      _pickTraits(
        'association',
        age < 16
            ? _randomSelection([0, 1], [65, 35])
            : _randomSelection([0, 1, 2], [30, 40, 30]),
      ),
    );
    traits.addAll(
      _pickTraits(
        'skill',
        age < 16
            ? _randomSelection([0, 1], [60, 40])
            : _randomSelection([1, 2, 3], [40, 50, 10]),
      ),
    );
    return traits;
  }

  static String _generateProfession(String gender, int age) {
    if (age < 16) return 'Child';
    return _pickOne([
      'Jeweler',
      'Blacksmith',
      'Surgeon',
      'Clockmaker',
      'Banker',
      'Horticulturalist',
      'Farmer',
      'Brewer',
      'Distiller',
      'Carpenter',
      'Cook',
      'Merchant',
      'Inventor',
      'Journalist',
      'Psychologist',
      'Doctor',
      'Florist',
    ]);
  }

  static List<BodyPart> _generateBodyParts() {
    return [
      BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightEye, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftEye, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.rightEar, health: 100, maxHealth: 100),
      BodyPart(type: BodyPartType.leftEar, health: 100, maxHealth: 100),
    ];
  }

  static T _pickOne<T>(List<T> options, {List<int>? weights}) {
    if (weights == null) return options[_random.nextInt(options.length)];
    int total = weights.reduce((a, b) => a + b);
    int r = _random.nextInt(total);
    int current = 0;
    for (int i = 0; i < weights.length; i++) {
      current += weights[i];
      if (r < current) return options[i];
    }
    return options.first;
  }

  static int _randomSelection(List<int> values, List<int> weights) {
    return _pickOne(values, weights: weights);
  }

  static List<NPCTrait> _pickTraits(String group, int count) {
    final pool = _traitPool[group] ?? [];
    if (pool.isEmpty || count == 0) return [];
    final result = <NPCTrait>[];
    final selectedPool = List<String>.from(pool)..shuffle(_random);
    for (int i = 0; i < min(count, selectedPool.length); i++) {
      String id = selectedPool[i];
      result.add(NPCTrait(id: id, name: _traitNames[id] ?? id, group: group));
    }
    return result;
  }

  static String _generateName(String gender) {
    final first = gender == 'Male'
        ? ['Hans', 'Karl', 'Otto', 'Wilhelm', 'Emil']
        : ['Heidi', 'Clara', 'Martha', 'Greta', 'Anna'];
    final last = ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber'];
    return "${first[_random.nextInt(first.length)]} ${last[_random.nextInt(last.length)]}";
  }

  static const _traitPool = {
    'character': [
      'loyal',
      'mutinous',
      'stoic',
      'hardworking',
      'lazy',
      'honest',
      'dishonest',
      'violent',
      'efficient',
      'genius',
      'idiot',
      'pleasant',
      'unpleasant',
    ],
    'association': [
      'religious',
      'communist',
      'racist',
      'conservative',
      'liberal',
    ],
    'skill': [
      'track_finder',
      'forager',
      'perfect_pitch',
      'greenthumb',
      'lucky',
      'super_vision',
      'leader',
      'teacher',
      'scrivener',
    ],
  };

  static String _generateBio(String name, String profession, int age) {
    final backgrounds = [
      "Born to a family of $profession practitioners, $name has spent years perfecting the craft.",
      "After a tragic accident in their youth, $name turned to $profession to find meaning.",
      "$name was once a prominent figure in their hometown, but political shifts forced them to flee.",
      "A mysterious traveler who rarely speaks of the past, focusing entirely on being a $profession.",
      "Descended from a line of explorers, $name seeks to apply $profession in ways never seen before.",
      "$name spent their early years in a remote monastery, learning the discipline required for $profession.",
      "A failed poet who found that $profession pays the bills far better than verse.",
      "Formerly an apprentice to a legendary master, $name is now out to prove they are the superior $profession.",
      "$name believes that $profession is the key to understanding the deeper mysteries of the world.",
      "A cheerful soul who treats $profession as a game, though their results are surprisingly professional.",
    ];
    return backgrounds[_random.nextInt(backgrounds.length)];
  }

  static const _traitNames = {
    'loyal': 'Loyal',
    'mutinous': 'Mutinous',
    'stoic': 'Stoic',
    'hardworking': 'Hardworking',
    'lazy': 'Lazy',
    'honest': 'Honest',
    'dishonest': 'Dishonest',
    'violent': 'Violent',
    'efficient': 'Efficient',
    'genius': 'Genius',
    'idiot': 'Idiot',
    'pleasant': 'Pleasant',
    'unpleasant': 'Unpleasant',
    'religious': 'Religious',
    'communist': 'Communist',
    'racist': 'Racist',
    'conservative': 'Conservative',
    'liberal': 'Liberal',
    'track_finder': 'Track Finder',
    'forager': 'Forager',
    'perfect_pitch': 'Perfect Pitch',
    'greenthumb': 'Green Thumb',
    'lucky': 'Lucky',
    'super_vision': 'Super Vision',
    'leader': 'Leader',
    'teacher': 'Teacher',
    'scrivener': 'Scrivener',
  };

  static CombatStats _generateCombatStats(String profession, int age) {
    // Base stats for a human refugee
    double hp = 40.0 + _random.nextInt(20);
    double atk = 5.0 + _random.nextInt(10);
    double def = 0.0 + _random.nextInt(5);
    double acc = 0.6 + (_random.nextDouble() * 0.2);
    double speed = 2.0 + (_random.nextDouble() * 1.5); // seconds per attack
    double move = 2.0 + (_random.nextDouble() * 1.0); // meters per second
    double dist = 1.0; // Melee by default
    int cost = 3;

    // Profession modifiers
    if (profession == 'Soldier' || profession == 'Mercenary') {
      hp += 20;
      atk += 5;
      def += 5;
      acc += 0.1;
      cost = 5;
    } else if (profession == 'Hunter') {
      dist = 15.0; // Ranged
      acc += 0.15;
      hp -= 5;
      cost = 4;
    } else if (profession == 'Surgeon' || profession == 'Doctor') {
      hp += 10;
      cost = 4;
    }

    // Age modifiers
    if (age < 18) {
      hp -= 10;
      atk -= 2;
    } else if (age > 60) {
      hp -= 15;
      speed += 1.0;
    }

    return CombatStats(
      attack: atk,
      health: hp,
      maxHealth: hp,
      speed: speed,
      movement: move,
      distance: dist,
      defense: def,
      accuracy: acc.clamp(0.0, 1.0),
      cost: cost,
    );
  }

  static List<Ability> _generateRefugeeAbilities(String profession) {
    final abilities = <Ability>[];

    // Common refugee traits
    if (_random.nextDouble() < 0.3) {
      abilities.add(
        const Ability(
          id: 'accuracy_boost',
          name: 'STAY FOCUSED',
          type: AbilityType.trait,
          description: 'Increases accuracy by 5% on spawn.',
          effectData: {'on_spawn': true},
        ),
      );
    }

    // Profession specific
    if (profession == 'Surgeon' || profession == 'Doctor') {
      abilities.add(
        const Ability(
          id: 'horn_heal',
          name: 'FIELD MEDIC',
          type: AbilityType.horn,
          description: 'Heals the nearest ally for 10 HP on spawn.',
          effectData: {'heal': 10, 'range': 5.0},
        ),
      );
    } else if (profession == 'Hunter') {
      abilities.add(
        const Ability(
          id: 'accuracy_boost',
          name: 'SNIPER SIGHT',
          type: AbilityType.trait,
          description: 'Passive accuracy boost.',
        ),
      );
    }

    return abilities;
  }
}
