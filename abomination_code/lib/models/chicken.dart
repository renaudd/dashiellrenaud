import 'package:uuid/uuid.dart';
import 'game_date.dart';

enum ChickenBreedType { houdan, dorking, scotsDumpie }

class ChickenBreed {
  final ChickenBreedType type;
  final String name;
  final String description;
  final double eggRate; // Average eggs per week
  final double growthRate; // Minutes to maturity
  final int meatYield; // Kilograms of meat
  final int basePrice;

  const ChickenBreed({
    required this.type,
    required this.name,
    required this.description,
    required this.eggRate,
    required this.growthRate,
    required this.meatYield,
    required this.basePrice,
  });

  static const List<ChickenBreed> breeds = [
    ChickenBreed(
      type: ChickenBreedType.houdan,
      name: 'Houdan',
      description:
          'French heritage breed known for excellent egg production and dual-purpose utility.',
      eggRate: 1.2, // Approx 8-9 eggs a week
      growthRate: 4800, // 80 hours to maturity
      meatYield: 2,
      basePrice: 15,
    ),
    ChickenBreed(
      type: ChickenBreedType.dorking,
      name: 'Dorking',
      description:
          'Ancient breed prized for its large size and superior meat quality.',
      eggRate: 0.8,
      growthRate: 6000, // 100 hours
      meatYield: 4,
      basePrice: 20,
    ),
    ChickenBreed(
      type: ChickenBreedType.scotsDumpie,
      name: 'Scots Dumpie',
      description:
          'Hardy, short-legged breed from Scotland. Excellent foragers and mothers.',
      eggRate: 1.0,
      growthRate: 3600, // 60 hours
      meatYield: 1,
      basePrice: 12,
    ),
  ];

  static ChickenBreed getByTyped(ChickenBreedType type) =>
      breeds.firstWhere((b) => b.type == type);
}

class Chicken {
  final String id;
  final ChickenBreedType breedType;
  final double ageMinutes;
  final bool isMarkedForButchery;
  final double hunger; // 0-100
  final GameDate lastEggDate;
  final bool isMale;
  final bool
  isFertilized; // Only for eggs if we had an Egg model, but currently tracked on hen for simplicity or we might need an Egg object later. Actually, the user said "eggs might be fertilized". I'll add isMale to Chicken and we can check for roosters in the coop.

  Chicken({
    required this.id,
    required this.breedType,
    this.ageMinutes = 0,
    this.isMarkedForButchery = false,
    this.hunger = 0,
    required this.lastEggDate,
    this.isMale = false,
    this.isFertilized = false,
  });

  bool get isMature => ageMinutes >= breed.growthRate;
  ChickenBreed get breed => ChickenBreed.getByTyped(breedType);

  Chicken copyWith({
    double? ageMinutes,
    bool? isMarkedForButchery,
    double? hunger,
    GameDate? lastEggDate,
    bool? isMale,
    bool? isFertilized,
  }) {
    return Chicken(
      id: id,
      breedType: breedType,
      ageMinutes: ageMinutes ?? this.ageMinutes,
      isMarkedForButchery: isMarkedForButchery ?? this.isMarkedForButchery,
      hunger: hunger ?? this.hunger,
      lastEggDate: lastEggDate ?? this.lastEggDate,
      isMale: isMale ?? this.isMale,
      isFertilized: isFertilized ?? this.isFertilized,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'breedType': breedType.index,
    'ageMinutes': ageMinutes,
    'isMarkedForButchery': isMarkedForButchery,
    'hunger': hunger,
    'lastEggDate': lastEggDate.toJson(),
    'isMale': isMale,
    'isFertilized': isFertilized,
  };

  factory Chicken.fromJson(Map<String, dynamic> json) => Chicken(
    id: json['id'] as String,
    breedType: ChickenBreedType.values[json['breedType'] as int],
    ageMinutes: (json['ageMinutes'] as num).toDouble(),
    isMarkedForButchery: json['isMarkedForButchery'] as bool,
    hunger: (json['hunger'] as num).toDouble(),
    lastEggDate: GameDate.fromJson(json['lastEggDate'] as Map<String, dynamic>),
    isMale: json['isMale'] as bool? ?? false,
    isFertilized: json['isFertilized'] as bool? ?? false,
  );

  factory Chicken.create(
    ChickenBreedType type,
    GameDate currentDate, {
    bool isMale = false,
  }) => Chicken(
    id: const Uuid().v4(),
    breedType: type,
    lastEggDate: currentDate,
    isMale: isMale,
  );
}
