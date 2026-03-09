enum ExperimentType {
  dissection,
  lobotomy,
  reanimation,
  transmutation,
  deprivation,
  administration,
  puzzle,
  breeding,
  operation,
}

class Experiment {
  final String id;
  final ExperimentType type;
  final String subjectId;
  int minutesRemaining;
  final int totalDuration;
  bool isComplete;

  Experiment({
    required this.id,
    required this.type,
    required this.subjectId,
    required this.minutesRemaining,
    required this.totalDuration,
    this.isComplete = false,
  });

  factory Experiment.create(String subjectId, ExperimentType type) {
    int duration = 0;
    switch (type) {
      case ExperimentType.dissection:
        duration = 120; // 2 hours
        break;
      case ExperimentType.lobotomy:
        duration = 240; // 4 hours
        break;
      case ExperimentType.reanimation:
        duration = 480; // 8 hours
        break;
      case ExperimentType.transmutation:
        duration = 60; // 1 hour
        break;
      case ExperimentType.deprivation:
        duration = 1440; // 24 hours
        break;
      case ExperimentType.administration:
        duration = 60;
        break;
      case ExperimentType.puzzle:
        duration = 30;
        break;
      case ExperimentType.breeding:
        duration = 480;
        break;
      case ExperimentType.operation:
        duration = 120;
        break;
    }

    return Experiment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      subjectId: subjectId,
      minutesRemaining: duration,
      totalDuration: duration,
    );
  }

  double get progress => 1.0 - (minutesRemaining / totalDuration);

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.index,
    'subjectId': subjectId,
    'minutesRemaining': minutesRemaining,
    'totalDuration': totalDuration,
    'isComplete': isComplete,
  };

  factory Experiment.fromJson(Map<String, dynamic> json) => Experiment(
    id: json['id'] as String,
    type: ExperimentType.values[json['type'] as int],
    subjectId: json['subjectId'] as String,
    minutesRemaining: json['minutesRemaining'] as int,
    totalDuration: json['totalDuration'] as int,
    isComplete: json['isComplete'] as bool,
  );
}
