import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/objective.dart';
import '../../models/npc.dart';

class JournalDialog extends StatelessWidget {
  const JournalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF241F1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Consumer<GameState>(
          builder: (context, state, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MASTER\'S JOURNAL',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFFC4B89B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 32),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Objectives
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('ACTIVE OBJECTIVES'),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                children: state.objectives
                                    .where((o) => !o.isCompleted)
                                    .map((o) => _buildObjectiveItem(o))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionHeader('COMPLETED GOALS'),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView(
                                children: state.objectives
                                    .where((o) => o.isCompleted)
                                    .map(
                                      (o) =>
                                          _buildObjectiveItem(o, isDone: true),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildSectionHeader('FORCES & CONSTRUCTS'),
                            const SizedBox(height: 16),
                            if (state.npcs
                                .where((n) => n.status == NPCStatus.zombie)
                                .isEmpty)
                              Text(
                                'NO COMBAT UNITS AVAILABLE.',
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white12,
                                  fontSize: 12,
                                ),
                              )
                            else
                              Expanded(
                                child: ListView(
                                  children: state.npcs
                                      .where(
                                        (n) => n.status == NPCStatus.zombie,
                                      )
                                      .map((n) => _buildForceItem(n))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: Colors.white10, width: 48),
                      // Discoveries & Research
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader('SCIENTIFIC DISCOVERIES'),
                            const SizedBox(height: 16),
                            if (state.unlockedDiscoveries.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'NO SIGNIFICANT BREAKTHROUGHS YET.',
                                  style: GoogleFonts.oldStandardTt(
                                    color: Colors.white12,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else
                              ...state.unlockedDiscoveries.map(
                                (d) => _buildDiscoveryItem(d),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.black.withValues(alpha: 0.3),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RESEARCH STANDING:',
                                    style: GoogleFonts.playfairDisplay(
                                      color: const Color(0xFFC4B89B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...[
                                    'Anatomy',
                                    'Zoology',
                                    'Medicine',
                                    'Chemistry',
                                  ].map(
                                    (discipline) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            discipline.toUpperCase(),
                                            style: GoogleFonts.oldStandardTt(
                                              color: const Color(0xFFE5D5B0),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            state
                                                .getKnowledgeLevel(discipline)
                                                .toStringAsFixed(1),
                                            style: GoogleFonts.oldStandardTt(
                                              color: const Color(0xFFC4B89B),
                                              fontSize: 12,
                                            ),
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
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFC4B89B),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildObjectiveItem(Objective obj, {bool isDone = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone
            ? Colors.transparent
            : Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: isDone
              ? Colors.white10
              : const Color(0xFFC4B89B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDone ? Icons.check_circle_outline : Icons.bookmark_border,
                size: 16,
                color: isDone ? Colors.white24 : const Color(0xFFE5D5B0),
              ),
              const SizedBox(width: 8),
              Text(
                obj.title.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: isDone ? Colors.white24 : const Color(0xFFE5D5B0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),
          if (!isDone) ...[
            const SizedBox(height: 8),
            Text(
              obj.description,
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveryItem(String id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFE5D5B0), size: 14),
          const SizedBox(width: 12),
          Text(
            id.replaceAll('_', ' ').toUpperCase(),
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForceItem(NPC npc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.blueAccent, size: 14),
          const SizedBox(width: 12),
          Text(
            npc.name.toUpperCase(),
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            "LV. ${(npc.stats['strength'] ?? 50) ~/ 10}",
            style: GoogleFonts.oldStandardTt(
              color: Colors.white24,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
