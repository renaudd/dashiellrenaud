import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../services/combat_unit_service.dart';
import '../widgets/character_blob_renderer.dart';
import 'combat_screen.dart';

class CombatSimulatorScreen extends StatefulWidget {
  const CombatSimulatorScreen({super.key});

  @override
  State<CombatSimulatorScreen> createState() => _CombatSimulatorScreenState();
}

class _CombatSimulatorScreenState extends State<CombatSimulatorScreen> {
  final List<String> _playerDeckTypes = [];
  final List<String> _aiDeckTypes = [];
  bool _isPlayerDeckSelected = true;

  final List<String> _availableTypes = [
    'giles',
    'militia',
    'captain',
    'peasant',
    'goon',
    'rats',
    'bats',
    'flying_rat',
    'sniper',
    'bully',
    'stitched_horror',
    'galvanized_corpse',
    'chemical_slinger',
    'shadow_creeper',
    'gravedigger',
    'plague_monk',
    'inquisitor',
    'iron_maiden',
    'flesh_hound',
    'alchemical_golem',
  ];

  @override
  void initState() {
    super.initState();
    _randomizeDecks();
  }

  void _randomizeDecks() {
    final random = Random();
    _playerDeckTypes.clear();
    _aiDeckTypes.clear();
    for (int i = 0; i < 12; i++) {
      _playerDeckTypes.add(
        _availableTypes[random.nextInt(_availableTypes.length)],
      );
      _aiDeckTypes.add(_availableTypes[random.nextInt(_availableTypes.length)]);
    }
  }

  void _addUnit(String type) {
    setState(() {
      final targetDeck = _isPlayerDeckSelected
          ? _playerDeckTypes
          : _aiDeckTypes;
      if (targetDeck.length < 12) {
        targetDeck.add(type);
      }
    });
  }

  void _removeUnit(int index) {
    setState(() {
      final targetDeck = _isPlayerDeckSelected
          ? _playerDeckTypes
          : _aiDeckTypes;
      targetDeck.removeAt(index);
    });
  }

  void _startSimulation(GameState state) {
    if (_playerDeckTypes.length < 12 || _aiDeckTypes.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both decks must have 12 units.')),
      );
      return;
    }

    // Create NPC instances for the decks
    final playerUnits = _playerDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();
    final aiUnits = _aiDeckTypes
        .map((t) => CombatUnitService.createUnit(t))
        .toList();

    // Setup simulator state
    state.startCombatSimulation(playerUnits, aiUnits);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CombatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'COMBAT SIMULATOR',
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
      body: Row(
        children: [
          // Left: Available Units
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                children: [
                  _sectionHeader("AVAILABLE UNITS"),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _availableTypes.length,
                      itemBuilder: (context, index) {
                        final type = _availableTypes[index];
                        final sampleUnit = CombatUnitService.createUnit(type);
                        final stats = sampleUnit.combatStats!;

                        return Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            leading: CharacterBlobRenderer(
                              npc: sampleUnit,
                              size: 30,
                            ),
                            title: Text(
                              type.toUpperCase().replaceAll('_', ' '),
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFFE5D5B0),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "HP:${stats.maxHealth.toInt()} | ATK:${stats.attack.toInt()} | SPD:${stats.speed} | ACC:${(stats.accuracy * 100).toInt()}%",
                                  style: GoogleFonts.playfairDisplay(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...sampleUnit.abilities.map(
                                  (a) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      "• ${a.name}: ${a.description}",
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white38,
                                        fontSize: 9,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${stats.cost} AP",
                                  style: GoogleFonts.oswald(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    size: 20,
                                    color: Color(0xFFC4B89B),
                                  ),
                                  onPressed: () => _addUnit(type),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right: Deck Building
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Row(
                  children: [
                    _deckTab(
                      "PLAYER DECK",
                      _isPlayerDeckSelected,
                      () => setState(() => _isPlayerDeckSelected = true),
                    ),
                    _deckTab(
                      "AI DECK",
                      !_isPlayerDeckSelected,
                      () => setState(() => _isPlayerDeckSelected = false),
                    ),
                  ],
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final currentDeck = _isPlayerDeckSelected
                                  ? _playerDeckTypes
                                  : _aiDeckTypes;
                              final bool hasUnit = index < currentDeck.length;
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(
                                      0xFFC4B89B,
                                    ).withValues(alpha: 0.3),
                                  ),
                                  color: Colors.black26,
                                ),
                                child: hasUnit
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CharacterBlobRenderer(
                                                npc:
                                                    CombatUnitService.createUnit(
                                                      currentDeck[index],
                                                    ),
                                                size: 30,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                currentDeck[index]
                                                    .replaceAll('_', ' ')
                                                    .toUpperCase(),
                                                style: GoogleFonts.oswald(
                                                  color: Colors.white70,
                                                  fontSize: 8,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.close,
                                                size: 14,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () =>
                                                  _removeUnit(index),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.add,
                                          color: Colors.white10,
                                        ),
                                      ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Consumer<GameState>(
                          builder: (context, state, child) {
                            return ElevatedButton(
                              onPressed: () => _startSimulation(state),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC4B89B),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 48,
                                  vertical: 20,
                                ),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child: Text(
                                "START SIMULATION",
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Colors.black26,
      child: Text(
        title,
        style: GoogleFonts.oldStandardTt(
          color: const Color(0xFFC4B89B),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _deckTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFFC4B89B) : Colors.transparent,
                width: 2,
              ),
            ),
            color: active
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: active ? const Color(0xFFE5D5B0) : Colors.white24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
