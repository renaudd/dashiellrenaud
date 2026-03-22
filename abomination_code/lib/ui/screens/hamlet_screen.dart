import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../widgets/hamlet_hotspot.dart';
import 'combat_screen.dart';

class HamletScreen extends StatefulWidget {
  const HamletScreen({super.key});

  @override
  State<HamletScreen> createState() => _HamletScreenState();
}

class _HamletScreenState extends State<HamletScreen> {
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

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'TOWN OF GLARUS',
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
                    n.worldDestinationId == 'hamlet' &&
                    n.worldTravelProgress >= 1.0,
              );

              return Stack(
                children: [
                  // Full Background Map
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/hamlet.jpg',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(
                        alpha: hasTraveler ? 0.3 : 0.6,
                      ),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),

                  // Interactive Hotspots
                  HamletHotspot(
                    label: 'Crossroads Tavern',
                    subtitle: 'Drink & Recruitment',
                    icon: Icons.nightlife,
                    top: constraints.maxHeight * 0.45,
                    left: constraints.maxWidth * 0.15,
                    width: 140,
                    height: 120,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showTavern(context) : null,
                  ),

                  HamletHotspot(
                    label: 'The Marketplace',
                    subtitle: 'Commerce & Supplies',
                    icon: Icons.storefront,
                    top: constraints.maxHeight * 0.55,
                    left: constraints.maxWidth * 0.65,
                    width: 180,
                    height: 140,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showMarket(context) : null,
                  ),

                  HamletHotspot(
                    label: 'Town Square',
                    subtitle: 'Distant Voices',
                    icon: Icons.account_balance,
                    top: constraints.maxHeight * 0.65,
                    left: constraints.maxWidth * 0.42,
                    width: 100,
                    height: 100,
                    hasTraveler: hasTraveler,
                    onTap: hasTraveler ? () => _showTownSquare(context) : null,
                  ),

                  // Top Info Overlay
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildInfoCard(),
                  ),

                  // Bottom Return Overlay
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: _buildReturnSection(context),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReturnSection(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final traveler = state.npcs.firstWhere(
          (n) =>
              n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
          orElse: () => throw Exception("No one here"),
        );
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
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
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
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A sleepy border town, relatively untouched by the war across the border. Many refugees congregate here, seeking passage further south.',
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarket(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            final resources = ['wood', 'meat', 'eggs', 'cabbage'];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MARKET OF GLARUS',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FUNDS: ${state.npcs.firstWhere((n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0).journeyInventory['funds']?.round()} CHF',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...resources.map(
                    (res) => _buildMarketItem(context, state, res),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMarketItem(BuildContext context, GameState state, String res) {
    final traveler = state.npcs.firstWhere(
      (n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0,
    );
    final sellPrice = state.marketService.getSellPrice(res);
    final buyPrice = state.marketService.getBuyPrice(res);
    final count = traveler.journeyInventory[res] ?? 0;
    final funds = traveler.journeyInventory['funds'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(_getResourceIcon(res), color: const Color(0xFFC4B89B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'In Stock: ${count.round()}',
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          _actionButton(
            'SELL ($sellPrice)',
            count > 0 ? () => state.sellResource(res, 1) : null,
          ),
          const SizedBox(width: 8),
          _actionButton(
            'BUY ($buyPrice)',
            funds >= buyPrice ? () => state.buyResource(res, 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: onTap != null ? const Color(0xFFC4B89B) : Colors.white10,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(
        label,
        style: GoogleFonts.playfairDisplay(
          color: onTap != null ? const Color(0xFFE5D5B0) : Colors.white12,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showTavern(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    if (state.availableHamletNpcs.isEmpty) state.refreshHamletNpcs();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      isScrollControlled: true,
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CROSSROADS TAVERN',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'FUNDS: ${state.npcs.firstWhere((n) => n.worldDestinationId == 'hamlet' && n.worldTravelProgress >= 1.0).journeyInventory['funds']?.round()} CHF',
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state.availableHamletNpcs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'The tavern is empty. No one is looking for work right now.',
                        style: GoogleFonts.oldStandardTt(color: Colors.white24),
                      ),
                    )
                  else
                    ...state.availableHamletNpcs.map(
                      (npc) => _buildNpcRecruitTile(context, state, npc),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => state.refreshHamletNpcs(),
                    child: Text(
                      'WAIT FOR OTHERS (-5 FUNDS)',
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFFC4B89B),
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNpcRecruitTile(
    BuildContext context,
    GameState state,
    dynamic npc,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
        color: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_outline, color: Color(0xFFC4B89B)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  npc.name.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${npc.role.toUpperCase()} | ${npc.age}Y | ${npc.nationality.toUpperCase()}',
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              state.hireNpc(npc);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC4B89B)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'HIRE (10 CHF)',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getResourceIcon(String res) {
    switch (res) {
      case 'wood':
        return Icons.forest;
      case 'meat':
        return Icons.restaurant;
      case 'eggs':
        return Icons.egg;
      case 'cabbage':
        return Icons.grass;
      default:
        return Icons.help_outline;
    }
  }

  void _showTownSquare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The town square is quiet today...')),
    );
  }
}
