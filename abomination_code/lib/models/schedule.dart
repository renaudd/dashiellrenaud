import '../services/task_service.dart';

enum ScheduleActivity {
  sleep,
  eat,
  work,
  leisure,
  prayer,
  study,
  guardCoop,
  cleanRoom,
  cook;

  bool get isStretchable {
    switch (this) {
      case ScheduleActivity.sleep:
      case ScheduleActivity.guardCoop:
      case ScheduleActivity.leisure:
      case ScheduleActivity.work:
      case ScheduleActivity.study:
      case ScheduleActivity.prayer:
        return true;
      default:
        return false;
    }
  }

  int get minDurationHours {
    switch (this) {
      case ScheduleActivity.cleanRoom:
      case ScheduleActivity.eat:
      case ScheduleActivity.cook:
      case ScheduleActivity.prayer:
        return 1;
      default:
        return 2;
    }
  }

  int get defaultDurationHours {
    switch (this) {
      case ScheduleActivity.cleanRoom:
      case ScheduleActivity.eat:
      case ScheduleActivity.cook:
        return 1;
      case ScheduleActivity.sleep:
        return 8;
      case ScheduleActivity.guardCoop:
        return 4;
      default:
        return 2;
    }
  }

  bool get isImplemented {
    return true; // Simple approach: anything scheduled is now valid for navigation
  }
}

class ScheduleBlock {
  final int hourIndex; // 0-167 (7 days * 24 hours)
  final ScheduleActivity activity;
  final String? preferredRoomId;
  final TaskType? manualTaskType;
  final String? manualTargetId;

  ScheduleBlock({
    required this.hourIndex,
    required this.activity,
    this.preferredRoomId,
    this.manualTaskType,
    this.manualTargetId,
  });

  int get hourOfDay => hourIndex % 24;
  int get dayOfWeek => hourIndex ~/ 24;

  Map<String, dynamic> toJson() => {
    'hourIndex': hourIndex,
    'activity': activity.index,
    'preferredRoomId': preferredRoomId,
    'manualTaskType': manualTaskType?.index,
    'manualTargetId': manualTargetId,
  };

  factory ScheduleBlock.fromJson(Map<String, dynamic> json) => ScheduleBlock(
    hourIndex: json['hourIndex'] ?? json['hour'] as int, // Migration support
    activity: ScheduleActivity.values[json['activity'] as int],
    preferredRoomId: json['preferredRoomId'] as String?,
    manualTaskType: json['manualTaskType'] != null
        ? TaskType.values[json['manualTaskType'] as int]
        : null,
    manualTargetId: json['manualTargetId'] as String?,
  );
}

class NPCSchedule {
  final List<ScheduleBlock> blocks;

  NPCSchedule({required this.blocks});

  ScheduleActivity getActivityForHour(int hourIndex) {
    return blocks.firstWhere((b) => b.hourIndex == hourIndex).activity;
  }

  String? getPreferredRoomForHour(int hourIndex) {
    return blocks.firstWhere((b) => b.hourIndex == hourIndex).preferredRoomId;
  }

  ScheduleBlock getBlock(int hourIndex) {
    return blocks.firstWhere((b) => b.hourIndex == hourIndex);
  }

  Map<String, dynamic> toJson() => {
    'blocks': blocks.map((b) => b.toJson()).toList(),
  };

  factory NPCSchedule.fromJson(Map<String, dynamic> json) => NPCSchedule(
    blocks: (json['blocks'] as List)
        .map((b) => ScheduleBlock.fromJson(b))
        .toList(),
  );

  factory NPCSchedule.defaultButler() {
    final blocks = <ScheduleBlock>[];
    for (int i = 0; i < 168; i++) {
      final hourOfDay = i % 24;
      if (hourOfDay >= 23 || hourOfDay < 6) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.sleep,
            preferredRoomId: 'butler_quarters',
          ),
        );
      } else if (hourOfDay == 7 || hourOfDay == 12 || hourOfDay == 18) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.eat,
            preferredRoomId: 'kitchen',
          ),
        );
      } else if ((hourOfDay >= 8 && hourOfDay < 12) ||
          (hourOfDay >= 13 && hourOfDay < 18)) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.work,
            preferredRoomId: 'entryway',
          ),
        );
      } else {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.leisure,
            preferredRoomId: 'entryway',
          ),
        );
      }
    }
    return NPCSchedule(blocks: blocks);
  }

  factory NPCSchedule.defaultScientist() {
    final blocks = <ScheduleBlock>[];
    for (int i = 0; i < 168; i++) {
      final hourOfDay = i % 24;
      if (hourOfDay >= 0 && hourOfDay < 7) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.sleep,
            preferredRoomId: 'master_bedroom',
          ),
        );
      } else if (hourOfDay == 8 || hourOfDay == 13 || hourOfDay == 19) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.eat,
            preferredRoomId: 'dining_hall',
          ),
        );
      } else if ((hourOfDay >= 9 && hourOfDay < 13) ||
          (hourOfDay >= 14 && hourOfDay < 19)) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.work,
            preferredRoomId: 'study',
          ),
        );
      } else {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.leisure,
            preferredRoomId: 'study',
          ),
        );
      }
    }
    return NPCSchedule(blocks: blocks);
  }

  factory NPCSchedule.visitor() {
    final blocks = <ScheduleBlock>[];
    for (int i = 0; i < 168; i++) {
      blocks.add(
        ScheduleBlock(
          hourIndex: i,
          activity: ScheduleActivity.leisure,
          preferredRoomId: 'entryway',
        ),
      );
    }
    return NPCSchedule(blocks: blocks);
  }

  factory NPCSchedule.defaultWorker() {
    final blocks = <ScheduleBlock>[];
    for (int i = 0; i < 168; i++) {
      final hourOfDay = i % 24;
      if (hourOfDay >= 22 || hourOfDay < 6) {
        blocks.add(
          ScheduleBlock(hourIndex: i, activity: ScheduleActivity.sleep),
        );
      } else if (hourOfDay == 7 || hourOfDay == 12 || hourOfDay == 18) {
        blocks.add(
          ScheduleBlock(
            hourIndex: i,
            activity: ScheduleActivity.eat,
            preferredRoomId: 'kitchen',
          ),
        );
      } else if ((hourOfDay >= 8 && hourOfDay < 12) ||
          (hourOfDay >= 13 && hourOfDay < 17)) {
        blocks.add(
          ScheduleBlock(hourIndex: i, activity: ScheduleActivity.work),
        );
      } else {
        blocks.add(
          ScheduleBlock(hourIndex: i, activity: ScheduleActivity.leisure),
        );
      }
    }
    return NPCSchedule(blocks: blocks);
  }
}
