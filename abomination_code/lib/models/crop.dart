import 'package:uuid/uuid.dart';

enum CropType { cabbage, potato, carrot, beet, fabaBean, greenBean, grain }

class Crop {
  final String id;
  final CropType type;
  final double growthProgress; // 0.0 to 1.0
  final DateTime plantedAt;
  final int yield;
  final bool isTilled;
  final bool isWatered;
  final double moistureLevel; // 0.0 to 1.0
  final DateTime? lastCaredForAt;
  final String? roomId;

  Crop({
    required this.id,
    required this.type,
    this.growthProgress = 0.0,
    required this.plantedAt,
    this.yield = 1,
    this.isTilled = false,
    this.isWatered = false,
    this.moistureLevel = 1.0,
    this.lastCaredForAt,
    this.roomId,
  });

  bool get isHarvestable => growthProgress >= 1.0;

  Crop copyWith({
    double? growthProgress,
    int? yield,
    bool? isTilled,
    bool? isWatered,
    double? moistureLevel,
    DateTime? lastCaredForAt,
    String? roomId,
  }) {
    return Crop(
      id: id,
      type: type,
      growthProgress: growthProgress ?? this.growthProgress,
      plantedAt: plantedAt,
      yield: yield ?? this.yield,
      isTilled: isTilled ?? this.isTilled,
      isWatered: isWatered ?? this.isWatered,
      moistureLevel: moistureLevel ?? this.moistureLevel,
      lastCaredForAt: lastCaredForAt ?? this.lastCaredForAt,
      roomId: roomId ?? this.roomId,
    );
  }

  factory Crop.create(CropType type, {String? roomId}) {
    return Crop(
      id: const Uuid().v4(),
      type: type,
      plantedAt: DateTime.now(),
      roomId: roomId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'growthProgress': growthProgress,
    'plantedAt': plantedAt.toIso8601String(),
    'yield': yield,
    'isTilled': isTilled,
    'isWatered': isWatered,
    'moistureLevel': moistureLevel,
    'lastCaredForAt': lastCaredForAt?.toIso8601String(),
    'roomId': roomId,
  };

  factory Crop.fromJson(Map<String, dynamic> json) => Crop(
    id: json['id'] as String,
    type: CropType.values[json['type'] as int],
    growthProgress: (json['growthProgress'] as num).toDouble(),
    plantedAt: DateTime.parse(json['plantedAt'] as String),
    yield: json['yield'] as int,
    isTilled: json['isTilled'] as bool? ?? false,
    isWatered: json['isWatered'] as bool? ?? false,
    moistureLevel: (json['moistureLevel'] as num?)?.toDouble() ?? 1.0,
    lastCaredForAt: json['lastCaredForAt'] != null
        ? DateTime.parse(json['lastCaredForAt'] as String)
        : null,
    roomId: json['roomId'] as String?,
  );
}
