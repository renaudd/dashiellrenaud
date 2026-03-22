import '../services/task_service.dart';

enum ResponsibilityCategory {
  medical,
  cooking,
  farming,
  labor,
  crafting,
  cleaning,
  research,
}

extension ResponsibilityCategoryExtensions on ResponsibilityCategory {
  String get displayName {
    switch (this) {
      case ResponsibilityCategory.medical:
        return 'Medical';
      case ResponsibilityCategory.cooking:
        return 'Cooking';
      case ResponsibilityCategory.farming:
        return 'Farming';
      case ResponsibilityCategory.labor:
        return 'Labor';
      case ResponsibilityCategory.crafting:
        return 'Crafting';
      case ResponsibilityCategory.cleaning:
        return 'Cleaning';
      case ResponsibilityCategory.research:
        return 'Research';
    }
  }
}

class TaskCategoryMapping {
  static ResponsibilityCategory? getCategory(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return ResponsibilityCategory.cleaning;

      case TaskType.collectEggs:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.tillSoil:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.refinePlantFungus:
        return ResponsibilityCategory.farming;

      case TaskType.research:
      case TaskType.transcribeNotes:
      case TaskType.observeExperiment:
      case TaskType.archiveResearch:
      case TaskType.deprivationStudy:
      case TaskType.puzzleStudy:
      case TaskType.invention:
      case TaskType.refineLifeForm:
      case TaskType.trainCreature:
        return ResponsibilityCategory.research;

      case TaskType.dissect:
      case TaskType.surgicalOperation:
      case TaskType.clinicalTrial:
      case TaskType.vivisection:
      case TaskType.surgery:
      case TaskType.careForInjured:
      case TaskType.careForSick:
      case TaskType.stopBleeding:
      case TaskType.diagnoseIllness:
      case TaskType.treatIllness:
      case TaskType.checkBedridden:
      case TaskType.surgicalCombination:
        return ResponsibilityCategory.medical;

      case TaskType.cook:
      case TaskType.prepareMeals:
      case TaskType.refineFood:
      case TaskType.butcherAnimals:
        return ResponsibilityCategory.cooking;

      case TaskType.brew:
      case TaskType.distill:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.refineNonLiving:
        return ResponsibilityCategory.crafting;

      case TaskType.hunt:
      case TaskType.guardCoop:
      
      case TaskType.greetGuest:
      case TaskType.setupBrewery:
      case TaskType.setupDistillery:
      case TaskType.setupWorkshop:
      case TaskType.setupGranary:
      case TaskType.collectIngredients:
      case TaskType.spyOnNeighbor:
      case TaskType.processTimber:
      case TaskType.hauling:
      case TaskType.construction:
      case TaskType.mining:
      case TaskType.strengthLabor:
      case TaskType.restoreRoom:
      case TaskType.breedingAttempt:
      case TaskType.extinguishFire:
      case TaskType.recombineSpecimen:
      case TaskType.defendManor:
        return ResponsibilityCategory.labor;

      case TaskType.study:
      case TaskType.experiment:
      case TaskType.operation:
      case TaskType.rest:
      case TaskType.eat:
      case TaskType.idle:
      case TaskType.useToilet:
      case TaskType.wash:
      case TaskType.relax:
        return null;
    }
  }

  static List<TaskType> getTasksForCategory(ResponsibilityCategory category) {
    return TaskType.values
        .where((type) => getCategory(type) == category)
        .toList();
  }
}
