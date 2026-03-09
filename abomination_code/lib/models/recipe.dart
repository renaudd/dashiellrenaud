class Recipe {
  final String id;
  final String name;
  final Map<String, int> inputs;
  final Map<String, int> outputs;
  final int requiredLevel;
  final String description;

  Recipe({
    required this.id,
    required this.name,
    required this.inputs,
    required this.outputs,
    this.requiredLevel = 1,
    required this.description,
  });

  static List<Recipe> getBrewingRecipes() {
    return [
      Recipe(
        id: 'small_beer',
        name: 'Small Beer',
        inputs: {'grain': 2},
        outputs: {'ale': 1},
        requiredLevel: 1,
        description: "A weak but safe beer for daily consumption.",
      ),
      Recipe(
        id: 'golden_ale',
        name: 'Golden Mountain Ale',
        inputs: {'grain': 4},
        outputs: {'ale': 3},
        requiredLevel: 3,
        description: "A rich, flavorful ale favored by the local cantons.",
      ),
    ];
  }

  static List<Recipe> getDistillingRecipes() {
    return [
      Recipe(
        id: 'clear_spirits',
        name: 'Clear Spirits',
        inputs: {'ale': 2},
        outputs: {'spirits': 1},
        requiredLevel: 1,
        description: "Rough spirits distilled from common ale.",
      ),
      Recipe(
        id: 'barrel_aged_brandy',
        name: 'Barrel-Aged Brandy',
        inputs: {'ale': 3, 'timber': 1},
        outputs: {'spirits': 2},
        requiredLevel: 5,
        description: "Potent brandy aged with refined timber.",
      ),
    ];
  }
}
