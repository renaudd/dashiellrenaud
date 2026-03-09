import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/responsibility.dart';
import '../../models/npc.dart';
import 'responsibility_detail_screen.dart';

class ResponsibilityGridScreen extends StatelessWidget {
  const ResponsibilityGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final npcs = state.npcs.where((n) => n.isResident).toList();
        final categories = ResponsibilityCategory.values;

        return Scaffold(
          backgroundColor: const Color(0xFF1A1612),
          appBar: AppBar(
            backgroundColor: Colors.black45,
            title: Text(
              'RESPONSIBILITY ASSIGNMENT',
              style: GoogleFonts.oswald(
                letterSpacing: 2,
                color: const Color(0xFFE5D5B0),
              ),
            ),
          ),
          body: Row(
            children: [
              // Character Column (Fixed)
              _buildCharacterHeader(npcs),
              // Category Grid (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      _buildGridHeader(context, categories),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Table(
                            defaultColumnWidth: const FixedColumnWidth(120),
                            children: npcs
                                .map(
                                  (npc) => _buildRow(
                                    context,
                                    state,
                                    npc,
                                    categories,
                                  ),
                                )
                                .toList(),
                          ),
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
    );
  }

  Widget _buildCharacterHeader(List<NPC> npcs) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Container(
            height: 50,
            alignment: Alignment.center,
            child: Text(
              'CHARACTER',
              style: GoogleFonts.oswald(fontSize: 12, color: Colors.white30),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: npcs.length,
              itemBuilder: (context, index) => Container(
                height: 60,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Text(
                  npcs[index].name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridHeader(
    BuildContext context,
    List<ResponsibilityCategory> categories,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: categories
            .map(
              (cat) => GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ResponsibilityDetailScreen(category: cat),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.displayName.toUpperCase(),
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.settings,
                        size: 12,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  TableRow _buildRow(
    BuildContext context,
    GameState state,
    NPC npc,
    List<ResponsibilityCategory> categories,
  ) {
    return TableRow(
      children: categories.map((cat) {
        final stars = npc.responsibilities[cat] ?? 0;
        return TableCell(
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white10),
                right: BorderSide(color: Colors.white10),
              ),
            ),
            child: InkWell(
              onTap: () => _toggleStars(state, npc, cat),
              onLongPress: () => _setZeroStars(state, npc, cat),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < stars ? Icons.star : Icons.star_border,
                      size: 16,
                      color: stars == 5
                          ? Colors.redAccent
                          : (stars == 4 ? Colors.orangeAccent : Colors.amber),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleStars(GameState state, NPC npc, ResponsibilityCategory cat) {
    final current = npc.responsibilities[cat] ?? 0;
    final next = (current + 1) % 6;
    final newResp = Map<ResponsibilityCategory, int>.from(npc.responsibilities);
    newResp[cat] = next;
    state.updateNpc(npc.copyWith(responsibilities: newResp));
  }

  void _setZeroStars(GameState state, NPC npc, ResponsibilityCategory cat) {
    final newResp = Map<ResponsibilityCategory, int>.from(npc.responsibilities);
    newResp[cat] = 0;
    state.updateNpc(npc.copyWith(responsibilities: newResp));
  }
}
