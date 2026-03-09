import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/combat_manager.dart';
import '../../models/npc.dart';
import '../../services/combat_unit_service.dart';
import '../../services/combat_unit_factory.dart';
import '../../state/game_state.dart';
import '../widgets/character_blob_renderer.dart';
import '../../models/combat_stats.dart';
import 'package:google_fonts/google_fonts.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _tickController;
  late CombatManager _combatManager;

  @override
  void initState() {
    super.initState();
    _combatManager = CombatManager();

    final state = Provider.of<GameState>(context, listen: false);
    final isSimulation = state.simulationPlayerDeck != null;

    if (isSimulation) {
      _combatManager.setupSimulation(
        state.simulationPlayerDeck!,
        state.simulationAiDeck!,
      );
    } else {
      _combatManager.prepareDeck(CombatUnitService.getInitialDeck());
    }

    // Always spawn Player Goalie
    _combatManager.spawnUnit(
      CombatUnitFactory.createAlphonse(),
      CombatSide.player,
      x: 10.0,
      y: CombatManager.fieldWidth / 2, // 42.5
    );

    // Always spawn AI Mirror Goalie
    _combatManager.spawnUnit(
      CombatUnitFactory.createAlphonse().copyWith(
        id: 'ai_mirror',
        name: 'AI Mirror',
        isPlayer: false,
      ),
      CombatSide.enemy,
      x: 190.0,
      y: CombatManager.fieldWidth / 2, // 42.5
    );

    if (!isSimulation) {
      // Add some initial variety for player to see in normal mode
      _combatManager.spawnUnit(
        CombatUnitFactory.createGoon(),
        CombatSide.enemy,
        x: 160.0,
        y: 20.0,
      );
    }

    _combatManager.startCombat();

    _tickController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            _combatManager.update(0.016); // ~60fps
            if (mounted) setState(() {});
          });
    _tickController.repeat();
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _combatManager,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            const _BattlefieldViewport(),
            const _CombatOverlay(),
            const _CombatLogPanel(),
            Positioned(bottom: 0, left: 0, right: 0, child: _CombatBottomBar()),
            if (_combatManager.isVictory || _combatManager.isDefeat)
              Positioned.fill(child: Container(color: Colors.black54)),
            if (_combatManager.isVictory) _buildVictoryOverlay(context),
            if (_combatManager.isDefeat) _buildDefeatOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VICTORY',
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFD4AF37), // Muted Gold
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'THE ROAD IS LITTERED WITH THEIR DEFEAT.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: Column(
                children: [
                  Text(
                    'SPOILS OF WAR',
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.yellow,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._combatManager.accumulatedLoot.entries
                      .where((e) => e.value > 0)
                      .map((e) {
                        final icon = e.key == 'funds'
                            ? Icons.monetization_on
                            : Icons.restaurant;
                        return _buildSpoilRow(
                          icon,
                          '${e.value} ${e.key.toUpperCase()}',
                        );
                      }),
                  if (_combatManager.killedEnemies.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ENEMIES VANQUISHED: ${_combatManager.killedEnemies.length}',
                      style: GoogleFonts.oldStandardTt(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow.shade800,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 20,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () {
                final state = Provider.of<GameState>(context, listen: false);
                state.addResources(_combatManager.accumulatedLoot);
                state.pendingCombatEncounter = false;
                Navigator.pop(context);
              },
              child: Text(
                'COLLECT & CONTINUE',
                style: GoogleFonts.oldStandardTt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpoilRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.yellow, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDefeatOverlay(BuildContext context) {
    return Container(
      color: const Color(0xFF4A0E0E).withValues(alpha: 0.95), // Dried blood red
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DEFEAT',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white,
                fontSize: 84,
                fontWeight: FontWeight.bold,
                letterSpacing: 10,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'THE EXPERIMENT HAS ENDED IN FAILURE.',
              style: GoogleFonts.oldStandardTt(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 64),
            _DefeatButton(
              label: 'TRY BATTLE AGAIN',
              onPressed: () {
                // Reset combat manager and restart
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CombatScreen()),
                );
              },
              primary: true,
            ),
            const SizedBox(height: 16),
            _DefeatButton(
              label: 'LOAD LAST SAVE',
              onPressed: () {
                // Load save logic would go here
                final state = Provider.of<GameState>(context, listen: false);
                state.pendingCombatEncounter = false;
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            _DefeatButton(
              label: 'ACCEPT FATE (QUIT)',
              onPressed: () {
                final state = Provider.of<GameState>(context, listen: false);
                state.pendingCombatEncounter = false;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DefeatButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _DefeatButton({
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: primary ? Colors.white : Colors.transparent,
          foregroundColor: primary ? Colors.red.shade900 : Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.oldStandardTt(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _BattlefieldViewport extends StatelessWidget {
  const _BattlefieldViewport();

  @override
  Widget build(BuildContext context) {
    return Consumer<CombatManager>(
      builder: (context, manager, child) {
        final screenSize = MediaQuery.of(context).size;
        final projection = _CombatProjection(
          viewSize: screenSize,
          fieldScroll: manager.fieldScroll,
        );

        return GestureDetector(
          onPanStart: (details) {
            final alphonse = manager.combatants.firstWhere(
              (c) => c.npc.isPlayer,
            );
            alphonse.moveDirX = 0;
            alphonse.moveDirY = 0;
          },
          onPanUpdate: (details) {
            final alphonse = manager.combatants.firstWhere(
              (c) => c.npc.isPlayer,
            );

            final worldPos = projection.unproject(details.localPosition);
            final dx = worldPos.dx - alphonse.x;
            final dy = worldPos.dy - alphonse.y;
            final len = sqrt(dx * dx + dy * dy);

            if (len > 0.1) {
              alphonse.moveDirX = dx / len;
              alphonse.moveDirY = dy / len;

              // Proactive boundary check: stop moving if trying to exit tactical area
              if ((alphonse.y <= 0.05 && alphonse.moveDirY < 0) ||
                  (alphonse.y >= 0.95 && alphonse.moveDirY > 0)) {
                alphonse.moveDirY = 0;
              }
            } else {
              alphonse.moveDirX = 0;
              alphonse.moveDirY = 0;
            }
          },
          onPanEnd: (details) {
            final alphonse = manager.combatants.firstWhere(
              (c) => c.npc.isPlayer,
            );
            alphonse.moveDirX = 0;
            alphonse.moveDirY = 0;
          },
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Colors.blue, // Sky fallback
            ),
            child: Stack(
              children: [
                // Environment/Background
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SwissCountrysidePainter(
                      fieldScroll: manager.fieldScroll,
                    ),
                  ),
                ),
                // 2a. Battlefield Background Art
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BattlefieldArtPainter(
                      projection: projection,
                      fieldScroll: manager.fieldScroll,
                    ),
                  ),
                ),

                // 2b. Tactical Grid & Mid-field line
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BattlefieldGridPainter(
                      fieldScroll: manager.fieldScroll,
                    ),
                  ),
                ),

                // Units (Y-sorted for 3D depth)
                ...(() {
                  final sorted = List<Combatant>.from(manager.combatants);
                  // Ensure all are inside world Y [0, 1] for projection safety
                  for (var c in sorted) {
                    c.y = c.y.clamp(0.0, CombatManager.fieldWidth);
                    c.x = c.x.clamp(
                      manager.fieldScroll,
                      manager.fieldScroll + CombatManager.fieldLength,
                    );
                  }
                  sorted.sort((a, b) => a.y.compareTo(b.y));
                  return sorted.map(
                    (c) => _CombatantSprite(
                      combatant: c,
                      screenPos: projection.project(c.x, c.y),
                    ),
                  );
                })(),

                // Projectiles
                ...manager.projectiles.map((p) {
                  final pos = projection.project(p.x, p.y);
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.side == CombatSide.player
                            ? Colors.teal.shade200
                            : Colors.deepOrange.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.side == CombatSide.player
                                ? Colors.teal.withValues(alpha: 0.5)
                                : Colors.deepOrange.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // 4. Atmosphere: Dark Vignette
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.5, // Increased radius
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5), // Lighter
                            Colors.black.withValues(alpha: 0.7), // Lighter
                          ],
                          stops: const [
                            0.2,
                            0.8,
                            1.0,
                          ], // More central visibility
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CombatantSprite extends StatelessWidget {
  final Combatant combatant;
  final Offset screenPos;

  const _CombatantSprite({required this.combatant, required this.screenPos});

  @override
  Widget build(BuildContext context) {
    final stats = combatant.npc.combatStats!;
    final healthPercent = stats.health / stats.maxHealth;
    final double opacity = combatant.isDead ? 0.3 : 1.0;
    // Scale based on Y depth
    final double scale =
        (0.8 + (combatant.y / CombatManager.fieldWidth) * 0.4) *
        1.5; // Larger base scale

    return Positioned(
      left: screenPos.dx - 50,
      top: screenPos.dy - 104, // 100 height for unit + some buffer
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: 100,
            height: 120, // Total height to include floating text
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Base Ring (Shadow)
                // Centered at screenPos.dy (which is at local Y=104)
                if (!combatant.isDead)
                  Positioned(
                    top: 98, // 104 - 6 (half ring height)
                    child: Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(20, 6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: combatant.side == CombatSide.player
                                ? Colors.blue.withValues(alpha: 0.4)
                                : Colors.red.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(
                          color: combatant.side == CombatSide.player
                              ? Colors.blue.withValues(alpha: 0.8)
                              : Colors.red.withValues(alpha: 0.8),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                // Main Body (Character + Health)
                // Bottom edge should touch screenPos.dy (local Y=104)
                Positioned(
                  bottom:
                      16, // 120 - 104 = 16 pixels from bottom is the ground plane
                  child: GestureDetector(
                    onTap: () {
                      if (combatant.side == CombatSide.enemy) {
                        context.read<CombatManager>().setPlayerTarget(
                          combatant.npc.id,
                        );
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Health Bar
                        Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: healthPercent,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        CharacterBlobRenderer(
                          npc: combatant.npc,
                          size: 40,
                          isWalking: combatant.attackCooldown <= 0,
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Messages
                if (combatant.floatingMessages.isNotEmpty)
                  Positioned(
                    top: 0, // Top of the 120 box
                    left: -50,
                    right: -50,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: combatant.floatingMessages.map((m) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: m.offsetY),
                          child: Text(
                            m.text,
                            style: GoogleFonts.oldStandardTt(
                              color: m.color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // Special Ready Button (centered on unit but at bottom)
                if (combatant.npc.specialCharge >= 1.0 &&
                    combatant.side == CombatSide.player)
                  Consumer<CombatManager>(
                    builder: (context, manager, child) {
                      final canUse = manager.canExecuteSpecial(
                        combatant.npc.id,
                      );
                      final special = combatant.npc.abilities.firstWhere(
                        (a) => a.type == AbilityType.special,
                      );

                      return Positioned(
                        bottom: -15, // Hanging slightly off the 120-high box
                        child: Tooltip(
                          message: special.description,
                          textStyle: GoogleFonts.oldStandardTt(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2F24),
                            border: Border.all(color: Colors.yellow[800]!),
                          ),
                          child: GestureDetector(
                            onTap: canUse
                                ? () {
                                    manager.executeSpecial(combatant.npc.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${combatant.npc.name} used ${special.name}!',
                                          style: GoogleFonts.oldStandardTt(
                                            color: Colors.white,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.yellow.shade800,
                                      ),
                                    );
                                  }
                                : null,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: canUse ? 1.0 : 0.4,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: canUse
                                      ? Colors.yellow[800]
                                      : Colors.grey[800],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                  boxShadow: canUse
                                      ? [
                                          BoxShadow(
                                            color: Colors.yellow.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                                child: const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CombatOverlay extends StatelessWidget {
  const _CombatOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      child: Consumer<CombatManager>(
        builder: (context, manager, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTION POINTS',
                style: GoogleFonts.oldStandardTt(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.timer, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    manager.actionPoints.toStringAsFixed(1),
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.blue,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CombatLogPanel extends StatelessWidget {
  const _CombatLogPanel();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100,
      right: 20,
      bottom: 140,
      width: 250,
      child: Consumer<CombatManager>(
        builder: (context, manager, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              reverse: false,
              itemCount: manager.logs.length,
              itemBuilder: (context, index) {
                final entry = manager.logs[index];
                final color = entry.side == CombatSide.player
                    ? Colors.cyanAccent.withValues(alpha: 0.8)
                    : entry.side == CombatSide.enemy
                    ? Colors.orangeAccent.withValues(alpha: 0.8)
                    : Colors.white70;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    entry.message,
                    style: GoogleFonts.oldStandardTt(
                      color: color,
                      fontSize: 12,
                      height: 1.2,
                      shadows: [
                        const Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CombatBottomBar extends StatefulWidget {
  const _CombatBottomBar();

  @override
  State<_CombatBottomBar> createState() => _CombatBottomBarState();
}

class _CombatBottomBarState extends State<_CombatBottomBar> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<NPC> _displayedHand = [];
  CombatManager? _manager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newManager = Provider.of<CombatManager>(context);
    if (_manager != newManager) {
      _manager?.removeListener(_onHandChanged);
      _manager = newManager;
      _manager?.addListener(_onHandChanged);
      _syncHand(initial: true);
    }
  }

  @override
  void dispose() {
    _manager?.removeListener(_onHandChanged);
    super.dispose();
  }

  void _onHandChanged() {
    if (mounted) {
      _syncHand();
    }
  }

  void _syncHand({bool initial = false}) {
    final currentHand = _manager?.hand ?? [];
    if (initial) {
      _displayedHand.clear();
      _displayedHand.addAll(currentHand);
      return;
    }

    // Simple diffing to trigger animations
    // 1. Remove missing items
    for (int i = _displayedHand.length - 1; i >= 0; i--) {
      final npc = _displayedHand[i];
      if (!currentHand.any((n) => n.id == npc.id)) {
        _displayedHand.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedCard(npc, animation),
          duration: const Duration(milliseconds: 300),
        );
      }
    }

    // 2. Add new items
    for (int i = 0; i < currentHand.length; i++) {
      final npc = currentHand[i];
      if (!_displayedHand.any((n) => n.id == npc.id)) {
        _displayedHand.insert(i, npc);
        _listKey.currentState?.insertItem(
          i,
          duration: const Duration(milliseconds: 400),
        );
      }
    }
  }

  Widget _buildAnimatedCard(NPC npc, Animation<double> animation) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: animation,
        child: _UnitCard(key: ValueKey(npc.id), npc: npc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        border: const Border(top: BorderSide(color: Colors.white10, width: 2)),
      ),
      child: Row(
        children: [
          // Hand of Cards
          Expanded(
            child: AnimatedList(
              key: _listKey,
              initialItemCount: _displayedHand.length,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index, animation) {
                if (index < _displayedHand.length) {
                  return _buildAnimatedCard(_displayedHand[index], animation);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatefulWidget {
  final NPC npc;
  const _UnitCard({super.key, required this.npc});

  @override
  State<_UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<_UnitCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CombatManager>(
      builder: (context, manager, child) {
        final cost = widget.npc.combatStats?.cost ?? 0;
        final canAfford = manager.actionPoints >= cost;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: 140,
            height: 70, // Base height
            margin: const EdgeInsets.only(right: 14),
            transform: Matrix4.translationValues(0, _isHovered ? -20 : 0, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF5E6), // Old Lace/Parchment
              border: Border.all(
                color: _isHovered
                    ? const Color(0xFF8B4513) // Saddle Brown
                    : (canAfford
                          ? const Color(0xFF5D4037) // Muted Brown
                          : const Color(0xFFD32F2F).withValues(alpha: 0.5)),
                width: _isHovered ? 3 : 2,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Draggable<NPC>(
                  data: widget.npc,
                  feedback: Material(
                    color: Colors.transparent,
                    child: Opacity(
                      opacity: 0.8,
                      child: CharacterBlobRenderer(npc: widget.npc, size: 50),
                    ),
                  ),
                  onDragEnd: (details) {
                    final screenSize = MediaQuery.of(context).size;
                    final projection = _CombatProjection(
                      viewSize: screenSize,
                      fieldScroll: manager.fieldScroll,
                    );
                    
                    // Allow dropping anywhere that projects to valid world Y
                    if (details.offset.dy < projection.yNear) {
                      // Compensate for the drag anchor (CharacterBlob is 50x50, anchor is center)
                      // We want the feet (bottom of blob) to match world position.
                      final dragFeetOffset =
                          details.offset + const Offset(25, 50);
                      final worldPos = projection.unproject(dragFeetOffset);
                      final dropX = worldPos.dx;
                      final dropY = worldPos.dy;

                      if (dropX <= manager.fieldScroll + 100.0) {
                        final clampedY = dropY.clamp(
                          0.0,
                          CombatManager.fieldWidth,
                        );
                        manager.spawnUnit(
                          widget.npc,
                          CombatSide.player,
                          x: dropX,
                          y: clampedY,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.npc.name} deployed!',
                              style: GoogleFonts.oldStandardTt(
                                color: Colors.white,
                              ),
                            ),
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.blue.shade800,
                          ),
                        );
                      }
                    }
                  },
                  child: SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Stats & Name (Left)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.npc.name.toUpperCase(),
                                  style: GoogleFonts.oldStandardTt(
                                    color: const Color(0xFF2E1A0A), // Dark Ink
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    _buildSmallStat(
                                      'A',
                                      widget.npc.combatStats?.attack.toInt() ??
                                          0,
                                    ),
                                    const SizedBox(width: 4),
                                    _buildSmallStat(
                                      'H',
                                      widget.npc.combatStats?.maxHealth
                                              .toInt() ??
                                          0,
                                    ),
                                  ],
                                ),
                                Text(
                                  'COST: $cost',
                                  style: GoogleFonts.oldStandardTt(
                                    color: canAfford
                                        ? const Color(0xFF388E3C)
                                        : const Color(0xFFD32F2F),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Character Image (Right)
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.1),
                              border: Border.all(
                                color: const Color(
                                  0xFF8B4513,
                                ).withValues(alpha: 0.3),
                              ),
                              shape: BoxShape.rectangle,
                            ),
                            child: Center(
                              child: CharacterBlobRenderer(
                                npc: widget.npc,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Hover Detail Panel (Lifted up above the main card)
                if (_isHovered)
                  Positioned(
                    bottom: 74,
                    left: -1,
                    right: -1,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Speed',
                            widget.npc.combatStats?.speed.toStringAsFixed(1) ??
                                '0',
                          ),
                          _buildDetailRow(
                            'Range',
                            widget.npc.combatStats?.distance.toStringAsFixed(
                                  1,
                                ) ??
                                '0',
                          ),
                          const Divider(color: Colors.white24, height: 8),
                          Text(
                            'ABILITIES',
                            style: GoogleFonts.oldStandardTt(
                              fontSize: 8,
                              color: Colors.blue[300],
                            ),
                          ),
                          ...widget.npc.abilities
                              .take(2)
                              .map(
                                (a) => Text(
                                  '• ${a.name}',
                                  style: GoogleFonts.oldStandardTt(
                                    fontSize: 8,
                                    color: Colors.white70,
                                  ),
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
      },
    );
  }

  Widget _buildSmallStat(String label, int value) {
    return Text(
      '$label:$value',
      style: GoogleFonts.oldStandardTt(color: Colors.white60, fontSize: 8),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.oldStandardTt(color: Colors.white54, fontSize: 8),
        ),
        Text(
          value,
          style: GoogleFonts.oldStandardTt(color: Colors.white, fontSize: 8),
        ),
      ],
    );
  }
}

class _BattlefieldGridPainter extends CustomPainter {
  final double fieldScroll;

  _BattlefieldGridPainter({required this.fieldScroll});

  @override
  void paint(Canvas canvas, Size size) {
    final projection = _CombatProjection(
      viewSize: size,
      fieldScroll: fieldScroll,
    );

    final gridPaint = Paint()
      ..color = Colors.white
          .withValues(alpha: 0.02) // More subtle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final midFieldPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // 1. Draw horizontal lane lines (depth lines)
    for (double y = 0; y <= CombatManager.fieldWidth * 1.5; y += 17.0) {
      // 5 lanes approx
      final p1 = projection.project(fieldScroll, y);
      final p2 = projection.project(fieldScroll + CombatManager.fieldLength, y);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // 2. Draw vertical meter lines (perspective slices)
    final startX = (fieldScroll / 20.0).floor() * 20.0;
    for (
      double x = startX;
      x <= fieldScroll + CombatManager.fieldLength;
      x += 20.0
    ) {
      if (x < fieldScroll) continue;
      final pTop = projection.project(x, 0.0);
      final pBottom = projection.project(x, CombatManager.fieldWidth * 1.5);

      canvas.drawLine(
        pTop,
        pBottom,
        (x - fieldScroll).abs() == 100.0
            ? midFieldPaint
            : gridPaint, // Midfield at 100ft
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattlefieldGridPainter oldDelegate) =>
      oldDelegate.fieldScroll != fieldScroll;
}

class _BattlefieldArtPainter extends CustomPainter {
  final _CombatProjection projection;
  final double fieldScroll;

  _BattlefieldArtPainter({required this.projection, required this.fieldScroll});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill ground background (Lighter, parchment-toned olive/brown)
    final bgPaint = Paint()..color = const Color(0xFF2C2F24);
    final shadowPaint = Paint()..color = const Color(0xFF1F221A);

    // Define the basic trapezoid of the field
    final path = Path();
    final pTL = projection.project(fieldScroll, 0.0);
    final pTR = projection.project(
      fieldScroll + CombatManager.fieldLength,
      0.0,
    );
    final pBR = projection.project(
      fieldScroll + CombatManager.fieldLength,
      CombatManager.fieldWidth * 1.5,
    );
    final pBL = projection.project(fieldScroll, CombatManager.fieldWidth * 1.5);

    path.moveTo(pTL.dx, pTL.dy);
    path.lineTo(pTR.dx, pTR.dy);
    path.lineTo(pBR.dx, pBR.dy);
    path.lineTo(pBL.dx, pBL.dy);
    path.close();

    canvas.drawPath(path, bgPaint);

    // 2. Add "noise" patches for dirt/dead grass (Stippled/High Contrast)
    final random = Random(42); // Seeded for consistency
    for (int i = 0; i < 80; i++) {
      final wx =
          random.nextDouble() * CombatManager.fieldLength * 2 +
          fieldScroll -
          20;
      final wy = random.nextDouble() * CombatManager.fieldWidth;
      final pos = projection.project(wx, wy);
      final r = 2.0 + random.nextDouble() * 5.0;

      // Use solid opacity circles for a "stippled" look rather than blurred ones
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );
    }

    // 3. Decorations (Craters, Debris)
    for (int i = 0; i < 15; i++) {
      final wx = (i * 77.0) % (CombatManager.fieldLength * 5);
      if (wx < fieldScroll - 50 ||
          wx > fieldScroll + CombatManager.fieldLength + 50) {
        continue;
      }

      final wy = (i * 33.0) % CombatManager.fieldWidth;
      final pos = projection.project(wx, wy);

      if (i % 3 == 0) {
        // Crater
        canvas.drawCircle(pos, 6, shadowPaint);
      } else {
        // Debris/Rocks
        final rect = Rect.fromCenter(center: pos, width: 4, height: 2);
        canvas.drawRect(
          rect,
          Paint()..color = Colors.grey.withValues(alpha: 0.2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BattlefieldArtPainter oldDelegate) =>
      oldDelegate.fieldScroll != fieldScroll;
}

class _CombatProjection {
  final Size viewSize;
  final double fieldScroll;

  _CombatProjection({required this.viewSize, required this.fieldScroll});

  double get yNear =>
      viewSize.height *
      0.76; // .76 is the right dimension, the issue is that the grid underneath the players isn't extending to the bottom edge of the battlefield.
  double get yFar =>
      viewSize.height *
      0.16; //.16 is also the right dimension. the background needs to be redrawn to match the battlefield edge as drawn at these dimensions.
  double get widthNear => viewSize.width * 1.1;
  double get widthFar => viewSize.width * 0.65;

  Offset project(double worldX, double worldY) {
    // worldX: 0 to 200 feet
    // worldY: 0.0 (far) to 85.0 (near)
    final relativeX = worldX - fieldScroll;

    // Perspective parameters (Soccer field feel)
    final normalizedY =
        worldY /
        CombatManager.fieldWidth; // Clamp removed to allow drawing 'apron'
    final screenY = yFar + (normalizedY * (yNear - yFar));
    final currentWidth = widthFar + (normalizedY * (widthNear - widthFar));
    final xOffset = (viewSize.width - currentWidth) / 2;

    const double visibleLength = CombatManager.fieldLength;
    final screenX = xOffset + (relativeX * (currentWidth / visibleLength));

    return Offset(screenX, screenY);
  }

  Offset unproject(Offset screenPos) {
    final normalizedY = ((screenPos.dy - yFar) / (yNear - yFar)).clamp(
      0.0,
      1.0,
    );
    final worldY = normalizedY * CombatManager.fieldWidth;

    final currentWidth = widthFar + (normalizedY * (widthNear - widthFar));
    final xOffset = (viewSize.width - currentWidth) / 2;

    const double visibleLength = CombatManager.fieldLength;
    final relativeX = (screenPos.dx - xOffset) / (currentWidth / visibleLength);

    return Offset(relativeX + fieldScroll, worldY);
  }
}
class _SwissCountrysidePainter extends CustomPainter {
  final double fieldScroll;

  _SwissCountrysidePainter({required this.fieldScroll});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky (Lighter Slate Grey)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.16),
      Paint()..color = const Color(0xFF23272D),
    );

    // 2. Distant Tonal Shapes (Moorland/Low Hills)
    final mountainPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    for (int i = 0; i < 8; i++) {
      final mWidth = size.width * 0.3;
      final mHeight = size.height * 0.15;
      final mX =
          (i * size.width * 0.15) - (fieldScroll * 2 % (size.width * 0.15));
      final mY = size.height * 0.16; // Synced with horizon

      final path = Path();
      path.moveTo(mX, mY);
      path.lineTo(mX + mWidth / 2, mY - mHeight);
      path.lineTo(mX + mWidth, mY);
      path.close();
      canvas.drawPath(path, mountainPaint);
    }

    // 3. Middle Ground Rolling Moor (Parchment Olive)
    final hillPaint = Paint()..color = const Color(0xFF3A3D33);
    final meadowYTop = size.height * 0.16; // Synced with yFar

    for (int i = 0; i < 4; i++) {
      final hWidth = size.width * 0.9;
      final hHeight = size.height * 0.12;
      final hX =
          (i * size.width * 0.4) - (fieldScroll * 10 % (size.width * 0.4));
      final hY = meadowYTop;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(hX + hWidth / 2, hY),
          width: hWidth,
          height: hHeight * 2,
        ),
        hillPaint,
      );
    }

    // 4. Foreground Meadow (Subdued Peat)
    canvas.drawRect(
      Rect.fromLTWH(0, meadowYTop, size.width, size.height - meadowYTop),
      Paint()..color = const Color(0xFF242721),
    );

    // 5. Tactical Grid Overlay
    final tacticalGridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw soccer-field markings (simplified)
    final projection = _CombatProjection(
      viewSize: size,
      fieldScroll: fieldScroll,
    );

    // Bounds of the field
    final pTL = projection.project(fieldScroll, 0.0);
    final pTR = projection.project(
      fieldScroll + CombatManager.fieldLength,
      0.0,
    );
    final pBL = projection.project(fieldScroll, CombatManager.fieldWidth * 1.5);
    final pBR = projection.project(
      fieldScroll + CombatManager.fieldLength,
      CombatManager.fieldWidth * 1.5,
    );

    canvas.drawLine(pTL, pTR, tacticalGridPaint);
    canvas.drawLine(pBL, pBR, tacticalGridPaint);
    canvas.drawLine(pTL, pBL, tacticalGridPaint);
    canvas.drawLine(pTR, pBR, tacticalGridPaint);

    // Midfield line
    final pMidTop = projection.project(fieldScroll + 100.0, 0.0);
    final pMidBottom = projection.project(
      fieldScroll + 100.0,
      CombatManager.fieldWidth,
    );
    canvas.drawLine(pMidTop, pMidBottom, tacticalGridPaint);
  }

  @override
  bool shouldRepaint(covariant _SwissCountrysidePainter oldDelegate) =>
      oldDelegate.fieldScroll != fieldScroll;
}
