import '../models/experiment.dart';
import '../models/npc.dart';
import 'dart:math';

class ExperimentationService {
  static final Random _random = Random();

  static Map<String, dynamic> processCompletion(
    Experiment experiment,
    NPC subject,
  ) {
    List<String> logs = [];
    NPC updatedSubject = subject;
    Map<String, int> resourceGain = {};
    int insightGain = 0;

    switch (experiment.type) {
      case ExperimentType.dissection:
        insightGain = 25;
        logs.add(
          "The dissection of ${subject.name} provided invaluable anatomical insights.",
        );
        // Dissection is fatal or highly damaging
        updatedSubject = _applyDamageToAllParts(updatedSubject, 50);
        resourceGain['meat'] = 2;
        break;

      case ExperimentType.lobotomy:
        insightGain = 15;
        logs.add(
          "${subject.name} has undergone a lobotomy. Their willpower is shattered, but they are now more... compliant.",
        );
        updatedSubject = updatedSubject.copyWith(
          stats: {
            ...updatedSubject.stats,
            'willpower': 10,
            'intellect': ((updatedSubject.stats['intellect'] ?? 50) / 2)
                .toInt(),
          },
        );
        break;

      case ExperimentType.reanimation:
        insightGain = 50;
        logs.add(
          "The sparking electrodes have done their work. ${subject.name} stirs once more!",
        );
        // Reanimation restores health but reduces intellect/willpower
        updatedSubject = _restoreAllParts(updatedSubject, 50);
        updatedSubject = updatedSubject.copyWith(
          status: NPCStatus.zombie,
          stats: {
            ...updatedSubject.stats,
            'intellect': 20,
            'willpower': 100, // Absolute loyalty/unthinking obedience
          },
        );
        break;

      case ExperimentType.transmutation:
        insightGain = 10;
        logs.add("Transmutation trial on ${subject.name} complete.");
        // Random effects
        if (_random.nextBool()) {
          updatedSubject = updatedSubject.copyWith(
            stats: {
              ...updatedSubject.stats,
              'strength': (updatedSubject.stats['strength'] ?? 50) + 10,
            },
          );
          logs.add("${subject.name} feels strangely stronger.");
        } else {
          updatedSubject = _applyDamageToAllParts(updatedSubject, 10);
          logs.add(
            "The transmutation was unstable, causing minor burns to ${subject.name}.",
          );
        }
        break;
      case ExperimentType.deprivation:
        logs.add("Deprivation study on ${subject.name} complete.");
        break;
      case ExperimentType.administration:
        logs.add("Substance administration on ${subject.name} complete.");
        break;
      case ExperimentType.puzzle:
        logs.add("Cognitive puzzle test on ${subject.name} complete.");
        break;
      case ExperimentType.breeding:
        logs.add("Breeding attempt complete.");
        if (subject.specimenType == 'Rat') {
          // If we had a mechanism to consume a Bat, we'd do it here.
          // For now, let's assume a 20% chance of a breakthrough if reagents are present.
          logs.add(
            "The rat exhibits strange, leathery protrusions. A breakthrough!",
          );
          resourceGain['flying_rat'] = 1;
        }
        break;
      case ExperimentType.operation:
        logs.add("Surgical operation on ${subject.name} complete.");
        break;
    }

    return {
      'subject': updatedSubject,
      'logs': logs,
      'insight': insightGain,
      'resources': resourceGain,
    };
  }

  static NPC _applyDamageToAllParts(NPC npc, int damage) {
    final updatedParts = npc.bodyParts.map((part) {
      return part.copyWith(health: max(0.0, part.health - damage),
      );
    }).toList();
    return npc.copyWith(bodyParts: updatedParts);
  }

  static NPC _restoreAllParts(NPC npc, int heal) {
    final updatedParts = npc.bodyParts.map((part) {
      return part.copyWith(
        health: min(part.maxHealth.toDouble(), part.health + heal),
      );
    }).toList();
    return npc.copyWith(bodyParts: updatedParts);
  }
}
