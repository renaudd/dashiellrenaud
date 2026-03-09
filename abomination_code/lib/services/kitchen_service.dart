class Recipe {
  final String id;
  final String name;
  final Map<String, int> ingredients;
  final int yield;
  final double baseQuality;
  final int durationMinutes;
  final bool isExperimental;

  final int minKnifeSkills;
  final int minFireSkills;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    this.yield = 1,
    this.baseQuality = 1.0,
    required this.durationMinutes,
    this.isExperimental = false,
    this.minKnifeSkills = 0,
    this.minFireSkills = 0,
  });
}

class KitchenService {
  static List<Recipe> getAvailableRecipes() {
    return [
      Recipe(
        id: 'staple_bread',
        name: 'Spelt Bread',
        ingredients: {'flour_spelt': 1, 'salt': 1},
        yield: 2,
        baseQuality: 0.9,
        durationMinutes: 60,
        minKnifeSkills: 5,
        minFireSkills: 10,
      ),
      Recipe(
        id: 'durum_pasta',
        name: 'Durum Pasta',
        ingredients: {'flour_durum': 1, 'eggs': 2},
        yield: 3,
        baseQuality: 1.1,
        durationMinutes: 90,
        minKnifeSkills: 15,
        minFireSkills: 10,
      ),
      Recipe(
        id: 'bean_stew',
        name: 'Faba & Green Bean Stew',
        ingredients: {'faba_beans': 1, 'green_beans': 1, 'salt': 1},
        yield: 4,
        baseQuality: 1.0,
        durationMinutes: 45,
        minKnifeSkills: 20,
        minFireSkills: 15,
      ),
      Recipe(
        id: 'roast_chicken',
        name: 'Herbed Roast Chicken',
        ingredients: {'meat_chicken': 1, 'salt': 1, 'pepper': 1},
        yield: 4,
        baseQuality: 1.3,
        durationMinutes: 120,
        minKnifeSkills: 25,
        minFireSkills: 20,
      ),
      Recipe(
        id: 'beef_root_stew',
        name: 'Beef & Root Stew',
        ingredients: {'meat_beef': 1, 'potato': 1, 'carrots': 1, 'beets': 1},
        yield: 6,
        baseQuality: 1.4,
        durationMinutes: 150,
        minKnifeSkills: 30,
        minFireSkills: 25,
      ),
      // Experimental Recipes (Delicacies)
      Recipe(
        id: 'chocolate_delight',
        name: 'Chocolate Ganache',
        ingredients: {'chocolate': 1, 'sugar': 1, 'milk': 1},
        yield: 2,
        baseQuality: 2.5,
        durationMinutes: 60,
        isExperimental: false,
        minKnifeSkills: 40,
        minFireSkills: 30,
      ),
      Recipe(
        id: 'morning_ritual',
        name: 'Coffee Blend',
        ingredients: {'coffee': 1, 'sugar': 1},
        yield: 1,
        baseQuality: 1.8,
        durationMinutes: 10,
        isExperimental: false,
        minKnifeSkills: 10,
        minFireSkills: 15,
      ),
      Recipe(
        id: 'protein_mistery_stew',
        name: 'Stew of Unknown Protein',
        ingredients: {'meat': 1, 'potato': 1, 'salt': 1},
        yield: 4,
        baseQuality: 0.8,
        durationMinutes: 60,
        minKnifeSkills: 10,
        minFireSkills: 10,
      ),
      Recipe(
        id: 'fried_generic_meat',
        name: 'Sizzling Generic Protein',
        ingredients: {'meat': 1, 'pepper': 1},
        yield: 2,
        baseQuality: 0.9,
        durationMinutes: 30,
        minKnifeSkills: 5,
        minFireSkills: 15,
      ),
    ];
  }
}
