import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../widgets/resident_bar.dart';

class ResidentsPanel extends StatelessWidget {
  const ResidentsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const Color parchmentBg = Color(0xFFE5D5B0);
    const Color brassColor = Color(0xFFC4B89B);
    const Color darkWood = Color(0xFF1A1612);

    return Scaffold(
      backgroundColor: darkWood,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        title: Text(
          'MANOR LOG: RESIDENTS',
          style: GoogleFonts.playfairDisplay(
            color: brassColor,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: brassColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<GameState>(
            builder: (context, state, child) {
              final residentCount = state.npcs
                  .where((n) => n.isResident)
                  .length;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text(
                    "TOTAL OCCUPANTS: $residentCount",
                    style: GoogleFonts.oswald(
                      color: brassColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background "Journal" texture or just dark wood
          Container(color: darkWood),

          Column(
            children: [
              // Header description area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: parchmentBg.withValues(alpha: 0.1),
                  border: Border.all(color: brassColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  "DETAILED ROSTER OF ALL SPECIMENS AND STAFF CURRENTLY DOMICILED WITHIN THE MANOR. ENTRIES INCLUDE VITAL SIGNS, BEHAVIORAL INTENTS, AND COMBAT READINESS.",
                  style: GoogleFonts.oldStandardTt(
                    color: brassColor.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              Expanded(
                child: Consumer<GameState>(
                  builder: (context, state, child) {
                    final residents = state.npcs
                        .where((n) => n.isResident)
                        .toList();

                    if (residents.isEmpty) {
                      return Center(
                        child: Text(
                          "THE LOGS ARE EMPTY.",
                          style: GoogleFonts.playfairDisplay(
                            color: brassColor.withValues(alpha: 0.3),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: residents.length,
                      itemBuilder: (context, index) {
                        return ResidentBar(npc: residents[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
