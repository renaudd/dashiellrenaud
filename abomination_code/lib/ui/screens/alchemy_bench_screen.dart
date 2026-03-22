import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';

class AlchemyBench extends StatelessWidget {
  const AlchemyBench({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'ALCHEMY BENCH',
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
            child: Column(
              children: [
                // Resource Summary
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _resourceDisplay('WOOD', state.resources['wood'] ?? 0),
                      _resourceDisplay('MEAT', state.resources['meat'] ?? 0),
                      _resourceDisplay(
                        'KNOWLEDGE',
                        state.inventory
                            .where(
                              (i) =>
                                  i.name.contains('Note') ||
                                  i.name.contains('Book'),
                            )
                            .length,
                      ),
                    ],
                  ),
                ),

                // Recipes
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALCHEMICAL FORMULAS',
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: ListView(
                            children: [
                              _buildRecipeTile(
                                context,
                                state,
                                'ALCHEMICAL FUEL',
                                'Sustains lanterns and experiments.',
                                {'wood': 2},
                                'Fuel Cell',
                              ),
                              _buildRecipeTile(
                                context,
                                state,
                                'VITA-SERUM',
                                'Heals superficial wounds on NPCs.',
                                {'meat': 1, 'wood': 1},
                                'Vita-Serum',
                              ),
                              _buildRecipeTile(
                                context,
                                state,
                                'MIND-OPENER',
                                'Increases Insight generation slightly.',
                                {'meat': 2, 'wood': 1},
                                'Mind-Opener',
                              ),
                            ],
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

  Widget _resourceDisplay(String label, num value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC4B89B),
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value.round().toString(),
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFE5D5B0),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeTile(
    BuildContext context,
    GameState state,
    String name,
    String desc,
    Map<String, num> requirements,
    String product,
  ) {
    bool canCraft = true;
    requirements.forEach((res, amount) {
      if ((state.resources[res] ?? 0).round() < amount.round()) canCraft = false;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
        color: Colors.black.withValues(alpha: 0.3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: requirements.entries
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: Text(
                              '${e.key.toUpperCase()}: ${e.value.round()}',
                              style: GoogleFonts.oldStandardTt(
                                color: (state.resources[e.key] ?? 0) >= e.value
                                    ? const Color(0xFFC4B89B)
                                    : Colors.red.withValues(alpha: 0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: canCraft
                  ? () {
                      state.craftItem(name, requirements, product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully transmuted $product!'),
                          backgroundColor: const Color(0xFF423428),
                        ),
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: canCraft ? const Color(0xFFC4B89B) : Colors.white10,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                'TRANSMUTE',
                style: GoogleFonts.playfairDisplay(
                  color: canCraft ? const Color(0xFFE5D5B0) : Colors.white12,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
