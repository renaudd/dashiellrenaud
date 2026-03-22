import 'dart:math';
import '../models/npc.dart';
import '../models/game_item.dart';
import 'task_service.dart';

class TaskResultGenerator {
  static final _random = Random();

  static TaskResult generate(
    TaskType type,
    String? targetName,
    NPC worker, {
    String? recipeId,
    String? targetId,
  }) {
    switch (type) {
      case TaskType.prepareMeals:
      case TaskType.refineFood:
      case TaskType.butcherAnimals:
        if (recipeId == 'butcher_cow' || targetId == 'cattle_carcass') {
          double weight = 200.0;
          return TaskResult(
            message: "The cow has been butchered. A significant amount of beef is ready.",
            resourcesGained: {
              'meat_beef': (weight * 0.5).round().clamp(50, 200),
            },
            quality: 1.0,
          );
        }
        
        if (recipeId == 'butcher_rat' || 
            targetId == 'rat_specimen' || 
            (targetName?.toLowerCase().contains('rat') ?? false)) {
          return TaskResult(
            message: "${worker.name} butchered a rat. It's not much, but it's meat.",
            resourcesGained: {'meat': 1},
            quality: 0.5,
          );
        }

        if (targetId == 'bat_specimen' || (targetName?.toLowerCase().contains('bat') ?? false)) {
          return TaskResult(
            message: "${worker.name} butchered a bat. Lean and gamey.",
            resourcesGained: {'meat': 1},
            quality: 0.5,
          );
        }

        if (targetName?.toLowerCase().contains('chicken') ?? false) {
          double weight = 2.0;
          return TaskResult(
            message: "The chicken has been butchered. Fresh poultry meat is ready.",
            resourcesGained: {
              'meat_chicken': (weight * 0.8).round().clamp(1, 10),
            },
            quality: 1.0,
          );
        }

        // Handle generic NPC or resident butchering
        if (targetId != null && targetId != 'kitchen') {
           return TaskResult(
            message: "${worker.name} butchered $targetName. The freezer is a bit fuller, though the soul feels lighter.",
            resourcesGained: {'meat': 15}, // Human-sized meat yield
            quality: 0.8,
          );
        }

        // Default cooking/butcher quality calculation
        double hygiene = (worker.stats['hygiene'] ?? 30) / 100.0;
        double perception = (worker.stats['perception'] ?? 30) / 100.0;
        double dexterity = (worker.stats['dexterity'] ?? 30) / 100.0;
        double intelligence = (worker.stats['intelligence'] ?? 30) / 100.0;
        double cookQuality =
            (hygiene + perception + dexterity + intelligence) / 4.0;

        final recipeDisplay = recipeId?.replaceAll('_', ' ') ?? "a meal";
        String qualityMsg = cookQuality > 0.6
            ? "exquisitely prepared"
            : (cookQuality < 0.3 ? "poorly prepared" : "prepared");
        return TaskResult(
          message:
              "${worker.name} finished processing $recipeDisplay. It appears to be $qualityMsg.",
          quality: cookQuality * 2.0,
        );
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        // Cleaning: endurance, hygiene, temperament
        double endurance = (worker.stats['endurance'] ?? 30) / 100.0;
        double hygiene = (worker.stats['hygiene'] ?? 30) / 100.0;
        double temperament = (worker.stats['temperament'] ?? 30) / 100.0;
        double cleanQuality = (endurance + hygiene + temperament) / 3.0;

        String cleanMsg = cleanQuality > 0.6
            ? "spotless"
            : (cleanQuality < 0.3 ? "somewhat tidy" : "clean");

        final specimens = _generateSpecimenLoot(type, targetId);

        return TaskResult(
          message:
              "${targetName != null ? "The $targetName" : "The target"} is now $cleanMsg thanks to ${worker.name}.${specimens.isNotEmpty ? " A specimen was found!" : ""}",
          quality: cleanQuality * 2.0,
          itemsFound: specimens,
        );

      case TaskType.restoreRoom:
        // Restoration: strength, endurance, dexterity
        double strength = (worker.stats['strength'] ?? 30) / 100.0;
        double endurance = (worker.stats['endurance'] ?? 30) / 100.0;
        double dexterity = (worker.stats['dexterity'] ?? 30) / 100.0;
        double restoreQuality = (strength + endurance + dexterity) / 3.0;

        final specimens = _generateSpecimenLoot(type, targetId);

        return TaskResult(
          message:
              "${worker.name} finished restoring ${targetName != null ? "the $targetName" : "the room"}.${specimens.isNotEmpty ? " During the heavy work, a specimen was uncovered!" : ""}",
          quality: restoreQuality * 2.0,
          itemsFound: specimens,
        );

      case TaskType.research:
      case TaskType.transcribeNotes:
      case TaskType.observeExperiment:
      case TaskType.archiveResearch:
        // Research: intelligence, judgment, perception
        double intelligence = (worker.stats['intelligence'] ?? 30) / 100.0;
        double judgment = (worker.stats['judgment'] ?? 30) / 100.0;
        double perception = (worker.stats['perception'] ?? 30) / 100.0;
        double researchQuality = (intelligence + judgment + perception) / 3.0;

        List<GameItem> researchLoots = [];
        if (_random.nextDouble() < (0.2 + researchQuality * 0.4)) {
          researchLoots.add(
            GameItem.create(
              name: 'Research Note',
              type: 'research_note',
              category: ItemCategory.knowledge,
              quality: (0.5 + researchQuality).clamp(0.1, 2.0),
              metadata: {'discipline': 'Anatomy'},
            ),
          );
        }
        return TaskResult(
          message:
              "${worker.name} completed their research. Quality: ${(researchQuality * 10).toInt()}/10",
          itemsFound: researchLoots,
          quality: researchQuality * 2.0,
        );

      case TaskType.construction:
      case TaskType.manufacturing:
      case TaskType.blacksmithing:
      case TaskType.surgery:
      case TaskType.surgicalOperation:
        // Operations: dexterity, judgment, intelligence, endurance
        double dexterity = (worker.stats['dexterity'] ?? 30) / 100.0;
        double judgment = (worker.stats['judgment'] ?? 30) / 100.0;
        double intelligence = (worker.stats['intelligence'] ?? 30) / 100.0;
        double endurance = (worker.stats['endurance'] ?? 30) / 100.0;
        double opQuality =
            (dexterity + judgment + intelligence + endurance) / 4.0;

        return TaskResult(
          message:
              "Operation completed with ${(opQuality * 10).toInt()}/10 precision.",
          quality: opQuality * 2.0,
        );

      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.tillSoil:
      case TaskType.harvestCrops:
        // Farming: strength, endurance, temperament
        double strength = (worker.stats['strength'] ?? 30) / 100.0;
        double endurance = (worker.stats['endurance'] ?? 30) / 100.0;
        double temperament = (worker.stats['temperament'] ?? 30) / 100.0;
        double farmEfficiency = (strength + endurance + temperament) / 3.0;

        return TaskResult(
          message:
              "Farming task completed. ${worker.name} worked with ${(farmEfficiency * 10).toInt()}/10 vigor.",
          quality: farmEfficiency * 2.0,
        );

      case TaskType.collectEggs:
        return TaskResult(message: "${worker.name} went to collect eggs.");
      case TaskType.harvestCabbage:
        return TaskResult(message: "Harvested fresh cabbage from the fields.");
      case TaskType.hunt:
        return _generateHuntResult();
      case TaskType.dissect:
        final intellect =
            worker.stats['intelligence'] ?? 30; // Changed from intellect
        final qualityBonus = (intellect / 100.0) * 0.5;
        
        return TaskResult(
          message: "The autopsy is complete. Anatomical notes have been filed.",
          itemsFound: [
            GameItem.create(
              name: 'Anatomical Study',
              type: 'research_note',
              category: ItemCategory.knowledge,
              quality: (0.8 + qualityBonus).clamp(0.1, 2.0),
              metadata: {'discipline': 'Anatomy'},
            ),
          ],
        );
      case TaskType.guardCoop:
        return TaskResult(
          message:
              "${worker.name} kept a watchful eye on the coop through the night.",
        );
      case TaskType.greetGuest:
        return TaskResult(
          message: "${worker.name} welcomed a guest into the entryway.",
        );
      case TaskType.rest:
        return TaskResult(
          message: "${worker.name} took some time to rest and recuperate.",
        );
      case TaskType.eat:
        return TaskResult(message: "${worker.name} finished a meal.");
      case TaskType.useToilet:
        return TaskResult(
            message: "${worker.name} finished using the washroom.");
      case TaskType.wash:
        return TaskResult(message: "${worker.name} finished washing up.");
      case TaskType.idle:
        return TaskResult(
          message: "${worker.name} is waiting instructions at their post.",
        );
      case TaskType.brew:
        return TaskResult(
          message: "${worker.name} brewed a batch of golden mountain ale.",
          resourcesGained: {'grain': -3, 'ale': 2},
        );
      case TaskType.distill:
        return TaskResult(
          message: "${worker.name} distilled potent spirits from the ale.",
          resourcesGained: {'ale': -2, 'spirits': 1},
        );
      case TaskType.processTimber:
        return TaskResult(
          message:
              "${worker.name} processed raw wood into high-quality timber.",
          resourcesGained: {'wood': -5, 'timber': 2},
        );
      case TaskType.harvestGrain:
        return TaskResult(
          message: "${worker.name} harvested a bountiful crop of golden grain.",
          resourcesGained: {'grain': 5 + _random.nextInt(4)},
        );
      case TaskType.setupBrewery:
        return TaskResult(
          message: "${worker.name} finished installing the brewing vats.",
        );
      case TaskType.setupDistillery:
        return TaskResult(
          message:
              "${worker.name} completed the calibration of the spirit stills.",
        );
      case TaskType.setupWorkshop:
        return TaskResult(
          message: "${worker.name} organized the carpenter's workshop.",
        );
      case TaskType.setupGranary:
        return TaskResult(
          message: "${worker.name} prepared the granary for storage.",
        );
      case TaskType.collectIngredients:
        return TaskResult(
          message: "${worker.name} collected various supplies.",
        );
      case TaskType.spyOnNeighbor:
        final success = _random.nextDouble() > 0.3;
        if (success) {
          final lootType = _random.nextInt(3);
          String lootMsg = "";
          List<GameItem> loots = [];
          if (lootType == 0) {
            lootMsg = "found some exquisite jewelry.";
          } else if (lootType == 1) {
            lootMsg = "intercepted a confidential letter.";
          } else {
            lootMsg = "stole some valuable research notes.";
            loots.add(
              GameItem.create(
                name: "Stolen Research Notes",
                type: "research_note",
                category: ItemCategory.knowledge,
                metadata: {'discipline': 'Anatomy'},
              ),
            );
          }
          return TaskResult(
            message:
                "${worker.name} successfully spied on the neighbor and $lootMsg",
            itemsFound: loots,
          );
        } else {
          return TaskResult(
            message:
                "${worker.name} was nearly caught while spying and had to retreat!",
          );
        }
      case TaskType.recombineSpecimen:
        return TaskResult(
          message: "The specimen was caught and returned to containment.",
        );
      case TaskType.defendManor:
        return TaskResult(
          message: "The intruder was driven off. The manor is safe.",
        );
      default:
        return TaskResult(message: "${type.displayName} completed.");
    }
  }

  static TaskResult _generateHuntResult() {
    double r = _random.nextDouble();
    if (r < 0.4) {
      return TaskResult(
        message: "The hunt was successful: a fat hare has been caught.",
        resourcesGained: {'meat': 1},
      );
    } else if (r < 0.6) {
      return TaskResult(
        message: "A brace of pheasants was brought down in the woods.",
        resourcesGained: {'meat': 2},
      );
    } else if (r < 0.1) {
      return TaskResult(
        message: "A rare ibex was spotted and taken!",
        resourcesGained: {'meat': 5, 'leather': 1},
      );
    }
    return TaskResult(
      message: "The butler returned empty-handed from the woods.",
    );
  }

  static List<GameItem> _generateSpecimenLoot(TaskType type, String? targetId) {
    List<GameItem> loots = [];
    final isRestoring = type == TaskType.restoreRoom;

    final isBatRoom = targetId == 'attic' || targetId == 'chicken_coop';
    final roll = _random.nextDouble();

    if (isBatRoom) {
      final batChance = isRestoring ? 0.15 : 0.04;
      if (roll < batChance) {
        final gender = _random.nextBool() ? 'Male' : 'Female';
        final age = 4 + _random.nextInt(17); // 4-20 weeks
        final weight = 10 + _random.nextInt(31); // 10-40g
        final species = 'Brown Bat';

        loots.add(
          GameItem.create(
            name: '$species ($gender, $age wks, ${weight}g)',
            type: 'bat_specimen',
            category: ItemCategory.specimen,
            metadata: {
              'specimenType': 'Bat',
              'species': species,
              'gender': gender,
              'ageWeeks': age,
              'weightGrams': weight,
            },
          ),
        );
      }
    } else {
      final ratChance = isRestoring ? 0.20 : 0.08;
      if (roll < ratChance) {
        final gender = _random.nextBool() ? 'Male' : 'Female';
        final age = 4 + _random.nextInt(17); // 4-20 weeks
        final weight = 100 + _random.nextInt(201); // 100-300g
        final species = 'Brown Rat';

        loots.add(
          GameItem.create(
            name: '$species ($gender, $age wks, ${weight}g)',
            type: 'rat_specimen',
            category: ItemCategory.specimen,
            metadata: {
              'specimenType': 'Rat',
              'species': species,
              'gender': gender,
              'ageWeeks': age,
              'weightGrams': weight,
            },
          ),
        );
      }
    }

    return loots;
  }
}
