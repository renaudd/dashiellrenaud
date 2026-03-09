import '../models/game_item.dart';

enum TaskType {
  cleanRoom,
  collectEggs,
  harvestCabbage,
  hunt,
  research,
  dissect,
  cook,
  transcribeNotes,
  observeExperiment,
  guardCoop,
  butcherChicken,
  archiveResearch,
  greetGuest,
  rest,
  eat,
  idle,
  brew,
  distill,
  processTimber,
  harvestGrain,
  setupBrewery,
  setupDistillery,
  setupWorkshop,
  setupGranary,
  collectIngredients,
  spyOnNeighbor,
  deprivationStudy,
  clinicalTrial,
  puzzleStudy,
  vivisection,
  breedingAttempt,
  surgicalOperation,
  // New tasks from MECE refinement
  surgery,
  careForInjured,
  careForSick,
  stopBleeding,
  diagnoseIllness,
  treatIllness,
  checkBedridden,
  prepareMeals,
  butcherAnimals,
  refineFood,
  plantCrops,
  waterCrops,
  tillSoil,
  fertilizeSoil,
  careForCrops,
  harvestCrops,
  refinePlantFungus,
  hauling,
  construction,
  mining,
  strengthLabor,
  restoreRoom,
  blacksmithing,
  manufacturing,
  refineNonLiving,
  discardSpoiledFood,
  discardTrash,
  invention,
  refineLifeForm,
  cleanDish,
  useToilet,
  extinguishFire,
  recombineSpecimen,
  defendManor,
  trainCreature,
  surgicalCombination,
}

extension TaskTypeExtensions on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.cleanRoom:
        return 'Clean Room';
      case TaskType.collectEggs:
        return 'Collect Eggs';
      case TaskType.harvestCabbage:
        return 'Harvest Cabbage';
      case TaskType.hunt:
        return 'Hunt';
      case TaskType.research:
        return 'Research';
      case TaskType.dissect:
        return 'Dissect';
      case TaskType.cook:
        return 'Cook';
      case TaskType.transcribeNotes:
        return 'Transcribe Notes';
      case TaskType.observeExperiment:
        return 'Observe Experiment';
      case TaskType.guardCoop:
        return 'Guard Coop';
      case TaskType.butcherChicken:
        return 'Butcher Chicken';
      case TaskType.archiveResearch:
        return 'Archive Research';
      case TaskType.greetGuest:
        return 'Greet Guest';
      case TaskType.rest:
        return 'Rest';
      case TaskType.eat:
        return 'Eat';
      case TaskType.idle:
        return 'Idle';
      case TaskType.brew:
        return 'Brew';
      case TaskType.distill:
        return 'Distill';
      case TaskType.processTimber:
        return 'Process Timber';
      case TaskType.harvestGrain:
        return 'Harvest Grain';
      case TaskType.setupBrewery:
        return 'Setup Brewery';
      case TaskType.setupDistillery:
        return 'Setup Distillery';
      case TaskType.setupWorkshop:
        return 'Setup Workshop';
      case TaskType.setupGranary:
        return 'Setup Granary';
      case TaskType.collectIngredients:
        return 'Collect Ingredients';
      case TaskType.spyOnNeighbor:
        return 'Spy on Neighbor';
      case TaskType.deprivationStudy:
        return 'Deprivation Study';
      case TaskType.clinicalTrial:
        return 'Clinical Trial';
      case TaskType.puzzleStudy:
        return 'Puzzle Study';
      case TaskType.vivisection:
        return 'Vivisection';
      case TaskType.breedingAttempt:
        return 'Breeding Attempt';
      case TaskType.surgicalOperation:
        return 'Surgical Operation';
      case TaskType.surgery:
        return 'Surgery';
      case TaskType.careForInjured:
        return 'Care for Injured';
      case TaskType.careForSick:
        return 'Care for Sick';
      case TaskType.stopBleeding:
        return 'Stop Bleeding';
      case TaskType.diagnoseIllness:
        return 'Diagnose Illness';
      case TaskType.treatIllness:
        return 'Treat Illness';
      case TaskType.checkBedridden:
        return 'Check Bed-ridden';
      case TaskType.prepareMeals:
        return 'Prepare Meals';
      case TaskType.butcherAnimals:
        return 'Butcher Animals';
      case TaskType.refineFood:
        return 'Refine Food';
      case TaskType.plantCrops:
        return 'Plant Crops';
      case TaskType.waterCrops:
        return 'Water Crops';
      case TaskType.tillSoil:
        return 'Till Soil';
      case TaskType.fertilizeSoil:
        return 'Fertilize Soil';
      case TaskType.careForCrops:
        return 'Care for Crops';
      case TaskType.harvestCrops:
        return 'Harvest Crops';
      case TaskType.refinePlantFungus:
        return 'Refine Plant/Fungus';
      case TaskType.hauling:
        return 'Hauling';
      case TaskType.construction:
        return 'Construction';
      case TaskType.mining:
        return 'Mining';
      case TaskType.strengthLabor:
        return 'Heavy Labor';
      case TaskType.restoreRoom:
        return 'Restore Room';
      case TaskType.blacksmithing:
        return 'Blacksmithing';
      case TaskType.manufacturing:
        return 'Manufacturing';
      case TaskType.refineNonLiving:
        return 'Refine Non-Living';
      case TaskType.discardSpoiledFood:
        return 'Discard Spoiled Food';
      case TaskType.discardTrash:
        return 'Discard Trash';
      case TaskType.invention:
        return 'Invention';
      case TaskType.refineLifeForm:
        return 'Refine Life Form';
      case TaskType.cleanDish:
        return 'Clean Dish';
      case TaskType.useToilet:
        return 'Using Washroom';
      case TaskType.extinguishFire:
        return 'Extinguishing Fire';
      case TaskType.recombineSpecimen:
        return 'Recombining Specimen';
      case TaskType.defendManor:
        return 'Defending Manor';
      case TaskType.trainCreature:
        return 'Train Creature';
      case TaskType.surgicalCombination:
        return 'Surgical Combination';
    }
  }
}

class TaskResult {
  final String message;
  final Map<String, int> resourcesGained; // {'wood': 2, 'eggs': 4}
  final List<GameItem> itemsFound;
  final double quality; // 0.0 to 2.0 (standard 1.0)

  TaskResult({
    required this.message,
    this.resourcesGained = const {},
    this.itemsFound = const [],
    this.quality = 1.0,
  });
}

class GameTask {
  final String id;
  final String npcId;
  final TaskType type;
  final String? targetId; // roomId, etc.
  final String? recipeId;
  double progressAccumulator = 0.0;
  final int totalMinutes;
  int minutesRemaining;
  bool isCompleted;

  GameTask({
    required this.id,
    required this.npcId,
    required this.type,
    this.targetId,
    this.recipeId,
    required this.minutesRemaining,
    this.totalMinutes = 0,
    this.isCompleted = false,
  });
}

class TaskMetadata {
  final String explanation;
  final String typicalDuration;
  final List<String> relevantAttributes;
  final List<String> possibleOutcomes;
  final Map<String, int> requirements;

  const TaskMetadata({
    required this.explanation,
    required this.typicalDuration,
    required this.relevantAttributes,
    required this.possibleOutcomes,
    this.requirements = const {},
  });
}

class TaskService {
  final List<GameTask> _activeTasks = [];

  List<GameTask> get activeTasks => List.unmodifiable(_activeTasks);

  static TaskMetadata getMetadata(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return const TaskMetadata(
          explanation: "Systematically removing dust and grime from the manor.",
          typicalDuration: "1-2 Hours",
          relevantAttributes: ['endurance', 'hygiene', 'temperament'],
          possibleOutcomes: [
            "Clean surfaces",
            "Improved hygiene",
            "Better morale",
          ],
        );
      case TaskType.research:
        return const TaskMetadata(
          explanation:
              "General Research: Synthesize insights from your collection. Advances a random scientific discipline by 12-15 points.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['intelligence', 'judgment', 'perception'],
          possibleOutcomes: [
            "Random scientific advancement",
            "Research notes",
            "Scientific breakthroughs",
          ],
        );
      case TaskType.archiveResearch:
        return const TaskMetadata(
          explanation:
              "Archival Research: Move all carried research notes and studies into the local room's catalog for permanent reference.",
          typicalDuration: "1-2 Hours",
          relevantAttributes: ['dexterity', 'judgment', 'perception'],
          possibleOutcomes: [
            "Organized knowledge",
            "Increased research efficiency",
          ],
        );
      case TaskType.transcribeNotes:
        return const TaskMetadata(
          explanation:
              "Formal Transcription: Convert raw, messy research notes into structured studies, increasing their scientific value by 20%.",
          typicalDuration: "3-5 Hours",
          relevantAttributes: ['intelligence', 'dexterity', 'perception'],
          possibleOutcomes: [
            "High-quality research studies",
            "Improved data clarity",
          ],
        );
      case TaskType.observeExperiment:
        return const TaskMetadata(
          explanation:
              "Longitudinal Observation: Carefully monitor an ongoing experiment to record its progression and note unexpected variables.",
          typicalDuration: "2-4 Hours",
          relevantAttributes: ['perception', 'intelligence', 'temperament'],
          possibleOutcomes: ["Experimental data", "Incremental breakthroughs"],
        );
      case TaskType.cook:
      case TaskType.prepareMeals:
      case TaskType.refineFood:
      case TaskType.butcherAnimals:
        return const TaskMetadata(
          explanation: "Converting raw ingredients into nourishing sustenence.",
          typicalDuration: "1-3 Hours",
          relevantAttributes: [
            'hygiene',
            'perception',
            'dexterity',
            'intelligence',
          ],
          possibleOutcomes: [
            "High-quality food",
            "Improved health",
            "Culinary skill",
          ],
        );
      case TaskType.dissect:
      case TaskType.vivisection:
        return const TaskMetadata(
          explanation:
              "Anatomizing a subject to understand its internal biology, often at great moral cost.",
          typicalDuration: "3-5 Hours",
          relevantAttributes: ['dexterity', 'intelligence', 'perception'],
          possibleOutcomes: [
            "Anatomical data",
            "Biological specimens",
            "Scientific depth",
            "Moral corruption",
          ],
        );
      case TaskType.clinicalTrial:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
        return const TaskMetadata(
          explanation:
              "Observing the long-term effects of controlled experimental conditions on a subject.",
          typicalDuration: "16-120 Hours",
          relevantAttributes: ['intelligence', 'perception', 'judgment'],
          possibleOutcomes: [
            "Experimental data",
            "Scientific breakthroughs",
            "Subject mortality",
          ],
        );
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.tillSoil:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
        return const TaskMetadata(
          explanation: "Performing essential agricultural labor for survival.",
          typicalDuration: "3-6 Hours",
          relevantAttributes: ['strength', 'endurance', 'temperament'],
          possibleOutcomes: ["Food resources", "Seeds", "Physical exhaustion"],
        );
      case TaskType.invention:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.processTimber:
        return const TaskMetadata(
          explanation: "Fabricating tools and structural components.",
          typicalDuration: "8-24 Hours",
          relevantAttributes: ['intelligence', 'dexterity', 'judgment'],
          possibleOutcomes: [
            "Manor upgrades",
            "New apparatus",
            "Industrial progress",
          ],
        );
      case TaskType.surgery:
      case TaskType.surgicalOperation:
        return const TaskMetadata(
          explanation: "Performing complex medical or life-science procedures.",
          typicalDuration: "2-6 Hours",
          relevantAttributes: [
            'dexterity',
            'judgment',
            'intelligence',
            'endurance',
          ],
          possibleOutcomes: [
            "Surgical success",
            "Physiological change",
            "Risk of death",
          ],
        );
      case TaskType.hunt:
        return const TaskMetadata(
          explanation: "Securing fresh protein from the estate grounds.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['dexterity', 'perception', 'endurance'],
          possibleOutcomes: ["Meat", "Hides", "Practical experience"],
        );
      case TaskType.guardCoop:
      case TaskType.defendManor:
        return const TaskMetadata(
          explanation: "Maintaining vigilance against external threats.",
          typicalDuration: "8-12 Hours",
          relevantAttributes: ['perception', 'endurance', 'temperament'],
          possibleOutcomes: ["Security", "Resident safety", "Deterrence"],
        );
      case TaskType.brew:
      case TaskType.distill:
        return const TaskMetadata(
          explanation: "The refined art of crafting ales and spirits.",
          typicalDuration: "4-6 Hours",
          relevantAttributes: ['intelligence', 'perception', 'dexterity'],
          possibleOutcomes: ["Beverages", "Social morale", "Trade goods"],
        );
      case TaskType.restoreRoom:
        return const TaskMetadata(
          explanation:
              "Renovating a section of the manor to functional status.",
          typicalDuration: "12-48 Hours",
          relevantAttributes: ['strength', 'endurance', 'dexterity'],
          possibleOutcomes: ["New room access", "Structural integrity"],
        );
      case TaskType.setupBrewery:
        return const TaskMetadata(
          explanation:
              "Installing massive copper mash tuns and fermentation vats.",
          typicalDuration: "6-12 Hours",
          relevantAttributes: ['strength', 'endurance', 'dexterity'],
          possibleOutcomes: ["Functional Brewery", "Industrial expansion"],
          requirements: {'funds': 20, 'wood': 15, 'timber': 5},
        );
      case TaskType.setupDistillery:
        return const TaskMetadata(
          explanation:
              "Calibrating a precision spirit still and condenser coils.",
          typicalDuration: "8-16 Hours",
          relevantAttributes: ['intelligence', 'perception', 'dexterity'],
          possibleOutcomes: ["Functional Distillery", "Advanced industry"],
          requirements: {'funds': 30, 'wood': 10, 'timber': 10, 'spirits': 1},
        );
      case TaskType.setupWorkshop:
        return const TaskMetadata(
          explanation:
              "Organizing tools and machinery for advanced manufacturing.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['dexterity', 'strength', 'intelligence'],
          possibleOutcomes: ["Functional Workshop", "Manufacturing hub"],
          requirements: {'funds': 15, 'wood': 20, 'timber': 5},
        );
      case TaskType.setupGranary:
        return const TaskMetadata(
          explanation:
              "Establishing reinforced storage for large-scale harvests.",
          typicalDuration: "6-10 Hours",
          relevantAttributes: ['strength', 'endurance', 'intelligence'],
          possibleOutcomes: ["Functional Granary", "Food security"],
          requirements: {'funds': 10, 'wood': 15, 'timber': 10},
        );
      // Fallback for others
      default:
        return const TaskMetadata(
          explanation: "A standard manor duty requiring attention and effort.",
          typicalDuration: "2-4 Hours",
          relevantAttributes: [],
          possibleOutcomes: ["Completion", "Experience gain"],
        );
    }
  }

  static List<String> getRelevantAttributes(TaskType type) {
    return getMetadata(type).relevantAttributes;
  }

  void addTask(GameTask task) {
    _activeTasks.add(task);
  }

  void removeTask(String taskId) {
    _activeTasks.removeWhere((t) => t.id == taskId);
  }

  void cancelTask(String taskId) {
    _activeTasks.removeWhere((t) => t.id == taskId);
  }

  void assignTask({
    required String npcId,
    required TaskType type,
    String? targetId,
    String? recipeId,
    required int durationMinutes,
  }) {

    _activeTasks.add(
      GameTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        npcId: npcId,
        type: type,
        targetId: targetId,
        recipeId: recipeId,
        minutesRemaining: durationMinutes,
        totalMinutes: durationMinutes,
      ),
    );
  }

  List<GameTask> processTick(
    List<String> readyNpcIds,
    Set<String> activeTaskIds,
    Map<String, int> Function(String) getStats,
  ) {
    final completed = <GameTask>[];
    for (var task in _activeTasks) {
      if (!task.isCompleted &&
          readyNpcIds.contains(task.npcId) &&
          activeTaskIds.contains(task.id)) {
        // Calculate efficiency based on relevant attributes
        final relevantAttrs = getRelevantAttributes(task.type);
        double efficiency = 1.0;

        if (relevantAttrs.isNotEmpty) {
          final stats = getStats(task.npcId);
          int sum = 0;
          for (var attr in relevantAttrs) {
            sum += stats[attr] ?? 30; // Default to median 3
          }
          // efficiency = (Average(RelevantStats) / 30.0)
          // At median 3 (30), efficiency is 1.0
          efficiency = (sum / relevantAttrs.length) / 30.0;
          // Clamp efficiency to avoid extreme slowdowns or hyper-speed
          efficiency = efficiency.clamp(0.2, 3.0);
        }

        task.progressAccumulator += efficiency;

        while (task.progressAccumulator >= 1.0 && !task.isCompleted) {
          task.minutesRemaining--;
          task.progressAccumulator -= 1.0;
          if (task.minutesRemaining <= 0) {
            task.isCompleted = true;
            completed.add(task);
          }
        }
      }
    }
    _activeTasks.removeWhere((task) => task.isCompleted);
    return completed;
  }

  String getTaskDescription(GameTask task) {
    switch (task.type) {
      case TaskType.cleanRoom:
        return "Cleaning room";
      case TaskType.collectEggs:
        return "Collecting eggs";
      case TaskType.harvestCabbage:
        return "Harvesting cabbage";
      case TaskType.hunt:
        return "Hunting";
      case TaskType.research:
        return "Researching";
      case TaskType.dissect:
        return "Dissecting";
      case TaskType.transcribeNotes:
        return "Transcribing notes";
      case TaskType.observeExperiment:
        return "Observing experiment";
      case TaskType.cook:
        return task.recipeId != null
            ? "Cooking ${task.recipeId!.replaceAll('_', ' ')}"
            : "Cooking";
      case TaskType.guardCoop:
        return "Guarding chicken coop";
      case TaskType.butcherChicken:
        return "Butchering poultry";
      case TaskType.archiveResearch:
        return "Archiving forbidden lore";
      case TaskType.greetGuest:
        return "Greeting a guest";
      case TaskType.rest:
        return "Resting";
      case TaskType.eat:
        return "Eating";
      case TaskType.idle:
        return "Staying at post";
      case TaskType.brew:
        return "Brewing ale";
      case TaskType.distill:
        return "Distilling spirits";
      case TaskType.processTimber:
        return "Processing timber";
      case TaskType.harvestGrain:
        return "Harvesting grain";
      case TaskType.setupBrewery:
        return "Setting up brewery equipment";
      case TaskType.setupDistillery:
        return "Calibrating distillery still";
      case TaskType.setupWorkshop:
        return "Organizing carpenter's workshop";
      case TaskType.setupGranary:
        return "Preparing granary storage";
      case TaskType.collectIngredients:
        return "Collecting supplies";
      case TaskType.spyOnNeighbor:
        return "Spying on neighbor";
      case TaskType.deprivationStudy:
        return "Conducting deprivation study";
      case TaskType.clinicalTrial:
        return "Administering clinical trials";
      case TaskType.puzzleStudy:
        return "Conducting cognitive puzzle study";
      case TaskType.vivisection:
        return "Performing vivisection";
      case TaskType.breedingAttempt:
        return "Managing breeding attempt";
      case TaskType.surgicalOperation:
        return "Performing surgical operation";
      case TaskType.surgery:
        return "Performing delicate surgery";
      case TaskType.careForInjured:
        return "Caring for the injured";
      case TaskType.careForSick:
        return "Tending to the sick";
      case TaskType.stopBleeding:
        return "Stopping blood loss";
      case TaskType.diagnoseIllness:
        return "Diagnosing a strange illness";
      case TaskType.treatIllness:
        return "Treating a persistent illness";
      case TaskType.checkBedridden:
        return "Checking on the bed-ridden";
      case TaskType.prepareMeals:
        return "Preparing a hearty meal";
      case TaskType.butcherAnimals:
        return "Butchering animals for meat";
      case TaskType.refineFood:
        return "Refining ingredients into delicacies";
      case TaskType.plantCrops:
        return "Planting seedlings in the soil";
      case TaskType.waterCrops:
        return "Watering thirsty crops";
      case TaskType.tillSoil:
        return "Tilling the garden soil";
      case TaskType.fertilizeSoil:
        return "Fertilizing the fields";
      case TaskType.careForCrops:
        return "Caring for growing plants";
      case TaskType.harvestCrops:
        return "Harvesting agricultural bounty";
      case TaskType.refinePlantFungus:
        return "Refining horticultural specimens";
      case TaskType.hauling:
        return "Hauling heavy goods";
      case TaskType.construction:
        return "Working on construction";
      case TaskType.mining:
        return "Mining for minerals";
      case TaskType.strengthLabor:
        return "Performing arduous labor";
      case TaskType.restoreRoom:
        return "Restoring a dilapidated room";
      case TaskType.blacksmithing:
        return "Toiling at the forge";
      case TaskType.manufacturing:
        return "Manufacturing goods";
      case TaskType.refineNonLiving:
        return "Refining non-living materials";
      case TaskType.discardSpoiledFood:
        return "Discarding spoiled provisions";
      case TaskType.discardTrash:
        return "Clearing out accumulated trash";
      case TaskType.invention:
        return "Working on a new invention";
      case TaskType.refineLifeForm:
        return "Refining biological specimens";
      case TaskType.cleanDish:
        return "Cleaning a dirty dish";
      case TaskType.useToilet:
        return "Using the toilet";
      case TaskType.extinguishFire:
        return "Fighting a blaze";
      case TaskType.recombineSpecimen:
        return "Containing a loose specimen";
      case TaskType.defendManor:
        return "Defending the manor from intruders";
      case TaskType.trainCreature:
        return "Training a creature for combat";
      case TaskType.surgicalCombination:
        return "Combining specimens via specialized surgery";
    }
  }
}
