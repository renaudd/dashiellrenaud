import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/npc.dart';

class PrepareJourneyDialog extends StatefulWidget {
  final String destinationId;

  const PrepareJourneyDialog({super.key, required this.destinationId});

  @override
  State<PrepareJourneyDialog> createState() => _PrepareJourneyDialogState();
}

class _PrepareJourneyDialogState extends State<PrepareJourneyDialog> {
  String? _selectedNpcId;
  final Map<String, int> _selectedResources = {
    'funds': 0,
    'meat': 0,
    'cabbage': 0,
  };
  final List<String> _escortIds = [];
  bool _isInitialized = false;

  void _initializeDefaults(List<NPC> npcs) {
    if (_isInitialized) return;
    _isInitialized = true;

    // Default traveler: Alphonse (player)
    _selectedNpcId = 'player';

    // Load persisted deck from player
    final player = npcs.firstWhere(
      (n) => n.id == 'player',
      orElse: () => npcs.first,
    );
    if (player.lastEscortIds.isNotEmpty) {
      _escortIds.addAll(player.lastEscortIds);
    } else {
      // Fallback: Auto-select initial unit pool as escorts if no history
      for (var npc in npcs) {
        if (npc.role == 'Minion' && _escortIds.length < 12) {
          _escortIds.add(npc.id);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final availableNpcs = state.npcs
            .where((n) => n.worldDestinationId == null)
            .toList();
        
        _initializeDefaults(availableNpcs);

        return Dialog(
          backgroundColor: const Color(0xFF1E1A15),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFC4B89B), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PREPARE EXPEDITION",
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "DESTINATION: ${widget.destinationId.toUpperCase()}",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // NPC Selector (Locked to Player)
                _sectionHeader("EXPEDITION LEADER"),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFC4B89B),
                    child: Icon(Icons.stars, color: Colors.black),
                  ),
                  title: Text(
                    "ALPHONSE",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "MASTER OF THE MANOR",
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resource Selector
                _sectionHeader("PACK SUPPLIES"),
                ..._selectedResources.keys.map(
                  (res) => _buildResourceSlider(state, res),
                ),

                const SizedBox(height: 24),

                // Escort Selector
                _sectionHeader("ESCORT ROSTER (12 SLOTS)"),
                _buildEscortGrid(state),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "CANCEL",
                        style: GoogleFonts.oldStandardTt(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: availableNpcs.isEmpty
                          ? null
                          : () {
                              state.startJourney(
                                _selectedNpcId!,
                                widget.destinationId,
                                _selectedResources,
                                _escortIds,
                              );
                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC4B89B),
                        foregroundColor: Colors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        "DEPART",
                        style: GoogleFonts.playfairDisplay(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEscortGrid(GameState state) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final bool hasUnit = index < _escortIds.length;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black26,
          ),
          child: InkWell(
            onTap: () => _showUnitSelection(context, state, index),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (hasUnit)
                  _buildUnitIcon(state, _escortIds[index])
                else
                  const Icon(Icons.add, color: Colors.white10, size: 16),
                if (hasUnit)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.close,
                      size: 10,
                      color: Colors.redAccent.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitIcon(GameState state, String id) {
    final npc = state.npcs.firstWhere((n) => n.id == id);
    return Tooltip(
      message: npc.name.toUpperCase(),
      child: Icon(
        npc.role == 'Minion' ? Icons.shield : Icons.person_search,
        color: npc.role == 'Minion'
            ? Colors.amberAccent
            : Colors.lightBlueAccent,
        size: 20,
      ),
    );
  }

  void _showUnitSelection(BuildContext context, GameState state, int index) {
    // If slot is occupied, remove it
    if (index < _escortIds.length) {
      setState(() => _escortIds.removeAt(index));
      return;
    }

    // Otherwise, show list of available units
    final travelerId = _selectedNpcId;
    final available = state.npcs.where((n) {
      return n.worldDestinationId == null &&
          n.id != travelerId &&
          !_escortIds.contains(n.id);
    }).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No further units available.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return ListView.builder(
          itemCount: available.length,
          itemBuilder: (context, i) {
            final npc = available[i];
            return ListTile(
              leading: Icon(
                npc.role == 'Minion' ? Icons.shield : Icons.person,
                color: const Color(0xFFC4B89B),
              ),
              title: Text(
                npc.name.toUpperCase(),
                style: GoogleFonts.oldStandardTt(color: Colors.white),
              ),
              subtitle: Text(
                npc.role.toUpperCase(),
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
              onTap: () {
                setState(() => _escortIds.add(npc.id));
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResourceSlider(GameState state, String res) {
    final maxAvailable = state.resources[res] ?? 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              res.toUpperCase(),
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
            Text(
              "${_selectedResources[res]} / $maxAvailable",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFC4B89B),
            inactiveTrackColor: Colors.white10,
            thumbColor: const Color(0xFFC4B89B),
            overlayColor: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            trackHeight: 2,
          ),
          child: Slider(
            value: _selectedResources[res]!.toDouble(),
            min: 0,
            max: maxAvailable.toDouble() > 0 ? maxAvailable.toDouble() : 1,
            onChanged: maxAvailable > 0
                ? (val) {
                    setState(() => _selectedResources[res] = val.toInt());
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
