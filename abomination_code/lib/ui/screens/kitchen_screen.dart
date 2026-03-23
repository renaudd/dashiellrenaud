import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/kitchen_service.dart';
import '../../services/task_service.dart';
import '../../models/room.dart';
import '../widgets/room_ledger.dart';

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
          final hasGoodMeat = (state.resources['meat_chicken'] ?? 0) > 0 || (state.resources['meat_beef'] ?? 0) > 0;
          
          final basicRecipes = KitchenService.getAvailableRecipes()
              .where((r) => !r.isExperimental)
              .where((r) {
                  if (hasGoodMeat && (r.id == 'protein_mistery_stew' || r.id == 'fried_generic_meat')) {
                      return false;
                  }
                  return true;
              })
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
                        _buildSectionTitle('KITCHEN LEDGER'),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: RoomLedger(
                              room: state.rooms.firstWhere((r) => r.type == RoomType.kitchen),
                              state: state,
                            ),
                          ),
                        ),
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

  Widget _buildRecipeTile(
    BuildContext context,
    GameState state,
    Recipe recipe,
  ) {
    bool canCraft = true;
    recipe.ingredients.forEach((res, amount) {
      num available = (state.resources[res] ?? 0);
      if (res == 'meat') {
          available += (state.resources['meat_chicken'] ?? 0) + (state.resources['meat_beef'] ?? 0);
      }
      if (available.round() < amount.round()) canCraft = false;
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
              recipe.id == 'butcher_generic'
                  ? "Select a creature or resident to yield meat and resources."
                  : "A standard culinary preparation requiring focus and hygiene.",
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
                          num available = (state.resources[e.key] ?? 0);
                          if (e.key == 'meat') {
                              available += (state.resources['meat_chicken'] ?? 0) + (state.resources['meat_beef'] ?? 0);
                          }
                          final has = available.round() >= e.value.round();
                          return Text(
                            '${e.key.toUpperCase()}: ${e.value.round()}',
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
                    ? () {
                        if (recipe.id == 'butcher_generic') {
                          _showButcherTargetDialog(context, state);
                        } else {
                          state.addToCookingQueue(recipe.id);
                        }
                      }
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
        String displayName;

        if (recipeId.startsWith('butcher_generic:')) {
          final parts = recipeId.split(':');
          displayName = "BUTCHER: ${parts[2].toUpperCase()}";
        } else {
          final baseId = recipeId.split(':').first;
          final recipe = recipes.firstWhere(
            (r) => r.id == baseId,
            orElse: () => recipes.first,
          );
          displayName = recipe.name.toUpperCase();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. $displayName',
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

  void _showButcherTargetDialog(BuildContext context, GameState state) {
    showDialog(
      context: context,
      builder: (context) {
        final targets = state.butcheryTargets;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1612),
          title: Text(
            'SELECT BUTCHERY TARGET',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: targets.isEmpty
                ? Text(
                    'NO VIABLE TARGETS FOUND.',
                    style: GoogleFonts.oldStandardTt(color: Colors.white24),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: targets.length,
                    itemBuilder: (context, index) {
                      final target = targets[index];
                      return ListTile(
                        title: Text(
                          target['name']!.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFC4B89B),
                            fontSize: 13,
                          ),
                        ),
                        onTap: () {
                          state.addToCookingQueue(
                            'butcher_generic',
                            targetId: target['id'],
                            targetName: target['name'],
                          );
                          Navigator.pop(context);
                        },
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Color(0xFFE5D5B0),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ABANDON',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.red.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
