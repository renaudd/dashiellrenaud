import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import 'combat_screen.dart';

class DestinationScreen extends StatefulWidget {
  final String destinationId;
  const DestinationScreen({super.key, required this.destinationId});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  bool _isNavigatingToCombat = false;

  void _checkCombatEncounter(GameState state) {
    if (state.pendingCombatEncounter && !_isNavigatingToCombat) {
      _isNavigatingToCombat = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CombatScreen()),
        ).then((_) {
          _isNavigatingToCombat = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    _checkCombatEncounter(state);

    final name = widget.destinationId.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          name,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Consumer<GameState>(
            builder: (context, state, child) {
              final hasTraveler = state.npcs.any(
                (n) =>
                    n.worldDestinationId == widget.destinationId &&
                    n.worldTravelProgress >= 1.0,
              );

              return Stack(
                children: [
                   // Placeholder for background image or stylized background
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Center(
                        child: Icon(
                          _getDestinationIcon(widget.destinationId),
                          size: 200,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                  ),

                  // Info Card
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Text(
                        _getDestinationDescription(widget.destinationId),
                        style: GoogleFonts.oldStandardTt(
                          color: const Color(0xFFC4B89B),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                  // Interaction Buttons (Generic for now)
                  if (hasTraveler)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionButton(
                            context,
                            'SCAVENGE AREA',
                            Icons.search,
                            () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Scavenging takes time and effort...')),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            context,
                            'REST BY CAMPFIRE',
                            Icons.fireplace,
                            () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Resting recovers a bit of energy.')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  // Return Section
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: _buildReturnSection(context, state),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback? onTap) {
    return SizedBox(
      width: 240,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF241F1A),
          foregroundColor: const Color(0xFFE5D5B0),
          side: const BorderSide(color: Color(0xFFC4B89B)),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildReturnSection(BuildContext context, GameState state) {
    final traveler = state.npcs.firstWhere(
      (n) => n.worldDestinationId == widget.destinationId && n.worldTravelProgress >= 1.0,
      orElse: () => state.npcs.first, // Fallback
    );

    final hasTraveler = state.npcs.any(
      (n) => n.worldDestinationId == widget.destinationId && n.worldTravelProgress >= 1.0,
    );

    if (!hasTraveler) return const SizedBox.shrink();

    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          state.returnToManor(traveler.id);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Colors.redAccent),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        icon: const Icon(Icons.keyboard_return),
        label: Text(
          "RETURN TO MANOR",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  IconData _getDestinationIcon(String id) {
    switch (id) {
      case 'mountains':
        return Icons.terrain;
      case 'woods':
        return Icons.forest;
      case 'river':
        return Icons.water;
      default:
        return Icons.explore;
    }
  }

  String _getDestinationDescription(String id) {
    switch (id) {
      case 'mountains':
        return 'The jagged peaks of the Swiss Alps loom overhead. The air is thin and cold, but rare minerals can be found in the crevices.';
      case 'woods':
        return 'A dense, ancient forest where the sunlight struggles to reach the mossy floor. Ideal for gathering timber and searching for specimens.';
      case 'river':
        return 'The icy waters of the Linth river flow rapidly towards the valley. A good place for fresh water and clay.';
      default:
        return 'A remote location on the estate grounds.';
    }
  }
}
