class FoxPopulation {
  final int currentCount;
  final DateTime lastMigrationDate;

  const FoxPopulation({
    required this.currentCount,
    required this.lastMigrationDate,
  });

  bool get isWipedOut => currentCount <= 0;

  FoxPopulation copyWith({int? currentCount, DateTime? lastMigrationDate}) {
    return FoxPopulation(
      currentCount: currentCount ?? this.currentCount,
      lastMigrationDate: lastMigrationDate ?? this.lastMigrationDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentCount': currentCount,
    'lastMigrationDate': lastMigrationDate.toIso8601String(),
  };

  factory FoxPopulation.fromJson(Map<String, dynamic> json) => FoxPopulation(
    currentCount: json['currentCount'] as int,
    lastMigrationDate: DateTime.parse(json['lastMigrationDate'] as String),
  );

  factory FoxPopulation.initial() => FoxPopulation(
    currentCount: 5, // Start with a small population
    lastMigrationDate: DateTime.now(),
  );
}
