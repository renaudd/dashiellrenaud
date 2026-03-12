import '../services/task_service.dart';

enum IntentPriority {
  leisure, // Free time / Background
  normal, // Scheduled routine/work
  assignment, // Player manual drop
  desire, // Desperate wants (interpersonal, etc)
  urgent, // 4-star responsibilities
  vital, // 5-star responsibilities / Scheduled needs
  panic, // Breaking Point (extreme hunger/exhaustion) / Emergency
}

class NPCIntent {
  final String id;
  final IntentPriority priority;
  final TaskType action;
  final String? targetRoomId;
  final String? recipeId;
  final String? targetName;
  final int? startTimeMin; // Optional: Wait until this game minute
  final int expectedDurationMin;
  final int? minutesRemaining;

  NPCIntent({
    required this.id,
    required this.priority,
    required this.action,
    this.targetRoomId,
    this.recipeId,
    this.targetName,
    this.startTimeMin,
    this.expectedDurationMin = 240,
    this.minutesRemaining,
  });

  NPCIntent copyWith({
    String? id,
    IntentPriority? priority,
    TaskType? action,
    String? targetRoomId,
    String? recipeId,
    String? targetName,
    int? startTimeMin,
    int? expectedDurationMin,
    int? minutesRemaining,
  }) {
    return NPCIntent(
      id: id ?? this.id,
      priority: priority ?? this.priority,
      action: action ?? this.action,
      targetRoomId: targetRoomId ?? this.targetRoomId,
      recipeId: recipeId ?? this.recipeId,
      targetName: targetName ?? this.targetName,
      startTimeMin: startTimeMin ?? this.startTimeMin,
      expectedDurationMin: expectedDurationMin ?? this.expectedDurationMin,
      minutesRemaining: minutesRemaining ?? this.minutesRemaining,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'priority': priority.index,
    'action': action.index,
    'targetRoomId': targetRoomId,
    'recipeId': recipeId,
    'targetName': targetName,
    'startTimeMin': startTimeMin,
    'expectedDurationMin': expectedDurationMin,
    'minutesRemaining': minutesRemaining,
  };

  factory NPCIntent.fromJson(Map<String, dynamic> json) => NPCIntent(
    id: json['id'],
    priority: IntentPriority.values[json['priority']],
    action: TaskType.values[json['action']],
    targetRoomId: json['targetRoomId'],
    recipeId: json['recipeId'],
    targetName: json['targetName'],
    startTimeMin: json['startTimeMin'],
    expectedDurationMin: json['expectedDurationMin'] ?? 240,
    minutesRemaining: json['minutesRemaining'],
  );
}
