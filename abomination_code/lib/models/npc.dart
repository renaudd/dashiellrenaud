import 'package:flutter/material.dart';
import 'npc_intent.dart';
import 'body_part.dart';
import 'schedule.dart';
import 'diet.dart';
import 'relationship.dart';
import 'game_item.dart';
import 'responsibility.dart';
import 'status_effect.dart';
import 'combat_stats.dart';

enum NPCStatus {
  working,
  idle,
  sleeping,
  imprisoned,
  zombie,
  dead,
  fainted,
  broken,
  panicked,
}

enum NPCDisposition { voluntary, duress, loyal }

enum SexualOrientation { straight, gay, lesbian, bisexual, asexual }

enum NPCOrgGroup { A, B, C, D } // Likelihood/Priority groups (A > B > C > D)

class ChefSkills {
  final int knifeSkills;
  final int fireSkills;
  final int sanitation;
  final int nose;

  ChefSkills({
    this.knifeSkills = 10,
    this.fireSkills = 10,
    this.sanitation = 10,
    this.nose = 10,
  });

  Map<String, int> toJson() => {
    'knifeSkills': knifeSkills,
    'fireSkills': fireSkills,
    'sanitation': sanitation,
    'nose': nose,
  };

  factory ChefSkills.fromJson(Map<String, dynamic> json) => ChefSkills(
    knifeSkills: json['knifeSkills'] as int? ?? 10,
    fireSkills: json['fireSkills'] as int? ?? 10,
    sanitation: json['sanitation'] as int? ?? 10,
    nose: json['nose'] as int? ?? 10,
  );
}

class NPCTrait {
  final String id;
  final String name;
  final String group; // character, association, skill, physical

  NPCTrait({required this.id, required this.name, required this.group});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'group': group};
  factory NPCTrait.fromJson(Map<String, dynamic> json) => NPCTrait(
    id: json['id'] as String,
    name: json['name'] as String,
    group: json['group'] as String,
  );
}

enum HairStyle { none, short, long, messy, bob, bald }

enum FacialHairStyle { none, beard, mustache, goatee, stubble }

class NPCAppearance {
  final HairStyle hairStyle;
  final FacialHairStyle facialHairStyle;
  final Color bodyColor;
  final Color hairColor;
  final Color outfitColor;
  final Color eyeColor;

  NPCAppearance({
    required this.hairStyle,
    required this.facialHairStyle,
    required this.bodyColor,
    required this.hairColor,
    required this.outfitColor,
    this.eyeColor = Colors.black,
  });

  Map<String, dynamic> toJson() => {
    'hairStyle': hairStyle.index,
    'facialHairStyle': facialHairStyle.index,
    'bodyColor': bodyColor.toARGB32(),
    'hairColor': hairColor.toARGB32(),
    'outfitColor': outfitColor.toARGB32(),
    'eyeColor': eyeColor.toARGB32(),
  };

  factory NPCAppearance.fromJson(Map<String, dynamic> json) => NPCAppearance(
    hairStyle: HairStyle.values[json['hairStyle'] as int],
    facialHairStyle: FacialHairStyle.values[json['facialHairStyle'] as int],
    bodyColor: Color(json['bodyColor'] as int),
    hairColor: Color(json['hairColor'] as int),
    outfitColor: Color(json['outfitColor'] as int),
    eyeColor: Color(json['eyeColor'] as int? ?? Colors.black.toARGB32()),
  );

  factory NPCAppearance.defaultButler() => NPCAppearance(
    hairStyle: HairStyle.short,
    facialHairStyle: FacialHairStyle.mustache,
    bodyColor: const Color(0xFFFFDBAC),
    hairColor: const Color(0xFFE8E8E8),
    outfitColor: const Color(0xFF4A5D6B), // Slate Grey/Blue (more visible)
  );

  factory NPCAppearance.random() {
    return NPCAppearance(
      hairStyle: HairStyle.short,
      facialHairStyle: FacialHairStyle.none,
      bodyColor: const Color(0xFFFFDBAC),
      hairColor: const Color(0xFF4B3621),
      outfitColor: const Color(0xFF556B2F),
    );
  }

  NPCAppearance copyWith({
    HairStyle? hairStyle,
    FacialHairStyle? facialHairStyle,
    Color? bodyColor,
    Color? hairColor,
    Color? outfitColor,
    Color? eyeColor,
  }) {
    return NPCAppearance(
      hairStyle: hairStyle ?? this.hairStyle,
      facialHairStyle: facialHairStyle ?? this.facialHairStyle,
      bodyColor: bodyColor ?? this.bodyColor,
      hairColor: hairColor ?? this.hairColor,
      outfitColor: outfitColor ?? this.outfitColor,
      eyeColor: eyeColor ?? this.eyeColor,
    );
  }
}

class NPC {
  final String id;
  final String name;
  final String role;
  final int age;
  final String gender;
  final String nationality;
  final String religion;
  final SexualOrientation sexualOrientation;
  final NPCOrgGroup group;

  final NPCStatus status;
  final NPCDisposition disposition;
  final bool isPlayer;

  // Navigation
  final String? currentRoomId;
  final String? targetRoomId;
  final double movementProgress; // 0.0 to 1.0
  final String? activeTaskId;
  final String? pendingTaskId;
  final String? currentThought;
  final String? assignedRoomId; // Dedicated housing

  final String specimenType; // 'Human', 'Rat', 'Bat', 'FlyingRat', etc.

  // Primary Stats (0-100 scale ideally)
  final Map<String, int> stats;
  // Intellect, Strength, Endurance, Temperament, Willpower, Libido, Greed, Guilt, WalkSpeed

  // Personality and Physical Attributes
  final List<NPCTrait> traits;

  // Health / Anatomy
  final List<BodyPart> bodyParts;

  // Inventory
  final List<GameItem> inventory;

  // Routines & Diet
  final NPCSchedule schedule;
  final NPCDiet diet;

  // RPG Needs (0-100 scale)
  final double energy;
  final double hunger;
  final double satisfaction;
  final double digestion;
  final int breakingPointMinutes;
  final int mentalBreakingPointMinutes;

  // Locomotion
  final List<String> movementPath;

  // Journey & Travel
  final Map<String, int> journeyInventory;
  final List<String> escortIds;
  final List<String> lastEscortIds; // Persist deck
  final String? worldDestinationId; // 'hamlet', 'manor'
  final String? worldDepartureId; // Starting point for current journey leg
  final double worldTravelProgress; // 0.0 to 1.0

  // Visuals
  final NPCAppearance appearance;
  final List<String> equippedVisuals;

  // Autonomy & Cooking
  final bool isResident;
  final int currentStateTicks;
  final ChefSkills chefStats;
  final Map<String, double> dishExperience;
  final List<NPCIntent> intentQueue;
  final int? lastScheduledHour;
  final int minutesStaying;
  final Map<ResponsibilityCategory, int> responsibilities;

  // Bio and Relationships
  final List<String> taskQueue; // IDs of enqueued tasks
  final String bio;
  final String hometown;
  final String background;
  final Map<String, Relationship> relationships;

  // Status Effects & History
  final List<StatusEffect> statusEffects;
  final List<String> records;

  // Combat
  final CombatStats? combatStats;
  final List<Ability> abilities;
  final double specialCharge; // 0.0 to 1.0
  final bool isTrained; // For creatures

  NPC({
    required this.id,
    required this.name,
    required this.role,
    required this.age,
    required this.gender,
    this.nationality = 'Swiss',
    this.religion = 'Protestant',
    this.sexualOrientation = SexualOrientation.straight,
    this.group = NPCOrgGroup.C,
    required this.specimenType,
    this.status = NPCStatus.idle,
    this.disposition = NPCDisposition.voluntary,
    this.isPlayer = false,
    this.stats = const {},
    this.traits = const [],
    required this.bodyParts,
    this.inventory = const [],
    required this.schedule,
    required this.diet,
    this.currentRoomId,
    this.targetRoomId,
    this.movementProgress = 1.0,
    this.activeTaskId,
    this.pendingTaskId,
    this.currentThought,
    this.assignedRoomId,
    this.energy = 100.0,
    this.hunger = 0.0,
    this.satisfaction = 100.0,
    this.digestion = 0.0,
    this.breakingPointMinutes = 0,
    this.mentalBreakingPointMinutes = 0,
    this.movementPath = const [],
    this.journeyInventory = const {},
    this.escortIds = const [],
    this.lastEscortIds = const [],
    this.worldDestinationId,
    this.worldDepartureId,
    this.worldTravelProgress = 0.0,
    required this.appearance,
    this.equippedVisuals = const [],
    this.isResident = true,
    this.currentStateTicks = 0,
    ChefSkills? chefStats,
    this.dishExperience = const {},
    this.intentQueue = const [],
    this.lastScheduledHour,
    this.minutesStaying = 0,
    this.taskQueue = const [],
    this.bio = '',
    this.hometown = 'Unknown',
    this.background = 'Commoner',
    this.relationships = const {},
    this.responsibilities = const {},
    this.statusEffects = const [],
    this.records = const [],
    this.combatStats,
    this.abilities = const [],
    this.specialCharge = 0.0,
    this.isTrained = false,
  }) : chefStats = chefStats ?? ChefSkills();

  Map<String, int> get effectiveStats {
    final result = Map<String, int>.from(stats);
    for (var effect in statusEffects) {
      for (var mod in effect.attributeModifiers.entries) {
        if (result.containsKey(mod.key)) {
          result[mod.key] = (result[mod.key]! + mod.value).clamp(0, 100);
        }
      }
    }
    return result;
  }

  NPC copyWith({
    String? id,
    String? name,
    String? role,
    int? age,
    String? gender,
    String? nationality,
    String? religion,
    SexualOrientation? sexualOrientation,
    NPCOrgGroup? group,
    NPCStatus? status,
    NPCDisposition? disposition,
    bool? isPlayer,
    String? currentRoomId,
    String? targetRoomId,
    double? movementProgress,
    String? activeTaskId,
    String? pendingTaskId,
    String? currentThought,
    Map<String, int>? stats,
    List<NPCTrait>? traits,
    List<BodyPart>? bodyParts,
    List<GameItem>? inventory,
    NPCSchedule? schedule,
    NPCDiet? diet,
    double? energy,
    double? hunger,
    double? satisfaction,
    double? digestion,
    int? breakingPointMinutes,
    int? mentalBreakingPointMinutes,
    List<String>? movementPath,
    Map<String, int>? journeyInventory,
    List<String>? escortIds,
    List<String>? lastEscortIds,
    String? worldDestinationId,
    String? worldDepartureId,
    double? worldTravelProgress,
    NPCAppearance? appearance,
    List<String>? equippedVisuals,
    String? assignedRoomId,
    bool? isResident,
    int? currentStateTicks,
    ChefSkills? chefStats,
    Map<String, double>? dishExperience,
    List<NPCIntent>? intentQueue,
    int? lastScheduledHour,
    int? minutesStaying,
    String? bio,
    String? hometown,
    String? background,
    String? specimenType,
    Map<String, Relationship>? relationships,
    Map<ResponsibilityCategory, int>? responsibilities,
    List<StatusEffect>? statusEffects,
    List<String>? records,
    CombatStats? combatStats,
    List<Ability>? abilities,
    double? specialCharge,
    List<String>? taskQueue,
    bool? isTrained,
    bool clearTarget = false,
    bool clearWorldDestination = false,
    bool clearThought = false,
    bool clearAssignedRoom = false,
  }) {
    return NPC(
      id: id ?? this.id,
      name: name ?? this.name,
      specimenType: specimenType ?? this.specimenType,
      role: role ?? this.role,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      nationality: nationality ?? this.nationality,
      religion: religion ?? this.religion,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      group: group ?? this.group,
      status: status ?? this.status,
      disposition: disposition ?? this.disposition,
      isPlayer: isPlayer ?? this.isPlayer,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      targetRoomId: clearTarget ? null : (targetRoomId ?? this.targetRoomId),
      movementProgress: movementProgress ?? this.movementProgress,
      activeTaskId: activeTaskId ?? this.activeTaskId,
      pendingTaskId: pendingTaskId ?? this.pendingTaskId,
      currentThought: clearThought
          ? null
          : (currentThought ?? this.currentThought),
      assignedRoomId: clearAssignedRoom
          ? null
          : (assignedRoomId ?? this.assignedRoomId),
      stats: stats ?? this.stats,
      traits: traits ?? this.traits,
      bodyParts: bodyParts ?? this.bodyParts,
      inventory: inventory ?? this.inventory,
      schedule: schedule ?? this.schedule,
      diet: diet ?? this.diet,
      energy: energy ?? this.energy,
      hunger: hunger ?? this.hunger,
      satisfaction: satisfaction ?? this.satisfaction,
      digestion: digestion ?? this.digestion,
      breakingPointMinutes: breakingPointMinutes ?? this.breakingPointMinutes,
      mentalBreakingPointMinutes:
          mentalBreakingPointMinutes ?? this.mentalBreakingPointMinutes,
      movementPath: movementPath ?? this.movementPath,
      journeyInventory: journeyInventory ?? this.journeyInventory,
      escortIds: escortIds ?? this.escortIds,
      lastEscortIds: lastEscortIds ?? this.lastEscortIds,
      worldDestinationId: clearWorldDestination
          ? null
          : (worldDestinationId ?? this.worldDestinationId),
      worldDepartureId: worldDepartureId ?? this.worldDepartureId,
      worldTravelProgress: worldTravelProgress ?? this.worldTravelProgress,
      appearance: appearance ?? this.appearance,
      equippedVisuals: equippedVisuals ?? this.equippedVisuals,
      isResident: isResident ?? this.isResident,
      currentStateTicks: currentStateTicks ?? this.currentStateTicks,
      chefStats: chefStats ?? this.chefStats,
      dishExperience: dishExperience ?? this.dishExperience,
      intentQueue: intentQueue ?? this.intentQueue,
      lastScheduledHour: lastScheduledHour ?? this.lastScheduledHour,
      minutesStaying: minutesStaying ?? this.minutesStaying,
      bio: bio ?? this.bio,
      hometown: hometown ?? this.hometown,
      background: background ?? this.background,
      relationships: relationships ?? this.relationships,
      responsibilities: responsibilities ?? this.responsibilities,
      statusEffects: statusEffects ?? this.statusEffects,
      records: records ?? this.records,
      combatStats: combatStats ?? this.combatStats,
      abilities: abilities ?? this.abilities,
      specialCharge: specialCharge ?? this.specialCharge,
      taskQueue: taskQueue ?? this.taskQueue,
      isTrained: isTrained ?? this.isTrained,
    );
  }

  factory NPC.initialButler() {
    return NPC(
      id: 'butler',
      name: 'Flaubert Giles',
      specimenType: 'Human',
      role: 'Butler',
      age: 55,
      gender: 'Male',
      sexualOrientation: SexualOrientation.straight,
      group: NPCOrgGroup.A,
      disposition: NPCDisposition.loyal,
      stats: {
        'strength': 40,
        'endurance': 50,
        'adaptability': 30,
        'dexterity': 10,
        'intelligence': 10,
        'perception': 20,
        'judgment': 30,
        'temperament': 50,
        'leadership': 30,
        'courage': 40,
        'hygiene': 50,
        'beauty': 10,
        'walkSpeed': 25,
      },
      traits: [
        NPCTrait(id: 'loyal', name: 'Loyal', group: 'character'),
        NPCTrait(id: 'hardworking', name: 'Hardworking', group: 'character'),
      ],
      bodyParts: [
        BodyPart(type: BodyPartType.head, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.torso, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftArm, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftLeg, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightEye, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftEye, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.rightEar, health: 100, maxHealth: 100),
        BodyPart(type: BodyPartType.leftEar, health: 100, maxHealth: 100),
      ],
      schedule: NPCSchedule.defaultButler(),
      diet: NPCDiet.defaultDiet(),
      currentRoomId: 'butler_quarters',
      assignedRoomId: 'butler_quarters',
      appearance: NPCAppearance.defaultButler(),
      responsibilities: {
        ResponsibilityCategory.cleaning: 3,
        ResponsibilityCategory.cooking: 2,
        ResponsibilityCategory.labor: 2,
      },
      combatStats: const CombatStats(
        attack: 25,
        health: 280,
        maxHealth: 280,
        speed: 1.8,
        movement: 0.6,
        distance: 0.3,
        defense: 0,
        accuracy: 0.8,
        cost: 3,
      ),
      abilities: [
        const Ability(
          id: 'execute_low_health',
          name: 'Execute',
          type: AbilityType.special,
          description: 'Kill enemy unit with <50% health within range.',
          chargeTime: 7.0,
          effectData: {'threshold': 0.5, 'type': 'interrupt_kill'},
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'age': age,
    'gender': gender,
    'nationality': nationality,
    'religion': religion,
    'sexualOrientation': sexualOrientation.index,
    'group': group.index,
    'status': status.index,
    'disposition': disposition.index,
    'stats': stats,
    'traits': traits.map((t) => t.toJson()).toList(),
    'bodyParts': bodyParts.map((bp) => bp.toJson()).toList(),
    'schedule': schedule.toJson(),
    'diet': diet.toJson(),
    'currentRoomId': currentRoomId,
    'targetRoomId': targetRoomId,
    'movementProgress': movementProgress,
    'isPlayer': isPlayer,
    'activeTaskId': activeTaskId,
    'pendingTaskId': pendingTaskId,
    'currentThought': currentThought,
    'energy': energy,
    'hunger': hunger,
    'satisfaction': satisfaction,
    'digestion': digestion,
    'breakingPointMinutes': breakingPointMinutes,
    'mentalBreakingPointMinutes': mentalBreakingPointMinutes,
    'movementPath': movementPath,
    'journeyInventory': journeyInventory,
    'escortIds': escortIds,
    'lastEscortIds': lastEscortIds,
    'worldDestinationId': worldDestinationId,
    'worldDepartureId': worldDepartureId,
    'worldTravelProgress': worldTravelProgress,
    'appearance': appearance.toJson(),
    'equippedVisuals': equippedVisuals,
    'assignedRoomId': assignedRoomId,
    'inventory': inventory.map((i) => i.toJson()).toList(),
    'isResident': isResident,
    'currentStateTicks': currentStateTicks,
    'chefStats': chefStats.toJson(),
    'dishExperience': dishExperience,
    'intentQueue': intentQueue.map((i) => i.toJson()).toList(),
    'lastScheduledHour': lastScheduledHour,
    'minutesStaying': minutesStaying,
    'bio': bio,
    'hometown': hometown,
    'background': background,
    'relationships': relationships.map((k, v) => MapEntry(k, v.toJson())),
    'responsibilities': responsibilities.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'statusEffects': statusEffects.map((e) => e.toJson()).toList(),
    'records': records,
    'combatStats': combatStats?.toJson(),
    'abilities': abilities.map((a) => a.toJson()).toList(),
    'specialCharge': specialCharge,
    'taskQueue': taskQueue,
    'isTrained': isTrained,
    'specimenType': specimenType,
  };

  factory NPC.fromJson(Map<String, dynamic> json) => NPC(
    id: json['id'] as String,
    name: json['name'] as String,
    role: json['role'] as String,
    age: json['age'] as int,
    gender: json['gender'] as String,
    nationality: json['nationality'] as String? ?? 'Swiss',
    religion: json['religion'] as String? ?? 'Protestant',
    sexualOrientation:
        SexualOrientation.values[json['sexualOrientation'] as int? ?? 0],
    group: NPCOrgGroup.values[json['group'] as int? ?? 2],
    specimenType: json['specimenType'] as String? ?? 'Human',
    status: NPCStatus.values[json['status'] as int],
    disposition: NPCDisposition.values[json['disposition'] as int],
    stats: Map<String, int>.from(json['stats'] as Map),
    traits: (json['traits'] as List).map((t) => NPCTrait.fromJson(t)).toList(),
    bodyParts: (json['bodyParts'] as List)
        .map((bp) => BodyPart.fromJson(bp))
        .toList(),
    schedule: NPCSchedule.fromJson(json['schedule'] as Map<String, dynamic>),
    diet: json['diet'] != null
        ? NPCDiet.fromJson(json['diet'] as Map<String, dynamic>)
        : NPCDiet.defaultDiet(),
    currentRoomId: json['currentRoomId'] as String?,
    targetRoomId: json['targetRoomId'] as String?,
    movementProgress: (json['movementProgress'] as num?)?.toDouble() ?? 1.0,
    isPlayer: json['isPlayer'] as bool? ?? false,
    activeTaskId: json['activeTaskId'] as String?,
    pendingTaskId: json['pendingTaskId'] as String?,
    currentThought: json['currentThought'] as String?,
    energy: (json['energy'] as num?)?.toDouble() ?? 100.0,
    hunger: (json['hunger'] as num?)?.toDouble() ?? 0.0,
    satisfaction: (json['satisfaction'] as num?)?.toDouble() ?? 100.0,
    digestion: (json['digestion'] as num?)?.toDouble() ?? 0.0,
    breakingPointMinutes: json['breakingPointMinutes'] as int? ?? 0,
    mentalBreakingPointMinutes: json['mentalBreakingPointMinutes'] as int? ?? 0,
    movementPath:
        (json['movementPath'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [],
    journeyInventory: Map<String, int>.from(
      json['journeyInventory'] as Map? ?? {},
    ),
    escortIds: List<String>.from(json['escortIds'] as List? ?? []),
    lastEscortIds: List<String>.from(json['lastEscortIds'] as List? ?? []),
    worldDestinationId: json['worldDestinationId'] as String?,
    worldDepartureId: json['worldDepartureId'] as String?,
    worldTravelProgress:
        (json['worldTravelProgress'] as num?)?.toDouble() ?? 0.0,
    appearance: json['appearance'] != null
        ? NPCAppearance.fromJson(json['appearance'] as Map<String, dynamic>)
        : NPCAppearance.random(),
    equippedVisuals: List<String>.from(json['equippedVisuals'] as List? ?? []),
    assignedRoomId: json['assignedRoomId'] as String?,
    inventory: (json['inventory'] as List? ?? [])
        .map((i) => GameItem.fromJson(i as Map<String, dynamic>))
        .toList(),
    isResident: json['isResident'] as bool? ?? true,
    currentStateTicks: json['currentStateTicks'] as int? ?? 0,
    chefStats: json['chefStats'] != null
        ? ChefSkills.fromJson(json['chefStats'] as Map<String, dynamic>)
        : ChefSkills(),
    dishExperience: Map<String, double>.from(
      json['dishExperience'] as Map? ?? {},
    ),
    intentQueue: (json['intentQueue'] as List? ?? [])
        .map((i) => NPCIntent.fromJson(i as Map<String, dynamic>))
        .toList(),
    lastScheduledHour: json['lastScheduledHour'] as int?,
    minutesStaying: json['minutesStaying'] as int? ?? 0,
    bio: json['bio'] as String? ?? '',
    hometown: json['hometown'] as String? ?? 'Unknown',
    background: json['background'] as String? ?? 'Commoner',
    relationships: (json['relationships'] as Map? ?? {}).map(
      (k, v) => MapEntry(
        k as String,
        Relationship.fromJson(v as Map<String, dynamic>),
      ),
    ),
    responsibilities: (json['responsibilities'] as Map? ?? {}).map(
      (k, v) => MapEntry(
        ResponsibilityCategory.values[int.parse(k as String)],
        v as int,
      ),
    ),
    statusEffects: (json['statusEffects'] as List? ?? [])
        .map((e) => StatusEffect.fromJson(e as Map<String, dynamic>))
        .toList(),
    records: List<String>.from(json['records'] as List? ?? []),
    combatStats: json['combatStats'] != null
        ? CombatStats.fromJson(json['combatStats'] as Map<String, dynamic>)
        : null,
    abilities: (json['abilities'] as List? ?? [])
        .map((a) => Ability.fromJson(a as Map<String, dynamic>))
        .toList(),
    specialCharge: (json['specialCharge'] as num? ?? 0.0).toDouble(),
    taskQueue: List<String>.from(json['taskQueue'] as List? ?? []),
    isTrained: json['isTrained'] as bool? ?? false,
  );
}
