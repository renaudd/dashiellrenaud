enum DishQuality {
  exquisite,
  delectable,
  sophisticated,
  fine,
  decent,
  alright,
  notBad,
  notGreat,
  mediocre,
  weak,
  awful,
  disgusting,
}

enum DishType { cereal, protein, vegetable, treat }

class Dish {
  final String id;
  final String name;
  final DishType type;
  final DishQuality quality;
  final DateTime cookedAt;
  final int shelfLifeHours;
  final double illnessRisk; // 0.0 to 1.0

  Dish({
    required this.id,
    required this.name,
    required this.type,
    required this.quality,
    required this.cookedAt,
    this.shelfLifeHours = 48,
    this.illnessRisk = 0.0,
  });

  bool isSpoiled(DateTime currentTime) {
    return currentTime.difference(cookedAt).inHours > shelfLifeHours;
  }

  double getCurrentIllnessRisk(DateTime currentTime) {
    if (!isSpoiled(currentTime)) return illnessRisk;
    // Risk increases dramatically after spoilage
    final hoursPast = currentTime.difference(cookedAt).inHours - shelfLifeHours;
    return (illnessRisk + (hoursPast * 0.05)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'quality': quality.index,
    'cookedAt': cookedAt.toIso8601String(),
    'shelfLifeHours': shelfLifeHours,
    'illnessRisk': illnessRisk,
  };

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
    id: json['id'],
    name: json['name'],
    type: DishType.values[json['type']],
    quality: DishQuality.values[json['quality']],
    cookedAt: DateTime.parse(json['cookedAt']),
    shelfLifeHours: json['shelfLifeHours'],
    illnessRisk: json['illnessRisk'],
  );
}
