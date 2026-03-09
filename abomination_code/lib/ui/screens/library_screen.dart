import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/room.dart';
import '../../services/task_service.dart';

class LibraryScreen extends StatelessWidget {
  final Room room;

  const LibraryScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        title: Text(
          'THE LIBRARY',
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
                // Left Panel: Archive Status
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
                        _buildSectionTitle('FORBIDDEN LORE'),
                        const SizedBox(height: 24),
                        _buildArchiveStat('TOTAL VOLUMES', '342'),
                        _buildArchiveStat('ARCHIVED', '12%'),
                        const Spacer(),
                        _buildSectionTitle('COLLECTION VALUE'),
                        const SizedBox(height: 8),
                        Text(
                          '${state.inventory.where((i) => i.name.contains('Note') || i.name.contains('Book')).length * 50} SHEKELS',
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Right Panel: Archiving Tasks
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('ACTIVE RESEARCH & ARCHIVING'),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.2),
                              ),
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: ListView(
                              padding: const EdgeInsets.all(20),
                              children: [
                                _buildArchiveTask(
                                  context,
                                  state,
                                  'ARCHIVE FORBIDDEN SCROLLS',
                                  'Consolidate research notes into the library collection.',
                                  Icons.history_edu,
                                  TaskType.archiveResearch,
                                ),
                                const SizedBox(height: 16),
                                _buildArchiveTask(
                                  context,
                                  state,
                                  'CATALOG SPECIMEN NOTES',
                                  'Systematically cross-reference and store anatomical data.',
                                  Icons.auto_stories,
                                  TaskType.transcribeNotes,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('ACTIVITY QUEUE'),
                        const SizedBox(height: 16),
                        _buildResearchQueue(context, state),
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

  Widget _buildArchiveStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFC4B89B),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFE5D5B0),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveTask(
    BuildContext context,
    GameState state,
    String title,
    String desc,
    IconData icon,
    TaskType type,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC4B89B), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // Add to the same unified queue
              state.addScienceActivityToQueue(
                type == TaskType.archiveResearch
                    ? 'library_archive'
                    : 'library_transcribe',
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFC4B89B)),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'ENQUEUE',
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResearchQueue(BuildContext context, GameState state) {
    final queue = state.researchQueue;
    if (queue.isEmpty) {
      return Center(
        child: Text(
          'NO PENDING TASKS',
          style: GoogleFonts.oldStandardTt(color: Colors.white10, fontSize: 12),
        ),
      );
    }

    return Column(
      children: List.generate(queue.length, (index) {
        final queueId = queue[index];
        final isArchive = queueId == 'library_archive';
        final isTranscribe = queueId == 'library_transcribe';

        if (!isArchive && !isTranscribe) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
            ),
            color: Colors.black.withValues(alpha: 0.3),
          ),
          child: ListTile(
            dense: true,
            leading: Icon(
              isArchive ? Icons.history_edu : Icons.auto_stories,
              color: const Color(0xFFC4B89B),
              size: 16,
            ),
            title: Text(
              (isArchive ? 'ARCHIVE RESEARCH' : 'TRANSCRIBE NOTES')
                  .toUpperCase(),
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close, color: Colors.white24, size: 14),
              onPressed: () => state.removeResearchFromQueue(index),
            ),
          ),
        );
      }).where((w) => w is! SizedBox).toList(),
    );
  }
}
