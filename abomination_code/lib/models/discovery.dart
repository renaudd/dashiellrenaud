class Discovery {
  final String id;
  final String name;
  final String description;
  final Map<String, int> requiredResearch; // {'Zoology': 2}
  final List<String> unlocks; // ['reanimation_experiment', 'muscle_graft']

  Discovery({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredResearch,
    this.unlocks = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'requiredResearch': requiredResearch,
    'unlocks': unlocks,
  };

  factory Discovery.fromJson(Map<String, dynamic> json) => Discovery(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    requiredResearch: Map<String, int>.from(json['requiredResearch'] as Map),
    unlocks: List<String>.from(json['unlocks'] as List? ?? []),
  );

  static List<Discovery> get allDiscoveries => [
    Discovery(
      id: 'basic_reanimation',
      name: 'Basic Reanimation',
      description:
          'The principles of restoring life to dead tissue using galvanism.',
      requiredResearch: {'Anatomy': 1, 'Alchemy': 1},
      unlocks: ['reanimation_experiment'],
    ),
    Discovery(
      id: 'freezing_tech',
      name: 'Cryogenic Suspension',
      description:
          'Techniques for preserving organic matter in a sub-zero state.',
      requiredResearch: {'Alchemy': 3},
      unlocks: ['cold_immunity_trait', 'ice_weapon'],
    ),
    Discovery(
      id: 'artificial_muscle',
      name: 'Artificial Muscle',
      description:
          'Synthetic fibers that mimic and exceed natural muscle strength.',
      requiredResearch: {'Anatomy': 2, 'Zoology': 2},
      unlocks: ['strength_augmentation'],
    ),
  ];
}
