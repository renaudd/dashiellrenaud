import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/npc.dart';
import '../../models/experiment.dart';
import '../../models/room.dart';

class LaboratoryScreen extends StatelessWidget {
  final Room room;

  const LaboratoryScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'THE LABORATORY',
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
      body: Consumer<GameState>(
        builder: (context, state, child) {
          final occupants = state.npcs
              .where((n) => n.currentRoomId == room.id)
              .toList();
          final activeExperiments = state.activeExperiments
              .where((e) => occupants.any((o) => o.id == e.subjectId))
              .toList();

          return Container(
            decoration: BoxDecoration(
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
            child: Row(
              children: [
                // Left Panel: Active Experiments
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('ACTIVE TRIALS'),
                        const SizedBox(height: 24),
                        if (activeExperiments.isEmpty)
                          Expanded(
                            child: Center(
                              child: Text(
                                'No ongoing experiments.',
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white12,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              itemCount: activeExperiments.length,
                              itemBuilder: (context, index) {
                                final exp = activeExperiments[index];
                                final subject = state.npcs.firstWhere(
                                  (n) => n.id == exp.subjectId,
                                );
                                return _buildActiveExperimentTile(
                                  context,
                                  exp,
                                  subject,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Subject Selection
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('POTENTIAL SUBJECTS'),
                        const SizedBox(height: 24),
                        if (occupants.isEmpty)
                          Expanded(
                            child: Center(
                              child: Text(
                                'No one is currently in this laboratory.',
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.5,
                                  ),
                              itemCount: occupants.length,
                              itemBuilder: (context, index) {
                                final npc = occupants[index];
                                final isBusy = activeExperiments.any(
                                  (e) => e.subjectId == npc.id,
                                );
                                return _buildSubjectTile(
                                  context,
                                  state,
                                  npc,
                                  isBusy,
                                );
                              },
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        color: const Color(0xFFE5D5B0),
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildActiveExperimentTile(
    BuildContext context,
    Experiment exp,
    NPC subject,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exp.type.name.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "SUBJECT: ${subject.name}",
            style: GoogleFonts.oldStandardTt(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: exp.progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFC4B89B)),
            minHeight: 2,
          ),
          const SizedBox(height: 8),
          Text(
            "${exp.minutesRemaining}M REMAINING",
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTile(
    BuildContext context,
    GameState state,
    NPC npc,
    bool isBusy,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(
              npc.isPlayer ? Icons.stars : Icons.person,
              color: const Color(0xFFC4B89B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            npc.name.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFE5D5B0),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (isBusy)
            Text(
              "IN TRIAL",
              style: GoogleFonts.oldStandardTt(
                color: Colors.amber,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            OutlinedButton(
              onPressed: () => _showExperimentSelection(context, state, npc),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC4B89B)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                "SELECT EXPERIMENT",
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

  void _showExperimentSelection(
    BuildContext context,
    GameState state,
    NPC npc,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT SCIENTIFIC PROCEDURE',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildExperimentOption(
                context,
                state,
                npc,
                ExperimentType.dissection,
                "DISSECTION",
                "Gather anatomical knowledge. (Fatal risk)",
              ),
              _buildExperimentOption(
                context,
                state,
                npc,
                ExperimentType.lobotomy,
                "LOBOTOMY",
                "Reduce willpower and intellect for compliance.",
              ),
              _buildExperimentOption(
                context,
                state,
                npc,
                ExperimentType.reanimation,
                "REANIMATION",
                "Stir the spark of life within the subject.",
                isLocked: !state.unlockedDiscoveries.contains(
                  'basic_reanimation',
                ),
              ),
              _buildExperimentOption(
                context,
                state,
                npc,
                ExperimentType.transmutation,
                "TRANSMUTATION",
                "Alter the biological foundation.",
                isLocked: !state.unlockedDiscoveries.contains(
                  'artificial_muscle',
                ), // Place holder for biological foundations
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExperimentOption(
    BuildContext context,
    GameState state,
    NPC npc,
    ExperimentType type,
    String title,
    String desc, {
    bool isLocked = false,
  }) {
    return ListTile(
      enabled: !isLocked,
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          color: isLocked ? Colors.white10 : const Color(0xFFE5D5B0),
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        isLocked ? "INSUFFICIENT SCIENTIFIC KNOWLEDGE" : desc,
        style: GoogleFonts.oldStandardTt(
          color: isLocked ? Colors.white10 : Colors.white54,
          fontSize: 12,
        ),
      ),
      onTap: isLocked
          ? null
          : () {
              final exp = Experiment.create(npc.id, type);
              state.startExperiment(exp);
              Navigator.pop(context);
            },
      trailing: Icon(
        isLocked ? Icons.lock : Icons.chevron_right,
        color: isLocked ? Colors.white10 : const Color(0xFFC4B89B),
        size: 14,
      ),
    );
  }
}
