enum WoundType {
  bruise,
  laceration,
  puncture,
  burn,
  fracture,
  concussion,
  amputation,
}

class Wound {
  final String id;
  final WoundType type;
  final String description;
  final int severity; // 1-10
  final DateTime timeApplied;
  bool isTreated;

  Wound({
    required this.id,
    required this.type,
    required this.description,
    required this.severity,
    required this.timeApplied,
    this.isTreated = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'description': description,
    'severity': severity,
    'timeApplied': timeApplied.toIso8601String(),
    'isTreated': isTreated,
  };

  factory Wound.fromJson(Map<String, dynamic> json) => Wound(
    id: json['id'] as String,
    type: WoundType.values[json['type'] as int],
    description: json['description'] as String,
    severity: json['severity'] as int,
    timeApplied: DateTime.parse(json['timeApplied'] as String),
    isTreated: json['isTreated'] as bool,
  );
}

enum BodyPartType {
  head,
  torso,
  rightArm,
  leftArm,
  rightLeg,
  leftLeg,
  rightEye,
  leftEye,
  rightEar,
  leftEar,
}

class BodyPart {
  final BodyPartType type;
  final double health; // 0.0-100.0
  final int maxHealth;
  final List<Wound> wounds;
  final bool isAttached;

  BodyPart({
    required this.type,
    required this.health,
    required this.maxHealth,
    this.wounds = const [],
    this.isAttached = true,
  });

  BodyPart copyWith({
    BodyPartType? type,
    double? health,
    int? maxHealth,
    List<Wound>? wounds,
    bool? isAttached,
  }) {
    return BodyPart(
      type: type ?? this.type,
      health: health ?? this.health,
      maxHealth: maxHealth ?? this.maxHealth,
      wounds: wounds ?? this.wounds,
      isAttached: isAttached ?? this.isAttached,
    );
  }

  String get name {
    switch (type) {
      case BodyPartType.head:
        return "Head";
      case BodyPartType.torso:
        return "Torso";
      case BodyPartType.rightArm:
        return "Right Arm";
      case BodyPartType.leftArm:
        return "Left Arm";
      case BodyPartType.rightLeg:
        return "Right Leg";
      case BodyPartType.leftLeg:
        return "Left Leg";
      case BodyPartType.rightEye:
        return "Right Eye";
      case BodyPartType.leftEye:
        return "Left Eye";
      case BodyPartType.rightEar:
        return "Right Ear";
      case BodyPartType.leftEar:
        return "Left Ear";
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type.index,
    'health': health,
    'maxHealth': maxHealth,
    'wounds': wounds.map((w) => w.toJson()).toList(),
    'isAttached': isAttached,
  };

  factory BodyPart.fromJson(Map<String, dynamic> json) => BodyPart(
    type: BodyPartType.values[json['type'] as int],
    health: (json['health'] as num).toDouble(),
    maxHealth: json['maxHealth'] as int,
    wounds: (json['wounds'] as List).map((w) => Wound.fromJson(w)).toList(),
    isAttached: json['isAttached'] as bool? ?? true,
  );
}
