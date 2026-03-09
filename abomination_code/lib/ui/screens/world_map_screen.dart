import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../widgets/location_tile.dart';
import '../widgets/prepare_journey_dialog.dart';
import 'hamlet_screen.dart';
import 'destination_screen.dart';
import 'regional_map_screen.dart';
import '../widgets/time_speed_controls.dart';
import 'combat_screen.dart';
import '../../models/npc.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  void _checkNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<GameState>();
      final destination = state.pendingNavigationTarget;

      if (destination != null) {
        state.clearPendingNavigation();
        if (destination == 'manor') {
          if (mounted) Navigator.pop(context);
        } else if (destination == 'hamlet') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HamletScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DestinationScreen(destinationId: destination),
            ),
          );
        }
      } else if (state.pendingCombatEncounter) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CombatScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes to trigger navigation
    context.watch<GameState>();
    _checkNavigation();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'SURVEY ESTATE',
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
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF241F1A),
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
        child: Stack(
          children: [
            // Parchment Overlay Effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5D5B0).withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Map Content (Strategic Layout)
            Center(
              child: AspectRatio(
                aspectRatio: 0.8,
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Stack(
                    children: [
                      // River (Visual Representation)
                      Positioned(
                        top: 100,
                        right: 0,
                        bottom: 0,
                        width: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.1),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Locations
                      Positioned(
                        top: 20,
                        left: 40,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'mountains' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'NORTHERN MOUNTAINS',
                              icon: Icons.terrain,
                              description: someoneThere
                                  ? 'Representative surveying the peaks.'
                                  : 'Unexplored peaks and potential mining sites.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'mountains'),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        top: 200,
                        left: 100,
                        child: LocationTile(
                          name: 'THE MANOR',
                          icon: Icons.castle,
                          description: 'Your inherited estate and laboratory.',
                          isCurrent: true,
                          onTap: () => Navigator.pop(context),
                        ),
                      ),

                      Positioned(
                        top: 350,
                        left: 30,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'hamlet' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'HAMLET',
                              icon: Icons.location_city,
                              description: someoneThere
                                  ? 'Your representative is in town.'
                                  : 'A sleepy border town. Send someone to trade.',
                              isCurrent: someoneThere,
                              onTap: () {
                                if (someoneThere) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const HamletScreen(),
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        const PrepareJourneyDialog(
                                          destinationId: 'hamlet',
                                        ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),

                      // Traveling NPC Icons
                      ..._buildTravelingNpcs(context),

                      Positioned(
                        top: 220,
                        right: 60,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'woods' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'ANCIENT WOODS',
                              icon: Icons.forest,
                              description: someoneThere
                                  ? 'Representative gathering intel in the woods.'
                                  : 'Bountiful wood, but scarce game due to the war.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'woods'),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 50,
                        right: 20,
                        child: Consumer<GameState>(
                          builder: (context, state, child) {
                            final someoneThere = state.npcs.any(
                              (n) =>
                                  n.worldDestinationId == 'river' &&
                                  n.worldTravelProgress >= 1.0,
                            );
                            return LocationTile(
                              name: 'RIVER ACCESS',
                              icon: Icons.water,
                              description: someoneThere
                                  ? 'Representative watching the river.'
                                  : 'River access. Leads to the city and beyond.',
                              isCurrent: someoneThere,
                              onTap: () =>
                                  _showPrepareJourney(context, 'river'),
                            );
                          },
                        ),
                      ),

                      Positioned(
                        bottom: 120,
                        right: -20,
                        child: LocationTile(
                          name: 'ROAD TO ROLLE',
                          icon: Icons.map_outlined,
                          description:
                              'Zoom out to view the regional geography.',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegionalMapScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Map Legend/Footer
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Column(
                  children: [
                    const TimeSpeedControls(),
                    const Divider(color: Colors.white10),
                    Text(
                      'CANTON OF VAUD, NEUTRAL SWITZERLAND - 1860',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrepareJourney(BuildContext context, String destinationId) {
    showDialog(
      context: context,
      builder: (context) => PrepareJourneyDialog(destinationId: destinationId),
    );
  }

  List<Widget> _buildTravelingNpcs(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final travelingNpcs = state.npcs.where(
          (n) =>
              n.worldDestinationId != null &&
              (n.worldTravelProgress < 1.0 || n.worldDestinationId != 'manor'),
        )
        .toList();

    if (travelingNpcs.isEmpty) return [];

    // Map location IDs to screen coordinates
    final Map<String, Offset> coords = {
      'manor': const Offset(100, 200),
      'hamlet': const Offset(30, 350),
      'mountains': const Offset(40, 20),
      'woods': const Offset(300, 220),
      'river': const Offset(340, 450),
    };

    // Group NPCs into parties based on their travel metadata
    final Map<String, List<NPC>> parties = {};
    for (var npc in travelingNpcs) {
      final key =
          "${npc.worldDestinationId}_${npc.worldDepartureId}_${npc.worldTravelProgress.toStringAsFixed(3)}";
      parties.putIfAbsent(key, () => []).add(npc);
    }

    return parties.entries.map((entry) {
      final party = entry.value;
      final leader = party.firstWhere(
        (n) => n.isPlayer,
        orElse: () => party.first,
      );
      final dest = leader.worldDestinationId!;

      Offset start;
      Offset end;

      if (dest == 'manor') {
        start = coords[leader.worldDepartureId] ?? coords['hamlet']!;
        end = coords['manor']!;
      } else {
        start = coords['manor']!;
        end = coords[dest] ?? coords['hamlet']!;
      }

      final progress = leader.worldTravelProgress.clamp(0.0, 1.0);
      final currentPos = Offset.lerp(start, end, progress)!;

      final bool hasPlayer = party.any((n) => n.isPlayer);
      final String label = party.length > 1
          ? "${leader.name.toUpperCase()} + ${party.length - 1} OTHERS"
          : leader.name.toUpperCase();

      return Positioned(
        top: currentPos.dy,
        left: currentPos.dx,
        child: Column(
          children: [
            Icon(
              hasPlayer ? Icons.stars : Icons.group,
              size: 24,
              color: hasPlayer ? Colors.amberAccent : Colors.white,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: Colors.black54,
              child: Text(
                label,
                style: GoogleFonts.oldStandardTt(
                  fontSize: 8,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
