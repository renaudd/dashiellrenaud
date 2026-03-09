import 'dish.dart';

class NPCDiet {
  final Map<DishType, int> dailyRequirements;
  final DishQuality minimumQuality;

  NPCDiet({
    required this.dailyRequirements,
    this.minimumQuality = DishQuality.decent,
  });

  factory NPCDiet.defaultDiet() {
    return NPCDiet(
      dailyRequirements: {
        DishType.cereal: 1,
        DishType.protein: 1,
        DishType.vegetable: 1,
      },
      minimumQuality: DishQuality.decent,
    );
  }

  factory NPCDiet.scientistDiet() {
    return NPCDiet(
      dailyRequirements: {
        DishType.cereal: 1,
        DishType.protein: 2,
        DishType.vegetable: 1,
        DishType.treat: 1,
      },
      minimumQuality: DishQuality.fine,
    );
  }

  Map<String, dynamic> toJson() => {
    'dailyRequirements': dailyRequirements.map(
      (k, v) => MapEntry(k.index.toString(), v),
    ),
    'minimumQuality': minimumQuality.index,
  };

  factory NPCDiet.fromJson(Map<String, dynamic> json) => NPCDiet(
    dailyRequirements: (json['dailyRequirements'] as Map).map(
      (k, v) => MapEntry(DishType.values[int.parse(k)], v as int),
    ),
    minimumQuality: DishQuality.values[json['minimumQuality'] as int],
  );
}
