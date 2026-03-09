import 'package:flutter_test/flutter_test.dart';
import 'package:abomination/models/npc.dart';
import 'package:abomination/models/relationship.dart';
import 'package:abomination/models/body_part.dart';
import 'package:abomination/models/schedule.dart';
import 'package:abomination/models/diet.dart';
import 'package:abomination/services/social_service.dart';

void main() {
  group('Relationship Model', () {
    test('Loyalty getter calculation', () {
      final rel = Relationship(admiration: 3.0, respect: 4.0, fear: 2.0);
      expect(rel.loyalty, closeTo(3.0, 0.01));
    });

    test('Attraction clamping', () {
      final rel = Relationship(attraction: 2.5);
      final updated = rel.copyWith(attraction: 6.0);
      expect(updated.attraction, 5.0);
      final updated2 = rel.copyWith(attraction: -1.0);
      expect(updated2.attraction, 0.0);
    });
  });

  group('Attraction Logic', () {
    final maleNpc = NPC(
      id: 'm1',
      name: 'Male',
      role: 'Worker',
      age: 30,
      gender: 'Male',
      specimenType: 'Human',
      sexualOrientation: SexualOrientation.straight,
      bodyParts: [],
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
    );

    final femaleNpc = NPC(
      id: 'f1',
      name: 'Female',
      role: 'Worker',
      age: 35,
      gender: 'Female',
      specimenType: 'Human',
      sexualOrientation: SexualOrientation.straight,
      bodyParts: [],
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      appearance: NPCAppearance.random(),
    );

    test('Straight orientation attraction/repulsion', () {
      final attractionMF = SocialService.calculateInitialAttraction(
        maleNpc,
        femaleNpc,
      );
      expect(attractionMF, greaterThanOrEqualTo(1.0));

      final attractionMM = SocialService.calculateInitialAttraction(
        maleNpc,
        maleNpc,
      );
      expect(attractionMM, lessThan(1.0));
    });

    test('Asexual orientation attraction', () {
      final asexualNpc = maleNpc.copyWith(
        sexualOrientation: SexualOrientation.asexual,
      );
      final attraction = SocialService.calculateInitialAttraction(
        asexualNpc,
        femaleNpc,
      );
      expect(attraction, lessThan(1.0));
    });

    test('Bisexual orientation attraction', () {
      final biNpc = maleNpc.copyWith(
        sexualOrientation: SexualOrientation.bisexual,
      );
      final attractMale = SocialService.calculateInitialAttraction(
        biNpc,
        maleNpc,
      );
      final attractFemale = SocialService.calculateInitialAttraction(
        biNpc,
        femaleNpc,
      );
      expect(attractMale, greaterThanOrEqualTo(1.0));
      expect(attractFemale, greaterThanOrEqualTo(1.0));
    });

    test('Stats influence attraction', () {
      final highCharisma = femaleNpc.copyWith(
        stats: {'charisma': 100, 'vitality': 100},
      );
      final lowCharisma = femaleNpc.copyWith(
        stats: {'charisma': 0, 'vitality': 0},
      );

      final attrHigh = SocialService.calculateInitialAttraction(
        maleNpc,
        highCharisma,
      );
      final attrLow = SocialService.calculateInitialAttraction(
        maleNpc,
        lowCharisma,
      );

      expect(attrHigh, greaterThan(attrLow));
    });

    test('Missing body parts penalty', () {
      final completeNpc = femaleNpc.copyWith(
        bodyParts: List.generate(
          10,
          (i) => BodyPart(
            type: BodyPartType.values[i % BodyPartType.values.length],
            health: 100,
            maxHealth: 100,
            isAttached: true,
          ),
        ),
      );
      final damagedNpc = femaleNpc.copyWith(
        bodyParts: List.generate(
          10,
          (i) => BodyPart(
            type: BodyPartType.values[i % BodyPartType.values.length],
            health: 100,
            maxHealth: 100,
            isAttached: false,
          ),
        ),
      );

      final attrComp = SocialService.calculateInitialAttraction(
        maleNpc,
        completeNpc,
      );
      final attrDam = SocialService.calculateInitialAttraction(
        maleNpc,
        damagedNpc,
      );

      expect(attrComp, greaterThan(attrDam));
    });

    test('Asymmetric age peaks', () {
      final youngFemale = femaleNpc.copyWith(age: 20);
      final matureFemale = femaleNpc.copyWith(age: 40);

      // Male should prefer 20
      final attrM20 = SocialService.calculateInitialAttraction(
        maleNpc,
        youngFemale,
      );
      final attrM40 = SocialService.calculateInitialAttraction(
        maleNpc,
        matureFemale,
      );
      expect(attrM20, greaterThan(attrM40));

      final youngMale = maleNpc.copyWith(age: 20);
      final matureMale = maleNpc.copyWith(age: 40);
      final biFemale = femaleNpc.copyWith(
        sexualOrientation: SexualOrientation.bisexual,
      );

      // Female should prefer 40
      final attrF20 = SocialService.calculateInitialAttraction(
        biFemale,
        youngMale,
      );
      final attrF40 = SocialService.calculateInitialAttraction(
        biFemale,
        matureMale,
      );
      expect(attrF40, greaterThan(attrF20));
    });
  });
}
