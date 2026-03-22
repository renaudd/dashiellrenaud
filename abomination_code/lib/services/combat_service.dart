import 'dart:math';
import '../models/npc.dart';
import '../models/body_part.dart';

class CombatService {
  static final _random = Random();

  /// Applies targeted damage to an NPC.
  /// If [targetPart] is null, a random part is hit.
  static NPC applyDamage(
    NPC npc, {
    BodyPartType? targetPart,
    int damage = 10,
    WoundType? woundType,
  }) {
    final bodyParts = List<BodyPart>.from(
      npc.bodyParts.map((bp) => bp.copyWith()),
    );

    // Select part to hit
    final targetType = targetPart ?? _selectRandomPart();
    final partIndex = bodyParts.indexWhere(
      (bp) => bp.type == targetType && bp.isAttached,
    );

    if (partIndex != -1) {
      final part = bodyParts[partIndex];
      bodyParts[partIndex] = part.copyWith(
        health: (part.health - damage).clamp(0.0, part.maxHealth.toDouble()),
      );

      // Apply wound if damage is significant
      if (damage > 5) {
        final newWound = Wound(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: woundType ?? _determineWoundType(damage),
          description: "Fresh injury from combat.",
          severity: (damage / 10).ceil().clamp(1, 10),
          timeApplied: DateTime.now(),
        );
        final updatedWounds = List<Wound>.from(bodyParts[partIndex].wounds);
        updatedWounds.add(newWound);
        bodyParts[partIndex] = bodyParts[partIndex].copyWith(
          wounds: updatedWounds,
        );
      }

      // Handle Dismemberment (if health reaches 0 and damage is high)
      if (bodyParts[partIndex].health == 0 &&
          damage >= 30 &&
          _isLimb(targetType)) {
        final currentWounds = List<Wound>.from(bodyParts[partIndex].wounds);
        currentWounds.add(
          Wound(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: WoundType.amputation,
            description: "Limb was severed or destroyed.",
            severity: 10,
            timeApplied: DateTime.now(),
          ),
        );
        bodyParts[partIndex] = bodyParts[partIndex].copyWith(
          isAttached: false,
          wounds: currentWounds,
        );
      }
    }

    return npc.copyWith(
      status: _evaluateDeadlyWounds(bodyParts) ? NPCStatus.dead : npc.status,
      stats: _calculateStatPenalties(npc.stats, bodyParts),
      bodyParts: bodyParts,
    );
  }

  static BodyPartType _selectRandomPart() {
    // Weights: Torso (40%), Head (10%), Arms (20%), Legs (30%)
    final r = _random.nextInt(100);
    if (r < 10) return BodyPartType.head;
    if (r < 50) return BodyPartType.torso;
    if (r < 60) return BodyPartType.rightArm;
    if (r < 70) return BodyPartType.leftArm;
    if (r < 85) return BodyPartType.rightLeg;
    return BodyPartType.leftLeg;
  }

  static WoundType _determineWoundType(int damage) {
    if (damage < 15) return WoundType.bruise;
    if (damage < 25) return WoundType.laceration;
    return WoundType.fracture;
  }

  static bool _isLimb(BodyPartType type) {
    return type == BodyPartType.rightArm ||
        type == BodyPartType.leftArm ||
        type == BodyPartType.rightLeg ||
        type == BodyPartType.leftLeg;
  }

  static bool _evaluateDeadlyWounds(List<BodyPart> bodyParts) {
    final head = bodyParts.firstWhere((bp) => bp.type == BodyPartType.head);
    final torso = bodyParts.firstWhere((bp) => bp.type == BodyPartType.torso);
    return head.health <= 0 || torso.health <= 0;
  }

  static Map<String, int> _calculateStatPenalties(
    Map<String, int> baseStats,
    List<BodyPart> bodyParts,
  ) {
    final stats = Map<String, int>.from(baseStats);

    // Leg wounds affect walkSpeed
    final rightLeg = bodyParts.firstWhere(
      (bp) => bp.type == BodyPartType.rightLeg,
    );
    final leftLeg = bodyParts.firstWhere(
      (bp) => bp.type == BodyPartType.leftLeg,
    );
    if (!rightLeg.isAttached || !leftLeg.isAttached) {
      stats['walkSpeed'] = 1; // Crawling
    } else if (rightLeg.health < 50 || leftLeg.health < 50) {
      stats['walkSpeed'] = (stats['walkSpeed'] ?? 5) ~/ 2;
    }

    // Head wounds affect intelligence
    final head = bodyParts.firstWhere((bp) => bp.type == BodyPartType.head);
    if (head.wounds.any((w) => w.type == WoundType.concussion)) {
      stats['intelligence'] = (stats['intelligence'] ?? 50) ~/ 2;
    }

    return stats;
  }
}
