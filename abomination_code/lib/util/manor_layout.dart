class ManorLayout {
  // Define floors from top to bottom
  // Each floor is a list of room IDs
  static final Map<int, List<String>> structure = {
    2: ['attic_1', 'attic_2'], // Top Floor
    1: [
      'master_bedroom',
      'bedroom_2',
      'bedroom_3',
      'bathroom_up',
      'study',
      'library',
    ], // Upper Floor
    0: [
      'kitchen',
      'dining_hall',
      'entryway',
      'bathroom_down',
      'unused_1f',
      'butler_quarters',
    ], // Main Floor
    -1: ['basement_1', 'basement_2', 'basement_3'],
    -2: ['basement_4', 'basement_5', 'basement_6'],
  };

  // Logical grid coordinates (x, y relative to manor center)
  // Manor width is 6 blocks (-3 to 3 range, centered at -0.5)
  static final Map<String, (double x, int floor, int layer, double width)>
  grid = {
    // Attic (Size 2)
    'attic_1': (-1.5, 2, 0, 2.0),
    'attic_2': (0.5, 2, 0, 2.0),

    // 2nd Story (Size 1)
    'master_bedroom': (-3.0, 1, 0, 1.0),
    'bedroom_2': (-2.0, 1, 0, 1.0),
    'bedroom_3': (-1.0, 1, 0, 1.0),
    'bathroom_up': (0.0, 1, 0, 1.0),
    'study': (1.0, 1, 0, 1.0),
    'library': (2.0, 1, 0, 1.0),

    // 1st Story (Size 1)
    'kitchen': (-3.0, 0, 0, 1.0),
    'dining_hall': (-2.0, 0, 0, 1.0),
    'entryway': (-1.0, 0, 0, 1.0),
    'bathroom_down': (0.0, 0, 0, 1.0),
    'unused_1f': (1.0, 0, 0, 1.0),
    'butler_quarters': (2.0, 0, 0, 1.0),

    // Basement Story 1 (Size 2) - Fills the 6-unit house width
    'basement_1': (-2.5, -1, 0, 2.0),
    'basement_2': (-0.5, -1, 0, 2.0),
    'basement_3': (1.5, -1, 0, 2.0),

    // External (Layer 1 is "surface/environs")
    'chicken_coop': (3.8, 0, 1, 1.5),
    'toolshed': (3.8, 1, 1, 1.2),
    'lot_garden': (-5.0, 1, 1, 2.0),
    'lot_building_1': (-5.0, 0, 1, 2.0),
    'vegetable_garden': (-3.0, 2, 1, 2.0),
    'field_2': (-1.0, 2, 1, 2.0),
    'field_3': (1.0, 2, 1, 2.0),
    'field_4': (3.0, 2, 1, 2.0),
    'road': (-5.0, -1, 1, 2.0),
  };

  static String getFloorName(int floor) {
    if (floor > 0) return 'Floor $floor';
    if (floor == 0) return 'Ground Floor';
    return 'Basement Level ${floor.abs()}';
  }
}
