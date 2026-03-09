import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/kitchen_service.dart';
import '../../services/task_service.dart';

class KitchenScreen extends StatelessWidget {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'THE KITCHEN',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE5D5B0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final basicRecipes = KitchenService.getAvailableRecipes()
              .where((r) => !r.isExperimental)
              .toList();

          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage(
                  'assets/images/Carl_Spitzweg_-_Der_Maler_im_Garten.jpg',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.9),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Row(
              children: [
                // Left Panel: Pantry & Resources
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('PANTRY INVENTORY'),
                        const SizedBox(height: 16),
                        _buildPantrySummary(state),
                        const SizedBox(height: 32),
                        _buildSectionTitle('CORE SUPPLIES'),
                        const SizedBox(height: 16),
                        _buildSuppliesGrid(state),
                        const SizedBox(height: 32),
                        _buildSectionTitle('COOKING QUEUE'),
                        const SizedBox(height: 16),
                        _buildCookingQueue(state),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Cooking & Feeding
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('HOUSEHOLD FEEDING'),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView.builder(
                            itemCount: basicRecipes.length,
                            itemBuilder: (context, index) {
                              final recipe = basicRecipes[index];
                              return _buildRecipeTile(context, state, recipe);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildPantrySummary(GameState state) {
    final dishes = state.pantry;
    if (dishes.isEmpty) {
      return Text(
        'EERILY EMPTY.',
        style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 12),
      );
    }

    // Group by name
    final counts = <String, int>{};
    for (var d in dishes) {
      counts[d.name] = (counts[d.name] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: counts.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            '${e.key.toUpperCase()} x${e.value}',
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 13,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuppliesGrid(GameState state) {
    final core = [
      'flour_spelt',
      'flour_durum',
      'meat_beef',
      'meat_chicken',
      'eggs',
      'salt',
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: core.map((key) {
        final val = state.resources[key] ?? 0;
        return Column(
          children: [
            Text(
              key.split('_').last.toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
              ),
            ),
            Text(
              val.toString(),
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFE5D5B0),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRecipeTile(
    BuildContext context,
    GameState state,
    Recipe recipe,
  ) {
    bool canCraft = true;
    recipe.ingredients.forEach((res, amount) {
      if ((state.resources[res] ?? 0) < amount) canCraft = false;
    });

    final metadata = TaskService.getMetadata(TaskType.cook);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.name.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Text(
                  metadata.typicalDuration,
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "A standard culinary preparation requiring focus and hygiene.",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INGREDIENTS',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: const Color(0xFFE5D5B0).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        children: recipe.ingredients.entries.map((e) {
                          final has = (state.resources[e.key] ?? 0) >= e.value;
                          return Text(
                            '${e.key.toUpperCase()}: ${e.value}',
                            style: GoogleFonts.oldStandardTt(
                              color: has ? const Color(0xFFC4B89B) : Colors.red,
                              fontSize: 10,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EFFICIENCY',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: const Color(0xFFE5D5B0).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        metadata.relevantAttributes.join(", ").toUpperCase(),
                        style: GoogleFonts.oldStandardTt(
                          fontSize: 10,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: canCraft
                    ? () => state.addToCookingQueue(recipe.id)
                    : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: canCraft ? const Color(0xFFC4B89B) : Colors.white10,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'COMMENCE PREPARATION',
                  style: GoogleFonts.playfairDisplay(
                    color: canCraft ? const Color(0xFFE5D5B0) : Colors.white12,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingQueue(GameState state) {
    if (state.cookingQueue.isEmpty) {
      return Text(
        'NO ORDERS.',
        style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 12),
      );
    }

    final recipes = KitchenService.getAvailableRecipes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.cookingQueue.asMap().entries.map((entry) {
        final index = entry.key;
        final recipeId = entry.value;
        final recipe = recipes.firstWhere(
          (r) => r.id == recipeId,
          orElse: () => recipes.first,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${recipe.name.toUpperCase()}',
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 14, color: Colors.white24),
                onPressed: () => state.removeFromCookingQueue(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
