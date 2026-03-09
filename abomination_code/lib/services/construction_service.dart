import '../models/room.dart';

class ConstructionBlueprint {
  final String id;
  final String name;
  final RoomType type;
  final Floor floor;
  final double width;
  final Map<String, int> cost;
  final int durationMinutes;
  final String description;

  ConstructionBlueprint({
    required this.id,
    required this.name,
    required this.type,
    required this.floor,
    required this.width,
    required this.cost,
    required this.durationMinutes,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'floor': floor.index,
    'width': width,
    'cost': cost,
    'durationMinutes': durationMinutes,
    'description': description,
  };

  factory ConstructionBlueprint.fromJson(Map<String, dynamic> json) =>
      ConstructionBlueprint(
        id: json['id'],
        name: json['name'],
        type: RoomType.values[json['type']],
        floor: Floor.values[json['floor']],
        width: (json['width'] as num).toDouble(),
        cost: Map<String, int>.from(json['cost']),
        durationMinutes: json['durationMinutes'],
        description: json['description'],
      );
}

class ConstructionProject {
  final ConstructionBlueprint blueprint;
  int minutesRemaining;

  ConstructionProject({
    required this.blueprint,
    required this.minutesRemaining,
  });

  Map<String, dynamic> toJson() => {
    'blueprint': blueprint.toJson(),
    'minutesRemaining': minutesRemaining,
  };

  factory ConstructionProject.fromJson(Map<String, dynamic> json) =>
      ConstructionProject(
        blueprint: ConstructionBlueprint.fromJson(json['blueprint']),
        minutesRemaining: json['minutesRemaining'],
      );
}

class ConstructionService {
  static List<ConstructionBlueprint> getAvailableBlueprints() {
    return [
      ConstructionBlueprint(
        id: 'greenhouse',
        name: 'Greenhouse',
        type: RoomType.unused, // We can add specialized types later
        floor: Floor.ground,
        width: 1.5,
        cost: {'funds': 500, 'wood': 100},
        durationMinutes: 48 * 60,
        description: "A glass-walled room for rare botanical experiments.",
      ),
      ConstructionBlueprint(
        id: 'tenement',
        name: 'NPC Tenement',
        type: RoomType.bedroom,
        floor: Floor.ground,
        width: 2.0,
        cost: {'funds': 300, 'wood': 200},
        durationMinutes: 72 * 60,
        description: "Large-scale housing for many refugees.",
      ),
      ConstructionBlueprint(
        id: 'reinforced_lab',
        name: 'Reinforced Lab',
        type: RoomType.study,
        floor: Floor.basement,
        width: 2.0,
        cost: {'funds': 1000, 'wood': 50},
        durationMinutes: 96 * 60,
        description: "A secure, iron-lined laboratory for dangerous research.",
      ),
    ];
  }
}
