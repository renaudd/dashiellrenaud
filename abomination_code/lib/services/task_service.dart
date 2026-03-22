import '../models/game_item.dart';
import '../models/npc_intent.dart';

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
  wash,
  study,
  experiment,
  operation,
  relax,
}


extension TaskTypeExtensions on TaskType {
  String get displayName {
    switch (this) {
      case TaskType.wash:
        return 'Wash';
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
        return 'Transcribe';
      case TaskType.observeExperiment:
        return 'Observe Experiment';
      case TaskType.guardCoop:
        return 'Guard Coop';
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
        return 'Breed Attempt';
      case TaskType.surgicalOperation:
        return 'Surgical Operation';
      case TaskType.surgery:
        return 'Surgery';
      case TaskType.careForInjured:
        return 'Care For Injured';
      case TaskType.careForSick:
        return 'Care For Sick';
      case TaskType.stopBleeding:
        return 'Stop Bleeding';
      case TaskType.diagnoseIllness:
        return 'Diagnose Illness';
      case TaskType.treatIllness:
        return 'Treat Illness';
      case TaskType.checkBedridden:
        return 'Check Bedridden';
      case TaskType.prepareMeals:
        return 'Prepare Meals';
      case TaskType.butcherAnimals:
        return 'Butcher Animal';
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
        return 'Care For Crops';
      case TaskType.harvestCrops:
        return 'Harvest Crops';
      case TaskType.refinePlantFungus:
        return 'Refine Plant/Fungus';
      case TaskType.hauling:
        return 'Haul';
      case TaskType.construction:
        return 'Construct';
      case TaskType.mining:
        return 'Mine';
      case TaskType.strengthLabor:
        return 'Heavy Labor';
      case TaskType.restoreRoom:
        return 'Restore Room';
      case TaskType.blacksmithing:
        return 'Blacksmith';
      case TaskType.manufacturing:
        return 'Manufacture';
      case TaskType.refineNonLiving:
        return 'Refining Non-Living';
      case TaskType.discardSpoiledFood:
        return 'Discard Spoiled Food';
      case TaskType.discardTrash:
        return 'Discard Trash';
      case TaskType.invention:
        return 'Invent';
      case TaskType.refineLifeForm:
        return 'Refine Life Form';
      case TaskType.cleanDish:
        return 'Clean Dish';
      case TaskType.useToilet:
        return 'Use Washroom';
      case TaskType.extinguishFire:
        return 'Extinguish Fire';
      case TaskType.recombineSpecimen:
        return 'Recombine Specimen';
      case TaskType.defendManor:
        return 'Defend Manor';
      case TaskType.trainCreature:
        return 'Train Creature';
      case TaskType.surgicalCombination:
        return 'Surgical Combination';
      case TaskType.study:
        return 'Fundamental Research';
      case TaskType.experiment:
        return 'Experiment';
      case TaskType.operation:
        return 'Operation';
      case TaskType.relax:
        return 'Relax';
    }
  }
}

class TaskResult {
  final String message;
  final Map<String, num> resourcesGained; // {'wood': 2, 'eggs': 4}
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
  final String? intentId; // Links back to the AI intent that created this task
  final String npcId;
  final IntentPriority priority;
  final TaskType type;
  final String? targetId; // roomId, etc.
  final String? targetName;
  final String? recipeId;
  final List<String> reservedEntityIds;
  double progressAccumulator = 0.0;
  final int totalMinutes;
  int minutesRemaining;
  bool isCompleted;

  GameTask({
    required this.id,
    this.intentId,
    required this.npcId,
    required this.priority,
    required this.type,
    this.targetId,
    this.targetName,
    this.recipeId,
    this.reservedEntityIds = const [],
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
  final Map<String, num> requirements;

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

  static bool isConcurrent(TaskType type) {
    return type == TaskType.restoreRoom ||
        type == TaskType.construction ||
        type == TaskType.tillSoil ||
        type == TaskType.fertilizeSoil ||
        type == TaskType.waterCrops ||
        type == TaskType.careForCrops ||
        type == TaskType.harvestCrops ||
        type == TaskType.rest ||
        type == TaskType.eat;
  }

  static TaskMetadata getMetadata(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.cleanDish:
      case TaskType.discardTrash:
      case TaskType.discardSpoiledFood:
        return const TaskMetadata(
          explanation: "Systematically removing dust and grime from the manor.",
          typicalDuration: "20-40 Minutes",
          relevantAttributes: ['endurance', 'hygiene', 'temperament'],
          possibleOutcomes: [
            "Clean surfaces",
            "Improved hygiene",
            "Better morale",
          ],
        );
      case TaskType.research:
      case TaskType.study:
      case TaskType.archiveResearch:
        return const TaskMetadata(
          explanation:
              "Synthesize insights from your collection. Advances a scientific discipline or deepens understanding.",
          typicalDuration: "4-8 Hours",
          relevantAttributes: ['intelligence', 'judgment', 'perception'],
          possibleOutcomes: [
            "Increased Knowledge points",
            "Science level advances",
            "Mental exhaustion",
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
      case TaskType.experiment:
        return const TaskMetadata(
          explanation: "Advanced scientific procedures to understand and manipulate biology.",
          typicalDuration: "4-12 Hours",
          relevantAttributes: ['precision', 'judgment', 'intelligence'],
          possibleOutcomes: [
            "Biological insights",
            "High quality specimens",
            "Ethical decay",
          ],
        );
      case TaskType.cook:
        return const TaskMetadata(
          explanation: "Preparing nourishing meals in the manor kitchen.",
          typicalDuration: "45-75 Minutes",
          relevantAttributes: [
            'dexterity',
            'intelligence',
            'perception',
          ],
          possibleOutcomes: [
            "High-quality food",
            "Culinary experience",
            "Burned meal",
          ],
        );
      case TaskType.prepareMeals:
      case TaskType.refineFood:
      case TaskType.butcherAnimals:
        return const TaskMetadata(
          explanation: "Converting raw ingredients into nourishing sustenence.",
          typicalDuration: "45-90 Minutes",
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
      case TaskType.surgicalOperation:
      case TaskType.operation:
      case TaskType.surgery:
      case TaskType.surgicalCombination:
        return const TaskMetadata(
          explanation: "Complex medical or life-science procedures involving anatomical manipulation.",
          typicalDuration: "4-12 Hours",
          relevantAttributes: ['precision', 'judgment', 'intelligence'],
          possibleOutcomes: [
            "Anatomical data",
            "Biological specimens",
            "Surgical skill",
            "Ethical decay",
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
          explanation: "Performing essential agricultural labor on the manor's fields to ensure survival.",
          typicalDuration: "4 Hours",
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
          typicalDuration: "4 Hours",
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
      case TaskType.useToilet:
      case TaskType.wash:
        return const TaskMetadata(
          explanation: "Personal maintenance and hygiene.",
          typicalDuration: "10-20 Minutes",
          relevantAttributes: ['hygiene'],
          possibleOutcomes: ["Improved hygiene", "Mental clarity"],
        );
      case TaskType.eat:
        return const TaskMetadata(
          explanation: "Restoring energy and fullness through nourishing meals.",
          typicalDuration: "30-45 Minutes",
          relevantAttributes: [],
          possibleOutcomes: ["Restored fullness", "Better morale"],
        );
      case TaskType.relax:
        return const TaskMetadata(
          explanation: "Taking a moment to breathe and clear one's mind.",
          typicalDuration: "30-60 Minutes",
          relevantAttributes: ['temperament'],
          possibleOutcomes: ["Restored focus", "Improved morale"],
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
    // DUPLICATE GUARD: Strictly reject if this task ID is already tracked.
    if (_activeTasks.any((t) => t.id == task.id)) return;
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
    String? intentId,
    IntentPriority priority = IntentPriority.normal,
    required int durationMinutes,
    List<String> reservedEntityIds = const [],
  }) {
    // Generate simulation-safe, unique task ID
    final taskId = "task_${npcId}_${DateTime.now().microsecondsSinceEpoch}_${type.name}";

    _activeTasks.add(
      GameTask(
        id: taskId,
        intentId: intentId,
        npcId: npcId,
        priority: priority,
        type: type,
        targetId: targetId,
        recipeId: recipeId,
        reservedEntityIds: reservedEntityIds,
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
        return "Clean room";
      case TaskType.collectEggs:
        return "Collect eggs";
      case TaskType.harvestCabbage:
        return "Harvest cabbage";
      case TaskType.hunt:
        return "Hunt";
      case TaskType.research:
        return "Research";
      case TaskType.dissect:
        return "Dissect";
      case TaskType.transcribeNotes:
        return "Transcribe notes";
      case TaskType.observeExperiment:
        return "Observe experiment";
      case TaskType.cook:
        return task.recipeId != null
            ? "Cook ${task.recipeId!.replaceAll('_', ' ')}"
            : "Cook";
      case TaskType.guardCoop:
        return "Guard chicken coop";
      case TaskType.archiveResearch:
        return "Archive forbidden lore";
      case TaskType.greetGuest:
        return "Greet a guest";
      case TaskType.rest:
        return "Rest";
      case TaskType.eat:
        return "Eat";
      case TaskType.idle:
        return "Stay at post";
      case TaskType.brew:
        return "Brew ale";
      case TaskType.distill:
        return "Distill spirits";
      case TaskType.processTimber:
        return "Process timber";
      case TaskType.harvestGrain:
        return "Harvest grain";
      case TaskType.setupBrewery:
        return "Setup brewery equipment";
      case TaskType.setupDistillery:
        return "Calibrate distillery still";
      case TaskType.setupWorkshop:
        return "Organize carpenter's workshop";
      case TaskType.setupGranary:
        return "Prepare granary storage";
      case TaskType.collectIngredients:
        return "Collect supplies";
      case TaskType.spyOnNeighbor:
        return "Spy on neighbor";
      case TaskType.deprivationStudy:
        return "Conduct deprivation study";
      case TaskType.clinicalTrial:
        return "Administer clinical trials";
      case TaskType.puzzleStudy:
        return "Conduct cognitive puzzle study";
      case TaskType.vivisection:
        return "Perform vivisection";
      case TaskType.breedingAttempt:
        return "Manage breeding attempt";
      case TaskType.surgicalOperation:
        return "Perform surgical operation";
      case TaskType.surgery:
        return "Perform delicate surgery";
      case TaskType.careForInjured:
        return "Care for the injured";
      case TaskType.careForSick:
        return "Tend to the sick";
      case TaskType.stopBleeding:
        return "Stop blood loss";
      case TaskType.diagnoseIllness:
        return "Diagnose a strange illness";
      case TaskType.treatIllness:
        return "Treat a persistent illness";
      case TaskType.checkBedridden:
        return "Check on the bed-ridden";
      case TaskType.prepareMeals:
        return "Prepare a hearty meal";
      case TaskType.butcherAnimals:
        return "Butcher animals for meat";
      case TaskType.refineFood:
        return "Refine ingredients into delicacies";
      case TaskType.plantCrops:
        return "Sow seedlings in the soil";
      case TaskType.waterCrops:
        return "Water thirsty crops";
      case TaskType.tillSoil:
        return "Till the field";
      case TaskType.fertilizeSoil:
        return "Fertilize the field";
      case TaskType.careForCrops:
        return "Tend to growing crops";
      case TaskType.harvestCrops:
        return "Harvest agricultural yield";
      case TaskType.refinePlantFungus:
        return "Refine horticultural specimens";
      case TaskType.hauling:
        return "Haul heavy goods";
      case TaskType.construction:
        return "Work on construction";
      case TaskType.mining:
        return "Mine for minerals";
      case TaskType.strengthLabor:
        return "Perform arduous labor";
      case TaskType.restoreRoom:
        return "Restore a dilapidated room";
      case TaskType.blacksmithing:
        return "Toil at the forge";
      case TaskType.manufacturing:
        return "Manufacture goods";
      case TaskType.refineNonLiving:
        return "Refine non-living materials";
      case TaskType.discardSpoiledFood:
        return "Discard spoiled provisions";
      case TaskType.discardTrash:
        return "Clear out accumulated trash";
      case TaskType.invention:
        return "Work on a new invention";
      case TaskType.refineLifeForm:
        return "Refine biological specimens";
      case TaskType.cleanDish:
        return "Clean a dirty dish";
      case TaskType.useToilet:
        return "Use the toilet";
      case TaskType.wash:
        return "Wash up";
      case TaskType.extinguishFire:
        return "Fight a blaze";
      case TaskType.recombineSpecimen:
        return "Contain a loose specimen";
      case TaskType.defendManor:
        return "Defend the manor from intruders";
      case TaskType.trainCreature:
        return "Train a creature for combat";
      case TaskType.surgicalCombination:
        return "Combine specimens via specialized surgery";
      case TaskType.study:
        return "Study";
      case TaskType.experiment:
        return "Experiment";
      case TaskType.operation:
        return "Perform operation";
      case TaskType.relax:
        return "Relax and restore focus";
    }
  }
}
