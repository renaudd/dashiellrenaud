import 'task_service.dart';

class ScienceActivity {
  final String id;
  final String name;
  final TaskType type;
  final Map<String, num> ingredients;
  final int baseDurationMinutes;
  final String discipline;
  final double moralCost; // 0.0 to 1.0 (Guilt increase)
  final String outcomeDescription;

  ScienceActivity({
    required this.id,
    required this.name,
    required this.type,
    required this.ingredients,
    required this.baseDurationMinutes,
    required this.discipline,
    this.moralCost = 0.0,
    required this.outcomeDescription,
  });
}

class ScienceService {
  static List<ScienceActivity> getAvailableActivities() {
    return [
      ScienceActivity(
        id: 'generic_research',
        name: 'Fundamental Research',
        type: TaskType.research,
        ingredients: {'unreviewed_document': 1},
        baseDurationMinutes: 15, // Adjusted per item if possible
        discipline: 'General',
        outcomeDescription:
            'Produces research notes and advances personal knowledge.',
      ),
      ScienceActivity(
        id: 'small_dissection',
        name: 'Small Specimen Dissection',
        type: TaskType.dissect,
        ingredients: {'rat_specimen': 1},
        baseDurationMinutes: 20,
        discipline: 'Anatomy',
        outcomeDescription:
            'Produces 1-15 pages of life science knowledge and poor quality meat.',
      ),
      ScienceActivity(
        id: 'large_dissection',
        name: 'Large Specimen Dissection',
        type: TaskType.dissect,
        ingredients: {'captive_human': 1}, // Example
        baseDurationMinutes: 90,
        discipline: 'Anatomy',
        outcomeDescription:
            'Produces significant life science knowledge and meat.',
      ),
      ScienceActivity(
        id: 'small_vivisection',
        name: 'Small Specimen Vivisection',
        type: TaskType.vivisection,
        ingredients: {'rat_specimen': 1},
        baseDurationMinutes: 45,
        discipline: 'Anatomy',
        moralCost: 0.2,
        outcomeDescription:
            'Produces 5-20 pages of life science knowledge and mediocre meat. Highly corrupting.',
      ),
      ScienceActivity(
        id: 'large_vivisection',
        name: 'Large Specimen Vivisection',
        type: TaskType.vivisection,
        ingredients: {'captive_human': 1},
        baseDurationMinutes: 150,
        discipline: 'Anatomy',
        moralCost: 0.5,
        outcomeDescription:
            'Produces vast life science knowledge and meat. Extremely corrupting.',
      ),
      ScienceActivity(
        id: 'puzzle_study',
        name: 'Cognitive Puzzle Study',
        type: TaskType.puzzleStudy,
        ingredients: {'rat_specimen': 5, 'meals': 1},
        baseDurationMinutes: 960, // 16 hours
        discipline: 'Psychology',
        outcomeDescription:
            'Produces psychology notes and some anatomy knowledge.',
      ),
      ScienceActivity(
        id: 'deprivation_study',
        name: 'Sensory Deprivation Study',
        type: TaskType.deprivationStudy,
        ingredients: {'rat_specimen': 5},
        baseDurationMinutes: 2400, // 40 hours
        discipline: 'Zoology',
        moralCost: 0.4,
        outcomeDescription:
            'Produces zoology notes. High mortality rate for subjects.',
      ),
      ScienceActivity(
        id: 'clinical_trial',
        name: 'General Clinical Trial',
        type: TaskType.clinicalTrial,
        ingredients: {'rat_specimen': 10, 'herb_reagent': 1, 'meals': 5},
        baseDurationMinutes: 7200, // 120 hours
        discipline: 'Medicine',
        moralCost: 0.1,
        outcomeDescription:
            'Produces notes in the medicine discipline and zoology.',
      ),
    ];
  }

  static ScienceActivity? getActivityById(String id) {
    try {
      return getAvailableActivities().firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
