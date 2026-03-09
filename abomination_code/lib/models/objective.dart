enum ObjectiveType { tutorial, story, science, combat }

class Objective {
  final String id;
  final String title;
  final String description;
  final ObjectiveType type;
  bool isCompleted;
  final Map<String, dynamic> requirements;
  final String? nextObjectiveId;

  Objective({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.isCompleted = false,
    this.requirements = const {},
    this.nextObjectiveId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.index,
    'isCompleted': isCompleted,
    'requirements': requirements,
    'nextObjectiveId': nextObjectiveId,
  };

  factory Objective.fromJson(Map<String, dynamic> json) => Objective(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    type: ObjectiveType.values[json['type'] as int],
    isCompleted: json['isCompleted'] as bool,
    requirements: json['requirements'] as Map<String, dynamic>? ?? {},
    nextObjectiveId: json['nextObjectiveId'] as String?,
  );
}
