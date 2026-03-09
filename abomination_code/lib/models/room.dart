import '../services/task_service.dart' as task_service;
import '../util/manor_layout.dart';
import 'game_item.dart';

enum RoomType {
  entryway,
  kitchen,
  diningRoom,
  study,
  bedroom,
  attic,
  basement,
  toilet,
  butlerQuarters,
  unused,
  laboratory,
  chickenCoop,
  library,
  field,
  garden,
  brewery,
  distillery,
  workshop,
  granary,
}

enum Floor { basement, ground, second, attic }

enum BedType { twin, queen, king, crib }

class Bed {
  final BedType type;
  final List<String?> assignedNpcIds;

  Bed({required this.type, required this.assignedNpcIds});

  bool get isShared => type == BedType.queen || type == BedType.king;
  int get capacity => type == BedType.king || type == BedType.queen ? 2 : 1;

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'assignedNpcIds': assignedNpcIds,
  };

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
    type: BedType.values[json['type'] as int],
    assignedNpcIds: List<String?>.from(json['assignedNpcIds'] as List),
  );

  Bed copyWith({BedType? type, List<String?>? assignedNpcIds}) {
    return Bed(
      type: type ?? this.type,
      assignedNpcIds: assignedNpcIds ?? this.assignedNpcIds,
    );
  }
}

enum ProjectType { cooking, research, laboratory, craft, assembly }

class PhysicalProject {
  final String id;
  final String taskId;
  final String name;
  final ProjectType type;
  final double progress; // 0.0 to 1.0
  final bool isAtWorkstation; // If false, it's "moved to the side"

  PhysicalProject({
    required this.id,
    required this.taskId,
    required this.name,
    required this.type,
    this.progress = 0.0,
    this.isAtWorkstation = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskId': taskId,
    'name': name,
    'type': type.index,
    'progress': progress,
    'isAtWorkstation': isAtWorkstation,
  };

  factory PhysicalProject.fromJson(Map<String, dynamic> json) =>
      PhysicalProject(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        name: json['name'] as String,
        type: ProjectType.values[json['type'] as int],
        progress: (json['progress'] as num).toDouble(),
        isAtWorkstation: json['isAtWorkstation'] as bool? ?? true,
      );

  PhysicalProject copyWith({
    String? id,
    String? taskId,
    String? name,
    ProjectType? type,
    double? progress,
    bool? isAtWorkstation,
  }) {
    return PhysicalProject(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      name: name ?? this.name,
      type: type ?? this.type,
      progress: progress ?? this.progress,
      isAtWorkstation: isAtWorkstation ?? this.isAtWorkstation,
    );
  }
}

class Room {
  final String id;
  final String name;
  final RoomType type;
  final bool isRestored;
  final String description;
  final Floor floor;
  final double width; // Relative width for layout
  final int level;
  final double experience;
  final List<GameItem> inventory;
  final List<String> taskQueue; // List of task descriptions or IDs
  final double dirtiness; // 0.0 to 1.0
  final List<Bed> beds;
  final double tilledAmount; // 0.0 to 1.0
  final double fertilizedAmount; // 0.0 to 1.0
  final String? occupyingNpcId; // Who is currently at the desk/station
  final Map<String, PhysicalProject> activeProjects; // taskId -> project

  Room({
    required this.id,
    required this.name,
    required this.type,
    this.isRestored = false,
    required this.description,
    required this.floor,
    this.width = 1.0,
    this.level = 1,
    this.experience = 0.0,
    this.inventory = const [],
    this.taskQueue = const [],
    this.dirtiness = 0.0,
    this.beds = const [],
    this.tilledAmount = 0.0,
    this.fertilizedAmount = 0.0,
    this.occupyingNpcId,
    this.activeProjects = const {},
  });

  factory Room.initial(
    String id,
    String name,
    RoomType type,
    Floor floor, {
    bool isRestored = true,
    String description = "",
    double width = 1.0,
    int level = 1,
    double experience = 0.0,
    List<GameItem> inventory = const [],
    List<String> taskQueue = const [],
    List<Bed> beds = const [],
  }) {
    return Room(
      id: id,
      name: name,
      type: type,
      isRestored: isRestored,
      description: description,
      floor: floor,
      width: width,
      level: level,
      experience: experience,
      inventory: inventory,
      taskQueue: taskQueue,
      dirtiness: 0.0,
      beds: beds,
      tilledAmount: 0.0,
      fertilizedAmount: 0.0,
      occupyingNpcId: null,
      activeProjects: const {},
    );
  }

  bool get isTilled => tilledAmount >= 1.0;
  bool get isFertilized => fertilizedAmount >= 1.0;

  Room copyWith({
    String? id,
    String? name,
    RoomType? type,
    bool? isRestored,
    String? description,
    Floor? floor,
    double? width,
    int? level,
    double? experience,
    List<GameItem>? inventory,
    List<String>? taskQueue,
    double? dirtiness,
    List<Bed>? beds,
    double? tilledAmount,
    double? fertilizedAmount,
    String? occupyingNpcId,
    bool clearOccupancy = false,
    Map<String, PhysicalProject>? activeProjects,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isRestored: isRestored ?? this.isRestored,
      description: description ?? this.description,
      floor: floor ?? this.floor,
      width: width ?? this.width,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      inventory: inventory ?? this.inventory,
      taskQueue: taskQueue ?? this.taskQueue,
      dirtiness: dirtiness ?? this.dirtiness,
      beds: beds ?? this.beds,
      tilledAmount: tilledAmount ?? this.tilledAmount,
      fertilizedAmount: fertilizedAmount ?? this.fertilizedAmount,
      occupyingNpcId: clearOccupancy
          ? null
          : (occupyingNpcId ?? this.occupyingNpcId),
      activeProjects: activeProjects ?? this.activeProjects,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'isRestored': isRestored,
    'description': description,
    'floor': floor.index,
    'width': width,
    'level': level,
    'experience': experience,
    'inventory': inventory.map((e) => e.toJson()).toList(),
    'taskQueue': taskQueue,
    'dirtiness': dirtiness,
    'beds': beds.map((e) => e.toJson()).toList(),
    'tilledAmount': tilledAmount,
    'fertilizedAmount': fertilizedAmount,
    'occupyingNpcId': occupyingNpcId,
    'activeProjects': activeProjects.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'] as String,
    name: json['name'] as String,
    type: RoomType.values[json['type'] as int],
    isRestored: json['isRestored'] as bool? ?? false,
    description: json['description'] as String,
    floor: Floor.values[json['floor'] as int],
    width: (json['width'] as num).toDouble(),
    level: json['level'] as int? ?? 1,
    experience: (json['experience'] as num?)?.toDouble() ?? 0.0,
    taskQueue:
        (json['taskQueue'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    dirtiness: (json['dirtiness'] as num?)?.toDouble() ?? 0.0,
    beds: (json['beds'] as List? ?? [])
        .map((b) => Bed.fromJson(b as Map<String, dynamic>))
        .toList(),
    tilledAmount: (json['tilledAmount'] as num?)?.toDouble() ?? 0.0,
    fertilizedAmount: (json['fertilizedAmount'] as num?)?.toDouble() ?? 0.0,
    occupyingNpcId: json['occupyingNpcId'] as String?,
    activeProjects:
        (json['activeProjects'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, PhysicalProject.fromJson(v)),
        ) ??
        {},
  );

  bool get isInsideManor {
    return ManorLayout.structure.values.any((floor) => floor.contains(id));
  }

  double calculateDisciplineKnowledge(String discipline) {
    double total = 0;
    for (var item in inventory) {
      if (item.category == ItemCategory.knowledge &&
          item.metadata['discipline'] == discipline) {
        // Multiplier based on item type
        double typeMultiplier = 1.0;
        switch (item.type) {
          case 'research_notes':
            typeMultiplier = 1.0;
            break;
          case 'research_study':
            typeMultiplier = 5.0;
            break;
          case 'research_book':
            typeMultiplier = 10.0;
            break;
          case 'encyclopedia':
            typeMultiplier = 50.0;
            break;
        }
        total += item.quantity * item.quality * typeMultiplier;
      }
    }
    return total;
  }

  List<task_service.TaskType> get availableTasks {
    if (!isRestored) return [task_service.TaskType.restoreRoom];

    List<task_service.TaskType> tasks = [task_service.TaskType.cleanRoom];

    switch (type) {
      case RoomType.kitchen:
        tasks.addAll([
          task_service.TaskType.cook,
          task_service.TaskType.refineFood,
          task_service.TaskType.butcherAnimals,
          task_service.TaskType.cleanDish,
        ]);
        break;
      case RoomType.study:
        tasks.addAll([
          task_service.TaskType.research,
        ]);
        break;
      case RoomType.laboratory:
        tasks.addAll([
          task_service.TaskType.observeExperiment,
          task_service.TaskType.dissect,
          task_service.TaskType.vivisection,
          task_service.TaskType.surgicalOperation,
          task_service.TaskType.recombineSpecimen,
          task_service.TaskType.invention,
        ]);
        break;
      case RoomType.chickenCoop:
        tasks.addAll([
          task_service.TaskType.collectEggs,
          task_service.TaskType.guardCoop,
          task_service.TaskType.butcherChicken,
        ]);
        break;
      case RoomType.library:
        tasks.addAll([
          task_service.TaskType.archiveResearch,
          task_service.TaskType.transcribeNotes,
          task_service.TaskType.research,
        ]);
        break;
      case RoomType.field:
        tasks.addAll([
          task_service.TaskType.tillSoil,
          task_service.TaskType.plantCrops,
          task_service.TaskType.waterCrops,
          task_service.TaskType.fertilizeSoil,
          task_service.TaskType.careForCrops,
          task_service.TaskType.harvestCrops,
        ]);
        break;
      case RoomType.garden:
        tasks.addAll([
          task_service.TaskType.tillSoil,
          task_service.TaskType.plantCrops,
          task_service.TaskType.waterCrops,
          task_service.TaskType.careForCrops,
          task_service.TaskType.harvestCrops,
          task_service.TaskType.research,
          task_service.TaskType.refinePlantFungus,
        ]);
        break;
      case RoomType.brewery:
        tasks.addAll([
          task_service.TaskType.brew,
          task_service.TaskType.hauling,
        ]);
        break;
      case RoomType.distillery:
        tasks.addAll([
          task_service.TaskType.distill,
          task_service.TaskType.hauling,
        ]);
        break;
      case RoomType.workshop:
        tasks.addAll([
          task_service.TaskType.processTimber,
          task_service.TaskType.blacksmithing,
          task_service.TaskType.manufacturing,
          task_service.TaskType.invention,
        ]);
        break;
      case RoomType.granary:
        tasks.addAll([
          task_service.TaskType.harvestGrain,
          task_service.TaskType.hauling,
        ]);
        break;
      case RoomType.bedroom:
      case RoomType.butlerQuarters:
      case RoomType.attic:
      case RoomType.basement:
        tasks.add(task_service.TaskType.rest);
        break;
      case RoomType.toilet:
        tasks.add(task_service.TaskType.useToilet);
        break;
      case RoomType.entryway:
        tasks.addAll([
          task_service.TaskType.greetGuest,
          task_service.TaskType.defendManor,
        ]);
        break;
      case RoomType.diningRoom:
        tasks.add(task_service.TaskType.eat);
        break;
      case RoomType.unused:
        tasks.addAll([
          task_service.TaskType.setupBrewery,
          task_service.TaskType.setupDistillery,
          task_service.TaskType.setupWorkshop,
          task_service.TaskType.setupGranary,
        ]);
        break;
    }

    return tasks;
  }

  static ProjectType getProjectType(task_service.TaskType type) {
    switch (type) {
      case task_service.TaskType.cook:
      case task_service.TaskType.prepareMeals:
      case task_service.TaskType.refineFood:
      case task_service.TaskType.butcherAnimals:
        return ProjectType.cooking;
      case task_service.TaskType.research:
      case task_service.TaskType.transcribeNotes:
      case task_service.TaskType.archiveResearch:
        return ProjectType.research;
      case task_service.TaskType.dissect:
      case task_service.TaskType.vivisection:
      case task_service.TaskType.surgicalOperation:
      case task_service.TaskType.recombineSpecimen:
      case task_service.TaskType.observeExperiment:
        return ProjectType.laboratory;
      case task_service.TaskType.blacksmithing:
      case task_service.TaskType.manufacturing:
      case task_service.TaskType.invention:
      case task_service.TaskType.processTimber:
        return ProjectType.craft;
      case task_service.TaskType.construction:
      case task_service.TaskType.setupBrewery:
      case task_service.TaskType.setupDistillery:
      case task_service.TaskType.setupWorkshop:
      case task_service.TaskType.setupGranary:
        return ProjectType.assembly;
      default:
        return ProjectType.craft;
    }
  }

  String get detailedDescription {
    String hygieneNote = "";
    if (isRestored) {
      if (dirtiness > 0.8) {
        hygieneNote =
            "\n\nCRITICAL: The room is FILTHY and needs immediate cleaning.";
      } else if (dirtiness > 0.4) {
        hygieneNote =
            "\n\nWARNING: The surfaces are covered in a noticeable layer of grime.";
      } else if (dirtiness > 0.1) {
        hygieneNote = "\n\nNOTE: It's starting to look a bit dusty.";
      }
    }

    if (!isRestored) {
      if (type == RoomType.unused) {
        if (isInsideManor) {
          return "A hollow, dusty space within the manor walls. It awaits a purpose and the materials for its configuration. Once restored, it can be assigned as a specialized workshop or storage area.";
        } else {
          return "A cleared plot of ground on the estate grounds. Though not arable like the fields, it is suitable for construction of specialized outbuildings like a greenhouse, stable, or additional housing.";
        }
      }
      return "This area remains in a state of disrepair. Dust-choked and dilapidated, it requires significant restoration work before it can be used for its intended purpose.";
    }

    String baseDesc = "";
    String capabilities = "";

    switch (type) {
      case RoomType.kitchen:
        baseDesc =
            "A vast fireplace dominates this brick-lined hall. Though now restored, the air still carries a faint scent of century-old grease and iron.";
        capabilities =
            "It serves as the heart of the estate's industry, where meat is butchered, ingredients refined, and hearty meals prepared for the residents.";
        break;
      case RoomType.study:
        baseDesc =
            "The oak-paneled walls and heavy velvet curtains swallow the light. Parchment lies waiting on the desk, and the silence here is perfect for study.";
        capabilities =
            "A sanctuary for intellectual labor. Here, your character can research new technologies, write treatises, and develop their scientific understanding.";
        break;
      case RoomType.laboratory:
        baseDesc =
            "White tiles glisten under the glow of specialized lamps. Drainage channels are clear, and the scent of ozone and formaldehyde lingers.";
        capabilities =
            "A precise workshop for the pursuit of forbidden science. From simple dissections to complex surgical operations and the creation of new life, this room handles your most ambitious experiments.";
        break;
      case RoomType.chickenCoop:
        baseDesc =
            "The coop is now secure and weather-tight. The nesting boxes are clean, and the structure stands firm against the elements.";
        capabilities =
            "Essential for the manor's survival. NPCs can collect eggs, guard the flock from foxes, or butcher poultry for meat.";
        break;
      case RoomType.library:
        baseDesc =
            "Tier upon tier of leather-bound volumes rise toward the high ceiling. The air is cool and smells of ancient paper and floor wax.";
        capabilities =
            "The repository of all your collected wisdom. Use this space to archive research, transcribe messy notes into permanent records, or simply study the great authors of the past.";
        break;
      case RoomType.field:
        baseDesc =
            "Broad stretches of arable land, clear of stones and weeds. They are prepared for the cycle of sowing and reaping.";
        capabilities =
            "The primary source of sustenance. Workers can till, plant, water, and eventually harvest the crops required to feed the growing household.";
        break;
      case RoomType.garden:
        baseDesc =
            "A refined plot of fertile earth, surrounded by low stone walls. It is a quiet sanctuary for the growth of rare specimens.";
        capabilities =
            "Unlike the open fields, the garden is for delicate horticultural research and the refinement of rare botanical or fungal samples.";
        break;
      case RoomType.brewery:
        baseDesc =
            "The copper tuns shine, and the scent of malt hangs in the air.";
        capabilities =
            "A specialized industrial facility for the production of ales and beers to maintain house morale and energy.";
        break;
      case RoomType.distillery:
        baseDesc = "A complex network of copper and glass pipes and stills.";
        capabilities =
            "Handles the precision work of distilling fine spirits and concentrated chemical tonics.";
        break;
      case RoomType.workshop:
        baseDesc =
            "A place of grit and utility with a central heavy-duty workbench.";
        capabilities =
            "The estate's fabrication hub. Here, timber is processed, blacksmithing is performed at the forge, and complex inventions are manufactured.";
        break;
      case RoomType.granary:
        baseDesc = "Dry, cool, and well-ventilated storage bins.";
        capabilities =
            "Dedicated to the processing and safe storage of harvested grain, protecting it from rot and pests.";
        break;
      case RoomType.bedroom:
        baseDesc =
            "Private and plush, offering the luxury required for deep, restorative sleep.";
        capabilities =
            "Residents assigned here will recover energy and satisfaction more effectively than on the bare floor.";
        break;
      case RoomType.entryway:
        baseDesc =
            "The grand double doors and sweeping staircase greet visitors with stern authority.";
        capabilities =
            "The public face of the manor. Used for greeting guests and as a primary defensive post if the manor is threatened.";
        break;
      case RoomType.butlerQuarters:
        baseDesc =
            "A modest but perfectly ordered space refletive of a disciplined nature.";
        capabilities =
            "The primary residence for your loyal butler and henchman.";
        break;
      case RoomType.basement:
      case RoomType.attic:
        baseDesc = "Secluded rooms offering privacy and isolation.";
        capabilities =
            "Ideal for additional resident housing or quiet storage of sensitive materials.";
        break;
      case RoomType.diningRoom:
        baseDesc =
            "A long mahogany table sits beneath a crystal chandelier, polished to a mirror finish.";
        capabilities =
            "Used for communal meals and formal dinners to build relationships and status.";
        break;
      case RoomType.toilet:
        baseDesc = "A private, tiled washroom with running water.";
        capabilities =
            "Essential for maintaining the hygiene and comfort of the manor's inhabitants.";
        break;
      default:
        baseDesc = description.isNotEmpty
            ? description
            : "A functional and well-maintained part of your estate.";
        capabilities = "Ready for use by the household.";
        break;
    }

    return "$baseDesc $capabilities$hygieneNote";
  }

  task_service.TaskType get defaultAction {
    if (!isRestored) return task_service.TaskType.restoreRoom;
    final tasks = availableTasks;
    // Return first task that isn't 'cleanRoom' if possible, otherwise first task
    return tasks.firstWhere(
      (t) => t != task_service.TaskType.cleanRoom,
      orElse: () => tasks.first,
    );
  }
}
