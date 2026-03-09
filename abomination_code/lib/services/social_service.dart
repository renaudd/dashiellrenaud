import '../models/npc.dart';
import '../models/relationship.dart';
import 'dart:math';

enum InteractionType {
  chat,
  argument,
  praise,
  threaten,
  encourage,
  boast,
  shareSecret,
  workTogether,
}

class SocialService {
  static final Random _random = Random();

  static Map<String, dynamic> performInteraction(
    NPC actor,
    NPC target,
    InteractionType type,
  ) {
    Relationship actorToTarget =
        actor.relationships[target.id] ?? Relationship();
    Relationship targetToActor =
        target.relationships[actor.id] ?? Relationship();

    String log = "";

    // Logic for how interactions affect relationship values
    switch (type) {
      case InteractionType.chat:
        log = "${actor.name} and ${target.name} had a pleasant conversation.";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration + 0.05,
          respect: targetToActor.respect + 0.02,
          attraction: targetToActor.attraction + 0.01,
        );
        break;
      case InteractionType.argument:
        log = "${actor.name} and ${target.name} had a heated argument.";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration - 0.1,
          respect: targetToActor.respect - 0.05,
          attraction: targetToActor.attraction - 0.05,
        );
        actorToTarget = actorToTarget.copyWith(
          admiration: actorToTarget.admiration - 0.1,
          attraction: actorToTarget.attraction - 0.05,
        );
        break;
      case InteractionType.praise:
        log = "${actor.name} praised ${target.name}'s efforts.";
        targetToActor = targetToActor.copyWith(
          admiration: targetToActor.admiration + 0.1,
          respect: targetToActor.respect + 0.05,
        );
        break;
      case InteractionType.threaten:
        log = "${actor.name} threatened ${target.name}.";
        targetToActor = targetToActor.copyWith(
          fear: targetToActor.fear + 0.2,
          admiration: targetToActor.admiration - 0.2,
          attraction: targetToActor.attraction - 0.1,
        );
        break;
      case InteractionType.encourage:
        log = "${actor.name} encouraged ${target.name}.";
        targetToActor = targetToActor.copyWith(
          respect: targetToActor.respect + 0.1,
          admiration: targetToActor.admiration + 0.05,
        );
        break;
      case InteractionType.workTogether:
        log = "${actor.name} and ${target.name} worked together efficiently.";
        targetToActor = targetToActor.copyWith(
          respect: targetToActor.respect + 0.05,
          admiration: targetToActor.admiration + 0.02,
        );
        actorToTarget = actorToTarget.copyWith(
          respect: actorToTarget.respect + 0.05,
          admiration: actorToTarget.admiration + 0.02,
        );
        break;
      default:
        log = "${actor.name} interacted with ${target.name}.";
    }

    return {
      'actorRelationship': actorToTarget,
      'targetRelationship': targetToActor,
      'log': log,
    };
  }

  static double calculateInitialAttraction(NPC observer, NPC target) {
    // 1. Orientation Check
    bool isAttractedByGender = false;
    final oSex = observer.gender.toLowerCase();
    final tSex = target.gender.toLowerCase();

    switch (observer.sexualOrientation) {
      case SexualOrientation.straight:
        isAttractedByGender = oSex != tSex;
        break;
      case SexualOrientation.gay:
        isAttractedByGender = oSex == 'male' && tSex == 'male';
        break;
      case SexualOrientation.lesbian:
        isAttractedByGender = oSex == 'female' && tSex == 'female';
        break;
      case SexualOrientation.bisexual:
        isAttractedByGender = true;
        break;
      case SexualOrientation.asexual:
        isAttractedByGender = false;
        break;
    }

    if (!isAttractedByGender) {
      return 0.5 + (_random.nextDouble() * 0.5); // Repulsed range (below 1.0)
    }

    // 2. Base Attraction (Stats)
    double base = 2.0;

    int charisma = target.stats['charisma'] ?? 50;
    int vitality = target.stats['vitality'] ?? 50;

    base += (charisma / 100.0) * 1.5;
    base += (vitality / 100.0) * 0.2; // Downgraded to tertiary

    // 3. Age Factor
    // Men are more attracted the closer target is to 20.
    // Women are more attracted the closer target is to 40.
    double ageScore = 1.0;
    if (observer.gender.toLowerCase() == 'male') {
      int distFrom20 = (target.age - 20).abs();
      ageScore = (1.0 - (distFrom20 / 40.0)).clamp(0.0, 1.0);
    } else {
      int distFrom40 = (target.age - 40).abs();
      ageScore = (1.0 - (distFrom40 / 40.0)).clamp(0.0, 1.0);
    }
    base += ageScore * 0.8;

    // 4. Physical Condition
    int missingParts = target.bodyParts.where((bp) => !bp.isAttached).length;
    base -= missingParts * 0.25;

    // 5. Random Variance (Reduced for test stability)
    base += (_random.nextDouble() * 0.2) - 0.1;

    return base.clamp(0.0, 5.0);
  }

  static InteractionType getRandomInteraction() {
    return InteractionType.values[_random.nextInt(
      InteractionType.values.length,
    )];
  }
}
