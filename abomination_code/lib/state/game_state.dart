import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

import '../models/manor_crisis.dart';
import '../models/npc.dart';
import '../models/room.dart';
import '../models/schedule.dart';
import '../models/npc_intent.dart';
import '../models/game_item.dart';
import '../models/crop.dart';
import '../models/game_date.dart';
import '../models/experiment.dart';
import '../models/responsibility.dart';
import '../models/body_part.dart';
import '../models/chicken.dart';
import '../models/discovery.dart';
import '../models/dish.dart';
import '../models/fox.dart';
import '../models/objective.dart';
import '../models/relationship.dart';
import '../models/status_effect.dart';
import '../models/diet.dart';

import '../services/task_service.dart';
import '../services/social_service.dart';
import '../services/kitchen_service.dart';
import '../services/science_service.dart';
import '../services/market_service.dart';
import '../services/construction_service.dart';
import '../services/task_result_generator.dart';
import '../services/npc_generator.dart';

import '../services/experimentation_service.dart';
import '../services/combat_unit_factory.dart';

enum GameSpeed { paused, slow, normal, fast, superFast }

enum DeathCause { disease, trainCrash, murderSuicide, misunderstanding }

enum LifeObjective { women, money, fame, science }

enum GilesTrait { sage, endsMeet, silent, shuffle }

enum ButlerDisposition { stern, kind, neutral }

class GameState extends ChangeNotifier {
  GameState() {
    _initializeResponsibilityDefaults();
  }

  void _initializeResponsibilityDefaults() {
    for (var cat in ResponsibilityCategory.values) {
      final tasks = TaskCategoryMapping.getTasksForCategory(cat);
      _categoryPriorities[cat] = tasks;
      _categoryDividers[cat] = (tasks.length / 2).floor(); // Default middle
    }
  }

  GameDate _currentDate = GameDate.initial();
  GameSpeed _speed = GameSpeed.paused;

  final List<NPC> _npcs = [];
  final List<NPC> _availableHamletNpcs = [];
  final List<Room> _rooms = [];
  final Map<String, num> _resources = {
    'funds': 100,
    'wood': 10,
    'meat': 5,
    'cabbage': 5,
    'eggs': 0,
    'meals': 2,
    'grain': 0,
    'ale': 0,
    'spirits': 0,
    'timber': 0,
    'herbs': 0,
    'fertilizer': 10,
  };
  final List<GameItem> _inventory = [];

  final TaskService _taskService = TaskService();
  final MarketService _marketService = MarketService();
  String? _butlerRoomId;
  final List<ConstructionProject> _activeConstruction = [];
  final List<Experiment> _activeExperiments = [];
  String? _lastAnnouncement;
  final List<String> _announcementHistory = [];
  final List<Objective> _objectives = [];
  final Set<TaskType> _completedTaskTypes = {};
  final List<String> _unlockedDiscoveries = [];
  final List<String> _performedExperiments = [];
  String? _pendingNavigationTarget;
  final List<Dish> _pantry = [];
  final List<String> _cookingQueue = [];
  final List<String> _researchQueue = [];
  int _unreadObjectiveCount = 0;
  bool _pendingCombatEncounter = false;
  int _lastEncounterMinute = -10; // Allow first encounter immediately

  final List<Chicken> _chickens = [];
  FoxPopulation _estateFoxes = FoxPopulation.initial();
  final List<Crop> _crops = [];
  int _uncollectedEggs = 0;
  ButlerDisposition _butlerDisposition = ButlerDisposition.neutral;

  bool _isGameOver = false;
  String? _gameOverReason;
  bool get isGameOver => _isGameOver;
  String? get gameOverReason => _gameOverReason;
  final List<ManorCrisis> _crises = [];

  final Map<ResponsibilityCategory, List<TaskType>> _categoryPriorities = {};
  final Map<ResponsibilityCategory, int> _categoryDividers = {};

  // New Game Choices
  String _playerFirstName = "The";
  String _playerLastName = "Master";
  String _estateName = "Manor";
  DeathCause? _deathCause;
  int _playerAge = 30;
  GilesTrait _gilesTrait = GilesTrait.silent;
  LifeObjective _mainObjective = LifeObjective.science;

  Map<String, dynamic> toJson() => {
    'currentDate': _currentDate.toJson(),
    'speed': _speed.index,
    'npcs': _npcs.map((n) => n.toJson()).toList(),
    'availableHamletNpcs': _availableHamletNpcs.map((n) => n.toJson()).toList(),
    'rooms': _rooms.map((r) => r.toJson()).toList(),
    'resources': _resources,
    'inventory': _inventory.map((i) => i.toJson()).toList(),
    'butlerRoomId': _butlerRoomId,
    'activeConstruction': _activeConstruction.map((c) => c.toJson()).toList(),
    'activeExperiments': _activeExperiments.map((e) => e.toJson()).toList(),
    'lastAnnouncement': _lastAnnouncement,
    'announcementHistory': _announcementHistory,
    'objectives': _objectives.map((o) => o.toJson()).toList(),
    'completedTaskTypes': _completedTaskTypes.map((t) => t.index).toList(),
    'unlockedDiscoveries': _unlockedDiscoveries,
    'performedExperiments': _performedExperiments,
    'pendingNavigationTarget': _pendingNavigationTarget,
    'pantry': _pantry.map((d) => d.toJson()).toList(),
    'cookingQueue': _cookingQueue,
    'researchQueue': _researchQueue,
    'unreadObjectiveCount': _unreadObjectiveCount,
    'chickens': _chickens.map((c) => c.toJson()).toList(),
    'estateFoxes': _estateFoxes.toJson(),
    'crops': _crops.map((c) => c.toJson()).toList(),
    'uncollectedEggs': _uncollectedEggs,
    'butlerDisposition': _butlerDisposition.index,
    'crises': _crises.map((c) => c.toJson()).toList(),
    'pendingCombatEncounter': _pendingCombatEncounter,
    'categoryPriorities': _categoryPriorities.map(
      (k, v) => MapEntry(k.index.toString(), v.map((t) => t.index).toList()),
    ),
    'categoryDividers': _categoryDividers.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'playerFirstName': _playerFirstName,
    'playerLastName': _playerLastName,
    'estateName': _estateName,
    'deathCause': _deathCause?.index,
    'playerAge': _playerAge,
    'gilesTrait': _gilesTrait.index,
    'mainObjective': _mainObjective.index,
  };

  void loadFromJson(Map<String, dynamic> json) {
    _currentDate = GameDate.fromJson(json['currentDate']);
    _speed = GameSpeed.values[json['speed'] as int? ?? GameSpeed.paused.index];

    _npcs.clear();
    _npcs.addAll((json['npcs'] as List).map((n) => NPC.fromJson(n)).toList());

    _availableHamletNpcs.clear();
    _availableHamletNpcs.addAll(
      (json['availableHamletNpcs'] as List)
          .map((n) => NPC.fromJson(n))
          .toList(),
    );

    _rooms.clear();
    _rooms.addAll(
      (json['rooms'] as List).map((r) => Room.fromJson(r)).toList(),
    );

    _resources.clear();
    _resources.addAll(Map<String, int>.from(json['resources']));

    _inventory.clear();
    _inventory.addAll(
      (json['inventory'] as List).map((i) => GameItem.fromJson(i)).toList(),
    );

    _butlerRoomId = json['butlerRoomId'] as String?;

    _activeConstruction.clear();
    _activeConstruction.addAll(
      (json['activeConstruction'] as List)
          .map((c) => ConstructionProject.fromJson(c))
          .toList(),
    );

    _activeExperiments.clear();
    _activeExperiments.addAll(
      (json['activeExperiments'] as List)
          .map((e) => Experiment.fromJson(e))
          .toList(),
    );

    _lastAnnouncement = json['lastAnnouncement'] as String?;
    _announcementHistory.clear();
    _announcementHistory.addAll(List<String>.from(json['announcementHistory']));

    _objectives.clear();
    _objectives.addAll(
      (json['objectives'] as List).map((o) => Objective.fromJson(o)).toList(),
    );

    _completedTaskTypes.clear();
    _completedTaskTypes.addAll(
      (json['completedTaskTypes'] as List)
          .map((t) => TaskType.values[t as int])
          .toSet(),
    );

    _unlockedDiscoveries.clear();
    _unlockedDiscoveries.addAll(List<String>.from(json['unlockedDiscoveries']));

    _performedExperiments.clear();
    _performedExperiments.addAll(
      List<String>.from(json['performedExperiments']),
    );

    _pendingNavigationTarget = json['pendingNavigationTarget'] as String?;

    _pantry.clear();
    _pantry.addAll(
      (json['pantry'] as List).map((d) => Dish.fromJson(d)).toList(),
    );

    _cookingQueue.clear();
    _cookingQueue.addAll(List<String>.from(json['cookingQueue']));

    _researchQueue.clear();
    _researchQueue.addAll(List<String>.from(json['researchQueue']));

    _unreadObjectiveCount = json['unreadObjectiveCount'] as int? ?? 0;

    _chickens.clear();
    _chickens.addAll(
      (json['chickens'] as List).map((c) => Chicken.fromJson(c)).toList(),
    );

    _estateFoxes = FoxPopulation.fromJson(json['estateFoxes']);

    _crops.clear();
    _crops.addAll(
      (json['crops'] as List).map((c) => Crop.fromJson(c)).toList(),
    );

    _uncollectedEggs = json['uncollectedEggs'] as int? ?? 0;
    _butlerDisposition =
        ButlerDisposition.values[json['butlerDisposition'] as int? ?? 2];

    _crises.clear();
    _crises.addAll(
      (json['crises'] as List).map((c) => ManorCrisis.fromJson(c)).toList(),
    );

    _categoryPriorities.clear();
    if (json['categoryPriorities'] != null) {
      (json['categoryPriorities'] as Map).forEach((k, v) {
        _categoryPriorities[ResponsibilityCategory.values[int.parse(k)]] =
            (v as List).map((t) => TaskType.values[t as int]).toList();
      });
    }

    _categoryDividers.clear();
    if (json['categoryDividers'] != null) {
      (json['categoryDividers'] as Map).forEach((k, v) {
        _categoryDividers[ResponsibilityCategory.values[int.parse(k)]] =
            v as int;
      });
    }

    _playerFirstName = json['playerFirstName'] as String? ?? 'The';
    _playerLastName = json['playerLastName'] as String? ?? 'Master';
    _estateName = json['estateName'] as String? ?? 'Manor';
    _deathCause = json['deathCause'] != null
        ? DeathCause.values[json['deathCause']]
        : null;
    _playerAge = json['playerAge'] as int? ?? 30;
    _gilesTrait = GilesTrait.values[json['gilesTrait'] as int? ?? 2];
    _mainObjective = LifeObjective.values[json['mainObjective'] as int? ?? 3];
    _pendingCombatEncounter = json['pendingCombatEncounter'] as bool? ?? false;

    notifyListeners();
  }

  List<NPC> get npcs => List.unmodifiable(_npcs);

  List<Map<String, dynamic>> get butcheryTargets {
    final List<Map<String, dynamic>> targets = [];

    // 1. Group identical chickens by breed and maturity
    final Map<String, List<String>> groupedChickens = {};
    for (var c in _chickens) {
      final isMature = c.isMature;
      final key = "${c.breed.name} Chicken (${isMature ? 'Mature' : 'Young'})";
      groupedChickens.putIfAbsent(key, () => []).add(c.id);
    }

    groupedChickens.forEach((name, ids) {
      if (ids.length > 1) {
        targets.add({
          'id': ids.first, 
          'name': "$name x${ids.length}", 
          'isGroup': true, 
          'ids': ids
        });
      } else {
        targets.add({'id': ids.first, 'name': name});
      }
    });

    // 2. Specimens from inventory (individual, as they have unique stats)
    for (var item in _inventory.where((i) => i.category == ItemCategory.specimen)) {
      targets.add({'id': item.id, 'name': item.name});
    }

    // 3. NPCs (individual)
    for (var npc in _npcs.where((n) => !n.isPlayer)) {
      targets.add({'id': npc.id, 'name': "${npc.name} (${npc.role.toUpperCase()})"});
    }

    return targets;
  }
  List<NPC> get availableHamletNpcs => List.unmodifiable(_availableHamletNpcs);
  List<Room> get rooms => List.unmodifiable(_rooms);
  Map<String, int> get resources => Map.unmodifiable(_resources);
  List<GameItem> get inventory => List.unmodifiable(_inventory);
  Map<ResponsibilityCategory, List<TaskType>> get categoryPriorities =>
      Map.unmodifiable(_categoryPriorities);
  Map<ResponsibilityCategory, int> get categoryDividers =>
      Map.unmodifiable(_categoryDividers);

  MarketService get marketService => _marketService;
  TaskService get taskService => _taskService;
  List<GameTask> get activeTasks => _taskService.activeTasks;

  double getKnowledgeLevel(String discipline) {
    return _rooms.fold(
      0.0,
      (sum, room) => sum + room.calculateDisciplineKnowledge(discipline),
    );
  }

  List<ConstructionProject> get activeConstruction =>
      List.unmodifiable(_activeConstruction);
  List<Experiment> get activeExperiments =>
      List.unmodifiable(_activeExperiments);
  String? get butlerRoomId => _butlerRoomId;
  String? get lastAnnouncement => _lastAnnouncement;
  List<String> get announcementHistory =>
      List.unmodifiable(_announcementHistory);
  GameDate get currentDate => _currentDate;
  List<ManorCrisis> get crises => List.unmodifiable(_crises);
  List<Crop> get crops => List.unmodifiable(_crops);
  GameSpeed get speed => _speed;
  String get playerFirstName => _playerFirstName;
  String get playerLastName => _playerLastName;
  String get estateName => _estateName;
  GilesTrait get gilesTrait => _gilesTrait;
  List<Chicken> get chickens => List.unmodifiable(_chickens);
  FoxPopulation get estateFoxes => _estateFoxes;
  DeathCause? get deathCause => _deathCause;
  List<String> get cookingQueue => List.unmodifiable(_cookingQueue);
  List<String> get researchQueue => List.unmodifiable(_researchQueue);
  List<Objective> get objectives => List.unmodifiable(_objectives);
  List<String> get unlockedDiscoveries =>
      List.unmodifiable(_unlockedDiscoveries);
  LifeObjective get mainObjective => _mainObjective;
  String? get pendingNavigationTarget => _pendingNavigationTarget;
  List<Dish> get pantry => List.unmodifiable(_pantry);
  int get unreadObjectiveCount => _unreadObjectiveCount;
  int get uncollectedEggs => _uncollectedEggs;
  ButlerDisposition get butlerDisposition => _butlerDisposition;
  bool get pendingCombatEncounter => _pendingCombatEncounter;

  set pendingCombatEncounter(bool value) {
    _pendingCombatEncounter = value;
    if (!value) {
      // Resume speed when combat is over
      _speed = GameSpeed.normal;
    }
    notifyListeners();
  }

  set butlerDisposition(ButlerDisposition value) {
    _butlerDisposition = value;
    notifyListeners();
  }

  void _consumeScienceIngredients(Map<String, int> ingredients) {
    ingredients.forEach((ing, count) {
      // Handle resources (sugar, coffee, etc)
      if (_resources.containsKey(ing)) {
        _resources[ing] = (_resources[ing] ?? 0) - count;
      } else {
        // Handle inventory items (specimens, documents)
        for (int i = 0; i < count; i++) {
          final itemIdx = _inventory.indexWhere((item) {
            if (ing == 'meat') {
              return item.type.contains('meat');
            }
            if (ing == 'specimen') {
              return item.category == ItemCategory.specimen;
            }
            return item.type == ing;
          });
          if (itemIdx != -1) {
            if (_inventory[itemIdx].quantity > 1) {
              _inventory[itemIdx] = _inventory[itemIdx].copyWith(
                quantity: _inventory[itemIdx].quantity - 1,
              );
            } else {
              _inventory.removeAt(itemIdx);
            }
          }
        }
      }
    });
  }

  void updateCategoryPriority(
    ResponsibilityCategory category,
    List<TaskType> tasks,
  ) {
    _categoryPriorities[category] = tasks;
    notifyListeners();
  }

  void updateCategoryDivider(ResponsibilityCategory category, int divider) {
    _categoryDividers[category] = divider;
    notifyListeners();
  }

  void clearPendingNavigation() {
    _pendingNavigationTarget = null;
    notifyListeners();
  }

  void addResearchToQueue(String itemId) {
    if (!_researchQueue.contains(itemId)) {
      _researchQueue.add(itemId);
      final item = _inventory.firstWhere((i) => i.id == itemId);
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] Enqueued ${item.name.toUpperCase()} for research.",
      );
      notifyListeners();
    }
  }

  void addScienceActivityToQueue(String activityId) {
    if (!_researchQueue.contains('activity:$activityId')) {
      _researchQueue.add('activity:$activityId');
      final activity = ScienceService.getActivityById(activityId);
      if (activity != null) {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] Enqueued ${activity.name.toUpperCase()} for study.",
        );
      }
      notifyListeners();
    }
  }

  void addExperimentalRecipeToQueue(String recipeId) {
    if (!_researchQueue.contains('recipe:$recipeId')) {
      _researchQueue.add('recipe:$recipeId');
      final recipes = KitchenService.getAvailableRecipes();
      final recipe = recipes.cast<Recipe?>().firstWhere((r) => r?.id == recipeId, orElse: () => null);
      if (recipe != null) {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] Enqueued ${recipe.name.toUpperCase()} for examination.",
        );
      }
      notifyListeners();
    }
  }

  void removeResearchFromQueue(int index) {
    if (index >= 0 && index < _researchQueue.length) {
      _researchQueue.removeAt(index);
      notifyListeners();
    }
  }

  void updateResource(String resource, int amount) {
    _resources[resource] = (_resources[resource] ?? 0) + amount;
    notifyListeners();
  }

  void addResources(Map<String, int> resources) {
    resources.forEach((key, value) {
      _resources[key] = (_resources[key] ?? 0) + value;
    });
    notifyListeners();
  }

  void addItemToRoom(String roomId, GameItem item) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final List<GameItem> newInv = List.from(_rooms[index].inventory);
      newInv.add(item);
      _rooms[index] = _rooms[index].copyWith(inventory: newInv);
      notifyListeners();
    }
  }

  void completeTaskManually(String npcId, GameTask task) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _handleTaskCompletion(task);
    }
  }

  void updateNpc(NPC updatedNpc) {
    final index = _npcs.indexWhere((n) => n.id == updatedNpc.id);
    if (index != -1) {
      _npcs[index] = updatedNpc;
      notifyListeners();
    }
  }

  void updateRoom(Room updatedRoom) {
    final index = _rooms.indexWhere((r) => r.id == updatedRoom.id);
    if (index != -1) {
      _rooms[index] = updatedRoom;
      notifyListeners();
    }
  }

  void updateCrop(Crop updatedCrop) {
    final index = _crops.indexWhere((c) => c.id == updatedCrop.id);
    if (index != -1) {
      _crops[index] = updatedCrop;
      notifyListeners();
    }
  }

  void setResource(String id, int amount) {
    _resources[id] = amount;
    notifyListeners();
  }

  void markObjectivesRead() {
    _unreadObjectiveCount = 0;
    notifyListeners();
  }

  void initializeNewGame({
    required String firstName,
    required String lastName,
    required String estateName,
    required DeathCause deathCause,
    required int age,
    required GilesTrait gilesTrait,
    required LifeObjective objective,
  }) {
    _playerFirstName = firstName;
    _playerLastName = lastName;
    _estateName = estateName;
    _deathCause = deathCause;
    _playerAge = age;
    _gilesTrait = gilesTrait;
    _mainObjective = objective;
    _completedTaskTypes.clear();


    _rooms.clear();
    _npcs.clear();
    _activeExperiments.clear();
    _activeConstruction.clear();
    _inventory.clear();
    _resources.clear();
    _resources.addAll({
      'funds': 100,
      'wood': 10,
      'meat': 5,
      'cabbage': 5,
      'eggs': 0,
      'meals': 2,
      'dirty_dishes': 0,
      'flour_spelt': 10,
      'flour_durum': 10,
      'rice': 10,
      'green_beans': 10,
      'faba_beans': 10,
      'cattle_carcass': 1,
      'meat_beef': 5,
      'meat_chicken': 5,
      'milk': 5,
      'salt': 5,
      'pepper': 5,
      'potato': 10,
      'carrots': 10,
      'beets': 10,
      'water': 20,
      'yeast': 5,
      'sugar': 5,
      'chocolate': 2,
      'coffee': 2,
      'seeds_cabbage': 10,
      'seeds_potato': 10,
      'seeds_carrot': 10,
      'seeds_grain': 20,
    });

    // 5 days of prepared meals for Giles and Frankenstein (30 meals total)
    // Spoil in 4 days (96 hours)
    _pantry.clear();
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      _pantry.add(
        Dish(
          id: const Uuid().v4(),
          name: i % 2 == 0 ? 'Hearty Stew' : 'Baked Bread',
          type: i % 2 == 0 ? DishType.protein : DishType.cereal,
          quality: DishQuality.decent,
          cookedAt: now,
          shelfLifeHours: 96, // 4 days
        ),
      );
    }

    // 2 weeks of raw materials for both to survive
    // Spoil in 10 days
    final List<Map<String, dynamic>> rawMaterials = [
      {'name': 'Raw Beef', 'type': 'meat_beef', 'qty': 20},
      {'name': 'Raw Poultry', 'type': 'meat_chicken', 'qty': 20},
      {'name': 'Fresh Vegetables', 'type': 'vegetables', 'qty': 40},
      {'name': 'Grains', 'type': 'grain', 'qty': 30},
    ];

    for (var mat in rawMaterials) {
      _inventory.add(
        GameItem.create(
          name: mat['name'],
          type: mat['type'],
          category: ItemCategory.food,
          quantity: mat['qty'],
          metadata: {
            'addedAt': now.toIso8601String(),
            'shelfLifeDays': 10,
          },
        ),
      );
    }

    _initializeManor();
    _initializeStartingCharacters();
    _initializeObjectives();
    notifyListeners();
  }

  void _initializeManor() {
    // 1. Transit & Fields
    _rooms.add(
      Room(
        id: 'road',
        name: 'Road',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'The approach to the house.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'vegetable_garden',
        name: 'Garden',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A well-maintained garden for vegetables.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_2',
        name: 'Field A',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_3',
        name: 'Field B',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'field_4',
        name: 'Field C',
        type: RoomType.field,
        isRestored: true,
        floor: Floor.ground,
        description: 'A quiet stretch of arable land, ready for the plow.',
        width: 2.0,
      ),
    );

    // 2. Main Floor (Floor 0)
    _rooms.add(
      Room(
        id: 'entryway',
        name: 'Entry',
        type: RoomType.entryway,
        isRestored: true,
        floor: Floor.ground,
        description: 'The main entrance to the manor.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'kitchen',
        name: 'Kitchen',
        type: RoomType.kitchen,
        isRestored: true,
        floor: Floor.ground,
        description: 'The heart of the manor.',
        width: 3.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'dining_hall',
        name: 'Dining',
        type: RoomType.diningRoom,
        isRestored: true,
        floor: Floor.ground,
        description: 'A grand space for meals.',
        width: 3.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'bathroom_down',
        name: 'Toilet',
        type: RoomType.toilet,
        isRestored: true,
        floor: Floor.ground,
        description: 'A small, clean washroom.',
        width: 1.5,
      ),
    );
    _rooms.add(
      Room(
        id: 'unused_1f',
        name: 'Unused',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.ground,
        description: 'A dusty, forgotten section.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'butler_quarters',
        name: "Butler",
        type: RoomType.butlerQuarters,
        isRestored: true,
        floor: Floor.ground, // Placed on ground per ManorLayout
        description: 'Private quarters for the butler.',
        width: 2.0,
        beds: [
          Bed(type: BedType.twin, assignedNpcIds: ['butler']),
        ],
      ),
    );

    // 3. 2nd Story (Floor 1)
    _rooms.add(
      Room(
        id: 'master_bedroom',
        name: 'Master Bedroom',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'The opulent quarters of the manor\'s master.',
        width: 1.0,
        beds: [
          Bed(type: BedType.king, assignedNpcIds: ['player', null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bedroom_2',
        name: 'Junior Bedroom',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'A comfortable room for family or high-status guests.',
        width: 1.0,
        beds: [
          Bed(type: BedType.queen, assignedNpcIds: [null, null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bedroom_3',
        name: 'Guest Room',
        type: RoomType.bedroom,
        isRestored: true,
        floor: Floor.second,
        description: 'A simple room with two twin beds.',
        width: 1.0,
        beds: [
          Bed(type: BedType.twin, assignedNpcIds: [null]),
          Bed(type: BedType.twin, assignedNpcIds: [null]),
        ],
      ),
    );
    _rooms.add(
      Room(
        id: 'bathroom_up',
        name: 'Washroom',
        type: RoomType.toilet,
        isRestored: true,
        floor: Floor.second,
        description: 'A pristine upstairs washroom.',
        width: 1.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'study',
        name: 'Study',
        type: RoomType.study,
        isRestored: true,
        floor: Floor.second,
        description: 'A quiet place for work.',
        width: 1.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'library',
        name: 'Library',
        type: RoomType.library,
        isRestored: false,
        floor: Floor.second,
        description: 'A vast, dusty collection of books.',
        width: 1.0,
      ),
    );

    // 4. Attic (Floor 2)
    _rooms.add(
      Room(
        id: 'attic_1',
        name: 'East Attic',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.attic,
        description: 'Empty space for future installations.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'attic_2',
        name: 'West Attic',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.attic,
        description: 'Empty space for future installations.',
        width: 2.0,
      ),
    );

    // 5. Basement (Floor -1 & -2)
    _rooms.add(
      Room(
        id: 'basement_1',
        name: 'Basement A',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Subterranean storage.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_2',
        name: 'Basement B',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Cold storage in the dark.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'basement_3',
        name: 'Basement C',
        type: RoomType.unused,
        isRestored: false,
        floor: Floor.basement,
        description: 'Quiet subterranean vaults.',
        width: 2.0,
      ),
    );

    // 6. External
    _rooms.add(
      Room(
        id: 'chicken_coop',
        name: 'Chicken Coop',
        type: RoomType.chickenCoop,
        isRestored: false,
        floor: Floor.ground,
        description: 'Dilapidated poultry housing.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'toolshed',
        name: 'Tool Shed',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'A small outbuilding for equipment.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'lot_garden',
        name: 'Garden Lot',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'External space for planting.',
        width: 2.0,
      ),
    );
    _rooms.add(
      Room(
        id: 'lot_building_1',
        name: 'Empty Lot',
        type: RoomType.unused,
        isRestored: true,
        floor: Floor.ground,
        description: 'Space for an external building.',
        width: 2.0,
      ),
    );
  }

  void _initializeStartingCharacters() {
    final player = NPC(
      id: 'player',
      name: '$_playerFirstName $_playerLastName',
      specimenType: 'Human',
      role: 'Master',
      isPlayer: true,
      age: _playerAge,
      gender: 'Male',
      group: NPCOrgGroup.A,
      stats: {
        'strength': 10,
        'endurance': 20,
        'adaptability': 30, // Median
        'dexterity': 40,
        'intelligence': 50,
        'perception': 40,
        'judgment': 20,
        'temperament': 10,
        'leadership': 30, // Median
        'courage': 30,
        'hygiene': 40,
        'beauty': 20,
        'walkSpeed': 35,
      },
      bodyParts: [
        BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
      ],
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      currentRoomId: 'entryway',
      assignedRoomId: 'master_bedroom',
      appearance: NPCAppearance.random(),
      relationships: {
        'butler': Relationship(
          admiration: 3.5,
          respect: 1.5,
          fear: 2.0,
          attraction: 1.2,
        ),
      },
    );

    final butler = CombatUnitFactory.createFlaubert().copyWith(
      appearance: NPCAppearance.defaultButler(),
      responsibilities: {
        ResponsibilityCategory.cleaning: 3,
        ResponsibilityCategory.cooking: 2,
        ResponsibilityCategory.labor: 2,
      },
      relationships: {
        'player': Relationship(
          admiration: 3.0,
          respect: 3.0,
          fear: 3.5,
          attraction: 2.0,
        ),
      },
    );

    _npcs.add(player);
    _npcs.add(butler);

    // Initial Combat Unit Pool - Giles is already added as the butler.
    // If we add more units to the initial deck later, we should filter out duplicates here.
    _butlerRoomId = 'butler_quarters';
  }

  void tick() {
    if (_speed == GameSpeed.paused) return;

    _processDishes();
    _processSpoilage();

    _processDiscreteSocialEvents();
    _processStatusEffectsTick();
    if (_currentDate.minute == 0) {
      _processHourlyRelationshipEvolution();
    }

    // History and Byproduct Logic (once per day or hour)
    if (_currentDate.hour == 23 && _currentDate.minute == 59) {
      // End of day: update chicken histories
      for (int i = 0; i < _chickens.length; i++) {
        final chicken = _chickens[i];
        final List<int> newHistory = List.from(chicken.eggProductionHistory);
        newHistory.add(chicken.eggsLaid);
        _chickens[i] = chicken.copyWith(eggProductionHistory: newHistory);
      }
    }

    if (_currentDate.minute == 0) {
      // Hourly byproduct check
      _processLivestockByproducts();
    }

    _currentDate = _currentDate.addMinute();

    // Identify NPCs that are either not moving or are already at their task's target room
    final readyNpcIds = _npcs
        .where((n) {
          // If they have a target and haven't arrived, they are definitely not ready
          if (n.targetRoomId != null && n.targetRoomId != n.currentRoomId) {
            return false;
          }
          if (n.movementProgress < 1.0 && n.targetRoomId != n.currentRoomId) {
            return false;
          }

          // Check if NPC is in the correct room for their current active task
          if (n.activeTaskId != null) {
            // Use findTaskById equivalent or manual search
            GameTask? task;
            for (var t in _taskService.activeTasks) {
              if (t.id == n.activeTaskId) {
                task = t;
                break;
              }
            }

            if (task != null &&
                task.targetId != null &&
                task.targetId != n.currentRoomId) {
              return false;
            }
          }
          return true;
        })
        .map((n) => n.id)
        .toList();
    // Identify active task IDs for filtering in TaskService
    final activeTaskIds = _npcs
        .where((n) => n.activeTaskId != null)
        .map((n) => n.activeTaskId!)
        .toSet();

    // Process Tasks only for arrived NPCs and their active task
    final completedTasks = _taskService.processTick(
      readyNpcIds,
      activeTaskIds,
      (npcId) {
        final npc = _npcs.firstWhere((n) => n.id == npcId);
        return npc.stats;
      },
    );

    // Sync active task progress back to intent queues and room physical projects
    for (int i = 0; i < _npcs.length; i++) {
      var npc = _npcs[i];
      if (npc.activeTaskId != null) {
        GameTask? task;
        for (var t in _taskService.activeTasks) {
          if (t.id == npc.activeTaskId) {
            task = t;
            break;
          }
        }
        if (task != null) {
          final activeTask = task;
          
          // Sync to NPC Intent
          final intentIndex = npc.intentQueue.indexWhere(
            (intent) => intent.id == activeTask.id,
          );
          if (intentIndex != -1) {
            final updatedIntent = npc.intentQueue[intentIndex].copyWith(
              minutesRemaining: task.minutesRemaining,
            );
            List<NPCIntent> newQueue = List.from(npc.intentQueue);
            newQueue[intentIndex] = updatedIntent;
            _npcs[i] = npc.copyWith(intentQueue: newQueue);
          }

          // Sync to Room Physical Project
          final targetId = activeTask.targetId;
          if (targetId != null) {
            final roomIndex = _rooms.indexWhere((r) => r.id == targetId);
            if (roomIndex != -1) {
              final room = _rooms[roomIndex];
              if (room.activeProjects.containsKey(task.id)) {
                final totalMin = task.totalMinutes > 0 ? task.totalMinutes : 60;
                final progress =
                    1.0 - (task.minutesRemaining / totalMin).clamp(0.0, 1.0);

                final Map<String, PhysicalProject> updatedProjects = Map.from(
                  room.activeProjects,
                );
                updatedProjects[task.id] = updatedProjects[task.id]!.copyWith(
                  progress: progress,
                );

                _rooms[roomIndex] = room.copyWith(
                  activeProjects: updatedProjects,
                );
              }
            }
          }
        }
      }
    }

    for (var task in completedTasks) {
      _handleTaskCompletion(task);
    }

    _updateNpcs();
    _processConstruction();
    _processExperiments();
    _processChickens();
    _processCrops();
    _processHygiene();
    _processCrises();
    _processPredators();
    _processVisitors();
    _processDigestion();
    _checkObjectives();
    _checkDiscoveries();

    notifyListeners();
  }

  void _processVisitors() {
    // 2% chance per hour (~0.03% per minute)
    if (Random().nextDouble() < 0.0003) {
      _triggerVisitorArrival();
    }
  }

  void _processDiscreteSocialEvents() {
    // 1% chance per minute to trigger an interaction if people are in the same room
    if (Random().nextDouble() > 0.01) return;

    // Group NPCs by room
    final roomGroups = <String, List<NPC>>{};
    for (var npc in _npcs.where(
      (n) => n.isResident && n.status != NPCStatus.zombie,
    )) {
      if (npc.currentRoomId != null) {
        roomGroups.putIfAbsent(npc.currentRoomId!, () => []).add(npc);
      }
    }

    // Pick a random room with at least 2 people
    final validRooms = roomGroups.entries
        .where((e) => e.value.length >= 2)
        .toList();
    if (validRooms.isEmpty) return;

    final roomEntry = validRooms[Random().nextInt(validRooms.length)];
    final candidates = roomEntry.value;

    // Pick two distinct NPCs
    final idx1 = Random().nextInt(candidates.length);
    int idx2 = Random().nextInt(candidates.length);
    while (idx2 == idx1) {
      idx2 = Random().nextInt(candidates.length);
    }

    final npc1 = candidates[idx1];
    final npc2 = candidates[idx2];

    final type = SocialService.getRandomInteraction();
    final result = SocialService.performInteraction(npc1, npc2, type);

    // Apply changes
    final n1Idx = _npcs.indexWhere((n) => n.id == npc1.id);
    final n2Idx = _npcs.indexWhere((n) => n.id == npc2.id);

    if (n1Idx != -1 && n2Idx != -1) {
      final newRels1 = Map<String, Relationship>.from(
        _npcs[n1Idx].relationships,
      );
      newRels1[npc2.id] = result['actorRelationship'] as Relationship;

      final newRels2 = Map<String, Relationship>.from(
        _npcs[n2Idx].relationships,
      );
      newRels2[npc1.id] = result['targetRelationship'] as Relationship;

      _npcs[n1Idx] = _npcs[n1Idx].copyWith(relationships: newRels1);
      _npcs[n2Idx] = _npcs[n2Idx].copyWith(relationships: newRels2);

      final log = result['log'] as String;
      _lastAnnouncement = log;
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SOCIAL: $log",
      );
      if (_announcementHistory.length > 50) _announcementHistory.removeLast();

      notifyListeners();
    }
  }

  void _triggerVisitorArrival() {
    final guests = [
      {'name': 'Inspector Kael', 'role': 'Inquisitive Visitor'},
      {'name': 'Lost Traveler', 'role': 'Weary Guest'},
      {'name': 'Merchant Silas', 'role': 'Traveling Merchant'},
    ];
    final guest = guests[Random().nextInt(guests.length)];

    // Create physical NPC
    final npc = NPCGenerator.generateRefugee().copyWith(
      name: guest['name']!,
      role: guest['role']!,
      currentRoomId: 'road',
      targetRoomId: 'road',
      movementProgress: 1.0,
      status: NPCStatus.idle,
      assignedRoomId: null, // Guests don't have rooms
      isResident: false, // Visitors are transient
    );

    // Check for uniqueness
    if (_npcs.any((n) => n.name == npc.name)) {
      return; // Already here
    }

    // Explicitly set a static schedule so they stay at road
    final visitorNpc = npc.copyWith(schedule: NPCSchedule.visitor());
    _npcs.add(visitorNpc);

    _lastAnnouncement =
        "A ${guest['role']}, ${guest['name']}, has arrived at the Road.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] GUEST ARRIVAL: ${guest['name']}",
    );
    notifyListeners();
  }

  void _processChickens() {
    bool hasRooster = _chickens.any((c) => c.isMale && c.isMature);

    for (int i = _chickens.length - 1; i >= 0; i--) {
      var chicken = _chickens[i];
      chicken = chicken.copyWith(ageMinutes: chicken.ageMinutes + 1);

      if (chicken.isMale) {
        _chickens[i] = chicken;
        continue;
      }

      if (chicken.isMature) {
        final minsSinceLastEgg =
            _currentDate.totalMinutes - chicken.lastEggDate.totalMinutes;

        // scaled by breed rate
        if (minsSinceLastEgg >= (24 * 60 / chicken.breed.eggRate)) {
          bool isFertilized = hasRooster && Random().nextDouble() < 0.4;

          if (isFertilized && Random().nextDouble() < 0.1) {
            // Hatching logic
            if (_currentDate.hour >= 6 && _currentDate.hour <= 9) {
              _chickens.add(
                Chicken.create(
                  chicken.breedType,
                  _currentDate,
                  isMale: Random().nextBool(),
                ),
              );
              _lastAnnouncement = "A new chick has hatched in the coop!";
            } else {
              _uncollectedEggs++;
              chicken = chicken.copyWith(eggsLaid: chicken.eggsLaid + 1);
            }
          } else {
            _uncollectedEggs++;
            chicken = chicken.copyWith(eggsLaid: chicken.eggsLaid + 1);
          }
          chicken = chicken.copyWith(lastEggDate: _currentDate);
        }
      }
      _chickens[i] = chicken;
    }
  }

  void _processLivestockByproducts() {
    // Check for rooms that could produce fertilizer (Pig Pen, Cattle Pasture)
    bool hasLivestockRoom = _rooms.any((r) => r.isRestored && (r.type == RoomType.pigPen || r.type == RoomType.cattlePasture));
    
    // Low chance per hour per room
    if (hasLivestockRoom && Random().nextDouble() < 0.3) {
      _resources['fertilizer'] = (_resources['fertilizer'] ?? 0) + 1;
    }
    
    // Even if no specific room yet, chickens produce a tiny bit
    if (_chickens.isNotEmpty && Random().nextDouble() < 0.1) {
      _resources['fertilizer'] = (_resources['fertilizer'] ?? 0) + 0.5;
    }
  }

  void _processCrops() {
    for (int i = 0; i < _crops.length; i++) {
      var crop = _crops[i];
      if (!crop.isHarvestable) {
        // Find the room for this crop (assuming crops are in rooms for now, 
        // but crops list is global. We might need a targetId on Crop if we want per-field growth diffs)
        // For now, let's assume a generic field or search for a field room if we had targetId.

        // Growth logic: Moisture and Fertilizer
        double moistureDecay = 0.0002; // Dries out over time
        
        // Cabbage/Crops should take 14-30 days to grow
        // 1 day = 1440 mins. 14 days = 20160 mins.
        double growthRate = 1.0 / 20160.0; // Base growth per tick (14 days)

        if (crop.type == CropType.grain) {
          growthRate = 1.0 / 43200.0; // 30 days
        }

        if (crop.moistureLevel > 0.1) {
          growthRate *= 2.0;
        } else {
          growthRate *= 0.1; // Stunted
        }

        // We need to know which room the crop is in to check fertilization.
        // Let's add roomId to Crop if it's missing, but it wasn't in the original model.
        // Wait, the original model didn't have roomId. Let's see how they are tracked.
        // In _handleTaskCompletion, harvestCabbage looks at _crops.
        // Let's add roomId to Crop to make it field-specific.

        _crops[i] = crop.copyWith(
          growthProgress: (crop.growthProgress + growthRate).clamp(0.0, 1.0),
          moistureLevel: (crop.moistureLevel - moistureDecay).clamp(0.0, 1.0),
        );
      }
    }
  }

  bool plantCrops(CropType type, String roomId) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return false;
    final room = _rooms[roomIndex];

    if (room.type != RoomType.field && room.type != RoomType.garden) {
      _lastAnnouncement = "${room.name} is not suitable for crops.";
      notifyListeners();
      return false;
    }

    if (!room.isTilled) {
      _lastAnnouncement =
          "The soil in ${room.name} must be tilled before planting.";
      notifyListeners();
      return false;
    }

    String seedId = 'seeds_${type.name}';
    double seedConsumption = room.tilledAmount >= 1.0 ? 1.0 : 0.5;
    if ((_resources[seedId] ?? 0) < seedConsumption) {
      _lastAnnouncement = "Not enough $seedId available.";
      notifyListeners();
      return false;
    }
    
    _resources[seedId] = (_resources[seedId] ?? 0) - seedConsumption;
    
    // Yield based on preparation: 0.5 multiplier if partial, plus fertilizer bonus
    final baseYield = room.tilledAmount >= 1.0 ? 4 : 2;
    final fertBonus = room.isFertilized ? 2 : 0;
    final totalYield = (baseYield + fertBonus).toInt();

    _crops.add(
      Crop(
        id: const Uuid().v4(),
        type: type,
        plantedAt: DateTime.now(),
        isTilled: room.tilledAmount >= 0.5,
        isWatered: true,
        moistureLevel: 1.0,
        roomId: roomId,
        yield: totalYield,
      ),
    );

    // Consume tilled state? Or let it persist for a bit?
    // Let's reduce tilled amount slightly.
    _rooms[roomIndex] = room.copyWith(
      tilledAmount: (room.tilledAmount - 0.2).clamp(0.0, 1.0),
    );

    _lastAnnouncement = "Planted ${type.name} in ${room.name}.";
    notifyListeners();
    return true;
  }

  void tillSoil(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _rooms[index];
      _rooms[index] = room.copyWith(
        tilledAmount: (room.tilledAmount + 0.5).clamp(0.0, 1.0),
      );
      notifyListeners();
    }
  }

  void fertilizeSoil(String roomId) {
    final index = _rooms.indexWhere((r) => r.id == roomId);
    if (index != -1) {
      final room = _rooms[index];
      _rooms[index] = room.copyWith(
        fertilizedAmount: (room.fertilizedAmount + 0.5).clamp(0.0, 1.0),
      );
      notifyListeners();
    }
  }

  void waterCrops(String roomId) {
    // For now, water all crops globally or we could filter if we had roomId on Crop
    for (int i = 0; i < _crops.length; i++) {
      _crops[i] = _crops[i].copyWith(isWatered: true, moistureLevel: 1.0);
    }
    _lastAnnouncement = "The crops have been watered.";
    notifyListeners();
  }

  void careForCrops(String roomId) {
    for (int i = 0; i < _crops.length; i++) {
      _crops[i] = _crops[i].copyWith(lastCaredForAt: DateTime.now());
    }
    _lastAnnouncement = "The crops have been tended to.";
    notifyListeners();
  }

  void _processPredators() {
    // Only check at night (e.g., 22:00 to 04:00)
    final hour = _currentDate.hour;
    if (hour < 22 && hour > 4) return;

    // Once per hour roll for attempt if foxes exist
    if (_estateFoxes.isWipedOut) {
      // Reintroduction logic
      final daysSinceMigration = DateTime.now()
          .difference(_estateFoxes.lastMigrationDate)
          .inDays;
      if (daysSinceMigration > 14) {
        // 2 weeks
        _estateFoxes = _estateFoxes.copyWith(
          currentCount: 3,
          lastMigrationDate: DateTime.now(),
        );
        _lastAnnouncement =
            "A pack of wild foxes has migrated onto the estate.";
      }
      return;
    }

    // Roll for attack (low chance per minute, e.g. 0.05%)
    if (Random().nextDouble() < 0.0005) {
      _triggerFoxRaid();
    }
  }

  void _triggerFoxRaid() {
    // Check for guards (either manual task or scheduled activity)
    final hour = _currentDate.hour;
    final guards = _npcs.where((n) {
      final isScheduled =
          n.schedule.getActivityForHour(hour) == ScheduleActivity.guardCoop;
      final hasManualTask =
          n.activeTaskId != null &&
          _taskService.activeTasks.any(
            (t) => t.npcId == n.id && t.type == TaskType.guardCoop,
          );

      // Effectiveness check (Endurance and Hunger impact)
      final endurance = n.stats['endurance'] ?? 50;
      bool isEffective = endurance > 20 && n.hunger < 80;

      return (isScheduled || hasManualTask) && isEffective;
    }).toList();

    if (guards.isNotEmpty) {
      // Success! Capturing or killing a fox
      _estateFoxes = _estateFoxes.copyWith(
        currentCount: _estateFoxes.currentCount - 1,
      );
      _lastAnnouncement =
          "The guard at the coop spotted a fox and drove it off (Population decreased).";
    } else if (_chickens.isNotEmpty) {
      // Fox wins
      _chickens.removeAt(Random().nextInt(_chickens.length));
      _lastAnnouncement =
          "Common bandits? No, a fox has raided the coop. One chicken is lost.";

      // Trigger "Intruder" crisis at the chicken coop
      final intruder = ManorCrisis(
        type: ManorCrisisType.intruder,
        roomId: 'chicken_coop',
        discoveryDate: _currentDate.toDateTime(),
        severity: 0.2,
        isDiscovered: true, // It's discovered because the message was sent
      );
      _crises.add(intruder);
    }
    notifyListeners();
  }

  void _processHygiene() {
    // Rooms get dirty based on occupancy
    final roomNpcs = <String, int>{};
    for (var npc in _npcs.where((n) => n.currentRoomId != null)) {
      roomNpcs[npc.currentRoomId!] = (roomNpcs[npc.currentRoomId!] ?? 0) + 1;
    }

    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      if (!room.isRestored || !room.isInsideManor) continue;

      int occupants = roomNpcs[room.id] ?? 0;
      double accumulation = 0.0001; // Base dust
      accumulation += occupants * 0.0005; // 0.03 per hour per person approx

      if (accumulation > 0) {
        _rooms[i] = room.copyWith(
          dirtiness: (room.dirtiness + accumulation).clamp(0.0, 1.0),
        );
      }
    }
  }

  void _processCrises() {
    // 1. Spontaneous crisis triggers

    // Kitchen Fire Trigger: Higher chance when cooking or kitchen is dirty
    if (_crises.where((c) => c.type == ManorCrisisType.fire).isEmpty) {
      final kitchenIndex = _rooms.indexWhere((r) => r.id == 'kitchen');
      if (kitchenIndex != -1) {
        final kitchen = _rooms[kitchenIndex];
        double fireChance = 0.0001; // Base per minute
        if (kitchen.dirtiness > 0.5) fireChance *= 2;

        // Use task service to check if anyone is cooking in kitchen
        final isCooking = _taskService.activeTasks.any(
          (t) => t.type == TaskType.cook && t.targetId == 'kitchen',
        );
        if (isCooking) fireChance *= 5;

        if (Random().nextDouble() < fireChance) {
          final fire = ManorCrisis(
            type: ManorCrisisType.fire,
            roomId: 'kitchen',
            discoveryDate: _currentDate.toDateTime(),
            severity: 0.1,
          );
          _crises.add(fire);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] EMERGENCY: A fire has broken out in the Kitchen!",
          );
        }
      }
    }

    // 2. Crisis Progression
    for (int i = _crises.length - 1; i >= 0; i--) {
      var crisis = _crises[i];
      double progression = 0.001; // Increase severity by 0.1% per minute

      // Fires grow faster if room is dirty
      if (crisis.type == ManorCrisisType.fire) {
        final roomIndex = _rooms.indexWhere((r) => r.id == crisis.roomId);
        if (roomIndex != -1) {
          progression += _rooms[roomIndex].dirtiness * 0.002;
        }
      }

      crisis = crisis.copyWith(
        severity: (crisis.severity + progression).clamp(0.0, 1.0),
      );
      _crises[i] = crisis;

      // Severity Effects
      if (crisis.severity >= 1.0) {
        // Crisis maxed out! Potential disaster logic here (destruction, death)
        if (crisis.type == ManorCrisisType.fire) {
          final room = _rooms.firstWhere((r) => r.id == crisis.roomId);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] DISASTER: The fire in the ${room.name} has consumed the Manor.",
          );
          _triggerGameOver(
            "THE MANOR HAS BURNED TO THE GROUND IN A TERRIBLE BLAZE.",
          );
        }
      }
    }

    if (_checkTotalFailure()) {
      _triggerGameOver(
        "THE RESIDENTS ARE CAPITULATED. NONE REMAIN TO STOP THE CONSUMING FLAME.",
      );
    }
  }

  void _triggerGameOver(String reason) {
    if (_isGameOver) return;
    _isGameOver = true;
    _gameOverReason = reason;
    _speed = GameSpeed.paused;
    notifyListeners();
  }

  bool _checkTotalFailure() {
    // Only check for failure if there is a serious fire
    final seriousFire = _crises.any(
      (c) => c.type == ManorCrisisType.fire && c.severity > 0.4,
    );
    if (!seriousFire) return false;

    // A capable resident is one who is not dead, fainted, or broken
    final capable = _npcs.where(
      (n) =>
          n.status != NPCStatus.dead &&
          n.status != NPCStatus.fainted &&
          n.status != NPCStatus.broken &&
          n.energy > 5,
    );

    return capable.isEmpty && _npcs.isNotEmpty;
  }

  void buyChicken(ChickenBreedType type) {
    final breed = ChickenBreed.getByTyped(type);
    if ((_resources['funds'] ?? 0) >= breed.basePrice) {
      _resources['funds'] = _resources['funds']! - breed.basePrice;
      _chickens.add(Chicken.create(
        type,
        _currentDate,
        isMale: type == ChickenBreedType.rooster,
        weight: type == ChickenBreedType.rooster ? 2.5 : 1.5,
      ));
      notifyListeners();
    }
  }


  void _processConstruction() {
    for (int i = _activeConstruction.length - 1; i >= 0; i--) {
      final project = _activeConstruction[i];
      project.minutesRemaining--;
      if (project.minutesRemaining <= 0) {
        _completeConstruction(project);
        _activeConstruction.removeAt(i);
      }
    }
  }

  void _completeConstruction(ConstructionProject project) {
    final bp = project.blueprint;
    final newRoom = Room.initial(
      "${bp.id}_${DateTime.now().millisecondsSinceEpoch}",
      bp.name,
      bp.type,
      bp.floor,
      width: bp.width,
      description: bp.description,
    );
    _rooms.add(newRoom);
    _lastAnnouncement = "${bp.name} construction is complete!";
    notifyListeners();
  }

  void _processExperiments() {
    for (int i = _activeExperiments.length - 1; i >= 0; i--) {
      final experiment = _activeExperiments[i];
      experiment.minutesRemaining--;

      if (experiment.minutesRemaining <= 0) {
        experiment.isComplete = true;
        _completeExperiment(experiment);
        _activeExperiments.removeAt(i);
      }
    }
  }

  void _completeExperiment(Experiment experiment) {
    final subjectIndex = _npcs.indexWhere((n) => n.id == experiment.subjectId);
    if (subjectIndex != -1) {
      final subject = _npcs[subjectIndex];
      final result = ExperimentationService.processCompletion(
        experiment,
        subject,
      );

      _npcs[subjectIndex] = result['subject'] as NPC;

      final Map<String, int> gains = result['resources'] as Map<String, int>;
      gains.forEach((key, value) {
        _resources[key] = (_resources[key] ?? 0) + value;
      });

      final List<String> logs = result['logs'] as List<String>;
      if (logs.isNotEmpty) {
        _lastAnnouncement = logs.first;
      }

      final typeStr = experiment.type.name;
      if (!_performedExperiments.contains(typeStr)) {
        _performedExperiments.add(typeStr);
      }
      _checkObjectives();
    }
    notifyListeners();
  }

  void _initializeObjectives() {
    _objectives.clear();
    _objectives.add(
      Objective(
        id: 'farming_tutorial_1',
        title: 'Break the Earth',
        description: 'The fields have lain fallow for too long. Assign an NPC to till the soil in Field A.',
        type: ObjectiveType.tutorial,
        requirements: {
          'tasks_performed': ['tillSoil'],
        },
      ),
    );
    _objectives.add(
      Objective(
        id: 'manor_restoration',
        title: 'The Great Restoration',
        description:
            'Rehabilitate every room within the Manor to bring the estate back to its former glory. (Reward: 1,000 Funds)',
        type: ObjectiveType.tutorial,
        requirements: {
          'rooms_cleaned': [
            'unused_1f',
            'library',
            'attic_1',
            'attic_2',
            'basement_1',
            'basement_2',
            'basement_3',
            'chicken_coop',
          ],
        },
      ),
    );
  }

  void _checkObjectives() {
    bool changed = false;
    final List<Objective> nextObjectives = [];

    for (var objective in _objectives.where((o) => !o.isCompleted).toList()) {
      bool completed = true;
      final reqs = objective.requirements;

      if (reqs.containsKey('rooms_cleaned')) {
        final targetRooms = List<String>.from(reqs['rooms_cleaned']);
        for (var roomId in targetRooms) {
          final room = _rooms.where((r) => r.id == roomId).firstOrNull;
          if (room == null || !room.isRestored) {
            completed = false;
            break;
          }
        }
      }

      if (reqs.containsKey('experiment_performed')) {
        final expType = reqs['experiment_performed'] as String;
        if (!_performedExperiments.contains(expType)) {
          completed = false;
        }
      }

      if (reqs.containsKey('tasks_performed')) {
        final targetTasksList = reqs['tasks_performed'] as List<dynamic>;
        for (var t in targetTasksList) {
          final tStr = t.toString();
          final tType = TaskType.values
              .where((type) => type.name == tStr)
              .firstOrNull;
          if (tType == null || !_completedTaskTypes.contains(tType)) {
            completed = false;
            break;
          }
        }
      }

      if (completed) {
        objective.isCompleted = true;
        changed = true;
        _unreadObjectiveCount++;
        _lastAnnouncement = "OBJECTIVE COMPLETE: ${objective.title}";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] QUEST: ${objective.title} COMPLETED",
        );

        // Apply Rewards
        if (objective.id == 'manor_restoration') {
          _resources['funds'] = (_resources['funds'] ?? 0) + 1000;
          _lastAnnouncement =
              "THE MANOR IS RESTORED. A BOUNTY OF 1000 FUNDS HAS BEEN AWARDED.";
        }

        // Handle follow-up objectives
        if (objective.id == 'manor_restoration') {
          nextObjectives.add(
            Objective(
              id: 'zoology_curiosity',
              title: 'Zoological Curiosity',
              description: 'Reach Zoology Level 1 to unlock advanced study.',
              type: ObjectiveType.science,
              requirements: {
                'research_level': {'Zoology': 1},
              },
            ),
          );
        } else if (objective.id == 'zoology_curiosity') {
          nextObjectives.add(
            Objective(
              id: 'the_spark',
              title: 'The Spark',
              description:
                  'Reach Alchemy Level 2 to discover reanimation principles.',
              type: ObjectiveType.science,
              requirements: {
                'research_level': {'Alchemy': 2},
              },
            ),
          );
        } else if (objective.id == 'the_spark') {
          nextObjectives.add(
            Objective(
              id: 'the_construct',
              title: 'The First Construct',
              description:
                  'Perform a Reanimation experiment in the Laboratory.',
              type: ObjectiveType.combat,
              requirements: {'experiment_performed': 'reanimation'},
            ),
          );
        } else if (objective.id == 'farming_tutorial_1') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_2',
              title: 'Enrich the Soil',
              description: 'The earth needs nutrients. Assign an NPC to fertilize Field A.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['fertilizeSoil'],
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_2') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_3',
              title: 'Sow the Seeds',
              description: 'The earth is prepared. Assign an NPC to plant cabbage seeds in Field A.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['plantCrops'],
              },
            ),
          );
        } else if (objective.id == 'farming_tutorial_3') {
          nextObjectives.add(
            Objective(
              id: 'farming_tutorial_4',
              title: 'Care for the Young',
              description: 'The seeds will wither without water. Ensure the fields are watered.',
              type: ObjectiveType.tutorial,
              requirements: {
                'tasks_performed': ['waterCrops'],
              },
            ),
          );
        }
      }
    }

    if (nextObjectives.isNotEmpty) {
      _objectives.addAll(nextObjectives);
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void _checkDiscoveries() {
    bool changed = false;
    for (var discovery in Discovery.allDiscoveries) {
      if (_unlockedDiscoveries.contains(discovery.id)) continue;

      bool met = true;
      // research_level check removed
      if (met) {
        _unlockedDiscoveries.add(discovery.id);
        changed = true;
        _lastAnnouncement = "NEW DISCOVERY: ${discovery.name}!";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] SCIENCE: ${discovery.name} unlocked.",
        );
      }
    }
    if (changed) notifyListeners();
  }

  void assignNpcToBed(
    String npcId,
    String roomId,
    int bedIndex,
    int spotIndex,
  ) {
    // 1. Unassign from previous bed if any
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      List<Bed> updatedBeds = [];
      bool changed = false;
      for (var bed in room.beds) {
        if (bed.assignedNpcIds.contains(npcId)) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          final idx = newSpots.indexOf(npcId);
          newSpots[idx] = null;
          updatedBeds.add(bed.copyWith(assignedNpcIds: newSpots));
          changed = true;
        } else {
          updatedBeds.add(bed);
        }
      }
      if (changed) {
        _rooms[i] = room.copyWith(beds: updatedBeds);
      }
    }

    // 2. Assign to new bed
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      final room = _rooms[roomIndex];
      if (bedIndex < room.beds.length) {
        final bed = room.beds[bedIndex];
        if (spotIndex < bed.assignedNpcIds.length) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          newSpots[spotIndex] = npcId;
          final updatedBeds = List<Bed>.from(room.beds);
          updatedBeds[bedIndex] = bed.copyWith(assignedNpcIds: newSpots);
          _rooms[roomIndex] = room.copyWith(beds: updatedBeds);
        }
      }
    }

    // 3. Update NPC's assignedRoomId
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex != -1) {
      _npcs[npcIndex] = _npcs[npcIndex].copyWith(assignedRoomId: roomId);
    }

    notifyListeners();
  }

  void unassignNpcFromBed(String npcId) {
    for (int i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      List<Bed> updatedBeds = [];
      bool changed = false;
      for (var bed in room.beds) {
        if (bed.assignedNpcIds.contains(npcId)) {
          final newSpots = List<String?>.from(bed.assignedNpcIds);
          final idx = newSpots.indexOf(npcId);
          newSpots[idx] = null;
          updatedBeds.add(bed.copyWith(assignedNpcIds: newSpots));
          changed = true;
        } else {
          updatedBeds.add(bed);
        }
      }
      if (changed) {
        _rooms[i] = room.copyWith(beds: updatedBeds);
      }
    }

    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex != -1) {
      _npcs[npcIndex] = _npcs[npcIndex].copyWith(clearAssignedRoom: true);
    }

    notifyListeners();
  }

  void startExperiment(Experiment experiment) {
    _activeExperiments.add(experiment);
    // Update NPC status
    final index = _npcs.indexWhere((n) => n.id == experiment.subjectId);
    if (index != -1) {
      _npcs[index] = _npcs[index].copyWith(status: NPCStatus.working);
    }
    _lastAnnouncement =
        "Experiment started on ${_npcs.firstWhere((n) => n.id == experiment.subjectId).name}.";
    notifyListeners();
  }

  void startConstruction(ConstructionBlueprint blueprint) {
    if (_resources['funds']! >= blueprint.cost['funds']! &&
        _resources['wood']! >= (blueprint.cost['wood'] ?? 0)) {
      _resources['funds'] = _resources['funds']! - blueprint.cost['funds']!;
      _resources['wood'] = _resources['wood']! - (blueprint.cost['wood'] ?? 0);

      _activeConstruction.add(
        ConstructionProject(
          blueprint: blueprint,
          minutesRemaining: blueprint.durationMinutes,
        ),
      );
      _lastAnnouncement = "Construction started on ${blueprint.name}.";
      notifyListeners();
    }
  }

  void _updateNpcs() {
    for (var i = 0; i < _npcs.length; i++) {
      // Intent Management
      _updateIntentQueue(i);
      _processCurrentIntent(i);

      // Refresh reference after intent processing
      var npc = _npcs[i];

      // Movement Logic
      if (npc.targetRoomId != null || npc.movementPath.isNotEmpty) {
        _processNpcMovement(i);
        npc = _npcs[i]; // Refresh after movement
      }

      // Deadlock Detection & Status Duration Tracking
      // Reset ticks if status changed OR if activeTaskId changed (sequential tasks)
      final bool statusChanged = npc.status != _npcs[i].status;
      final bool taskChanged = npc.activeTaskId != _npcs[i].activeTaskId;

      if (statusChanged || taskChanged) {
        _npcs[i] = _npcs[i].copyWith(currentStateTicks: 0);
        npc = _npcs[i]; // Refresh for next part of loop if needed
      } else if (npc.status != NPCStatus.idle &&
          npc.status != NPCStatus.dead &&
          npc.status != NPCStatus.sleeping &&
          npc.status != NPCStatus.fainted &&
          npc.status != NPCStatus.broken) {
        final newTicks = npc.currentStateTicks + 1;
        // 12 hour timeout is a bit low for industrious NPCs, let's bump it to 18 hours (1080)
        if (newTicks > 1080) {
          // 12 hour timeout
          final preferredRoom = npc.assignedRoomId ?? _butlerRoomId;
          _npcs[i] = npc.copyWith(
            status: NPCStatus.idle,
            activeTaskId: null,
            targetRoomId: preferredRoom,
            movementProgress: (preferredRoom == npc.currentRoomId) ? 1.0 : 0.0,
            currentStateTicks: 0,
            currentThought: "I've been here too long...",
          );
          npc = _npcs[i]; // Refresh
        } else {
          _npcs[i] = npc.copyWith(currentStateTicks: newTicks);
          npc = _npcs[i]; // Refresh
        }
      } else if (statusChanged) {
        _npcs[i] = npc.copyWith(currentStateTicks: 0);
        npc = _npcs[i]; // Refresh
      }

      // Refresh reference after ticks
      npc = _npcs[i];

      // Needs Simulation
      _processNpcNeeds(i);

      // World Travel Simulation
      _processNpcTravel(i);

      // Visitor Departure tracking
      if (!npc.isResident &&
          npc.role != 'Minion' &&
          npc.worldDestinationId == null) {
        final newMinutes = npc.minutesStaying + 1;
        if (newMinutes > 180) {
          // Leave after 3 hours
          _npcs[i] = _npcs[i].copyWith(
            minutesStaying: newMinutes,
            worldDestinationId: 'road',
            worldTravelProgress: 0.0,
            currentThought: "I should head out now.",
            status: NPCStatus.idle,
          );
        } else {
          _npcs[i] = _npcs[i].copyWith(minutesStaying: newMinutes);
        }
      }
    }

    // Cleanup NPCs that finished traveling away
    _npcs.removeWhere(
      (n) =>
          !n.isResident &&
          n.worldDestinationId == 'road' &&
          n.worldTravelProgress >= 1.0,
    );
  }

  void _processNpcTravel(int index) {
    var npc = _npcs[index];
    if (npc.worldDestinationId == null) return;

    // Travel speed: Manor <-> Hamlet takes 4 hours (240 minutes)
    // 1 minute per tick (if 1x speed), so approx 0.004 progress per tick
    const double travelInterval = 1.0 / 240.0;
    double newProgress = (npc.worldTravelProgress + travelInterval).clamp(
      0.0,
      1.0,
    );

    if (newProgress >= 1.0 && npc.worldTravelProgress < 1.0) {
      // Arrival!
      if (npc.worldDestinationId == 'manor') {
        _completeJourneyAtManor(index);
      } else {
        _npcs[index] = npc.copyWith(worldTravelProgress: 1.0);
        _lastAnnouncement =
            "${npc.name} has arrived at ${npc.worldDestinationId!.toUpperCase()}.";
        if (npc.isPlayer) {
          _pendingNavigationTarget = npc.worldDestinationId;
        }
        setSpeed(GameSpeed.normal);
      }
      notifyListeners();
    } else {
      _npcs[index] = npc.copyWith(worldTravelProgress: newProgress);
    }

    // Random Encounter Trigger (0.05% per minute) - Only if Player actively moving
    // Cooldown: 10 minutes between encounters
    if (!_pendingCombatEncounter &&
        npc.isPlayer &&
        newProgress < 1.0 &&
        (_currentDate.totalMinutes - _lastEncounterMinute >= 10) &&
        Random().nextDouble() < 0.0005) {
      _triggerCombatEncounter();
    }
  }

  void _triggerCombatEncounter() {
    _pendingCombatEncounter = true;
    _lastEncounterMinute = _currentDate.totalMinutes;
    _lastAnnouncement = "BANDITS! An encounter has occurred on the road.";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] ENCOUNTER: Bandits on the road!",
    );
    _speed = GameSpeed.paused;
    notifyListeners();
  }

  void _processDishes() {
    // Every game minute (tick), NPCs check if it's mealtime
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      final hourIndex = _currentDate.hour;
      final activity = npc.schedule.getActivityForHour(hourIndex);

      if (activity == ScheduleActivity.eat && npc.hunger > 20) {
        // Check pantry for preferred dish types
        final neededTypes = npc.diet.dailyRequirements.keys.toList();
        int? bestDishIndex;

        // Find best quality dish of needed type
        for (int j = 0; j < _pantry.length; j++) {
          final dish = _pantry[j];
          if (neededTypes.contains(dish.type)) {
            if (bestDishIndex == null ||
                _pantry[bestDishIndex].quality.index > dish.quality.index) {
              bestDishIndex = j;
            }
          }
        }

        if (bestDishIndex != null) {
          final dish = _pantry.removeAt(bestDishIndex);
          double hungerRecovered = 40.0;
          _npcs[i] = npc.copyWith(
            hunger: (npc.hunger - hungerRecovered).clamp(0, 100),
            currentThought: "EXCELLENT ${dish.name.toUpperCase()} ($activity).",
          );
        }
      }
    }
  }

  void _processSpoilage() {
    // Every tick (minute), check if anything spoiled
    // To avoid too many DateTime calls, we check every 60 ticks (1 hour)
    if (_currentDate.minute == 0) {
      final now = DateTime.now();
      
      // Spoil pantry dishes (48h default, meals in prompt are preserved for 4 days)
      _pantry.removeWhere((d) => d.isSpoiled(now));

      // Spoil inventory items (Raw materials spoil in 10 days)
      _inventory.removeWhere((item) {
        if (item.category == ItemCategory.resource || item.category == ItemCategory.food) {
          final addedAtStr = item.metadata['addedAt'] as String?;
          if (addedAtStr != null) {
            final addedAt = DateTime.parse(addedAtStr);
            final shelfLifeDays = (item.metadata['shelfLifeDays'] as num? ?? 10).toDouble();
            if (now.difference(addedAt).inDays >= shelfLifeDays) {
              return true; // Item spoiled
            }
          }
        }
        return false;
      });
    }
  }

  NPC? _getBedSharer(NPC npc) {
    if (npc.assignedRoomId == null) return null;
    final room = _rooms.where((r) => r.id == npc.assignedRoomId).firstOrNull;
    if (room == null) return null;

    for (var bed in room.beds) {
      if (bed.isShared && bed.assignedNpcIds.contains(npc.id)) {
        final sharerId = bed.assignedNpcIds.firstWhere(
          (id) => id != npc.id && id != null,
          orElse: () => null,
        );
        if (sharerId != null) {
          return _npcs.where((n) => n.id == sharerId).firstOrNull;
        }
      }
    }
    return null;
  }

  bool _hasRomanticLove(NPC a, NPC b) {
    final relA = a.relationships[b.id];
    final relB = b.relationships[a.id];
    if (relA == null || relB == null) return false;

    // "Romantic Love" = attraction > 4.0 AND admiration > 4.0 (bi-directional)
    return relA.attraction > 4.0 &&
        relA.admiration > 4.0 &&
        relB.attraction > 4.0 &&
        relB.admiration > 4.0;
  }

  void _processNpcNeeds(int index) {
    var npc = _npcs[index];
    final hour = _currentDate.hour;
    final activity = npc.schedule.getActivityForHour(hour);

    double dEnergy = 0.0;
    double dHunger = (2.5 / 60.0); // Hunger increases by 2.5 per hour (approx 60/day)
    double dSatisf = 0.0;

    // "Thriving" or "Starving" satisfaction logic
    if (npc.hunger < 20.0) {
      dSatisf += (5.0 / 60.0); // Bliss from being well-fed
    } else if (npc.hunger > 80.0) {
      dSatisf -= (10.0 / 60.0); // Misery from hunger
    }

    // Digestion: Ramp up such that NPCs need to use toilet 2-3 times/day
    // Target: ~480-720 minutes to hit 100.
    double digestionMultiplier = npc.isPlayer ? 3.5 : 2.5; 
    double dDigestion = (digestionMultiplier * 100.0 / 1440.0);

    // Hygiene decay logic based on numerical hygiene stat
    double hygieneDecayDays;
    if (npc.hygiene > 75) {
      hygieneDecayDays = 1.0; // High
    } else if (npc.hygiene > 25) {
      hygieneDecayDays = 3.5; // Moderate
    } else {
      hygieneDecayDays = 7.0; // Low
    }
    double dHygiene = -(100.0 / (hygieneDecayDays * 1440.0));

    if (npc.status == NPCStatus.sleeping) {
      dEnergy = (10.0 / 60.0); // Recovery while sleeping
      
      // Bed sharing consequences
      final sharer = _getBedSharer(npc);
      if (sharer != null && sharer.status == NPCStatus.sleeping) {
        final love = _hasRomanticLove(npc, sharer);
        if (love) {
          dEnergy += (2.0 / 60.0); // Better rest with love
          dSatisf += (5.0 / 60.0); // Blissful sleep
        } else {
          dSatisf -= (3.0 / 60.0); // Uncomfortable sharing without love
        }
      }
    } else {
      dEnergy = -(2.0 / 60.0); // Exhaustion while awake
    }

    if (npc.status == NPCStatus.working) {
      dEnergy *= 1.5; // Tasks are tiring
      dHunger *= 1.5;
      // Working makes you dirtier
      dHygiene *= 1.25;
    }

    // Auto-eating logic
    double newHunger = npc.hunger + dHunger;
    double newSatisf = (npc.satisfaction + dSatisf).clamp(0.0, 100.0);

    // If very hungry, try to eat from pantry if in a kitchen/dining area or scheduled to eat
    if (newHunger > 50.0 &&
        (activity == ScheduleActivity.eat || npc.status == NPCStatus.idle)) {
      if ((_resources['meals'] ?? 0) > 0) {
        _resources['meals'] = _resources['meals']! - 1;
        newHunger -= 60.0;
        newSatisf += 10.0;
        // Increment dirty dishes on auto-eat
        _resources['dirty_dishes'] = (_resources['dirty_dishes'] ?? 0) + 1;
      }
    }

    // Diet / Hunger recovery is now handled by _processDishes
    // But we keep basic logic if pantry is empty (emergency foraging?)
    if (activity == ScheduleActivity.eat && newHunger > 50 && _pantry.isEmpty) {
      if ((_resources['meat'] ?? 0) > 0 || (_resources['cabbage'] ?? 0) > 0) {
        // Emergency feeding from raw ingredients if no dishes
        if ((_resources['meat'] ?? 0) > 0) {
          _resources['meat'] = _resources['meat']! - 1;
          newHunger -= 20.0; // Raw meat is worse than cooked meal
        } else {
          _resources['cabbage'] = _resources['cabbage']! - 1;
          newHunger -= 10.0;
        }
        // Increment dirty dishes on emergency eat
        _resources['dirty_dishes'] = (_resources['dirty_dishes'] ?? 0) + 1;
      }
    }

    // --- Survival Failure Logic ---

    // 1. Energy Collapse (Fainting)
    double newEnergy = (npc.energy + dEnergy).clamp(0.0, 100.0);
    double newHygiene = (npc.hygiene + dHygiene).clamp(0.0, 100.0);
    NPCStatus newStatus = npc.status;
    String? newThought = npc.currentThought;
    String? newActiveTaskId = npc.activeTaskId;
    String? newTargetRoomId = npc.targetRoomId;

    if (newEnergy <= 0.0 &&
        npc.status != NPCStatus.fainted &&
        npc.status != NPCStatus.dead) {
      newStatus = NPCStatus.fainted;
      newThought = "Everything is... turning... black...";
      newActiveTaskId = null;
      newTargetRoomId = null;
    } else if (npc.status == NPCStatus.fainted && newEnergy >= 30.0) {
      // Recover from fainting at 30 energy
      newStatus = NPCStatus.idle;
      newThought = "Ugh... my head...";
    }

    // 2. Starvation & Health Decay
    if (newHunger >= 100.0 && npc.status != NPCStatus.dead) {
      // NPC is starving! Damage body parts.
      final List<BodyPart> newBodyParts = List.from(npc.bodyParts);
      bool died = false;
      for (int i = 0; i < newBodyParts.length; i++) {
        // Lose 0.5 HP per tick (approx 30 HP per hour)
        double newHp = (newBodyParts[i].health - 0.5).clamp(0.0, 100.0);
        newBodyParts[i] = newBodyParts[i].copyWith(health: newHp);

        if (newHp <= 0 &&
            (newBodyParts[i].type == BodyPartType.head ||
                newBodyParts[i].type == BodyPartType.torso)) {
          died = true;
        }
      }

      if (died) {
        newStatus = NPCStatus.dead;
        newThought = "Farewell...";
      } else {
        newThought = "SO... HUNGRY...";
      }
      _npcs[index] = npc.copyWith(bodyParts: newBodyParts);
      npc = _npcs[index]; // Refresh ref
    } else if (newHunger < 50.0 && npc.status != NPCStatus.dead) {
      // Natural healing if well fed
      final List<BodyPart> newBodyParts = List.from(npc.bodyParts);
      for (int i = 0; i < newBodyParts.length; i++) {
        if (newBodyParts[i].health < newBodyParts[i].maxHealth) {
          double newHp = (newBodyParts[i].health + 0.1).clamp(
            0.0,
            newBodyParts[i].maxHealth.toDouble(),
          );
          newBodyParts[i] = newBodyParts[i].copyWith(health: newHp);
        }
      }
      _npcs[index] = npc.copyWith(bodyParts: newBodyParts);
      npc = _npcs[index]; // Refresh ref
    }

    // 3. Autonomous Hygiene & Digestion Trigger
    if (newActiveTaskId == null && newStatus == NPCStatus.idle) {
      // Digestion Trigger
      if (npc.digestion > 85.0) {
        final toiletRoom = _rooms.firstWhere(
          (r) => r.type == RoomType.toilet && r.isRestored,
          orElse: () => _rooms.firstWhere((r) => r.type == RoomType.toilet, orElse: () => _rooms.first),
        );
        assignTask(
          GameTask(
            id: "toilet_${npc.id}_${_currentDate.totalMinutes}",
            npcId: npc.id,
            type: TaskType.useToilet,
            targetId: toiletRoom.id,
            minutesRemaining: 10, // Base duration
          ),
        );
      }
      // Hygiene Trigger
      else if (newHygiene < 20.0) {
        final washRoom = _rooms.firstWhere(
          (r) => r.type == RoomType.toilet && r.isRestored,
          orElse: () => _rooms.firstWhere(
            (r) => r.type == RoomType.toilet,
            orElse: () => Room.initial('na', 'na', RoomType.unused, Floor.ground),
          ),
        );

        if (washRoom.id != 'na') {
          // Duration based on hygiene needs (simulated via current hygiene level or traits if available)
          int duration = (newHygiene < 10) ? 25 : 15;
          assignTask(
            GameTask(
              id: "wash_${npc.id}_${_currentDate.totalMinutes}",
              npcId: npc.id,
              type: TaskType.wash,
              targetId: washRoom.id,
              minutesRemaining: duration,
            ),
          );
          newThought = "I desperately need to wash up.";
        }
      }
    }

    _npcs[index] = npc.copyWith(
      status: newStatus,
      energy: newEnergy,
      hunger: newHunger.clamp(0.0, 100.0),
      satisfaction: newSatisf.clamp(0.0, 100.0),
      digestion: (npc.digestion + dDigestion).clamp(0.0, 105.0),
      hygiene: newHygiene,
      currentThought: newThought,
      activeTaskId: newActiveTaskId,
      targetRoomId: newTargetRoomId,
      clearTarget: newTargetRoomId == null,
    );
  }

  void _processDigestion() {
    for (int i = 0; i < _npcs.length; i++) {
      var latestNpc = _npcs[i];
      if (latestNpc.status == NPCStatus.dead ||
          latestNpc.status == NPCStatus.zombie) {
        continue;
      }

      // 0. Recovery from Breaking Point
      if (latestNpc.status == NPCStatus.broken &&
          latestNpc.breakStartTime != null &&
          latestNpc.breakDuration != null) {
        if (_currentDate.totalMinutes >=
            latestNpc.breakStartTime! + latestNpc.breakDuration!) {
          // Readjust satisfaction to a safe level (50-70% depending on episode history)
          final episodeFactor = (latestNpc.mentalEpisodeCount * 5.0).clamp(0.0, 30.0);
          final newSatisfValue = (70.0 - episodeFactor).clamp(40.0, 80.0);
          
          _npcs[i] = latestNpc.copyWith(
            status: NPCStatus.idle,
            satisfaction: newSatisfValue,
            currentThought: "I feel... better now. What was I doing?",
          );
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] RECOVERY: ${latestNpc.name} has recovered from their episode.",
          );
          continue; // Skip further processing for this tick
        }
      }

      // 1. Breaking Point Tracking
      if (latestNpc.digestion >= 100.0) {
        int newBreakingMinutes = latestNpc.breakingPointMinutes + 1;
        if (newBreakingMinutes >= 15) {
          _triggerBowelMovementIncident(i);
        } else {
          _npcs[i] = latestNpc.copyWith(
            breakingPointMinutes: newBreakingMinutes,
            currentThought: "I CAN'T HOLD IT MUCH LONGER!",
          );
        }
      }

      // 3. Mental Breaking Point Tracking
      final double guilt = (latestNpc.stats['guilt'] ?? 0).toDouble();
      if (guilt >= 90.0 || latestNpc.satisfaction <= 5.0) {
        int newMentalBreaking = latestNpc.mentalBreakingPointMinutes + 1;
        if (newMentalBreaking >= 30) {
          _triggerMentalBreakdownIncident(i);
        } else {
          _npcs[i] = _npcs[i].copyWith(
            mentalBreakingPointMinutes: newMentalBreaking,
            currentThought: "I can't take this anymore...",
          );
        }
      } else {
        if (latestNpc.mentalBreakingPointMinutes > 0) {
          _npcs[i] = _npcs[i].copyWith(mentalBreakingPointMinutes: 0);
        }
      }

      // 2. Desperate Need (85%)
      latestNpc = _npcs[i]; // Refresh reference
      if (latestNpc.digestion >= 85.0 &&
          latestNpc.activeTaskId == null &&
          latestNpc.status != NPCStatus.working) {
        // Try to find a toilet
        final toiletRoom = _rooms.firstWhere(
          (r) => r.type == RoomType.toilet && r.isRestored,
          orElse: () => _rooms.firstWhere(
            (r) => r.type == RoomType.toilet,
            orElse: () =>
                Room.initial('na', 'na', RoomType.unused, Floor.ground),
          ),
        );

        if (toiletRoom.id != 'na') {
          assignTask(
            GameTask(
              id: "toilet_${latestNpc.id}_${_currentDate.totalMinutes}",
              npcId: latestNpc.id,
              type: TaskType.useToilet,
              targetId: toiletRoom.id,
              minutesRemaining: 3 + Random().nextInt(18),
            ),
          );
          _npcs[i] = _npcs[i].copyWith(
            currentThought: "DESPERATE NEED: TOILET.",
          );
        }
      }
    }
  }

  void _triggerMentalBreakdownIncident(int npcIndex) {
    var npc = _npcs[npcIndex];
    final episodeNum = npc.mentalEpisodeCount + 1;
    
    // Determine if it's an Anger Episode or a Psychotic Break
    // First episode is always Anger. Subsequent have increasing psychotic chance.
    bool isPsychotic = false;
    if (episodeNum > 1) {
      final breakChance = (episodeNum - 1) * 0.3; // 30%, 60%, 90%...
      isPsychotic = Random().nextDouble() < breakChance;
    }

    int duration;
    String incidentName;
    String thought;
    NPCStatus newStatus = NPCStatus.broken;

    if (!isPsychotic) {
      incidentName = "Anger Episode";
      duration = 60; // 1 hour
      thought = "I'm SO ANGRY! I can't think straight!";
      // We'll keep status as broken for now as it clears the queue, 
      // but maybe we use panicked or a custom one if needed.
    } else {
      incidentName = "Psychotic Break";
      // Up to 1 day (1440 mins) in early game (first 60 days)
      final earlyGameFactor = _currentDate.day <= 60 ? 1.0 : 2.0;
      duration = (120 + Random().nextInt(1320)).toInt(); // 2h to 24h
      duration = (duration * earlyGameFactor).toInt();
      thought = "I CAN'T TAKE IT! THE VOICES! THE GUILT!";
    }

    _lastAnnouncement =
        "INCIDENT: ${npc.name} is having an $incidentName!";
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] INCIDENT: $incidentName for ${npc.name}.",
    );

    // Character status change
    _npcs[npcIndex] = npc.copyWith(
      status: newStatus,
      activeTaskId: null,
      targetRoomId: null,
      clearTarget: true,
      satisfaction: (npc.satisfaction - 10).clamp(0, 100),
      mentalBreakingPointMinutes: 0,
      mentalEpisodeCount: episodeNum,
      breakStartTime: _currentDate.totalMinutes,
      breakDuration: duration,
      currentThought: thought,
    );

    // Social effects - others might be frightened
    final roomId = npc.currentRoomId;
    if (roomId != null) {
      for (int j = 0; j < _npcs.length; j++) {
        if (j == npcIndex) continue;
        if (_npcs[j].currentRoomId == roomId) {
          final other = _npcs[j];
          final rels = Map<String, Relationship>.from(other.relationships);
          final oldRel = rels[npc.id] ?? Relationship();
          rels[npc.id] = oldRel.copyWith(
            fear: (oldRel.fear + 1.5).clamp(0, 5),
            respect: (oldRel.respect - 0.5).clamp(0, 5),
          );
          _npcs[j] = other.copyWith(
            relationships: rels,
            satisfaction: (other.satisfaction - 15).clamp(0, 100),
            currentThought:
                "Someone help ${npc.name}! They've lost their mind!",
          );
        }
      }
    }
    notifyListeners();
  }

  void _processHourlyRelationshipEvolution() {
    final Map<String, List<int>> rooms = {};

    for (int i = 0; i < _npcs.length; i++) {
      final roomId = _npcs[i].currentRoomId;
      if (roomId != null && _npcs[i].status != NPCStatus.dead) {
        rooms.putIfAbsent(roomId, () => []).add(i);
      }
    }

    final isKind = _butlerDisposition == ButlerDisposition.kind;
    final isStern = _butlerDisposition == ButlerDisposition.stern;

    rooms.forEach((roomId, npcIndices) {
      if (npcIndices.length < 2) return;

      for (int i = 0; i < npcIndices.length; i++) {
        final npcIndexA = npcIndices[i];
        final npcA = _npcs[npcIndexA];

        for (int j = i + 1; j < npcIndices.length; j++) {
          final npcIndexB = npcIndices[j];
          final npcB = _npcs[npcIndexB];

          // Link relationships A -> B and B -> A
          final relsA = Map<String, Relationship>.from(npcA.relationships);
          final relsB = Map<String, Relationship>.from(npcB.relationships);

          final oldRelAB = relsA[npcB.id] ?? Relationship();
          final oldRelBA = relsB[npcA.id] ?? Relationship();

          relsA[npcB.id] = oldRelAB.evolve(
            isKind: isKind,
            isStern: isStern,
            satisfaction: npcA.satisfaction,
          );
          relsB[npcA.id] = oldRelBA.evolve(
            isKind: isKind,
            isStern: isStern,
            satisfaction: npcB.satisfaction,
          );

          _npcs[npcIndexA] = npcA.copyWith(relationships: relsA);
          _npcs[npcIndexB] = npcB.copyWith(relationships: relsB);

          // Random Interaction (10% chance)
          if (Random().nextDouble() < 0.10) {
            final avgSat = (npcA.satisfaction + npcB.satisfaction) / 2.0;
            if (avgSat > 50) {
              _npcs[npcIndexA] = _npcs[npcIndexA].copyWith(
                currentThought: "Having a pleasant exchange with ${npcB.name}.",
                satisfaction: (npcA.satisfaction + 2).clamp(0, 100),
              );
            } else {
              _npcs[npcIndexA] = _npcs[npcIndexA].copyWith(
                currentThought: "Tense disagreement with ${npcB.name}...",
                satisfaction: (npcA.satisfaction - 5).clamp(0, 100),
              );
            }
          }
        }
      }
    });

    // Butler influence on overall satisfaction
    if (isKind) {
      for (int i = 0; i < _npcs.length; i++) {
        _npcs[i] = _npcs[i].copyWith(
          satisfaction: (_npcs[i].satisfaction + 1).clamp(0, 100),
        );
      }
    } else if (isStern) {
      for (int i = 0; i < _npcs.length; i++) {
        _npcs[i] = _npcs[i].copyWith(
          satisfaction: (_npcs[i].satisfaction - 1).clamp(0, 100),
        );
      }
    }
  }

  void _triggerBowelMovementIncident(int npcIndex) {
    var npc = _npcs[npcIndex];
    final roomId = npc.currentRoomId;
    if (roomId == null) return;

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      var room = _rooms[roomIndex];
      _rooms[roomIndex] = room.copyWith(isRestored: false, dirtiness: 1.0);

      _lastAnnouncement =
          "URGENT: ${npc.name} has suffered an unplanned bowel movement incident in ${room.name}!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] INCIDENT: UBMI in ${room.name}.",
      );

      // Character mood drop
      _npcs[npcIndex] = npc.copyWith(
        status: NPCStatus.idle,
        activeTaskId: null,
        satisfaction: (npc.satisfaction - 40).clamp(0, 100),
        digestion: 0.0,
        breakingPointMinutes: 0,
        currentThought: "I am utterly humiliated...",
      );

      // Social effects for others in the room
      for (int j = 0; j < _npcs.length; j++) {
        if (j == npcIndex) continue;
        if (_npcs[j].currentRoomId == roomId) {
          // Rel penalties
          final other = _npcs[j];
          final rels = Map<String, Relationship>.from(other.relationships);
          final oldRel = rels[npc.id] ?? Relationship();
          rels[npc.id] = oldRel.copyWith(
            attraction: (oldRel.attraction - 1.0).clamp(0, 5),
            admiration: (oldRel.admiration - 0.5).clamp(0, 5),
            respect: (oldRel.respect - 0.5).clamp(0, 5),
          );
          _npcs[j] = other.copyWith(
            relationships: rels,
            satisfaction: (other.satisfaction - 10).clamp(0, 100),
            currentThought: "That is absolutely disgusting, ${npc.name}.",
          );
        }
      }
      notifyListeners();
    }
  }

  // Scheduled activities are now managed by Intent Queue

  void _processNpcMovement(int index) {
    var npc = _npcs[index];

    // If we have a path but no current target, set the next target from path
    if (npc.targetRoomId == null && npc.movementPath.isNotEmpty) {
      final List<String> newPath = List.from(npc.movementPath);
      final String nextTarget = newPath.removeAt(0);
      _npcs[index] = npc.copyWith(
        targetRoomId: nextTarget,
        movementPath: newPath,
        movementProgress: 0.0,
      );
      return;
    }

    if (npc.targetRoomId == null || npc.currentRoomId == npc.targetRoomId) {
      _npcs[index] = npc.copyWith(movementProgress: 1.0, clearTarget: true);
      return;
    }

    // walkSpeed is now percentage points per minute (e.g. 15 = 0.15 per minute)
    final double walkSpeed = (npc.stats['walkSpeed'] ?? 10).toDouble();
    final double speedPerMinute = walkSpeed / 100.0;

    double newProgress = npc.movementProgress + speedPerMinute;

    if (newProgress >= 1.0) {
      _npcs[index] = npc.copyWith(
        currentRoomId: npc.targetRoomId,
        clearTarget: true,
        movementProgress: 1.0,
      );
      // After arriving, if there's more path, it will be picked up next tick (or we could chain it here)
    } else {
      _npcs[index] = npc.copyWith(movementProgress: newProgress);
    }
  }

  static const Map<String, List<String>> _roomConnections = {
    // Floor 0: Entryway Hub
    'entryway': [
      'kitchen',
      'dining_hall',
      'bathroom_down',
      'butler_quarters',
      'unused_1f',
      'road',
      'study', // Stairs down to Entryway
      'bathroom_up', // Stairs down to Entryway
    ],
    // Floor 1 Sequential: Master <-> Bed 2 <-> Bed 3 <-> Bath Up <-> Study <-> Library
    'master_bedroom': [
      'bedroom_2',
      'attic_1',
    ], // Stairs to Attic from point between Master/Guest A
    'bedroom_2': ['master_bedroom', 'bedroom_3', 'attic_1'],
    'bedroom_3': ['bedroom_2', 'bathroom_up'],
    'bathroom_up': ['bedroom_3', 'study', 'entryway'],
    'study': ['bathroom_up', 'library', 'entryway'],
    'library': ['study'],

    // Attic Hub: center point connects to both slots
    'attic_1': ['attic_2', 'master_bedroom', 'bedroom_2'],
    'attic_2': ['attic_1', 'master_bedroom', 'bedroom_2'],

    // Basement: Access via Unused Wing to Basement 2
    'unused_1f': ['entryway', 'basement_2'],
    'basement_2': ['basement_1', 'basement_3', 'unused_1f'],
    'basement_1': ['basement_2'],
    'basement_3': ['basement_2'],

    // Exterior Hub
    'road': [
      'entryway',
      'vegetable_garden',
      'field_2',
      'field_3',
      'field_4',
      'chicken_coop',
      'toolshed',
      'lot_garden',
      'lot_building_1',
    ],
  };

  List<String> _findPath(String startId, String endId) {
    if (startId == endId) return [];

    // Simple BFS for shortest path in unweighted graph
    final Map<String, String?> parent = {startId: null};
    final List<String> queue = [startId];
    final Set<String> visited = {startId};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (current == endId) break;

      // Get neighbors from _roomConnections
      // Hubs are direct, but rooms only connect to their hubs
      List<String> neighbors = [];
      if (_roomConnections.containsKey(current)) {
        neighbors = _roomConnections[current]!;
      } else {
        // If it's a room, find which hub it belongs to
        _roomConnections.forEach((hub, members) {
          if (members.contains(current)) {
            neighbors.add(hub);
          }
        });
      }

      for (var neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          parent[neighbor] = current;
          queue.add(neighbor);
        }
      }
    }

    if (!parent.containsKey(endId)) return [endId]; // Fallback to direct

    final List<String> path = [];
    String? curr = endId;
    while (curr != null && curr != startId) {
      path.insert(0, curr);
      curr = parent[curr];
    }
    return path;
  }

  void assignTask(GameTask task) {
    // 1. Add to Room Queue if it's a room-based task
    if (task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        final List<String> newQueue = List.from(room.taskQueue);
        newQueue.add(task.id);

        // If no one is occupying and no project is at the workstation, this NPC takes it
        String? newOccupancy = room.occupyingNpcId;
        final Map<String, PhysicalProject> newProjects = Map.from(
          room.activeProjects,
        );

        final projectType = Room.getProjectType(task.type);
        newProjects[task.id] = PhysicalProject(
          id: task.id,
          taskId: task.id,
          name: task.type.displayName,
          type: projectType,
          progress: 0.0,
          isAtWorkstation: room.occupyingNpcId == null,
        );

        if (room.occupyingNpcId == null) {
          newOccupancy = task.npcId;
        }

        _rooms[roomIndex] = room.copyWith(
          taskQueue: newQueue,
          occupyingNpcId: newOccupancy,
          activeProjects: newProjects,
        );

        // Also add to global task service for tracking
        _taskService.addTask(task);
      }
    } else {
      _taskService.addTask(task);
    }

    // 2. Update NPC status and move them to target room
    final index = _npcs.indexWhere((n) => n.id == task.npcId);
    if (index != -1) {
      var npc = _npcs[index];

      final intent = NPCIntent(
        id: task.id,
        priority: IntentPriority.assignment,
        action: task.type,
        targetRoomId: task.targetId,
        recipeId: task.recipeId,
        targetName: task.targetName,
        minutesRemaining: task.minutesRemaining,
        expectedDurationMin: task.minutesRemaining,
      );

      _npcs[index] = npc.copyWith(
        intentQueue: [...npc.intentQueue, intent],
      );
      _lastAnnouncement = "Task for ${npc.name} added to assignment queue.";
    }
    notifyListeners();
  }

  void moveProjectFromWorkstation(String roomId, String taskId) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final room = _rooms[roomIndex];
    if (room.activeProjects.containsKey(taskId)) {
      final Map<String, PhysicalProject> nextProjects = Map.from(
        room.activeProjects,
      );
      nextProjects[taskId] = nextProjects[taskId]!.copyWith(
        isAtWorkstation: false,
      );

      String? nextOccupancy = room.occupyingNpcId;
      // If the NPC owning this project was occupying the room, clear it
      // Find NPC owning this taskId
      try {
        final task = _taskService.activeTasks.firstWhere((t) => t.id == taskId);
        if (room.occupyingNpcId == task.npcId) {
          nextOccupancy = null;
        }
      } catch (e) {
        // Task maybe gone, still clear occupancy if it was the last thing there
        nextOccupancy = null;
      }

      _rooms[roomIndex] = room.copyWith(
        activeProjects: nextProjects,
        occupyingNpcId: nextOccupancy,
        clearOccupancy: nextOccupancy == null,
      );
      notifyListeners();
    }
  }

  void clearRoomOccupancy(String roomId) {
    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex != -1) {
      _rooms[roomIndex] = _rooms[roomIndex].copyWith(clearOccupancy: true);
      notifyListeners();
    }
  }

  void _handleTaskCompletion(GameTask task) {
    final npcIndex = _npcs.indexWhere((n) => n.id == task.npcId);
    if (npcIndex == -1) return;

    final room = task.targetId != null
        ? _rooms.firstWhereOrNull((r) => r.id == task.targetId)
        : null;

    var worker = _npcs[npcIndex];

    // Clear room occupancy if this was a room task
    if (task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final room = _rooms[roomIndex];
        final List<String> newQueue = List.from(room.taskQueue);
        newQueue.remove(task.id);

        final Map<String, PhysicalProject> newProjects = Map.from(
          room.activeProjects,
        );
        newProjects.remove(task.id);

        _rooms[roomIndex] = room.copyWith(
          taskQueue: newQueue,
          clearOccupancy: room.occupyingNpcId == task.npcId,
          activeProjects: newProjects,
        );
      }
    }
    TaskResult result = TaskResultGenerator.generate(
      task.type,
      room?.name,
      worker,
      recipeId: task.recipeId,
      targetId: task.targetId,
    );

    if (result.quality > 1.5) {
      triggerJoy(worker.id, task.type.name);
      // Re-fetch worker to include new status effect if we use it later
      worker = _npcs[npcIndex];
    }

    _completedTaskTypes.add(task.type);

    // Process Loot (apply penalties if worker is unsuitable)
    double yieldMultiplier = 1.0;
    if (worker.role == 'Scientist' &&
        (task.type == TaskType.cleanRoom ||
            task.type == TaskType.collectEggs ||
            task.type == TaskType.harvestCabbage)) {
      yieldMultiplier = 0.5; // Master is bad at chores
    } else if (worker.role == 'Butler' &&
        (task.type == TaskType.research || task.type == TaskType.dissect)) {
      yieldMultiplier = 0.5; // Butler is bad at science
      // Waste resources
      _resources['funds'] = (_resources['funds'] ?? 0) - 5;
      _lastAnnouncement =
          "${worker.name} wasted materials while attempting ${task.type.name}!";
    }

    if (task.type == TaskType.collectEggs) {
      if (_uncollectedEggs > 0) {
        _resources['eggs'] = (_resources['eggs'] ?? 0) + _uncollectedEggs;
        _lastAnnouncement =
            "${worker.name} collected $_uncollectedEggs eggs from the coop.";
        _uncollectedEggs = 0;
      } else {
        _lastAnnouncement = "${worker.name} found no eggs in the coop today.";
      }
    } else if (task.type == TaskType.harvestCabbage ||
        task.type == TaskType.harvestCrops) {
      final ready = _crops
          .where(
            (c) =>
                (c.type == CropType.cabbage ||
                    c.type == CropType.carrot ||
                    c.type == CropType.potato ||
                    c.type == CropType.grain) &&
                c.isHarvestable,
          )
          .toList();
      if (ready.isNotEmpty) {
        int total = 0;
        for (var crop in ready) {
          final int y = crop.yield.toInt();
          total = total + y;
          _crops.removeWhere((c) => c.id == crop.id);
          // Gained specific crop type
          String resId = crop.type.name;
          _resources[resId] = (_resources[resId] ?? 0) + y;
        }
        _lastAnnouncement =
            "${worker.name} harvested crops from the garden.";
      } else {
        _lastAnnouncement =
            "${worker.name} found no crops ready for harvest.";
      }
    } else if (task.type == TaskType.butcherAnimals) {
      if (task.targetId == 'rat_specimen' || task.targetId == 'bat_specimen') {
        _resources[task.targetId!] = (_resources[task.targetId!] ?? 0) - 1;
        _lastAnnouncement = "${worker.name} butchered a ${task.targetId == 'rat_specimen' ? 'rat' : 'bat'}.";
      } else if (task.targetId != null) {
        // Remove from inventory if it's an item
        final itemIndex = _inventory.indexWhere((i) => i.id == task.targetId);
        if (itemIndex != -1) {
          final itemName = _inventory[itemIndex].name;
          _inventory.removeAt(itemIndex);
          _lastAnnouncement = "${worker.name} has finished butchering $itemName.";
        }

        _chickens.removeWhere((c) => c.id == task.targetId);
        _npcs.removeWhere((n) => n.id == task.targetId && !n.isPlayer);
        _lastAnnouncement = "${worker.name} has finished the butchery.";
      }
    } else if (task.type == TaskType.tillSoil) {
      if (task.targetId != null) tillSoil(task.targetId!);
    } else if (task.type == TaskType.plantCrops) {
      CropType type = CropType.cabbage;
      if (task.recipeId != null) {
        try {
          type = CropType.values.firstWhere((e) => e.name == task.recipeId);
        } catch (_) {}
      }
      plantCrops(type, task.targetId ?? 'vegetable_garden');
    } else if (task.type == TaskType.waterCrops) {
      if (task.targetId != null) waterCrops(task.targetId!);
    } else if (task.type == TaskType.fertilizeSoil) {
      if (task.targetId != null) fertilizeSoil(task.targetId!);
    } else if (task.type == TaskType.careForCrops) {
      if (task.targetId != null) careForCrops(task.targetId!);
    } else if (task.type == TaskType.extinguishFire ||
        task.type == TaskType.recombineSpecimen ||
        task.type == TaskType.defendManor) {
      final crisisIndex = _crises.indexWhere(
        (c) =>
            c.roomId == task.targetId &&
            ((c.type == ManorCrisisType.fire &&
                    task.type == TaskType.extinguishFire) ||
                (c.type == ManorCrisisType.specimenEscape &&
                    task.type == TaskType.recombineSpecimen) ||
                (c.type == ManorCrisisType.intruder &&
                    task.type == TaskType.defendManor)),
      );

      if (crisisIndex != -1) {
        var crisis = _crises[crisisIndex];
        // Reduction based on worker stats (e.g. Endurance for fire, Strength for defense)
        double reduction = 0.3; // Base 30% reduction per task
        if (task.type == TaskType.defendManor) {
          reduction += (worker.stats['strength'] ?? 50) / 500.0; // Up to +0.2
        } else if (task.type == TaskType.extinguishFire) {
          reduction += (worker.stats['endurance'] ?? 50) / 500.0;
        }

        crisis = crisis.copyWith(
          severity: (crisis.severity - reduction).clamp(0.0, 1.0),
        );

        if (crisis.severity <= 0) {
          _crises.removeAt(crisisIndex);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] SUCCESS: The ${crisis.name} in the ${room?.name} has been resolved!",
          );
          // Return NPC to normal status if no more crises discovered
          bool stillPanicked = _crises.any(
            (c) =>
                c.isDiscovered &&
                _npcs.any(
                  (n) => n.id == worker.id && n.currentRoomId == c.roomId,
                ),
          );
          if (!stillPanicked) {
            _npcs[npcIndex] = worker.copyWith(status: NPCStatus.idle);
          }
        } else {
          _crises[crisisIndex] = crisis;
          _lastAnnouncement =
              "${worker.name} is making progress against the ${crisis.name}.";
        }
      }

      // Check if we need to clear an intent (Unified Queue)
      final updatedWorker = _npcs[npcIndex];
      final List<NPCIntent> newQueue = List.from(updatedWorker.intentQueue);
      newQueue.removeWhere((intent) => intent.id == task.id);

      _npcs[npcIndex] = updatedWorker.copyWith(
        status: NPCStatus.idle,
        activeTaskId: null,
        intentQueue: newQueue,
      );
      _taskService.removeTask(task.id);
      notifyListeners();
    }

    // 2. Process Items Found
    for (var item in result.itemsFound) {
      _inventory.add(item);
    }

    // 3. Process Resources Gained (Loot)
    for (var entry in result.resourcesGained.entries) {
      final key = entry.key;
      final value = entry.value;
      _resources[key] =
          (_resources[key] ?? 0) + (value * yieldMultiplier);
    }

    // 4. Process Specialized Task Types
    if (task.type == TaskType.collectIngredients) {
      if (task.recipeId != null) {
        final activity = ScienceService.getActivityById(task.recipeId!);
        if (activity != null) {
          final missing = _getMissingIngredientsForActivity(npcIndex, activity);
          final List<GameItem> workerInv = List<GameItem>.from(
            worker.inventory,
          );

          for (var entry in missing.entries) {
            String key = entry.key;
            int stillNeeded = entry.value;

            // 1. Take from global inventory
            for (
              int i = _inventory.length - 1;
              i >= 0 && stillNeeded > 0;
              i--
            ) {
              final item = _inventory[i];
              bool matches = false;
              if (key == 'meat') {
                matches =
                    item.type.contains('meat') ||
                    item.category == ItemCategory.specimen;
              } else if (key == 'specimen' || key == 'rat_specimen') {
                matches =
                    item.category == ItemCategory.specimen ||
                    item.type == 'rat_specimen';
              } else {
                matches = item.type == key;
              }

              if (matches) {
                int toTake = min(item.quantity, stillNeeded);
                workerInv.add(
                  item.copyWith(quantity: toTake, id: const Uuid().v4()),
                );
                if (item.quantity > toTake) {
                  _inventory[i] = item.copyWith(
                    quantity: item.quantity - toTake,
                  );
                } else {
                  _inventory.removeAt(i);
                }
                stillNeeded -= toTake;
              }
            }

            // 2. Take from resources
            if (stillNeeded > 0 && (_resources[key] ?? 0) > 0) {
              int toTake = min((_resources[key] ?? 0).toInt(), stillNeeded);
              _resources[key] = (_resources[key] ?? 0) - toTake;
              workerInv.add(
                GameItem.create(
                  name: key.toUpperCase(),
                  type: key,
                  category: ItemCategory.resource,
                  quantity: toTake,
                ),
              );
              stillNeeded -= toTake;
            }
          }
          _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);
          _lastAnnouncement =
              "${worker.name} collected materials for ${activity.name}.";
        }
      } else if (room != null) {
        final List<GameItem> roomInv = List<GameItem>.from(
          _rooms[_rooms.indexOf(room)].inventory,
        );
        final List<GameItem> workerInv = List<GameItem>.from(
          _npcs[npcIndex].inventory,
        );
        workerInv.addAll(roomInv);
        _rooms[_rooms.indexOf(room)] = room.copyWith(inventory: []);
        _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);
        _lastAnnouncement =
            "${worker.name} collected supplies from ${room.name}.";
      }
    } else if (task.type == TaskType.cook) {
      final recipes = KitchenService.getAvailableRecipes();
      final recipe = task.recipeId != null
          ? recipes.firstWhere(
              (r) => r.id == task.recipeId,
              orElse: () => recipes.first,
            )
          : recipes.first;

      bool hasAll = true;
      final kitchenIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      final List<GameItem> kitchenInv = kitchenIndex != -1
          ? List<GameItem>.from(_rooms[kitchenIndex].inventory)
          : [];
      final List<GameItem> workerInv = List<GameItem>.from(
        _npcs[npcIndex].inventory,
      );

      for (var ingEntry in recipe.ingredients.entries) {
        final ing = ingEntry.key;
        final count = ingEntry.value;

        int availableInRoom = 0;
        int availableInWorker = 0;
        int availableInResources = (_resources[ing] ?? 0).toInt();

        if (ing == 'meat') {
          // Special case for generic meat
          availableInRoom = kitchenInv
              .where(
                (i) =>
                    i.type.contains('meat') ||
                    i.category == ItemCategory.specimen,
              )
              .fold(0, (sum, i) => sum + i.quantity);
          availableInWorker = workerInv
              .where(
                (i) =>
                    i.type.contains('meat') ||
                    i.category == ItemCategory.specimen,
              )
              .fold(0, (sum, i) => sum + i.quantity);
          // Generic meat resource is already included in availableInResources
        } else {
          availableInRoom = kitchenInv
              .where((i) => i.type == ing)
              .fold(0, (sum, i) => sum + i.quantity);
          availableInWorker = workerInv
              .where((i) => i.type == ing)
              .fold(0, (sum, i) => sum + i.quantity);
        }

        if (availableInRoom + availableInWorker + (availableInResources).toInt() <
            count) {
          hasAll = false;
        }
      }

      if (hasAll) {
        for (var ingEntry in recipe.ingredients.entries) {
          final ing = ingEntry.key;
          final count = ingEntry.value;
          int remainingToDeduct = count;

          while (remainingToDeduct > 0) {
            final itemIndex = kitchenInv.indexWhere((i) {
              if (ing == 'meat') {
                return i.type.contains('meat') ||
                    i.category == ItemCategory.specimen;
              }
              return i.type == ing;
            });
            if (itemIndex == -1) break;
            final item = kitchenInv[itemIndex];
            final taken = min(item.quantity, remainingToDeduct);
            if (item.quantity > taken) {
              kitchenInv[itemIndex] = item.copyWith(
                quantity: item.quantity - taken,
              );
            } else {
              kitchenInv.removeAt(itemIndex);
            }
            remainingToDeduct -= taken;
          }

          while (remainingToDeduct > 0) {
            final itemIndex = workerInv.indexWhere((i) {
              if (ing == 'meat') {
                return i.type.contains('meat') ||
                    i.category == ItemCategory.specimen;
              }
              return i.type == ing;
            });
            if (itemIndex == -1) break;
            final item = workerInv[itemIndex];
            final taken = min(item.quantity, remainingToDeduct);
            if (item.quantity > taken) {
              workerInv[itemIndex] = item.copyWith(
                quantity: item.quantity - taken,
              );
            } else {
              workerInv.removeAt(itemIndex);
            }
            remainingToDeduct -= taken;
          }
          if (remainingToDeduct > 0) {
            _resources[ing] = (_resources[ing] ?? 0) - remainingToDeduct;
          }
        }

        if (kitchenIndex != -1) {
          _rooms[kitchenIndex] = _rooms[kitchenIndex].copyWith(
            inventory: kitchenInv,
          );
        }
        _npcs[npcIndex] = _npcs[npcIndex].copyWith(inventory: workerInv);

        final latestWorker = _npcs[npcIndex];
        final knife = latestWorker.chefStats.knifeSkills;
        final sanitation = latestWorker.chefStats.sanitation;
        final nose = latestWorker.chefStats.nose;
        final fire = latestWorker.chefStats.fireSkills;
        final exp = latestWorker.dishExperience[recipe.id] ?? 0.0;

        double quality = recipe.baseQuality;
        quality += (nose / 100.0) * 0.5;
        quality += exp * 0.2;

        final rand = Random();
        if (rand.nextInt(100) > (40 + knife)) {
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${latestWorker.name} cut themselves while prepping!",
          );
          _npcs[npcIndex] = _npcs[npcIndex].copyWith(
            satisfaction: (_npcs[npcIndex].satisfaction - 10).clamp(0, 100),
          );
        }

        double yieldLoss = 0.0;
        if (rand.nextInt(100) > (30 + fire + (nose / 2))) {
          yieldLoss = 0.2 + (rand.nextDouble() * 0.3);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${latestWorker.name} scorched the ${recipe.id}!",
          );
        }

        final kitchen = _rooms.firstWhere((r) => r.id == 'kitchen');
        double healthRisk =
            (1.0 -
                    (sanitation / 100.0) -
                    (nose / 200.0) +
                    (kitchen.dirtiness * 0.5))
                .clamp(0.0, 1.0);

        _rooms[_rooms.indexOf(kitchen)] = kitchen.copyWith(
          dirtiness: (kitchen.dirtiness + 0.1).clamp(0.0, 1.0),
        );

        int finalYield = (recipe.yield * (1.0 - yieldLoss)).round().clamp(
          1,
          100,
        );

        for (int i = 0; i < finalYield; i++) {
          _pantry.add(
            Dish(
              id: const Uuid().v4(),
              name: recipe.name,
              type: _mapToDishType(recipe.id),
              quality: _mapToDishQuality(quality),
              cookedAt: DateTime.now(),
              illnessRisk: healthRisk,
            ),
          );
        }

        Map<String, double> newExp = Map.from(_npcs[npcIndex].dishExperience);
        newExp[recipe.id] = (exp + 0.05).clamp(0.0, 1.0);
        _npcs[npcIndex] = _npcs[npcIndex].copyWith(dishExperience: newExp);

        if (_cookingQueue.isNotEmpty && _cookingQueue.first == recipe.id) {
          _cookingQueue.removeAt(0);
        }
      } else {
        final recipeName = recipe.name;
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} failed to cook $recipeName: Insufficient ingredients.",
        );
      }
    } else if (task.type == TaskType.research ||
        task.type == TaskType.dissect ||
        task.type == TaskType.vivisection ||
        task.type == TaskType.puzzleStudy ||
        task.type == TaskType.deprivationStudy ||
        task.type == TaskType.clinicalTrial ||
        task.type == TaskType.refineFood) {
      if (task.type == TaskType.refineFood && task.recipeId != null) {
        cookRecipe(task.recipeId!, task.npcId, isPrepared: true);
      } else {
        _handleScienceTaskCompletion(npcIndex, task);
      }
    } else if (task.type == TaskType.archiveResearch ||
        task.type == TaskType.transcribeNotes) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        int processedCount = 0;
        final bool isTranscribe = task.type == TaskType.transcribeNotes;

        if (isTranscribe) {
          // TRANSCRIBE: Refine notes -> studies (Quality focus)
          // Process worker inventory
          final List<GameItem> workerInv = List.from(worker.inventory);
          for (int i = 0; i < workerInv.length; i++) {
            if (workerInv[i].type == 'research_notes') {
              workerInv[i] = workerInv[i].copyWith(
                name: workerInv[i].name.replaceFirst('Notes', 'Study'),
                type: 'research_study',
                quality: (workerInv[i].quality + 0.2).clamp(0.0, 2.0),
              );
              processedCount++;
            }
          }
          worker = worker.copyWith(inventory: workerInv);

          // Process room inventory
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
          for (int i = 0; i < roomInv.length; i++) {
            if (roomInv[i].type == 'research_notes') {
              roomInv[i] = roomInv[i].copyWith(
                name: roomInv[i].name.replaceFirst('Notes', 'Study'),
                type: 'research_study',
                quality: (roomInv[i].quality + 0.2).clamp(0.0, 2.0),
              );
              processedCount++;
            }
          }
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);

          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} refined $processedCount research notes into structured studies.",
          );
        } else {
          // ARCHIVE: Organise items into room (Efficiency focus)
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);

          // From worker
          final List<GameItem> workerInv = List.from(worker.inventory);
          for (int i = workerInv.length - 1; i >= 0; i--) {
            if (workerInv[i].category == ItemCategory.knowledge) {
              roomInv.add(workerInv.removeAt(i));
              processedCount++;
            }
          }
          worker = worker.copyWith(inventory: workerInv);

          // From global
          if (task.targetId == 'library' || task.targetId == 'study') {
            for (int i = _inventory.length - 1; i >= 0; i--) {
              if (_inventory[i].category == ItemCategory.knowledge) {
                roomInv.add(_inventory.removeAt(i));
                processedCount++;
              }
            }
          }
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);

          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} organized $processedCount items into the ${_rooms[roomIndex].name} archive.",
          );
        }
        _npcs[npcIndex] = worker;
      }
    }

    if (task.type == TaskType.greetGuest) {
      _lastAnnouncement = "${worker.name} greeted the guest at the door.";
    } else if (task.type == TaskType.trainCreature) {
      // Find the entity being trained (assuming it's in the room or targetId)
      final targetNpcIndex = _npcs.indexWhere((n) => n.id == task.targetId);
      if (targetNpcIndex != -1) {
        _npcs[targetNpcIndex] = _npcs[targetNpcIndex].copyWith(isTrained: true);
        _lastAnnouncement =
            "${worker.name} has finished training ${_npcs[targetNpcIndex].name} for combat.";
      }
    } else if (task.type == TaskType.surgicalCombination) {
      _handleSurgicalCombination(npcIndex, task);
    }

    // Character status synchronization
    var currentNpc = _npcs[npcIndex];
    List<NPCIntent> newQueue = List.from(currentNpc.intentQueue);
    newQueue.removeWhere((i) => i.id == task.id);

    // Points logic
    final hour = _currentDate.hour;
    final preferredRoom = currentNpc.schedule.getPreferredRoomForHour(hour);

    double newSatisfaction = currentNpc.satisfaction;
    double newDigestion = currentNpc.digestion;
    double newHygiene = currentNpc.hygiene;
    int newBreakingPointMinutes = currentNpc.breakingPointMinutes;
    String? newThought = currentNpc.currentThought;

    if (task.type == TaskType.eat) {
      // 1. Try to find a dish in the pantry
      int? bestDishIndex;
      final neededTypes = currentNpc.diet.dailyRequirements.keys.toList();
      for (int j = 0; j < _pantry.length; j++) {
        final dish = _pantry[j];
        if (neededTypes.contains(dish.type)) {
          if (bestDishIndex == null ||
              _pantry[bestDishIndex].quality.index > dish.quality.index) {
            bestDishIndex = j;
          }
        }
      }

      String mealSource = "supplies";
      String mealName = "a simple meal";

      if (bestDishIndex != null) {
        final dish = _pantry.removeAt(bestDishIndex);
        mealSource = "the pantry";
        mealName = dish.name;
        newSatisfaction = (newSatisfaction + 15.0).clamp(0.0, 100.0);
      } else if ((_resources['meals'] ?? 0) > 0) {
        _resources['meals'] = _resources['meals']! - 1;
        newSatisfaction = (newSatisfaction + 5.0).clamp(0.0, 100.0);
      } else if ((_resources['meat'] ?? 0) > 0 ||
          (_resources['cabbage'] ?? 0) > 0) {
        if ((_resources['meat'] ?? 0) > 0) {
          _resources['meat'] = _resources['meat']! - 1;
        } else {
          _resources['cabbage'] = _resources['cabbage']! - 1;
        }
        mealSource = "raw ingredients";
        mealName = "scavenged food";
        newSatisfaction = (newSatisfaction - 5.0).clamp(0.0, 100.0);
      }

      _resources['dirty_dishes'] = (_resources['dirty_dishes'] ?? 0) + 1;
      _lastAnnouncement =
          "${currentNpc.name} consumed $mealName from $mealSource.";

      if (currentNpc.isResident) {
        newQueue.insert(
          0,
          NPCIntent(
            id: 'cleanish_${currentNpc.id}_${DateTime.now().millisecondsSinceEpoch}',
            priority: IntentPriority.normal,
            action: TaskType.cleanDish,
            targetRoomId: 'butler_quarters',
            expectedDurationMin: 15,
          ),
        );
      }
    }

    if (task.type == TaskType.wash) {
      newHygiene = 100.0;
      newThought = "Clean and refreshed.";
      _lastAnnouncement = "${currentNpc.name} has finished washing up.";
    }


    if (task.type == TaskType.useToilet) {
      newDigestion = 0.0;
      newBreakingPointMinutes = 0;
      newThought = "Much better.";
    }

    if (currentNpc.role == 'Scientist' &&
        (task.type == TaskType.cleanRoom ||
            task.type == TaskType.collectEggs ||
            task.type == TaskType.harvestCabbage)) {
      newSatisfaction -= 15.0;
    }

    _npcs[npcIndex] = currentNpc.copyWith(
      status: NPCStatus.idle,
      activeTaskId: null,
      targetRoomId: preferredRoom,
      clearTarget: preferredRoom == null,
      movementProgress:
          (preferredRoom == currentNpc.currentRoomId || preferredRoom == null)
              ? 1.0
              : 0.0,
      satisfaction: newSatisfaction.clamp(0.0, 100.0),
      digestion: newDigestion,
      hygiene: newHygiene,
      breakingPointMinutes: newBreakingPointMinutes,
      currentThought: newThought,
      currentStateTicks: 0, // Reset ticks on task completion
      intentQueue: newQueue,
    );

    if (task.type == TaskType.useToilet && task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final r = _rooms[roomIndex];
        _rooms[roomIndex] = r.copyWith(
          dirtiness: (r.dirtiness + 0.15).clamp(0.0, 1.0),
        );
      }
    }

    _inventory.addAll(result.itemsFound);
    _lastAnnouncement = result.message;
    _announcementHistory.insert(
      0,
      "[${_currentDate.formattedTime}] ${result.message}",
    );
    if (_announcementHistory.length > 50) _announcementHistory.removeLast();

    // Room Type Conversion for Industrials (Use latest worker state if needed)
    if (task.targetId != null) {
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        Room r = _rooms[roomIndex];
        RoomType? newType;
        String? announcement;

        if (task.type == TaskType.setupBrewery && r.type == RoomType.unused) {
          newType = RoomType.brewery;
          announcement =
              "${worker.name} has finished converting ${r.name} into a Brewery!";
        } else if (task.type == TaskType.setupDistillery &&
            r.type == RoomType.unused) {
          newType = RoomType.distillery;
          announcement =
              "${worker.name} has finished converting ${r.name} into a Distillery!";
        } else if (task.type == TaskType.setupWorkshop &&
            r.type == RoomType.unused) {
          newType = RoomType.workshop;
          announcement =
              "${worker.name} has finished converting ${r.name} into a Carpenter's Workshop!";
        } else if (task.type == TaskType.setupGranary &&
            r.type == RoomType.unused) {
          newType = RoomType.granary;
          announcement =
              "${worker.name} has finished converting ${r.name} into a Granary!";
        }

        if (newType != null) {
          _rooms[roomIndex] = r.copyWith(type: newType, isRestored: true);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] $announcement",
          );
          _checkObjectives();
        } else if (task.type == TaskType.restoreRoom) {
          _rooms[roomIndex] = r.copyWith(isRestored: true);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} finished restoring the ${r.name}.",
          );

          if (r.id == 'chicken_coop') {
            for (int i = 0; i < 3; i++) {
              _chickens.add(
                Chicken.create(ChickenBreedType.houdan, _currentDate, isMale: false),
              );
            }
            _lastAnnouncement =
                "${worker.name} finished restoring the coop, and 3 Houdan chickens have been settled in!";
          }

          // Chance to find creatures
          _checkForCreatures(worker, r);
          _checkObjectives();
        } else if (task.type == TaskType.cleanRoom) {
          _rooms[roomIndex] = r.copyWith(dirtiness: 0.0);
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${worker.name} finished cleaning the ${r.name}.",
          );
          
          // Chance to find creatures
          _checkForCreatures(worker, r);
        }
      }
    }
  }

  void _checkForCreatures(NPC worker, Room r) {
    final random = Random();
    final roll = random.nextDouble();

    // 1. Chance for Specimens (15%)
    if (roll < 0.15) {
      String? creatureId;
      String? creatureName;

      if (r.floor == Floor.basement) {
        creatureId = 'rat_specimen';
        creatureName = 'a scurrying rat';
      } else if (r.floor == Floor.attic || r.floor == Floor.second) {
        creatureId = 'bat_specimen';
        creatureName = 'a leathery bat';
      }

      if (creatureId != null) {
        final isMale = random.nextBool();
        final ageWks = random.nextInt(20) + 1; // 1-20 weeks
        final weightG = random.nextInt(300) + 50; // 50-350g
        
        final displayName = "${creatureId == 'rat_specimen' ? 'Brown Rat' : 'Leathery Bat'} (${isMale ? 'Male' : 'Female'}, $ageWks wks, ${weightG}g)";
        
        _inventory.add(GameItem.create(
          name: displayName,
          type: creatureId,
          category: ItemCategory.specimen,
          metadata: {
            'gender': isMale ? 'Male' : 'Female',
            'ageWeeks': ageWks,
            'weightGrams': weightG,
          },
        ));

        _lastAnnouncement = "${worker.name} discovered $creatureName and captured it!";
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] DISCOVERY: Captured a specimen in the ${r.name}.",
        );
      }
    }

    // 2. Chance for Notes (10%)
    final noteRoll = random.nextDouble();
    if (noteRoll < 0.10) {
      final disciplines = [
        'Anatomy',
        'Zoology',
        'Medicine',
        'Chemistry',
        'Psychology',
      ];
      final discipline = disciplines[random.nextInt(disciplines.length)];

      final note = GameItem.create(
        name: 'Old Notes ($discipline)',
        type: 'research_notes',
        category: ItemCategory.knowledge,
        quantity: 1,
        quality: 0.5 + (random.nextDouble() * 0.5),
        metadata: {
          'discipline': discipline,
          'description':
              'Faded observations found tucked behind a loose floorboard.',
        },
      );

      _inventory.add(note);
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] DISCOVERY: Found discarded research notes on $discipline.",
      );
    }
  }

  double getTaskEfficiency(NPC npc, TaskType type) {
    bool isMaster = npc.role == 'Scientist' || npc.role == 'Master';
    bool isButler = npc.role == 'Butler';

    switch (type) {
      case TaskType.cleanRoom:
      case TaskType.restoreRoom:
      case TaskType.collectEggs:
      case TaskType.harvestCabbage:
        return isMaster ? 0.5 : (isButler ? 1.2 : 1.0);
      case TaskType.research:
      case TaskType.dissect:
      case TaskType.transcribeNotes:
      case TaskType.observeExperiment:
        return isMaster ? 1.5 : (isButler ? 0.6 : 0.8);
      case TaskType.hunt:
        return isButler ? 1.3 : 1.0;
      case TaskType.brew:
      case TaskType.setupBrewery:
        return npc.role == 'Brewer' ? 2.0 : 0.5;
      case TaskType.distill:
      case TaskType.setupDistillery:
        return npc.role == 'Distiller' ? 2.0 : 0.3;
      case TaskType.processTimber:
      case TaskType.setupWorkshop:
        return npc.role == 'Carpenter' ? 2.0 : 0.5;
      case TaskType.harvestGrain:
      case TaskType.setupGranary:
        return npc.role == 'Farmer' ? 1.5 : 0.8;
      default:
        return 1.0;
    }
  }

  int getEstimatedTaskMinutes(NPC npc, TaskType type) {
    int baseMinutes = 4 * 60; // 4 hours base
    if (type == TaskType.cleanRoom) {
      baseMinutes = 20; // 20 minutes for regular cleaning
    }
    final efficiency = getTaskEfficiency(npc, type);
    return (baseMinutes / efficiency).round();
  }

  void assignNpcToTask(
    String npcId,
    TaskType type,
    String? targetId, {
    String? recipeId,
  }) {
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) return;

    final npc = _npcs[npcIndex];
    if (!npc.isResident) {
      _lastAnnouncement =
          "${npc.name} is a visitor and cannot be assigned tasks.";
      notifyListeners();
      return;
    }

    // Avoid redundant task assignment if already working on the same thing or it's already queued
    final isQueueBased = (targetId == 'kitchen' && type == TaskType.cook) ||
        (targetId == 'study' && type == TaskType.research) ||
        (targetId == 'library' &&
            (type == TaskType.archiveResearch ||
                type == TaskType.transcribeNotes));

    if (!isQueueBased) {
      // Check active task
      if (npc.status == NPCStatus.working && npc.activeTaskId != null) {
        try {
          final currentTask = _taskService.activeTasks.firstWhere(
            (t) => t.id == npc.activeTaskId,
          );
          if (currentTask.type == type && currentTask.targetId == targetId) {
            _lastAnnouncement = "${npc.name} is already performing this task.";
            notifyListeners();
            return;
          }
        } catch (e) {}
      }
      // Check intent queue
      if (npc.intentQueue.any((i) => i.action == type && i.targetRoomId == targetId)) {
        _lastAnnouncement = "${npc.name} already has this task in their queue.";
        notifyListeners();
        return;
      }
    }

    // RESOURCE CHECK & DEDUCTION
    final metadata = TaskService.getMetadata(type);
    if (metadata.requirements.isNotEmpty) {
      // Check if we have all resources
      for (var req in metadata.requirements.entries) {
        final has = _resources[req.key] ?? 0;
        if (has < req.value) {
          _lastAnnouncement =
              "Insufficient ${req.key.toUpperCase()} for ${type.displayName}. Need ${req.value}, have $has.";
          notifyListeners();
          return;
        }
      }

      // Deduct resources
      for (var req in metadata.requirements.entries) {
        _resources[req.key] = (_resources[req.key] ?? 0) - req.value;
      }
    }

    // OCCUPANCY CHECK
    if (targetId != null) {
      final room = _rooms.firstWhere((r) => r.id == targetId);
      if (room.occupyingNpcId != null && room.occupyingNpcId != npcId) {
        _lastAnnouncement = "The ${room.name} workstation is currently busy.";
        notifyListeners();
        return;
      }
    }

    // Kitchen Special Logic: Enforce queue-only
    TaskType assignedType = type;
    String? assignedRecipeId = recipeId;
    String? assignedTargetId = targetId;
    String? assignedTargetName;
    int duration = 0;

    if (targetId == 'study') {
      if (type == TaskType.research) {
        if (_researchQueue.isNotEmpty) {
          final qId = _researchQueue.removeAt(0);
          assignedRecipeId = qId;

          if (qId.startsWith('activity:')) {
            final activityId = qId.replaceFirst('activity:', '');
            final activity = ScienceService.getActivityById(activityId);
            if (activity != null) {
              assignedType = activity.type;
              assignedRecipeId = activityId;
              duration = activity.baseDurationMinutes;

              // Consume ingredients immediately on assignment to avoid double-spend
              _consumeScienceIngredients(activity.ingredients);
            }
          } else if (qId.startsWith('recipe:')) {
            final recipe = KitchenService.getAvailableRecipes().firstWhere(
              (r) => r.id == qId.replaceFirst('recipe:', ''),
            );
            assignedType =
                TaskType.refineFood; // Map generic research to specific
            assignedRecipeId = recipe.id;
            duration = recipe.durationMinutes;

            // Consume ingredients
            for (var entry in recipe.ingredients.entries) {
              _resources[entry.key] =
                  (_resources[entry.key] ?? 0) - entry.value;
            }
          } else {
            // Direct item research
            assignedType = TaskType.research;
            assignedRecipeId = qId;
            duration = 60; // Base study time
          }
        } else {
          // No queue! Clean room?
          final room = _rooms.firstWhere((r) => r.id == targetId);
          if (room.dirtiness > 0.1) {
            assignedType = TaskType.cleanRoom;
          } else {
            _lastAnnouncement = "${npc.name} found nothing to research.";
            notifyListeners();
            return;
          }
        }
      }
    } else if (targetId == 'library' &&
        (type == TaskType.archiveResearch ||
            type == TaskType.transcribeNotes)) {
      if (_researchQueue.isNotEmpty) {
        final qId = _researchQueue.removeAt(0);
        assignedRecipeId = qId;

        if (qId == 'library_archive') {
          assignedType = TaskType.archiveResearch;
          duration = 45;
        } else if (qId == 'library_transcribe') {
          assignedType = TaskType.transcribeNotes;
          duration = 60;
        } else {
          // Fallback for other research/items in library queue
          assignedType = TaskType.archiveResearch;
          duration = 30;
        }
      } else {
        // No queue! Clean?
        final room = _rooms.firstWhere((r) => r.id == targetId);
        if (room.dirtiness > 0.1) {
          assignedType = TaskType.cleanRoom;
        } else {
          _lastAnnouncement = "${npc.name} found nothing to archive.";
          notifyListeners();
          return;
        }
      }
    } else if (targetId == 'kitchen') {
      if (type == TaskType.cook) {
        if (_cookingQueue.isNotEmpty) {
          final orderStr = _cookingQueue.first;
          _cookingQueue.removeAt(0);
          
          if (orderStr.startsWith('butcher:')) {
            final parts = orderStr.split(':');
            assignedType = TaskType.butcherAnimals;
            assignedRecipeId = parts[1];
            assignedTargetId = parts[2];
            assignedTargetName = parts[3];
          } else {
            assignedType = TaskType.cook;
            assignedRecipeId = orderStr;
          }
        } else {
          // No queue! Does it need cleaning?
          final kitchen = _rooms.firstWhere((r) => r.id == 'kitchen');
          if (kitchen.dirtiness > 0.1) {
            assignedType = TaskType.cleanRoom;
          } else {
            _lastAnnouncement =
                "${npc.name} found nothing to do in the kitchen.";
            notifyListeners();
            return;
          }
        }
      }
    }

    // Cleaning logic: If room is already restored, it's a hygiene clean (quick)
    if (duration == 0) {
      if (assignedType == TaskType.cleanRoom && targetId != null) {
        final room = _rooms.firstWhere((r) => r.id == targetId);
        if (room.isRestored) {
          // Hygiene clean: 15-20 mins based on speed
          final speed = npc.stats['walkSpeed'] ?? 25;
          duration = (20 * (25 / speed)).round().clamp(10, 45);
        } else {
          duration = getEstimatedTaskMinutes(npc, assignedType);
        }
      } else {
        duration = getEstimatedTaskMinutes(npc, assignedType);
      }
    }

    // Agricultural reduction: half labor if partial field
    if ((assignedType == TaskType.plantCrops ||
            assignedType == TaskType.harvestCrops) &&
        assignedTargetId != null) {
      final room = _rooms.firstWhere((r) => r.id == assignedTargetId);
      if (room.tilledAmount < 1.0) {
        duration = (duration * 0.5).round();
      }
    }

    final intentId = DateTime.now().millisecondsSinceEpoch.toString();
    final task = GameTask(
      id: intentId,
      npcId: npc.id,
      type: assignedType,
      targetId: assignedTargetId,
      targetName: assignedTargetName,
      recipeId: assignedRecipeId,
      minutesRemaining: duration,
    );

    // Use assignTask to handle queuing correctly
    assignTask(task);
  }

  void assignTaskByRole(String role, TaskType type, String? targetId) {
    try {
      final npcId = _npcs.firstWhere((n) => n.role == role).id;
      assignNpcToTask(npcId, type, targetId);
    } catch (e) {
      _lastAnnouncement = "No one with the role of $role is available.";
      notifyListeners();
    }
  }

  void assignButlerTask(TaskType type, String? targetId) {
    assignTaskByRole('Butler', type, targetId);
  }

  List<NPC>? _simulationPlayerDeck;
  List<NPC>? _simulationAiDeck;

  void startCombatSimulation(List<NPC> playerDeck, List<NPC> aiDeck) {
    _simulationPlayerDeck = playerDeck;
    _simulationAiDeck = aiDeck;
    notifyListeners();
  }

  List<NPC>? get simulationPlayerDeck => _simulationPlayerDeck;
  List<NPC>? get simulationAiDeck => _simulationAiDeck;

  void clearSimulation() {
    _simulationPlayerDeck = null;
    _simulationAiDeck = null;
    notifyListeners();
  }

  void startJourney(
    String npcId,
    String destinationId,
    Map<String, int> resources,
    List<String> escortIds,
  ) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    var npc = _npcs[index];

    // Deduct from manor, add to NPC
    for (var entry in resources.entries) {
      if ((_resources[entry.key] ?? 0) >= entry.value) {
        _resources[entry.key] = _resources[entry.key]! - entry.value;
      }
    }

    _npcs[index] = npc.copyWith(
      worldDestinationId: destinationId,
      worldDepartureId: 'manor',
      worldTravelProgress: 0.0,
      journeyInventory: Map<String, int>.from(resources),
      escortIds: escortIds,
      lastEscortIds: escortIds, // Persist for next time
      status: NPCStatus.idle,
      activeTaskId: null,
      targetRoomId: 'road',
      isResident: false,
    );

    // Sync escort travel status
    for (final fieldId in escortIds) {
      final eIndex = _npcs.indexWhere((n) => n.id == fieldId);
      if (eIndex != -1) {
        _npcs[eIndex] = _npcs[eIndex].copyWith(
          worldDestinationId: destinationId,
          worldDepartureId: 'manor',
          worldTravelProgress: 0.0,
          status: NPCStatus.idle,
          activeTaskId: null,
          targetRoomId: 'road',
          isResident: false,
        );
      }
    }

    _lastAnnouncement = "${npc.name} has departed for $destinationId.";
    notifyListeners();
  }

  void returnToManor(String leaderId) {
    final leaderIndex = _npcs.indexWhere((n) => n.id == leaderId);
    if (leaderIndex == -1) return;

    final leader = _npcs[leaderIndex];
    final departureId = leader.worldDestinationId;

    // All NPCs at the same destination who are controlled by the player
    // (isResident implies they are part of the manor/player group)
    // Actually, any NPC whose worldDestinationId matches the leader's and progress is 1.0
    for (int i = 0; i < _npcs.length; i++) {
      if (_npcs[i].worldDestinationId == departureId &&
          _npcs[i].worldTravelProgress >= 1.0) {
        _npcs[i] = _npcs[i].copyWith(
          worldDepartureId: departureId,
          worldDestinationId: 'manor',
          worldTravelProgress: 0.0,
        );
      }
    }

    setSpeed(GameSpeed.normal);
    _lastAnnouncement = "The expedition is returning home from $departureId.";
    notifyListeners();
  }

  void _completeJourneyAtManor(int index) {
    var npc = _npcs[index];

    // Merge items back
    for (var entry in npc.journeyInventory.entries) {
      _resources[entry.key] = (_resources[entry.key] ?? 0) + entry.value;
    }

    final hour = _currentDate.hour;
    final preferredRoom = npc.schedule.getPreferredRoomForHour(hour);

    _npcs[index] = npc.copyWith(
      clearWorldDestination: true,
      worldTravelProgress: 0.0,
      journeyInventory: {},
      escortIds: [],
      currentRoomId: 'road',
      targetRoomId: preferredRoom,
      movementProgress: 0.0,
      isResident: true,
    );

    if (npc.isPlayer) {
      _pendingNavigationTarget = 'manor';
    }

    _lastAnnouncement = "${npc.name} has returned and unloaded their goods.";
    notifyListeners();
  }

  void setSpeed(GameSpeed newSpeed) {
    _speed = newSpeed;
    notifyListeners();
  }

  void cookRecipe(String recipeId, String npcId, {bool isPrepared = false}) {
    final recipe = KitchenService.getAvailableRecipes().firstWhere(
      (r) => r.id == recipeId,
    );
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) return;
    final npc = _npcs[npcIndex];

    if (!isPrepared) {
      // Check ingredients
      for (var entry in recipe.ingredients.entries) {
        if ((_resources[entry.key] ?? 0) < entry.value) {
          _lastAnnouncement = "NOT ENOUGH ${entry.key.toUpperCase()}!";
          notifyListeners();
          return;
        }
      }

      // Consume ingredients
      for (var entry in recipe.ingredients.entries) {
        _resources[entry.key] = (_resources[entry.key] ?? 0) - entry.value;
      }
    }

    // Create Dishes or handle special results
    if (recipe.id == 'butcher_cattle') {
      _resources['meat_beef'] = (_resources['meat_beef'] ?? 0) + recipe.yield;
    } else {
      for (int i = 0; i < recipe.yield; i++) {
        _pantry.add(
          Dish(
            id: const Uuid().v4(),
            name: recipe.name,
            type: _getDishTypeForRecipe(recipe.id),
            quality: _calculateCookQuality(npc),
            cookedAt: DateTime.now(),
            shelfLifeHours: 48,
          ),
        );
      }
    }

    _lastAnnouncement = "${npc.name} PREPARED ${recipe.name.toUpperCase()}!";
    notifyListeners();
  }

  void assignHousing(String npcId, String? roomId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;
    _npcs[index] = _npcs[index].copyWith(assignedRoomId: roomId);
    notifyListeners();
  }

  DishType _getDishTypeForRecipe(String id) {
    if (id.contains('bread') || id.contains('pasta')) return DishType.cereal;
    if (id.contains('chicken') || id.contains('beef')) return DishType.protein;
    if (id.contains('bean')) return DishType.vegetable;
    if (id.contains('chocolate') || id.contains('coffee')) {
      return DishType.treat;
    }
    return DishType.cereal;
  }

  DishQuality _calculateCookQuality(NPC npc) {
    final skill = npc.stats['intellect'] ?? 50;
    if (skill > 90) return DishQuality.exquisite;
    if (skill > 80) return DishQuality.delectable;
    if (skill > 70) return DishQuality.sophisticated;
    if (skill > 60) return DishQuality.fine;
    if (skill > 50) return DishQuality.decent;
    if (skill > 40) return DishQuality.alright;
    if (skill > 30) return DishQuality.notBad;
    if (skill > 20) return DishQuality.notGreat;
    return DishQuality.mediocre;
  }

  String getTaskDescription(GameTask task) =>
      _taskService.getTaskDescription(task);

  void spawnRefugee() {
    final refugee = NPCGenerator.generateRefugee();
    _npcs.add(refugee);
    _lastAnnouncement =
        "A new refugee, ${refugee.name}, has arrived at the manor gates.";
    notifyListeners();
  }

  void resetState() {
    _npcs.clear();
    _rooms.clear();
    _resources.clear();
    _resources.addAll({
      'gold': 500,
      'meat': 10,
      'eggs': 6,
      'cabbage': 8,
      'wood': 20,
      'meals': 2,
      'grain': 0,
      'ale': 0,
      'spirits': 0,
      'timber': 0,
      'herbs': 0,
    });
    _inventory.clear();
    _activeConstruction.clear();
    _activeExperiments.clear();
    _announcementHistory.clear();
    _objectives.clear();
    _unlockedDiscoveries.clear();
    _performedExperiments.clear();
    _pantry.clear();
    _cookingQueue.clear();
    _chickens.clear();
    _crops.clear();
    _uncollectedEggs = 0;
    _lastAnnouncement = null;

    _initializeManor();
    _initializeStartingCharacters();
    _initializeObjectives();
    notifyListeners();
  }

  // Placeholder for new research consumption logic if needed.
  // For now, physical items in room inventory are the source of truth.

  void craftItem(String name, Map<String, int> requirements, String product) {
    bool canCraft = true;
    requirements.forEach((res, amount) {
      if ((_resources[res] ?? 0) < amount) canCraft = false;
    });

    if (canCraft) {
      requirements.forEach((res, amount) {
        _resources[res] = (_resources[res] ?? 0) - amount;
      });
      _inventory.add(
        GameItem.create(
          name: product,
          type: product.toLowerCase().replaceAll(' ', '_'),
          category: ItemCategory.utility,
        ),
      );
      _lastAnnouncement = "Successfully transmuted $product.";
      notifyListeners();
    }
  }

  void sellResource(String resource, int amount) {
    // Check for someone at Hamlet
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () => throw Exception("No one is at the Hamlet to trade!"),
    );

    final travelerStock = traveler.journeyInventory[resource] ?? 0;
    if (travelerStock >= amount) {
      final price = _marketService.getSellPrice(resource);
      final int gain = (price * amount).toInt();

      final newInv = Map<String, int>.from(traveler.journeyInventory);
      newInv[resource] = travelerStock - amount;
      newInv['funds'] = (newInv['funds'] ?? 0) + gain;

      final index = _npcs.indexOf(traveler);
      _npcs[index] = traveler.copyWith(journeyInventory: newInv);

      _lastAnnouncement = "Sold $amount $resource via ${traveler.name}.";

      _lastAnnouncement = "Purchased $amount $resource via ${traveler.name}.";
      notifyListeners();
    }
  }

  void refreshHamletNpcs() {
    const cost = 5;

    // Check manor funds first
    if ((_resources['funds'] ?? 0) >= cost) {
      _resources['funds'] = (_resources['funds'] ?? 0) - cost;
      _refreshHamletNpcsLogic();
      return;
    }

    // If manor funds low, check if a traveler AT the hamlet has funds
    try {
      final traveler = _npcs.firstWhere(
        (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      );
      final travelerFunds = traveler.journeyInventory['funds'] ?? 0;
      if (travelerFunds >= cost) {
        final newInv = Map<String, int>.from(traveler.journeyInventory);
        newInv['funds'] = travelerFunds - cost;
        final index = _npcs.indexOf(traveler);
        _npcs[index] = traveler.copyWith(journeyInventory: newInv);
        _refreshHamletNpcsLogic();
      } else {
        _lastAnnouncement = "Not enough funds to attract new travelers.";
        notifyListeners();
      }
    } catch (e) {
      _lastAnnouncement = "Not enough funds in the manor to attract travelers.";
      notifyListeners();
    }
  }

  void _refreshHamletNpcsLogic() {
    _availableHamletNpcs.clear();
    for (int i = 0; i < 3; i++) {
      _availableHamletNpcs.add(NPCGenerator.generateRefugee());
    }
    _lastAnnouncement = "A new group of travelers has arrived at the Tavern.";
    notifyListeners();
  }

  void welcomeNpc(String npcId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _npcs[index] = _npcs[index].copyWith(
        isResident: true,
        disposition: NPCDisposition.voluntary,
        schedule: NPCSchedule.defaultWorker(), // Give them a worker schedule
      );
      _lastAnnouncement = "${_npcs[index].name} has joined the manor staff.";
      _checkObjectives();
      notifyListeners();
    }
  }

  void dismissNpc(String npcId) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index != -1) {
      _lastAnnouncement = "${_npcs[index].name} has departed the manor.";
      _npcs.removeAt(index);
      notifyListeners();
    }
  }

  void tryScheduleNpcTask(String npcId, TaskType type, String targetId) {
    final npcIndex = _npcs.indexWhere((n) => n.id == npcId);
    if (npcIndex == -1) return;
    var npc = _npcs[npcIndex];

    final durationHours = (getEstimatedTaskMinutes(npc, type) / 60.0).ceil();
    final currentHour = _currentDate.hourIndex;

    // 1. Determine where to start searching.
    // We skip until the end of the current Sleep, Eat, or existing Manual Assignment block
    // to ensure we don't interrupt critical activities or recently assigned tasks.
    int searchStart = currentHour;
    final maxSearch = currentHour + 168; // Search up to a week
    while (searchStart < maxSearch) {
      final idx = searchStart % 168;
      final activity = npc.schedule.getActivityForHour(idx);
      final block = npc.schedule.getBlock(idx);
      if (activity == ScheduleActivity.sleep ||
          activity == ScheduleActivity.eat ||
          block.manualTaskType != null) {
        searchStart++;
      } else {
        break;
      }
    }

    // 2. Collect the next available hours that are not Sleep, Eat, or existing Manual Assignment.
    // We allow splitting the task across multiple gaps.
    final List<int> targetHours = [];
    for (int i = searchStart; i < maxSearch; i++) {
      final idx = i % 168;
      final activity = npc.schedule.getActivityForHour(idx);
      final block = npc.schedule.getBlock(idx);

      if (activity != ScheduleActivity.sleep &&
          activity != ScheduleActivity.eat &&
          block.manualTaskType == null) {
        targetHours.add(idx);
        if (targetHours.length >= durationHours) break;
      }
    }

    if (targetHours.length < durationHours) {
      _lastAnnouncement = "${npc.name} is too busy to perform this task.";
      notifyListeners();
      return;
    }

    // 3. Apply the manual assignment to the found hours.
    var updatedSchedule = npc.schedule;
    for (final idx in targetHours) {
      updatedSchedule = updatedSchedule.updateBlock(
        idx,
        updatedSchedule.getBlock(idx).copyWith(
              manualTaskType: type,
              manualTargetId: targetId,
            ),
      );
    }

    _npcs[npcIndex] = npc.copyWith(
      schedule: updatedSchedule,
      clearThought: true,
    );
    _lastAnnouncement =
        "Scheduled ${type.name} for ${npc.name} starting ${targetHours.contains(_currentDate.hourIndex) ? 'now' : 'later'}.";
    notifyListeners();
  }

  void buyResource(String resource, int amount) {
    // Check for someone at Hamlet
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () => throw Exception("No one is at the Hamlet to trade!"),
    );

    final price = _marketService.getBuyPrice(resource).toInt();
    final totalCost = price * amount;
    final travelerFunds = traveler.journeyInventory['funds'] ?? 0;

    if (travelerFunds >= totalCost) {
      final newInv = Map<String, int>.from(traveler.journeyInventory);
      newInv['funds'] = travelerFunds - totalCost;
      newInv[resource] = (newInv[resource] ?? 0) + amount;

      final index = _npcs.indexOf(traveler);
      _npcs[index] = traveler.copyWith(journeyInventory: newInv);

      _lastAnnouncement = "Purchased $amount $resource via ${traveler.name}.";
      notifyListeners();
    }
  }

  void reorderTaskQueue(String npcId, int oldIndex, int newIndex) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      final npc = _npcs[idx];
      var queue = List<String>.from(npc.taskQueue);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
      _npcs[idx] = npc.copyWith(taskQueue: queue);
      notifyListeners();
    }
  }

  void reorderIntentQueue(String npcId, int oldIndex, int newIndex) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      final npc = _npcs[idx];
      var queue = List<NPCIntent>.from(npc.intentQueue);
      if (newIndex > oldIndex) newIndex -= 1;
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
      _npcs[idx] = npc.copyWith(intentQueue: queue);
      notifyListeners();
    }
  }

  void cancelEnqueuedTask(String npcId, String taskId) {
    cancelTask(taskId);
  }

  void cancelTask(String taskId) {
    // 1. Find NPC using this task
    final npcIndex = _npcs.indexWhere((n) => n.activeTaskId == taskId);
    if (npcIndex != -1) {
      final npc = _npcs[npcIndex];
      _npcs[npcIndex] = npc.copyWith(
        status: NPCStatus.idle,
        activeTaskId: null,
        currentThought: "Assignment cancelled.",
      );
    }

    // 2. Remove from all NPC intent queues
    for (int i = 0; i < _npcs.length; i++) {
      if (_npcs[i].intentQueue.any((it) => it.id == taskId)) {
        final newIntents = _npcs[i].intentQueue.where((it) => it.id != taskId).toList();
        _npcs[i] = _npcs[i].copyWith(intentQueue: newIntents);
      }
      if (_npcs[i].taskQueue.contains(taskId)) {
        final newTasks = _npcs[i].taskQueue.where((id) => id != taskId).toList();
        _npcs[i] = _npcs[i].copyWith(taskQueue: newTasks);
      }
    }

    // 3. Remove from all Room task queues and active projects
    for (int i = 0; i < _rooms.length; i++) {
      bool changed = false;
      List<String> newQueue = _rooms[i].taskQueue.toList();
      if (newQueue.contains(taskId)) {
        newQueue.remove(taskId);
        changed = true;
      }

      Map<String, PhysicalProject> newProjects = Map.from(_rooms[i].activeProjects);
      if (newProjects.containsKey(taskId)) {
        newProjects.remove(taskId);
        changed = true;
      }

      String? newOccupancy = _rooms[i].occupyingNpcId;
      if (newOccupancy != null) {
        // If the NPC was occupying this room for THIS task
        final npc = _npcs.firstWhere((n) => n.id == newOccupancy, orElse: () => _npcs[0]);
        if (npc.activeTaskId == taskId) {
          newOccupancy = null;
          changed = true;
        }
      }

      if (changed) {
        _rooms[i] = _rooms[i].copyWith(
          taskQueue: newQueue,
          activeProjects: newProjects,
          occupyingNpcId: newOccupancy,
        );
      }
    }

    // 4. Remove from Task Service
    _taskService.cancelTask(taskId);
    notifyListeners();
  }

  void cancelEnqueuedIntent(String npcId, String intentId) {
    final idx = _npcs.indexWhere((n) => n.id == npcId);
    if (idx != -1) {
      final npc = _npcs[idx];
      var queue = List<NPCIntent>.from(npc.intentQueue);
      queue.removeWhere((i) => i.id == intentId);
      _npcs[idx] = npc.copyWith(intentQueue: queue);
      notifyListeners();
    }
  }

  void hireNpc(NPC npc) {
    // Check for traveler at Hamlet to pay the fee
    final traveler = _npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
      orElse: () =>
          throw Exception("No one is at the Hamlet to hire recruits!"),
    );

    const hiringFee = 10;
    final travelerFunds = traveler.journeyInventory['funds'] ?? 0;

    if (travelerFunds >= hiringFee) {
      bool removed = false;
      _availableHamletNpcs.removeWhere((n) {
        if (n.id == npc.id) {
          removed = true;
          return true;
        }
        return false;
      });

      if (removed) {
        // Pay the fee
        final newInv = Map<String, int>.from(traveler.journeyInventory);
        newInv['funds'] = travelerFunds - hiringFee;
        final tIndex = _npcs.indexOf(traveler);
        
        // Update traveler's inventory
        _npcs[tIndex] = traveler.copyWith(journeyInventory: newInv);

        // SYNC: Hired NPC is now at the destination with the recruiter
        final hiredNpc = npc.copyWith(
          worldDestinationId: 'hamlet',
          worldDepartureId: 'manor',
          worldTravelProgress: 1.0,
          currentRoomId: null, // They are outside
          isResident: true, // Now under player control
        );
        _npcs.add(hiredNpc);

        // Add to roster history for player to ensure they join future journeys
        final playerIdx = _npcs.indexWhere((n) => n.id == 'player');
        if (playerIdx != -1) {
          final player = _npcs[playerIdx];
          final List<String> deck = List.from(player.lastEscortIds);
          if (!deck.contains(hiredNpc.id) && deck.length < 12) {
            deck.add(hiredNpc.id);
          }
          _npcs[playerIdx] = player.copyWith(lastEscortIds: deck);
        }

        _lastAnnouncement =
            "${npc.name} has been hired and joined your retinue.";
        notifyListeners();
      }
    } else {
      _lastAnnouncement =
          "Not enough funds carried by ${traveler.name} to hire ${npc.name}.";
      notifyListeners();
    }
  }

  void addToCookingQueue(String recipeId, {String? targetId, String? targetName}) {
    if (targetId != null) {
      _cookingQueue.add("butcher:$recipeId:$targetId:$targetName");
    } else {
      _cookingQueue.add(recipeId);
    }
    notifyListeners();
  }

  void removeFromCookingQueue(int index) {
    if (index >= 0 && index < _cookingQueue.length) {
      _cookingQueue.removeAt(index);
      notifyListeners();
    }
  }

  DishQuality _mapToDishQuality(double value) {
    if (value > 2.0) return DishQuality.exquisite;
    if (value > 1.8) return DishQuality.delectable;
    if (value > 1.6) return DishQuality.sophisticated;
    if (value > 1.4) return DishQuality.fine;
    if (value > 1.2) return DishQuality.decent;
    if (value > 1.0) return DishQuality.alright;
    if (value > 0.8) return DishQuality.notBad;
    if (value > 0.6) return DishQuality.notGreat;
    if (value > 0.4) return DishQuality.mediocre;
    if (value > 0.2) return DishQuality.weak;
    if (value > 0.0) return DishQuality.awful;
    return DishQuality.disgusting;
  }

  DishType _mapToDishType(String recipeId) {
    if (recipeId.contains('bread') || recipeId.contains('pasta')) {
      return DishType.cereal;
    }
    if (recipeId.contains('chicken') ||
        recipeId.contains('beef') ||
        recipeId.contains('meat')) {
      return DishType.protein;
    }
    if (recipeId.contains('stew') ||
        recipeId.contains('soup') ||
        recipeId.contains('bean')) {
      return DishType.vegetable;
    }
    return DishType.treat;
  }

  void _updateIntentQueue(int index) {
    var npc = _npcs[index];
    List<NPCIntent> newQueue = List.from(npc.intentQueue);
    final hourIndex = _currentDate.hourIndex;
    final activity = npc.schedule.getActivityForHour(hourIndex);
    final block = npc.schedule.getBlock(hourIndex);
    
    if (npc.status == NPCStatus.dead ||
        npc.status == NPCStatus.fainted ||
        npc.status == NPCStatus.broken) {
      // Clear queue if they can't act
      if (newQueue.isNotEmpty) {
        _npcs[index] = npc.copyWith(intentQueue: []);
      }
      return;
    }

    // 0. Emergency Response (Highest Priority)
    for (var crisis in _crises) {
      // Crisis is discovered if NPC is in the room or it's already discovered
      bool isNear = npc.currentRoomId == crisis.roomId;

      if (isNear || crisis.isDiscovered) {
        // If not discovered, discovering it now
        if (!crisis.isDiscovered && isNear) {
          final updatedCrisis = crisis.copyWith(isDiscovered: true);
          final cIndex = _crises.indexOf(crisis);
          if (cIndex != -1) _crises[cIndex] = updatedCrisis;
          _announcementHistory.insert(
            0,
            "[${_currentDate.formattedTime}] ${npc.name} has discovered the ${crisis.name} in the ${_rooms.firstWhere((r) => r.id == crisis.roomId).name}!",
          );
        }

        // Trigger panic intent if not already handling it
        TaskType emergencyTask;
        switch (crisis.type) {
          case ManorCrisisType.fire:
            emergencyTask = TaskType.extinguishFire;
            break;
          case ManorCrisisType.specimenEscape:
            emergencyTask = TaskType.recombineSpecimen;
            break;
          case ManorCrisisType.intruder:
            emergencyTask = TaskType.defendManor;
            break;
        }

        bool alreadyHandling = newQueue.any(
          (intent) =>
              intent.action == emergencyTask &&
              intent.targetRoomId == crisis.roomId,
        );

        if (!alreadyHandling) {
          final panicIntent = NPCIntent(
            id: 'panic_${crisis.id}_${npc.id}',
            action: emergencyTask,
            targetRoomId: crisis.roomId,
            priority: IntentPriority.panic,
            minutesRemaining: (15 + (crisis.severity * 30)).toInt(),
            expectedDurationMin: (20 + (crisis.severity * 40)).toInt(),
          );

          // Panic intents clear lower priority tasks or prepend
          newQueue.insert(0, panicIntent);
          _npcs[index] = npc.copyWith(
            intentQueue: newQueue,
            status: NPCStatus.panicked,
          );
          notifyListeners();
          return; // Process this immediately
        }
      }
    }

    // 1. Determine autonomous candidates from Responsibility Grid
    List<_ResponsibilityTaskCandidate> candidates = [];

    for (var cat in ResponsibilityCategory.values) {
      final stars = npc.responsibilities[cat] ?? 0;
      if (stars == 0) continue;

      final tasks = _categoryPriorities[cat] ?? [];
      final divider = _categoryDividers[cat] ?? 0;

      for (int i = 0; i < tasks.length; i++) {
        final taskType = tasks[i];
        final isAboveDivider = i < divider;

        final targetRoomId = _getAutonomousTargetForTask(taskType, npc);
        if (targetRoomId == null) continue;

        bool canPerformNow = false;
        IntentPriority priority = IntentPriority.normal;

        if (stars == 5 && isAboveDivider) {
          canPerformNow = true;
          priority = IntentPriority.vital; // Overrides routine eat/sleep
        } else if (stars == 4 && isAboveDivider) {
          // 4-star only if not eating/sleeping
          if (activity != ScheduleActivity.sleep &&
              activity != ScheduleActivity.eat) {
            canPerformNow = true;
          }
          priority = IntentPriority.urgent;
        } else if (activity == ScheduleActivity.work) {
          canPerformNow = true;
          priority = IntentPriority.normal;
        }

        if (canPerformNow) {
          candidates.add(
            _ResponsibilityTaskCandidate(
              taskType: taskType,
              category: cat,
              stars: stars,
              priority: priority,
              targetRoomId: targetRoomId,
              isAboveDivider: isAboveDivider,
              verticalIndex: i,
            ),
          );
        }
      }
    }

    // Sort candidates
    candidates.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.index.compareTo(a.priority.index);
      }
      if (a.stars != b.stars) {
        return b.stars.compareTo(a.stars);
      }
      return a.verticalIndex.compareTo(b.verticalIndex);
    });

    // 2. Clear stale autonomous/scheduled intents from queue
    // Preserve ONLY the currently active intent to avoid flickering restart
    newQueue.removeWhere(
      (i) =>
          i.id != npc.activeTaskId &&
          (i.priority == IntentPriority.normal ||
              i.priority == IntentPriority.urgent ||
              i.priority == IntentPriority.vital ||
              i.priority == IntentPriority.panic),
    );

    // 3. Panic State Overrides (Breaking point needs) - Point 1
    // TODO: Point 2 - Emergency System (Fire, Combat, etc)
    // Characters should respond to global emergencies here with highest priority.
    final inEmergency = newQueue.any(
      (i) =>
          i.action == TaskType.extinguishFire ||
          i.action == TaskType.defendManor ||
          i.action == TaskType.recombineSpecimen,
    );

    if (npc.hunger > 95 && !inEmergency) {
      newQueue.insert(
        0,
        NPCIntent(
          id: 'panic_hunger_${npc.id}_$hourIndex',
          priority: IntentPriority.panic,
          action: TaskType.eat,
          targetRoomId: 'kitchen',
          expectedDurationMin: 30,
        ),
      );
    } else if (npc.energy < 5 && !inEmergency) {
      newQueue.insert(
        0,
        NPCIntent(
          id: 'panic_exhaustion_${npc.id}_$hourIndex',
          priority: IntentPriority.panic,
          action: TaskType.rest,
          targetRoomId: npc.assignedRoomId ?? 'butler_quarters',
          expectedDurationMin: 240,
        ),
      );
    } else if (npc.digestion >= 85) {
      // Find a toilet
      final toiletRoom = _rooms.firstWhere(
        (r) => r.type == RoomType.toilet && r.isRestored,
        orElse: () => _rooms.firstWhere(
          (r) => r.type == RoomType.toilet,
          orElse: () => Room.initial('na', 'na', RoomType.unused, Floor.ground),
        ),
      );
      if (toiletRoom.id != 'na' &&
          !newQueue.any((i) => i.action == TaskType.useToilet)) {
        newQueue.insert(
          0,
          NPCIntent(
            id: 'urgent_toilet_${npc.id}_$hourIndex',
            priority: npc.digestion >= 95
                ? IntentPriority.panic
                : IntentPriority.urgent,
            action: TaskType.useToilet,
            targetRoomId: toiletRoom.id,
            expectedDurationMin: 15,
          ),
        );
      }
    }

    // 4. Add Top Responsibility candidate if exists - Point 3 & 6
    if (candidates.isNotEmpty) {
      final top = candidates.first;
      if (!newQueue.any(
        (i) => i.action == top.taskType && i.priority == top.priority,
      )) {
        final isScienceTask =
            (top.taskType == TaskType.research ||
            top.taskType == TaskType.vivisection ||
            top.taskType == TaskType.dissect ||
            top.taskType == TaskType.puzzleStudy ||
            top.taskType == TaskType.deprivationStudy ||
            top.taskType == TaskType.clinicalTrial);

        final scienceActivity = isScienceTask
            ? _getAvailableScienceActivityForNpc(index, top.taskType)
            : null;

        if (scienceActivity != null) {
          final missingIngredients = _getMissingIngredientsForActivity(
            index,
            scienceActivity,
          );
          if (missingIngredients.isNotEmpty) {
            // NPC needs to gather ingredients first
            if (!newQueue.any((i) => i.action == TaskType.collectIngredients)) {
              newQueue.insert(
                0,
                NPCIntent(
                  id: 'gather_${npc.id}_${scienceActivity.id}_$hourIndex',
                  priority: IntentPriority
                      .urgent, // Higher priority than the activity itself
                  action: TaskType.collectIngredients,
                  targetRoomId: 'pantry', // Default to pantry for now
                  expectedDurationMin: 30,
                  recipeId: scienceActivity.id, // Stashing activityId here
                ),
              );
            }
          }
        }

        String? targetRecipeId = scienceActivity?.id;
        if (targetRecipeId == null && top.taskType == TaskType.research) {
          for (var qId in _researchQueue) {
            if (!qId.startsWith('activity:')) {
              targetRecipeId = qId;
              break;
            }
          }
        }

        final intent = NPCIntent(
          id: 'resp_${npc.id}_${top.taskType.name}_$hourIndex',
          priority: top.priority,
          action: top.taskType,
          targetRoomId: top.targetRoomId,
          expectedDurationMin: 60,
          recipeId: targetRecipeId,
        );
        // Insert based on priority
        if (top.priority.index >= IntentPriority.vital.index) {
          newQueue.insert(0, intent);
        } else {
          newQueue.add(intent);
        }
      }
    }

    // 5. Default Scheduled needs (Eat/Sleep) - Point 4 & 5
    if (activity == ScheduleActivity.eat &&
        !newQueue.any((i) => i.priority.index >= IntentPriority.vital.index)) {
      newQueue.add(
        NPCIntent(
          id: 'sched_eat_${npc.id}_$hourIndex',
          priority: IntentPriority.vital,
          action: TaskType.eat,
          targetRoomId: 'kitchen',
          expectedDurationMin: 60,
        ),
      );
    } else if (activity == ScheduleActivity.sleep &&
        !newQueue.any((i) => i.priority.index >= IntentPriority.vital.index)) {
      newQueue.add(
        NPCIntent(
          id: 'sched_sleep_${npc.id}_$hourIndex',
          priority: IntentPriority.vital,
          action: TaskType.rest,
          targetRoomId: npc.assignedRoomId ?? 'butler_quarters',
          expectedDurationMin: 480,
        ),
      );
    }

    // 6. Default Scheduled Work/Routine - Point 9 & 10
    if (newQueue.isEmpty ||
        !newQueue.any((i) => i.priority.index > IntentPriority.normal.index)) {
      TaskType scheduledTask = _mapActivityToTask(activity, npc);
      String? personalityTarget = _getPersonalityIdleTarget(index, activity);

      // We allow re-adding if queue is truly empty (except possibly low-priority wander)
      // ID includes hour and a 'salt' to allow re-evaluation within the hour if finished
      final salt = Random().nextInt(1000);
      newQueue.add(
        NPCIntent(
          id: 'sched_normal_${npc.id}_${hourIndex}_$salt',
          priority: IntentPriority.normal,
          action: scheduledTask,
          targetRoomId: personalityTarget ?? block.preferredRoomId,
          expectedDurationMin: 15 + Random().nextInt(15), // Re-evaluate every 15-30m
        ),
      );
    }

    // 7. Manual Assignments (Drag & Drop overrides)
    if (block.manualTaskType != null) {
      final manualId = 'manual_assign_${npc.id}_${block.manualTaskType!.name}';
      if (!newQueue.any((i) =>
          i.priority == IntentPriority.assignment &&
          i.action == block.manualTaskType &&
          i.targetRoomId == block.manualTargetId)) {
        newQueue.insert(
          0,
          NPCIntent(
            id: manualId,
            priority: IntentPriority.assignment,
            action: block.manualTaskType!,
            targetRoomId: block.manualTargetId,
            expectedDurationMin: 60,
          ),
        );
      }
    }

    // 8. Sort Queue by priority AGAIN to ensure correct order
    newQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    _npcs[index] = npc.copyWith(
      intentQueue: newQueue,
      lastScheduledHour: hourIndex,
    );
  }

  String? _getAutonomousTargetForTask(TaskType type, NPC npc) {
    switch (type) {
      case TaskType.cleanRoom:
        // Find the dirtiest manor room
        final dirtyRooms = _rooms
            .where((r) => r.isRestored && r.isInsideManor && r.dirtiness > 0.1)
            .toList();
        if (dirtyRooms.isEmpty) return null;
        dirtyRooms.sort((a, b) => b.dirtiness.compareTo(a.dirtiness));
        return dirtyRooms.first.id;
      case TaskType.cook:
        return _cookingQueue.isNotEmpty ? 'kitchen' : null;
      case TaskType.tillSoil:
        final untilliedFields = _rooms
            .where((r) => r.type == RoomType.field && r.tilledAmount < 0.9)
            .toList();
        if (untilliedFields.isEmpty) return null;
        untilliedFields.sort(
          (a, b) => a.tilledAmount.compareTo(b.tilledAmount),
        );
        return untilliedFields.first.id;
      case TaskType.fertilizeSoil:
        final unfertilizedFields = _rooms
            .where((r) => r.type == RoomType.field && r.fertilizedAmount < 0.9)
            .toList();
        if (unfertilizedFields.isEmpty) return null;
        unfertilizedFields.sort(
          (a, b) => a.fertilizedAmount.compareTo(b.fertilizedAmount),
        );
        return unfertilizedFields.first.id;
      case TaskType.plantCrops:
        // Plant if we have tilled soil and seeds
        final tilledFields = _rooms
            .where((r) => r.type == RoomType.field && r.isTilled)
            .toList();
        if (tilledFields.isEmpty) return null;
        // Check for any seeds
        bool hasSeeds = false;
        for (var type in CropType.values) {
          if ((_resources['seeds_${type.name}'] ?? 0) > 0) {
            hasSeeds = true;
            break;
          }
        }
        return hasSeeds ? tilledFields.first.id : null;
      case TaskType.waterCrops:
        bool needsWater = _crops.any((c) => c.moistureLevel < 0.5);
        return needsWater
            ? 'vegetable_garden'
            : null; // Default to garden for now
      case TaskType.careForCrops:
        bool needsCare = _crops.any(
          (c) =>
              c.lastCaredForAt == null ||
              DateTime.now().difference(c.lastCaredForAt!).inHours > 12,
        );
        return needsCare ? 'vegetable_garden' : null;
      case TaskType.harvestCabbage:
      case TaskType.harvestCrops:
        final mature = _crops.any((c) => c.isHarvestable);
        return mature ? 'vegetable_garden' : null;
      case TaskType.research:
        return _researchQueue.isNotEmpty ? 'study' : null;
      case TaskType.study:
        return _researchQueue.isNotEmpty ? 'library' : null;
      case TaskType.experiment:
        return _researchQueue.isNotEmpty ? 'laboratory' : null;
      case TaskType.operation:
      case TaskType.surgery:
      case TaskType.surgicalOperation:
        return _researchQueue.isNotEmpty ? 'operating_room' : null;
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.puzzleStudy:
      case TaskType.deprivationStudy:
      case TaskType.clinicalTrial:
      case TaskType.transcribeNotes:
      case TaskType.archiveResearch:
        final hasKnowledgeInGlobal = _inventory.any(
          (i) => i.category == ItemCategory.knowledge,
        );
        final hasKnowledgeOnPerson = npc.inventory.any(
          (i) => i.category == ItemCategory.knowledge,
        );

        if (!hasKnowledgeInGlobal && !hasKnowledgeOnPerson) return null;

        final library = _rooms.firstWhere(
          (r) => r.type == RoomType.library && r.isRestored,
          orElse: () => _rooms.firstWhere(
            (r) => r.type == RoomType.study,
            orElse: () => _rooms[0],
          ),
        );
        return library.id;
      case TaskType.guardCoop:
        return 'chicken_coop';
      case TaskType.hunt:
        return 'entryway'; // "Outside"
      case TaskType.brew:
      case TaskType.distill:
        final productionRoom = _rooms.firstWhere(
          (r) => r.type == RoomType.unused && r.isRestored,
          orElse: () => _rooms[0],
        );
        return productionRoom.id;
      default:
        return null; // Not autonomously performable yet
    }
  }

  String _getRandomPropertyRoom() {
    final pool = [
      'kitchen',
      'study',
      'library',
      'laboratory',
      'operating_room',
      'dining_hall',
      'master_bedroom',
      'bathroom_up',
      'bathroom_down',
      'butler_quarters',
      'vegetable_garden',
      'chicken_coop',
      'field_1',
      'field_2',
      'entryway',
    ];
    // Filter by restored? User said "inspecting all buildings and fields"
    // Let's just use the pool but maybe weighted or filtered by existence
    final validRooms = _rooms.where((r) => pool.contains(r.id)).toList();
    if (validRooms.isEmpty) return 'entryway';
    return validRooms[Random().nextInt(validRooms.length)].id;
  }

  String? _getPersonalityIdleTarget(int index, ScheduleActivity activity) {
    final npc = _npcs[index];
    final isGiles = npc.role == 'Butler';
    final isAlphonse = npc.isPlayer;
    final random = Random();

    if (activity == ScheduleActivity.work) {
      if (isAlphonse) {
        // experiment > research > study > cook > garden
        final searches = [
          TaskType.experiment,
          TaskType.research,
          TaskType.study,
          TaskType.cook,
          TaskType.harvestCrops,
        ];
        for (var task in searches) {
          final target = _getAutonomousTargetForTask(task, npc);
          if (target != null) return target;
        }
      }
      // Giles work logic: Clean or stand in Entryway (handled by mapActivityToTask + preferredRoom)
    }

    // Default/Leisure/Free Time or no work found
    if (isGiles) {
      if (activity == ScheduleActivity.leisure) {
        final areas = [
          'kitchen',
          'butler_quarters',
          'bathroom_down',
          'chicken_coop'
        ];
        // 25% chance to wander
        if (random.nextDouble() < 0.25) return _getRandomPropertyRoom();
        return areas[random.nextInt(areas.length)];
      }
    } else if (isAlphonse) {
      if (activity == ScheduleActivity.leisure) {
        final areas = [
          'vegetable_garden',
          'library',
          'master_bedroom',
          'bathroom_up'
        ];
        // 25% chance to wander
        if (random.nextDouble() < 0.25) return _getRandomPropertyRoom();
        return areas[random.nextInt(areas.length)];
      }
      // If it's work hours but no work found, he wanders/inspects
      return _getRandomPropertyRoom();
    }

    return null;
  }

  void _processCurrentIntent(int index) {
    var npc = _npcs[index];
    if (npc.intentQueue.isEmpty) return;

    final totalMin = _currentDate.totalMinutes;
    final readyIntents = npc.intentQueue
        .where((i) => i.startTimeMin == null || i.startTimeMin! <= totalMin)
        .toList();

    if (readyIntents.isEmpty) return;
    final currentIntent = readyIntents.first;

    // Check if we are already doing this
    if (npc.activeTaskId != null) {
      // Is the current task an intent in our queue?
      final activeIntentInQueue = npc.intentQueue
          .where((i) => i.id == npc.activeTaskId)
          .firstOrNull;

      if (activeIntentInQueue == null) {
        // Legacy or manual task not in queue - allow cancellation for ANY intent since we want to move to unified
        _taskService.cancelTask(npc.activeTaskId!);
      } else {
        // If the top intent is different from our active task:
        if (activeIntentInQueue.id != currentIntent.id) {
          // Only switch if the new intent has HIGHER priority than current
          if (currentIntent.priority.index >
              activeIntentInQueue.priority.index) {
            _taskService.cancelTask(npc.activeTaskId!);
          } else {
            // Keep doing what we're doing
            return;
          }
        } else {
          // It's the same intent, just keep working
          return;
        }
      }
    }

    String? assignedRecipeId = currentIntent.recipeId;
    final isScienceAction =
        (currentIntent.action == TaskType.research ||
        currentIntent.action == TaskType.dissect ||
        currentIntent.action == TaskType.vivisection ||
        currentIntent.action == TaskType.puzzleStudy ||
        currentIntent.action == TaskType.deprivationStudy ||
        currentIntent.action == TaskType.clinicalTrial);

    if (currentIntent.action == TaskType.cook && assignedRecipeId == null) {
      if (_cookingQueue.isNotEmpty) {
        assignedRecipeId = _cookingQueue.first;
      }
    } else if (isScienceAction && assignedRecipeId == null) {
      if (_researchQueue.isNotEmpty) {
        // Try to find a matching activity or just take the first item if research
        String? foundId;
        for (var qId in _researchQueue) {
          if (qId.startsWith('activity:')) {
            final aId = qId.replaceFirst('activity:', '');
            final activity = ScienceService.getActivityById(aId);
            if (activity != null && activity.type == currentIntent.action) {
              foundId = aId;
              break;
            }
          } else if (currentIntent.action == TaskType.research) {
            foundId = qId;
            break;
          }
        }
        assignedRecipeId = foundId;
      }
    }

    int baseDuration =
        currentIntent.minutesRemaining ?? currentIntent.expectedDurationMin;
    int actualDuration = baseDuration;

    // Apply intellect-based duration reduction for science tasks
    final isScienceTask =
        (currentIntent.action == TaskType.research ||
        currentIntent.action == TaskType.dissect ||
        currentIntent.action == TaskType.vivisection ||
        currentIntent.action == TaskType.puzzleStudy ||
        currentIntent.action == TaskType.deprivationStudy ||
        currentIntent.action == TaskType.clinicalTrial);

    if (isScienceTask) {
      final intellect = npc.stats['intellect'] ?? 10;
      // Formula: -1% duration per 2 intellect points, max 40% reduction at 80 intellect
      final reductionPercent = (intellect / 2).clamp(0, 40) / 100.0;
      actualDuration = (baseDuration * (1.0 - reductionPercent)).round();
      if (actualDuration < 1) actualDuration = 1;
    }

    final task = GameTask(
      id: currentIntent.id,
      npcId: npc.id,
      type: currentIntent.action,
      targetId: currentIntent.targetRoomId,
      recipeId: assignedRecipeId,
      minutesRemaining: actualDuration,
    );

    _taskService.addTask(task);

    List<String> path = [];
    String? firstTarget = task.targetId;

    if (task.targetId != null && task.targetId != npc.currentRoomId) {
      path = _findPath(npc.currentRoomId ?? 'entryway', task.targetId!);
      if (path.isNotEmpty) {
        firstTarget = path.removeAt(0);
      }
    }

    _npcs[index] = npc.copyWith(
      activeTaskId: task.id,
      targetRoomId: firstTarget,
      movementPath: path,
      movementProgress: (firstTarget == npc.currentRoomId) ? 1.0 : 0.0,
      status:
          task.type == TaskType.rest ||
              task.type == TaskType.eat ||
              task.type == TaskType.idle
          ? (task.type == TaskType.rest ? NPCStatus.sleeping : NPCStatus.idle)
          : NPCStatus.working,
    );
  }

  TaskType _mapActivityToTask(ScheduleActivity activity, NPC npc) {
    switch (activity) {
      case ScheduleActivity.sleep:
        return TaskType.rest;
      case ScheduleActivity.eat:
        return TaskType.eat;
      case ScheduleActivity.cook:
        return TaskType.cook;
      case ScheduleActivity.guardCoop:
        return TaskType.guardCoop;
      case ScheduleActivity.work:
      case ScheduleActivity.cleanRoom:
        if (npc.isPlayer) {
          // experiment > research > study > cook > garden
          if (_getAutonomousTargetForTask(TaskType.experiment, npc) != null) {
            return TaskType.experiment;
          }
          if (_getAutonomousTargetForTask(TaskType.research, npc) != null) {
            return TaskType.research;
          }
          if (_getAutonomousTargetForTask(TaskType.study, npc) != null) {
            return TaskType.study;
          }
          if (_getAutonomousTargetForTask(TaskType.cook, npc) != null) {
            return TaskType.cook;
          }
          if (_getAutonomousTargetForTask(TaskType.harvestCrops, npc) != null) {
            return TaskType.harvestCrops;
          }
        }
        if (npc.role == 'Scientist') return TaskType.research;
        // Only clean if something is actually dirty
        final needsCleaning = _rooms.any(
          (r) => r.isRestored && r.isInsideManor && r.dirtiness > 0.1,
        );
        return needsCleaning ? TaskType.cleanRoom : TaskType.idle;
      case ScheduleActivity.study:
        return TaskType.research;
      case ScheduleActivity.leisure:
      case ScheduleActivity.prayer:
        return TaskType.idle;
    }
  }

  void interactWithNpc(String npcId, InteractionType type) {
    final targetIdx = _npcs.indexWhere((n) => n.id == npcId);
    final playerIdx = _npcs.indexWhere((n) => n.isPlayer);

    if (targetIdx != -1 && playerIdx != -1) {
      final npc1 = _npcs[playerIdx];
      final npc2 = _npcs[targetIdx];

      final result = SocialService.performInteraction(npc1, npc2, type);

      final newRels1 = Map<String, Relationship>.from(
        _npcs[playerIdx].relationships,
      );
      newRels1[npcId] = result['actorRelationship'] as Relationship;

      final newRels2 = Map<String, Relationship>.from(
        _npcs[targetIdx].relationships,
      );
      newRels2[npc1.id] = result['targetRelationship'] as Relationship;

      _npcs[playerIdx] = _npcs[playerIdx].copyWith(relationships: newRels1);
      _npcs[targetIdx] = _npcs[targetIdx].copyWith(relationships: newRels2);

      final log = "YOU: ${result['log']}";
      _lastAnnouncement = log;
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SOCIAL: $log",
      );
      if (_announcementHistory.length > 50) _announcementHistory.removeLast();

      notifyListeners();
    }
  }

  void _handleScienceTaskCompletion(int npcIndex, GameTask task) {
    var worker = _npcs[npcIndex];
    final activity = ScienceService.getActivityById(task.recipeId ?? '');

    if (activity != null) {
      // 1. Handle Projected Science Activity (Dissection, Vivisection, etc.)
      bool hasAll = true;
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      final roomInv = roomIndex != -1
          ? _rooms[roomIndex].inventory
          : <GameItem>[];

      for (var entry in activity.ingredients.entries) {
        int avail = 0;
        final key = entry.key;

        bool matches(String type) {
          if (type == key) return true;
          if (key == 'meat' &&
              (type.startsWith('meat_') || type.endsWith('_specimen'))) {
            return true;
          }
          if (key == 'specimen' && type.endsWith('_specimen')) {
            return true;
          }
          return false;
        }

        avail += _inventory
            .where((i) => matches(i.type))
            .fold<int>(0, (sum, i) => sum + i.quantity);
        avail += roomInv
            .where((i) => matches(i.type))
            .fold<int>(0, (sum, i) => sum + i.quantity);
        avail += worker.inventory
            .where((i) => matches(i.type))
            .fold<int>(0, (sum, i) => sum + i.quantity);
        avail += (_resources[key] ?? 0).toInt();

        if (avail < entry.value) {
          hasAll = false;
        }
      }

      if (hasAll) {
        // Deduct ingredients effectively
        for (var entry in activity.ingredients.entries) {
          int remaining = entry.value;
          final key = entry.key;

          bool matches(String type) {
            if (type == key) {
              return true;
            }
            if (key == 'meat' &&
                (type.startsWith('meat_') || type.endsWith('_specimen'))) {
              return true;
            }
            if (key == 'specimen' && type.endsWith('_specimen')) {
              return true;
            }
            return false;
          }

          // Deduct from worker first
          final List<GameItem> updatedWorkerInv = List.from(worker.inventory);
          for (int i = 0; i < updatedWorkerInv.length && remaining > 0; i++) {
            if (matches(updatedWorkerInv[i].type)) {
              int toTake = min(updatedWorkerInv[i].quantity, remaining);
              updatedWorkerInv[i] = updatedWorkerInv[i].copyWith(
                quantity: updatedWorkerInv[i].quantity - toTake,
              );
              remaining -= toTake;
            }
          }
          worker = worker.copyWith(
            inventory: updatedWorkerInv.where((i) => i.quantity > 0).toList(),
          );

          // Deduct from room
          if (remaining > 0 && roomIndex != -1) {
            final List<GameItem> updatedRoomInv = List.from(
              _rooms[roomIndex].inventory,
            );
            for (int i = 0; i < updatedRoomInv.length && remaining > 0; i++) {
              if (matches(updatedRoomInv[i].type)) {
                int toTake = min(updatedRoomInv[i].quantity, remaining);
                updatedRoomInv[i] = updatedRoomInv[i].copyWith(
                  quantity: updatedRoomInv[i].quantity - toTake,
                );
                remaining -= toTake;
              }
            }
            _rooms[roomIndex] = _rooms[roomIndex].copyWith(
              inventory: updatedRoomInv.where((i) => i.quantity > 0).toList(),
            );
          }

          // Deduct from global inventory
          if (remaining > 0) {
            for (int i = _inventory.length - 1; i >= 0 && remaining > 0; i--) {
              if (matches(_inventory[i].type)) {
                int toTake = min(_inventory[i].quantity, remaining);
                int newQty = _inventory[i].quantity - toTake;
                if (newQty <= 0) {
                  _inventory.removeAt(i);
                } else {
                  _inventory[i] = _inventory[i].copyWith(quantity: newQty);
                }
                remaining -= toTake;
              }
            }
          }

          // Deduct from resources
          if (remaining > 0) {
            _resources[key] = (_resources[key] ?? 0) - remaining;
          }
        }

        // Apply outcomes
        double corruption = activity.moralCost;
        // The triggers are called after worker is saved back to _npcs list at the end of this if(hasAll) block or method

        // Generate knowledge item
        final noteCount =
            (Random().nextInt(15) +
            (activity.type == TaskType.vivisection ? 5 : 1));
        final notes = GameItem.create(
          name: '${activity.name} Notes',
          type: 'research_notes',
          category: ItemCategory.knowledge,
          quantity: 1,
          metadata: {'discipline': activity.discipline, 'pages': noteCount},
        );
        _inventory.add(notes);

        // Dissection/Vivisection meat yield
        if (activity.type == TaskType.dissect ||
            activity.type == TaskType.vivisection) {
          final meat = GameItem.create(
            name: 'Raw Protein',
            type: 'meat_generic',
            category: ItemCategory.food,
            quantity: 2,
          );
          _inventory.add(meat);
        }

        // Move notes to room inventory immediately to update knowledge points
        if (roomIndex != -1) {
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
          roomInv.add(notes);
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
          _inventory.removeLast(); // Remove from global as it's now in room
        }

        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} completed ${activity.name}. ${activity.outcomeDescription}",
        );

        _researchQueue.remove(activity.id);
        _researchQueue.remove('activity:${activity.id}');

        // PERSIST worker before triggers
        _npcs[npcIndex] = worker;

        if (corruption > 0) {
          triggerGuilt(worker.id, source: activity.name);
          if (corruption >= 0.4) {
            triggerInsanity(
              worker.id,
              corruption >= 0.5 ? 'severe_temporary' : 'mild',
            );
          }
        }
      } else {
        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} failed ${activity.name}: Insufficient materials.",
        );
      }
    } else if (task.recipeId != null) {
      // 2. Handle Document Research / Item Study
      final itemId = task.recipeId!;

      // Check worker inventory first (since they might have gathered it)
      int workerItemIndex = worker.inventory.indexWhere((i) => i.id == itemId);
      int globalItemIndex = _inventory.indexWhere((i) => i.id == itemId);

      GameItem? itemToStudy;
      if (workerItemIndex != -1) {
        itemToStudy = worker.inventory[workerItemIndex];
        final List<GameItem> newInv = List.from(worker.inventory);
        newInv.removeAt(workerItemIndex);
        worker = worker.copyWith(inventory: newInv);
        _npcs[npcIndex] = worker;
      } else if (globalItemIndex != -1) {
        itemToStudy = _inventory[globalItemIndex];
        _inventory.removeAt(globalItemIndex);
      }

      if (itemToStudy != null) {
        _researchQueue.remove(itemId);
        _researchQueue.remove('activity:$itemId');

        int totalPages = itemToStudy.metadata['pages'] ?? 10;
        int notesGenerated =
            (totalPages * (0.25 + Random().nextDouble() * 0.25)).ceil();

        final study = GameItem.create(
          name: '${itemToStudy.name} Analysis',
          type: 'research_study',
          category: ItemCategory.knowledge,
          metadata: {
            'discipline': itemToStudy.metadata['discipline'] ?? 'Anatomy',
            'source': itemToStudy.name,
            'pages': notesGenerated,
          },
        );
        _inventory.add(study);

        // Move analysis to room inventory immediately
        final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
        if (roomIndex != -1) {
          final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
          roomInv.add(study);
          _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
          _inventory.removeLast();
        }

        _announcementHistory.insert(
          0,
          "[${_currentDate.formattedTime}] ${worker.name} finished studying ${itemToStudy.name}, producing an analysis.",
        );
      }
    } else if (task.type == TaskType.research) {
      // 3. Fallback: General Research / Synthetic Insight
      final disciplines = [
        "Anatomy",
        "Chemistry",
        "Botany",
        "Physics",
        "Theology",
      ];
      final discipline = disciplines[Random().nextInt(disciplines.length)];
      final points = (Random().nextInt(4) + 12); // 12-15

      final notes = GameItem.create(
        name: 'Synthetic Insight ($discipline)',
        type: 'research_notes',
        category: ItemCategory.knowledge,
        quantity: points,
        metadata: {'discipline': discipline, 'pages': points * 2},
      );

      // Add to room inventory immediately
      final roomIndex = _rooms.indexWhere((r) => r.id == task.targetId);
      if (roomIndex != -1) {
        final List<GameItem> roomInv = List.from(_rooms[roomIndex].inventory);
        roomInv.add(notes);
        _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
      } else {
        _inventory.add(notes);
      }

      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] ${worker.name} synthesized new insights, advancing knowledge in $discipline.",
      );
    }
    _npcs[npcIndex] = worker;
  }

  ScienceActivity? _getAvailableScienceActivityForNpc(
    int index,
    TaskType type,
  ) {
    if (_researchQueue.isEmpty) {
      return null;
    }

    for (String qId in _researchQueue) {
      if (qId.startsWith('activity:')) {
        final aId = qId.replaceFirst('activity:', '');
        final activity = ScienceService.getActivityById(aId);
        if (activity != null && activity.type == type) return activity;
      } else if (type == TaskType.research) {
        // Fallback: If we are just doing "Research", any item in the queue counts
        // We'll return null here but the caller might need to know which itemId to use.
        // Actually, let's look at how candidates are used.
      }
    }
    return null;
  }

  Map<String, int> _getMissingIngredientsForActivity(
    int npcIndex,
    ScienceActivity activity,
  ) {
    final Map<String, int> missing = {};
    final npc = _npcs[npcIndex];

    for (var entry in activity.ingredients.entries) {
      final key = entry.key;
      final needed = entry.value;

      int avail = npc.inventory
          .where((i) {
            if (key == 'meat') {
              return i.type.contains('meat') ||
                  i.category == ItemCategory.specimen;
            }
            if (key == 'specimen') {
              return i.category == ItemCategory.specimen;
            }
            if (key == 'rat_specimen') {
              return i.type == 'rat' ||
                  i.type == 'bat' ||
                  i.type == 'chicken' ||
                  i.type == 'rat_specimen';
            }
            return i.type == key;
          })
          .fold(0, (sum, i) => sum + i.quantity);

      if (avail < needed) {
        missing[key] = needed - avail;
      }
    }
    return missing;
  }

  void applyStatusEffect(String npcId, StatusEffect effect) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    var npc = _npcs[index];
    final newEffects = List<StatusEffect>.from(npc.statusEffects)..add(effect);
    final newRecords = List<String>.from(npc.records)
      ..add(
        "[${_currentDate.formattedDate}] ${effect.name}: ${effect.description}",
      );

    _npcs[index] = npc.copyWith(statusEffects: newEffects, records: newRecords);
    notifyListeners();
  }

  void triggerGuilt(String npcId, {String? source}) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    final npc = _npcs[index];
    final judgment = npc.effectiveStats['judgment'] ?? 50;

    // Threshold: Below 20 judgment, the character is too cold to feel guilt
    if (judgment < 20) return;

    final penalty = (judgment / 10).round().clamp(1, 10);

    final guiltEffect = StatusEffect(
      id: 'guilt_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Burden of Guilt',
      type: StatusEffectType.guilt,
      description:
          'The weight of recent actions affects temperament and judgment.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440 * 3, // 3 days
      attributeModifiers: {
        'temperament': -penalty,
        'judgment': -(penalty ~/ 2),
      },
      metadata: {'source': source ?? 'Unknown'},
    );

    applyStatusEffect(npcId, guiltEffect);
  }

  void triggerInsanity(String npcId, String intensity) {
    final index = _npcs.indexWhere((n) => n.id == npcId);
    if (index == -1) return;

    int percMod = 0;
    int judMod = 0;
    int intMod = 0;
    int duration = 60;
    String name = 'Nervous Tremors';

    switch (intensity) {
      case 'mild':
        percMod = -5;
        duration = 120; // 2 hours
        break;
      case 'severe_temporary':
        percMod = -20;
        judMod = -10;
        duration = 30; // 30 mins
        name = 'Acute Psychosis';
        break;
      case 'permanent':
        percMod = -10;
        judMod = -10;
        intMod = -5;
        duration = 0; // Handled by isPermanent
        name = 'Fractured Mind';
        break;
    }

    final insanityEffect = StatusEffect(
      id: 'insanity_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: StatusEffectType.insanity,
      description:
          'Exposure to forbidden knowledge or horrors has damaged the mind.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: duration > 0 ? duration : null,
      isPermanent: duration == 0,
      attributeModifiers: {
        'perception': percMod,
        'judgment': judMod,
        'intelligence': intMod,
      },
    );

    applyStatusEffect(npcId, insanityEffect);
  }

  void triggerDisease(String npcId, String diseaseName) {
    int duration = 1440 * 2; // 2 days
    int endMod = -10;
    int strMod = -10;

    final diseaseEffect = StatusEffect(
      id: 'disease_${diseaseName}_${DateTime.now().millisecondsSinceEpoch}',
      name: diseaseName,
      type: StatusEffectType.disease,
      description:
          'A foul ailment is sapping the character\'s strength and endurance.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: duration,
      attributeModifiers: {'strength': strMod, 'endurance': endMod},
      metadata: {'symptom': 'fever'},
    );

    applyStatusEffect(npcId, diseaseEffect);
  }

  void triggerLove(String npcId, String targetNpcId) {
    final targetIndex = _npcs.indexWhere((n) => n.id == targetNpcId);
    if (targetIndex == -1) return;
    final targetName = _npcs[targetIndex].name;

    final loveEffect = StatusEffect(
      id: 'love_${targetNpcId}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Enamored with $targetName',
      type: StatusEffectType.love,
      description:
          'The character is captivated by $targetName, affecting their focus and temperament.',
      startTimestamp: _currentDate.totalMinutes,
      isPermanent: true,
      attributeModifiers: {'temperament': 10, 'judgment': -5},
      metadata: {'targetId': targetNpcId},
    );

    applyStatusEffect(npcId, loveEffect);
  }

  void triggerHate(String npcId, String targetNpcId) {
    final targetIndex = _npcs.indexWhere((n) => n.id == targetNpcId);
    if (targetIndex == -1) return;
    final targetName = _npcs[targetIndex].name;

    final hateEffect = StatusEffect(
      id: 'hate_${targetNpcId}_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Resentment: $targetName',
      type: StatusEffectType.hate,
      description:
          'A deep-seated hatred for $targetName bubbles beneath the surface.',
      startTimestamp: _currentDate.totalMinutes,
      isPermanent: true,
      attributeModifiers: {'temperament': -10, 'judgment': -5},
      metadata: {'targetId': targetNpcId},
    );

    applyStatusEffect(npcId, hateEffect);
  }

  void triggerJoy(String npcId, String cause) {
    final joyEffect = StatusEffect(
      id: 'joy_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Overjoyed',
      type: StatusEffectType.joy,
      description:
          'A sense of great accomplishment ($cause) uplifts the spirit.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440, // 1 day
      attributeModifiers: {'temperament': 15, 'endurance': 5, 'strength': 5},
    );

    applyStatusEffect(npcId, joyEffect);
  }

  void triggerSadness(String npcId, String cause) {
    final sadnessEffect = StatusEffect(
      id: 'sadness_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Deep Sadness',
      type: StatusEffectType.sadness,
      description: 'A heavy sorrow ($cause) weighs on the mind and body.',
      startTimestamp: _currentDate.totalMinutes,
      durationMinutes: 1440 * 2, // 2 days
      attributeModifiers: {'temperament': -15, 'endurance': -5, 'strength': -5},
    );

    applyStatusEffect(npcId, sadnessEffect);
  }

  void _processStatusEffectsTick() {
    bool changed = false;
    for (int i = 0; i < _npcs.length; i++) {
      final npc = _npcs[i];
      if (npc.statusEffects.isEmpty) continue;

      final currentMinutes = _currentDate.totalMinutes;
      final activeEffects = npc.statusEffects
          .where((e) => !e.isExpired(currentMinutes))
          .toList();

      if (activeEffects.length != npc.statusEffects.length) {
        _npcs[i] = npc.copyWith(statusEffects: activeEffects);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _handleSurgicalCombination(int workerIndex, GameTask task) {
    // Logic for combining Rat + Bat -> Winged Rat
    final roomId = task.targetId;
    if (roomId == null) return;

    final roomIndex = _rooms.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final roomInv = List<GameItem>.from(_rooms[roomIndex].inventory);
    final ratIdx = roomInv.indexWhere((i) => i.type == 'rat_specimen');
    final batIdx = roomInv.indexWhere((i) => i.type == 'bat_specimen');

    if (ratIdx != -1 && batIdx != -1) {
      // Success! Create Winged Rat
      final worker = _npcs[workerIndex];

      // Remove specimens (careful with indices)
      roomInv.removeAt(max(ratIdx, batIdx));
      roomInv.removeAt(min(ratIdx, batIdx));

      final wingedRat = GameItem.create(
        name: 'Winged Rat',
        type: 'winged_rat_specimen',
        category: ItemCategory.specimen,
        quantity: 1,
      );
      roomInv.add(wingedRat);

      _rooms[roomIndex] = _rooms[roomIndex].copyWith(inventory: roomInv);
      _lastAnnouncement =
          "${worker.name} successfully combined the specimens into a Winged Rat!";
      _announcementHistory.insert(
        0,
        "[${_currentDate.formattedTime}] SURGERY SUCCESS: Winged Rat created.",
      );
    } else {
      _lastAnnouncement =
          "The combination failed: Missing required specimens in the room.";
    }
    notifyListeners();
  }
}

class _ResponsibilityTaskCandidate {
  final TaskType taskType;
  final ResponsibilityCategory category;
  final int stars;
  final IntentPriority priority;
  final String targetRoomId;
  final bool isAboveDivider;
  final int verticalIndex;

  _ResponsibilityTaskCandidate({
    required this.taskType,
    required this.category,
    required this.stars,
    required this.priority,
    required this.targetRoomId,
    required this.isAboveDivider,
    required this.verticalIndex,
  });
}
