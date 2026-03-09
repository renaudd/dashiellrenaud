import 'package:flutter/foundation.dart';

enum AbilityType { horn, special, trait, knell }

@immutable
class CombatStats {
  final double attack;
  final double health;
  final double maxHealth;
  final double speed; // seconds per attack
  final double movement; // meters per second
  final double distance; // attack range
  final double defense;
  final double accuracy;
  final int cost; // AP cost to summon
  final bool isFlying;
  final int swarmSize; // 0 if single unit, >0 for swarms
  final double radius; // Physics radius for collision

  const CombatStats({
    required this.attack,
    required this.health,
    required this.maxHealth,
    required this.speed,
    required this.movement,
    required this.distance,
    this.defense = 0,
    required this.accuracy,
    required this.cost,
    this.isFlying = false,
    this.swarmSize = 0,
    this.radius = 1.5,
  });

  CombatStats copyWith({
    double? attack,
    double? health,
    double? maxHealth,
    double? speed,
    double? movement,
    double? distance,
    double? defense,
    double? accuracy,
    int? cost,
    bool? isFlying,
    int? swarmSize,
    double? radius,
  }) {
    return CombatStats(
      attack: attack ?? this.attack,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      speed: speed ?? this.speed,
      movement: movement ?? this.movement,
      distance: distance ?? this.distance,
      defense: defense ?? this.defense,
      accuracy: accuracy ?? this.accuracy,
      cost: cost ?? this.cost,
      isFlying: isFlying ?? this.isFlying,
      swarmSize: swarmSize ?? this.swarmSize,
      radius: radius ?? this.radius,
    );
  }

  Map<String, dynamic> toJson() => {
    'attack': attack,
    'health': health,
    'maxHealth': maxHealth,
    'speed': speed,
    'movement': movement,
    'distance': distance,
    'defense': defense,
    'accuracy': accuracy,
    'cost': cost,
    'isFlying': isFlying,
    'swarmSize': swarmSize,
    'radius': radius,
  };

  factory CombatStats.fromJson(Map<String, dynamic> json) => CombatStats(
    attack: (json['attack'] as num).toDouble(),
    health: (json['health'] as num).toDouble(),
    maxHealth: (json['maxHealth'] as num).toDouble(),
    speed: (json['speed'] as num).toDouble(),
    movement: (json['movement'] as num).toDouble(),
    distance: (json['distance'] as num).toDouble(),
    defense: (json['defense'] as num? ?? 0).toDouble(),
    accuracy: (json['accuracy'] as num).toDouble(),
    cost: json['cost'] as int,
    isFlying: json['isFlying'] as bool? ?? false,
    swarmSize: json['swarmSize'] as int? ?? 0,
    radius: (json['radius'] as num? ?? 1.5).toDouble(),
  );
}

@immutable
class Ability {
  final String id;
  final String name;
  final AbilityType type;
  final String description;
  final double? chargeTime; // For special attacks
  final Map<String, dynamic> effectData;

  const Ability({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    this.chargeTime,
    this.effectData = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'description': description,
    'chargeTime': chargeTime,
    'effectData': effectData,
  };

  factory Ability.fromJson(Map<String, dynamic> json) => Ability(
    id: json['id'] as String,
    name: json['name'] as String,
    type: AbilityType.values.byName(json['type'] as String),
    description: json['description'] as String,
    chargeTime: (json['chargeTime'] as num?)?.toDouble(),
    effectData: json['effectData'] as Map<String, dynamic>? ?? {},
  );
}
