import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/npc.dart';
import '../../models/npc_intent.dart';
import '../../models/room.dart';
import '../../models/relationship.dart';
import '../../services/social_service.dart';
import '../../state/game_state.dart';
import 'character_blob_renderer.dart';
import '../../services/task_service.dart';

class CharacterPortraitDialog extends StatelessWidget {
  final NPC npc;

  const CharacterPortraitDialog({super.key, required this.npc});

  String _getMoodDescription() {
    if (npc.satisfaction < 30) return "ANGRY";
    if (npc.satisfaction < 60) return "DISCONTENT";
    if (npc.energy < 30) return "EXHAUSTED";
    if (npc.hunger > 70) return "FAMISHED";
    return "CONTENT";
  }

  Color _getMoodColor() {
    final mood = _getMoodDescription();
    if (mood == "ANGRY" || mood == "FAMISHED") return Colors.redAccent;
    if (mood == "DISCONTENT" || mood == "EXHAUSTED") return Colors.orangeAccent;
    return const Color(0xFFC4B89B);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1A15),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: DefaultTabController(
        length: 3,
        child: Container(
          width: 450,
          height: 600,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFC4B89B), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Portrait and Basic Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
                      ),
                      color: Colors.black26,
                    ),
                    child: Center(
                      child: CharacterBlobRenderer(
                        npc: npc,
                        size: 80,
                        isIdle: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          npc.name.toUpperCase(),
                          style: GoogleFonts.playfairDisplay(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          npc.status == NPCStatus.zombie
                              ? "${npc.role} (REANIMATED)".toUpperCase()
                              : npc.role.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            color: npc.status == NPCStatus.zombie
                                ? const Color(0xFF7A9E7E)
                                : const Color(
                                    0xFFC4B89B,
                                  ).withValues(alpha: 0.7),
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: npc.status == NPCStatus.zombie
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                indicatorColor: const Color(0xFFC4B89B),
                labelColor: const Color(0xFFE5D5B0),
                unselectedLabelColor: Colors.white24,
                labelStyle: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                tabs: const [
                  Tab(text: "STATUS"),
                  Tab(text: "BIO"),
                  Tab(text: "SOCIAL"),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildStatusTab(context),
                    _buildBioTab(context),
                    _buildSocialTab(context),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "CLOSE",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab(BuildContext context) {
    return ListView(
      children: [
        _buildStatBar(
          "ENERGY / EXHAUSTION",
          npc.energy / 100,
          Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar(
          "DIGESTION",
          npc.digestion / 100,
          Colors.deepOrangeAccent,
        ),
        const SizedBox(height: 12),
        _buildStatBar("FULLNESS", (100 - npc.hunger) / 100, Colors.greenAccent),
        const SizedBox(height: 12),
        _buildStatBar(
          "SATISFACTION",
          npc.satisfaction / 100,
          Colors.amberAccent,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: _getMoodColor().withValues(alpha: 0.3)),
            ),
            child: Text(
              _getMoodDescription(),
              style: GoogleFonts.playfairDisplay(
                color: _getMoodColor(),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActivitySection(context),
        const SizedBox(height: 24),
        _buildUpcomingSection(),
        const SizedBox(height: 24),
        _buildHousingSection(context),
      ],
    );
  }

  Widget _buildBioTab(BuildContext context) {
    return ListView(
      children: [
        _buildInfoText("HOMETOWN", npc.hometown),
        _buildInfoText("BACKGROUND", npc.background),
        _buildInfoText("AGE", "${npc.age} YEARS"),
        _buildInfoText("GENDER", npc.gender),
        _buildInfoText("ORIENTATION", npc.sexualOrientation.name.toUpperCase()),
        _buildInfoText("RELIGION", npc.religion),
        const SizedBox(height: 16),
        Text(
          "BIOGRAPHY",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFC4B89B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.black26,
          child: Text(
            npc.bio.isEmpty ? "No records available." : npc.bio,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInteractionSection(context),
      ],
    );
  }

  Widget _buildInteractionSection(BuildContext context) {
    if (npc.isPlayer) return const SizedBox.shrink();

    final state = Provider.of<GameState>(context, listen: false);
    final player = state.npcs.firstWhere((n) => n.isPlayer, orElse: () => npc);

    // Only allow interaction if they are in the same room
    if (player.currentRoomId != npc.currentRoomId || player.id == npc.id) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MANUAL INTERACTION",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFC4B89B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInteractButton(context, "CHAT", InteractionType.chat),
            _buildInteractButton(context, "PRAISE", InteractionType.praise),
            _buildInteractButton(context, "ARGUE", InteractionType.argument),
            _buildInteractButton(context, "THREATEN", InteractionType.threaten),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractButton(
    BuildContext context,
    String label,
    InteractionType type,
  ) {
    final state = Provider.of<GameState>(context, listen: false);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFC4B89B)),
        foregroundColor: const Color(0xFFC4B89B),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      onPressed: () {
        state.interactWithNpc(npc.id, type);
      },
      child: Text(
        label,
        style: GoogleFonts.oldStandardTt(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSocialTab(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final residents = state.npcs.where((n) => n.id != npc.id).toList();

    if (residents.isEmpty) {
      return Center(
        child: Text(
          "No other residents known.",
          style: GoogleFonts.oldStandardTt(color: Colors.white24, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      itemCount: residents.length,
      itemBuilder: (context, index) {
        final other = residents[index];
        final rel = npc.relationships[other.id] ?? Relationship();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black12,
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                other.name.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMiniRelBar("ADMIRATION", rel.admiration, Colors.pinkAccent),
              const SizedBox(height: 6),
              _buildMiniRelBar("RESPECT", rel.respect, Colors.cyanAccent),
              const SizedBox(height: 6),
              _buildMiniRelBar("FEAR", rel.fear, Colors.deepPurpleAccent),
              const SizedBox(height: 6),
              _buildMiniRelBar("ATTRACTION", rel.attraction, Colors.redAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniRelBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: Colors.white24,
              fontSize: 8,
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value / 5.0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(
              color.withValues(alpha: 0.4),
            ),
            minHeight: 2,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toStringAsFixed(2),
          style: GoogleFonts.oldStandardTt(color: color, fontSize: 8),
        ),
      ],
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: const Color(0xFFC4B89B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: GoogleFonts.oldStandardTt(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHousingSection(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    final currentRoom = state.rooms.firstWhere(
      (r) => r.id == npc.currentRoomId,
      orElse: () => Room.initial('na', 'na', RoomType.unused, Floor.ground),
    );
    bool inBedroom = currentRoom.type == RoomType.bedroom;
    bool isHome = npc.assignedRoomId == currentRoom.id;

    return Column(
      children: [
        if (npc.assignedRoomId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              "HOME: ${state.rooms.firstWhere((r) => r.id == npc.assignedRoomId).name.toUpperCase()}",
              style: GoogleFonts.oldStandardTt(
                color: Colors.white54,
                fontSize: 10,
              ),
            ),
          ),
        if (inBedroom && !isHome)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC4B89B),
              foregroundColor: Colors.black,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () {
              state.updateNpc(npc.copyWith(assignedRoomId: currentRoom.id));
            },
            child: const Text("ASSIGN AS HOME"),
          ),
      ],
    );
  }

  Widget _buildStatBar(String label, double progress, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.oldStandardTt(
                color: const Color(0xFFC4B89B),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(
            color.withValues(alpha: 0.6),
          ),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    final activeTask = state.activeTasks.cast<dynamic>().firstWhere(
      (t) => t.npcId == npc.id,
      orElse: () => null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CURRENT ACTIVITY",
          style: GoogleFonts.oldStandardTt(
            color: const Color(0xFFC4B89B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black38,
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activeTask != null
                    ? state.getTaskDescription(activeTask).toUpperCase()
                    : "IDLE / AT POST",
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (activeTask != null) ...[
                const SizedBox(height: 4),
                Text(
                  "${activeTask.minutesRemaining} MINUTES REMAINING",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSection() {
    return Consumer<GameState>(
      builder: (context, state, child) {
        final List<NPCIntent> enqueuedIntents = npc.intentQueue;

        // The first intent in the queue is usually the one being worked on,
        // but let's check activeTasks to be sure of progress.
        final activeTask = state.taskService.activeTasks.firstWhere(
          (t) => t.npcId == npc.id,
          orElse: () => GameTask(
            id: 'none',
            npcId: npc.id,
            type: TaskType.idle,
            minutesRemaining: 0,
          ),
        );

        // Intents that aren't the current active task (indices 1+)
        final upcomingIntents = enqueuedIntents.length > 1
            ? enqueuedIntents.sublist(1)
            : <NPCIntent>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader("WORK QUEUE"),
                Text(
                  "${enqueuedIntents.length} TASKS",
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeTask.id != 'none') ...[
              _buildTaskTile(state, activeTask: activeTask, isActive: true),
              if (upcomingIntents.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white10, height: 1),
                ),
            ],
            if (enqueuedIntents.isEmpty && activeTask.id == 'none')
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    "NO TASKS ASSIGNED",
                    style: GoogleFonts.oldStandardTt(
                      color: Colors.white12,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: upcomingIntents.length * 52.0, // Fixed height per item
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcomingIntents.length,
                  onReorder: (oldIndex, newIndex) {
                    // Reordering intents (offset by 1 because index 0 is active)
                    state.reorderIntentQueue(
                      npc.id,
                      oldIndex + 1,
                      newIndex + 1,
                    );
                  },
                  itemBuilder: (context, index) {
                    final intent = upcomingIntents[index];
                    return _buildIntentTile(
                      state,
                      intent,
                      key: ValueKey(intent.id),
                      index: index,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.oldStandardTt(
        color: const Color(0xFFC4B89B),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTaskTile(
    GameState state, {
    required GameTask activeTask,
    Key? key,
    bool isActive = true,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle, color: Color(0xFFC4B89B), size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.taskService
                      .getTaskDescription(activeTask)
                      .toUpperCase(),
                  style: GoogleFonts.oldStandardTt(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${activeTask.minutesRemaining} MIN REMAINING",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentTile(
    GameState state,
    NPCIntent intent, {
    Key? key,
    int? index,
  }) {
    // We create a temporary GameTask to use getTaskDescription helper
    final tempTask = GameTask(
      id: intent.id,
      npcId: npc.id,
      type: intent.action,
      targetId: intent.targetRoomId,
      recipeId: intent.recipeId,
      minutesRemaining: intent.minutesRemaining ?? intent.expectedDurationMin,
    );

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Colors.white24, size: 16),
          const SizedBox(width: 8),
          const Icon(Icons.schedule, color: Colors.white24, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.taskService.getTaskDescription(tempTask).toUpperCase(),
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
                Text(
                  "${intent.priority.name.toUpperCase()} PRIORITY",
                  style: GoogleFonts.oldStandardTt(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => state.cancelEnqueuedIntent(npc.id, intent.id),
          ),
        ],
      ),
    );
  }
}
