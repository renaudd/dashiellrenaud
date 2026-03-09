import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/chicken.dart';

class ChickenCoopScreen extends StatelessWidget {
  const ChickenCoopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A15),
      appBar: AppBar(
        title: Text(
          'THE CHICKEN COOP',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        elevation: 0,
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          return Column(
            children: [
              _buildFoxThreatBanner(state),
              _buildPurchaseSection(context, state),
              const Divider(color: Colors.white10, height: 1),
              Expanded(child: _buildChickenList(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFoxThreatBanner(GameState state) {
    final foxPop = state.estateFoxes;
    final isWipedOut = foxPop.isWipedOut;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: isWipedOut
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            isWipedOut ? Icons.shield : Icons.warning_amber,
            color: isWipedOut ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWipedOut ? "COOP SECURE" : "PREDATOR ALERT",
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    color: isWipedOut ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                Text(
                  isWipedOut
                      ? "The local fox population has been decimated. No raids expected."
                      : "A pack of ${foxPop.currentCount} foxes is active in the woods. Night guards recommended.",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PURCHASE LIVESTOCK",
            style: GoogleFonts.playfairDisplay(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: const Color(0xFFC4B89B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: ChickenBreed.breeds.map((breed) {
              final canAfford =
                  (state.resources['funds'] ?? 0) >= breed.basePrice;
              return Expanded(
                child: Card(
                  color: Colors.black26,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: canAfford
                        ? () => state.buyChicken(breed.type)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            breed.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color(0xFFE5D5B0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${breed.basePrice}F",
                            style: GoogleFonts.oldStandardTt(
                              color: canAfford
                                  ? Colors.amberAccent
                                  : Colors.white10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _breedStat("Eggs", breed.eggRate.toString()),
                          _breedStat("Meat", "${breed.meatYield}kg"),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _breedStat(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white24),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildChickenList(BuildContext context, GameState state) {
    if (state.chickens.isEmpty) {
      return Center(
        child: Text(
          "The coop is currently empty.",
          style: GoogleFonts.oldStandardTt(
            color: Colors.white10,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.chickens.length,
      itemBuilder: (context, index) {
        final chicken = state.chickens[index];
        final breed = chicken.breed;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            color: chicken.isMarkedForButchery
                ? Colors.red.withValues(alpha: 0.05)
                : Colors.black12,
          ),
          child: Row(
            children: [
              const Icon(Icons.egg, color: Color(0xFFC4B89B), size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${breed.name} Chicken",
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                    Text(
                      chicken.isMature
                          ? "Mature"
                          : "Growing (${(chicken.ageMinutes / breed.growthRate * 100).toInt()}%)",
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 11,
                        color: Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "MARK FOR BUTCHERY",
                    style: GoogleFonts.oldStandardTt(
                      fontSize: 9,
                      color: Colors.white24,
                    ),
                  ),
                  Switch(
                    value: chicken.isMarkedForButchery,
                    onChanged: (val) => state.toggleChickenButchery(chicken.id),
                    activeThumbColor: Colors.redAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
