import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/room.dart';
import '../../services/task_service.dart';
import '../widgets/manor_renderer.dart';
import '../widgets/character_portrait_dialog.dart';
import '../widgets/room_ledger.dart';
import '../widgets/bed_assignment_widget.dart';
import 'calendar_screen.dart';
import 'study_screen.dart';
import 'kitchen_screen.dart';
import 'library_screen.dart';
import 'laboratory_screen.dart';
import 'chicken_coop_screen.dart';
import '../widgets/journal_dialog.dart';
import 'world_map_screen.dart';
import 'responsibility_grid_screen.dart';
import '../widgets/time_speed_controls.dart';
import 'residents_panel.dart';
import '../widgets/save_load_dialogs.dart';
import 'combat_screen.dart';
import 'game_over_screen.dart';

class ManorScreen extends StatefulWidget {
  const ManorScreen({super.key});

  @override
  State<ManorScreen> createState() => _ManorScreenState();
}

class _ManorScreenState extends State<ManorScreen> {
  bool _hudExpanded = true;
  bool _isNavigatingToCombat = false;

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback or status listener if needed,
    // but a simpler way is to check in didChangeDependencies or use a listener.
  }

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

    if (state.isGameOver) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => GameOverScreen(
              reason: state.gameOverReason ?? "The experiment has ended.",
            ),
          ),
          (route) => false,
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1612),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'ABOMINATION',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 18,
            color: const Color(0xFFE5D5B0),
          ),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _hudExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFFC4B89B),
            ),
            onPressed: () => setState(() => _hudExpanded = !_hudExpanded),
            tooltip: 'Toggle HUD',
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFFC4B89B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WorldMapScreen()),
              );
            },
            tooltip: 'Survey Estate',
          ),
          IconButton(
            icon: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFC4B89B),
            ),
            onPressed: () => _showInventory(context),
            tooltip: 'Inventory',
          ),
          IconButton(
            icon: const Icon(
              Icons.assignment_ind_outlined,
              color: Color(0xFFC4B89B),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ResponsibilityGridScreen(),
                ),
              );
            },
            tooltip: 'Responsibilities',
          ),
          IconButton(
            icon: const Icon(Icons.groups_outlined, color: Color(0xFFC4B89B)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResidentsPanel()),
              );
            },
            tooltip: 'Residents',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Color(0xFFC4B89B)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SaveGameDialog(),
              );
            },
            tooltip: 'Document Progress',
          ),
          _buildClockWidget(context),
        ],
      ),
      body: Container(
        color: const Color(0xFF0A0C0E),
        child: Column(
          children: [
            // Persistent Resource Bar
            _buildResourceBar(context),
            
            // Collapsible Section
            AnimatedCrossFade(
              firstChild: Column(
                children: [
                  _buildAnnouncementBanner(context),
                  const TimeSpeedControls(),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Divider(color: Colors.white10),
                  ),
                ],
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _hudExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 300),
            ),

            Expanded(
              child: Consumer<GameState>(
                builder: (context, state, child) {
                  return ManorRenderer(
                    rooms: state.rooms,
                    npcs: state.npcs,
                    crises: state.crises,
                    activeConstruction: state.activeConstruction,
                    onRoomTap: (room) => _showRoomDetails(context, room),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBar(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.black.withValues(alpha: 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _resourceItem(
                Icons.payments,
                (state.resources['funds'] ?? 0).round().toString(),
              ),
              _resourceItem(
                Icons.forest,
                (state.resources['wood'] ?? 0).round().toString(),
              ),
              _resourceItem(
                Icons.restaurant,
                (state.resources['meat'] ?? 0).round().toString(),
              ),
              _resourceItem(
                Icons.egg,
                (state.resources['eggs'] ?? 0).round().toString(),
              ),
              _resourceItem(
                Icons.grass,
                (state.resources['cabbage'] ?? 0).round().toString(),
              ),
              const VerticalDivider(color: Colors.white10),
              Consumer<GameState>(
                builder: (context, state, child) {
                  return Badge(
                    label: Text(state.unreadObjectiveCount.toString()),
                    isLabelVisible: state.unreadObjectiveCount > 0,
                    backgroundColor: const Color(0xFF8B0000), // Blood red
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu_book,
                        size: 18,
                        color: Color(0xFFC4B89B),
                      ),
                      onPressed: () {
                        state.markObjectivesRead();
                        showDialog(
                          context: context,
                          builder: (context) => const JournalDialog(),
                        );
                      },
                      tooltip: 'Master\'s Journal',
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.history_edu,
                  size: 18,
                  color: Color(0xFFC4B89B),
                ),
                onPressed: () => _showNotificationHistory(context),
                tooltip: 'Chronicle of Events',
              ),
              IconButton(
                icon: const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Color(0xFFC4B89B),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
                tooltip: 'Chronicle of Time',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _resourceItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFFC4B89B)),
        const SizedBox(width: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFFE5D5B0),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showNotificationHistory(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHRONICLE OF EVENTS',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
              const SizedBox(height: 16),
              if (state.announcementHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'The journals are empty.',
                      style: GoogleFonts.outfit(color: Colors.white24),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: state.announcementHistory.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          state.announcementHistory[index].toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFC4B89B),
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementBanner(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        if (state.lastAnnouncement == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF241F1A),
            border: Border.all(
              color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Color(0xFFE5D5B0),
                size: 16,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.lastAnnouncement!.toUpperCase(),
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFE5D5B0),
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInventory(BuildContext context) {
    final state = Provider.of<GameState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLLECTED SPECIMENS & ITEMS',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
              const SizedBox(height: 16),
              if (state.inventory.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(
                    child: Text(
                      'No items collected yet.',
                      style: GoogleFonts.oldStandardTt(color: Colors.white24),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.inventory
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.science_outlined,
                                size: 14,
                                color: Color(0xFFC4B89B),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.name.toUpperCase(),
                                style: GoogleFonts.oldStandardTt(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showRoomDetails(BuildContext context, Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF241F1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            final liveRoom = state.rooms.firstWhere(
              (r) => r.id == room.id,
              orElse: () => room,
            );
            final roomQueue = state.getRoomTaskQueue(liveRoom.id);
            final activeTask = state.activeTasks
                .where((t) => t.targetId == liveRoom.id)
                .firstOrNull;
            final displayQueue = roomQueue.where((q) => q.intentId != activeTask?.intentId && q.intentId != activeTask?.id).toList();

            return Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      liveRoom.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      liveRoom.isRestored
                          ? 'RESTORED AND FUNCTIONAL.'
                          : 'THIS ROOM IS IN DISREPAIR AND REQUIRES RESTORATION.',
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 14,
                        color: const Color(0xFFC4B89B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (activeTask != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          color: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_bottom,
                              color: Color(0xFFE5D5B0),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "${state.npcs.firstWhereOrNull((n) => n.id == activeTask.npcId)?.name.toUpperCase() ?? "WORKER"} IS CURRENTLY ${state.getTaskDescription(activeTask).toUpperCase()}",
                          style: GoogleFonts.oldStandardTt(
                            color: const Color(0xFFE5D5B0),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        activeTask.type == TaskType.rest ? "UNTIL WAKEFUL" : "${(activeTask.minutesRemaining ~/ 60)}H ${activeTask.minutesRemaining % 60}M",
                        style: GoogleFonts.oswald(
                          color: const Color(0xFFC4B89B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                            IconButton(
                              onPressed: () => state.cancelTask(activeTask.id),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              tooltip: 'CANCEL TASK',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      liveRoom.description,
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 14,
                        color: const Color(0xFFE5D5B0).withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ROOM TASK QUEUE (Dynamic view of NPC intents)
                    if (displayQueue.isNotEmpty) ...[
                      Text(
                        'ENQUEUED TASKS',

                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC4B89B),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...displayQueue.map(
                        (task) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "• ${task.description.toUpperCase()}",
                                  style: GoogleFonts.oldStandardTt(
                                    fontSize: 12,
                                    color: const Color(
                                      0xFFE5D5B0,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 24.0),
                                child: IconButton(
                                  onPressed: () => state.cancelEnqueuedIntent(task.npcId, task.intentId),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.redAccent,
                                    size: 16,
                                  ),
                                  tooltip: 'CANCEL TASK',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // BUILDING & CONVERSION OPTIONS
                    if (liveRoom.type == RoomType.unused) ...[
                      // Spare Bedroom (Ground Floor Unused)
                      if (liveRoom.floor == Floor.ground)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'CONVERT TO SPARE BEDROOM',
                            'Establish a quiet dwelling for residents (250 Wood, 500 Funds)',
                            Icons.king_bed,
                            () => state.convertUnusedToBedroom(liveRoom.id),
                          ),
                        ),

                      // Greenhouse (Garden Lot)
                      if (liveRoom.id == 'garden_lot')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'BUILD GREENHOUSE',
                            'Construct a glass enclosure for rare botanicals (100 Wood, 200 Funds)',
                            Icons.eco,
                            () => state.buildGreenhouse(liveRoom.id),
                          ),
                        ),

                      // Tenement (Empty Lot)
                      if (liveRoom.id == 'empty_lot')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'BUILD TENEMENT',
                            'Communal housing for additional labor (200 Wood, 400 Funds)',
                            Icons.domain,
                            () => state.buildTenement(liveRoom.id),
                          ),
                        ),

                      // Laboratory (Attic/Basement)
                      if (liveRoom.floor == Floor.attic ||
                          liveRoom.floor == Floor.basement)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildExpandButton(
                            context,
                            'CONVERT TO LABORATORY',
                            'Outfit this secluded room for experimentation (50 Wood, 1000 Funds)',
                            Icons.biotech,
                            () => state.convertRoomToLaboratory(liveRoom.id),
                          ),
                        ),
                    ],
                    if (liveRoom.isRestored &&
                        (liveRoom.type == RoomType.study ||
                            liveRoom.type == RoomType.kitchen ||
                            liveRoom.type == RoomType.laboratory ||
                            liveRoom.type == RoomType.chickenCoop ||
                            liveRoom.type == RoomType.library))
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (liveRoom.type == RoomType.study) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudyScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.kitchen) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KitchenScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.laboratory) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaboratoryScreen(room: liveRoom),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.chickenCoop) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChickenCoopScreen(),
                                ),
                              );
                            } else if (liveRoom.type == RoomType.library) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LibraryScreen(room: liveRoom),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFC4B89B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                            backgroundColor: const Color(
                              0xFFC4B89B,
                            ).withValues(alpha: 0.1),
                          ),
                          icon: const Icon(
                            Icons.login,
                            color: Color(0xFFE5D5B0),
                          ),
                          label: Text(
                            'ENTER ${liveRoom.name.toUpperCase()}',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    if (liveRoom.type == RoomType.kitchen ||
                        liveRoom.type == RoomType.study ||
                        liveRoom.type == RoomType.library ||
                        liveRoom.type == RoomType.chickenCoop) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),
                      Text(
                        'ROOM LEDGER',
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoomLedger(room: liveRoom, state: state),
                      const SizedBox(height: 32),
                    ],
                    if (liveRoom.type == RoomType.field ||
                        liveRoom.type == RoomType.garden)
                      _buildFieldStatus(context, state, liveRoom),
                    ...liveRoom.availableTasks
                        .where((taskType) {
                      // Only show available tasks. If it's a one-time task and someone is already doing it,
                      // it will be caught by _isTaskAvailable logic or assignNpcToTask.
                      // For now, let's keep it simple: always show if available.
                          return _isTaskAvailable(state, liveRoom, taskType);
                    }).map((taskType) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _assignmentButton(
                          context,
                          state,
                          taskType,
                          () => _handleTaskInteraction(
                            context,
                            state,
                                liveRoom,
                            taskType,
                          ),
                        ),
                      );
                    }),
                    if (liveRoom.isRestored &&
                        (liveRoom.type == RoomType.bedroom ||
                            liveRoom.type == RoomType.butlerQuarters ||
                            liveRoom.type == RoomType.attic ||
                            liveRoom.type == RoomType.basement))
                      BedAssignmentWidget(room: liveRoom),
                    const SizedBox(height: 24),
                    if (state.npcs.any(
                      (n) => n.currentRoomId == liveRoom.id,
                    )) ...[
                      Text(
                        "OCCUPANTS:",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFC4B89B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: state.npcs
                            .where((n) => n.currentRoomId == liveRoom.id)
                            .map(
                              (npc) => InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) =>
                                        CharacterPortraitDialog(npc: npc),
                                  );
                                },
                                child: Chip(
                                  label: Text(
                                    npc.name.toUpperCase(),
                                    style: GoogleFonts.oldStandardTt(
                                      fontSize: 10,
                                    ),
                                  ),
                                  avatar: Icon(
                                    npc.isPlayer ? Icons.stars : Icons.person,
                                    size: 14,
                                  ),
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _assignmentButton(
    BuildContext context,
    GameState state,
    TaskType type,
    VoidCallback? onPressed, {
    bool isGreyed = false,
  }) {
    final metadata = TaskService.getMetadata(type);
    String label = type.displayName.toUpperCase();
 
    // Dynamic labels for Cook and Research
    if (type == TaskType.cook && state.cookingQueue.isNotEmpty) {
      final recipeId = state.cookingQueue.first;
      label = "COOK ${recipeId.replaceAll('_', ' ')}".toUpperCase();
    } else if (type == TaskType.research && state.researchQueue.isNotEmpty) {
      final topic = state.researchQueue.first;
      label = "RESEARCH ${topic.toUpperCase()}";
    }
 
    final icon = _getTaskIcon(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isGreyed
                ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                : const Color(0xFFE5D5B0),
          ),
          padding: const EdgeInsets.all(16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: isGreyed ? Colors.transparent : Colors.black12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isGreyed
                      ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                      : const Color(0xFFE5D5B0),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: isGreyed
                        ? const Color(0xFFC4B89B).withValues(alpha: 0.2)
                        : const Color(0xFFE5D5B0),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (!isGreyed)
                  Text(
                    metadata.typicalDuration.toUpperCase(),
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (!isGreyed) ...[
              const SizedBox(height: 8),
              Text(
                metadata.explanation,
                style: GoogleFonts.oldStandardTt(
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.7),
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "REQUIRED SKILLS:",
                          style: GoogleFonts.oswald(
                            fontSize: 9,
                            color: const Color(
                              0xFFE5D5B0,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          metadata.relevantAttributes.join(", ").toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            fontSize: 10,
                            color: const Color(0xFFC4B89B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "POTENTIAL OUTCOMES:",
                          style: GoogleFonts.oswald(
                            fontSize: 9,
                            color: const Color(
                              0xFFE5D5B0,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        Text(
                          metadata.possibleOutcomes.join(", ").toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            fontSize: 10,
                            color: const Color(0xFFC4B89B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (metadata.requirements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isGreyed
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.white10,
                  border: Border.all(
                    color: isGreyed
                        ? Colors.red.withValues(alpha: 0.3)
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 10,
                      color: isGreyed
                          ? Colors.redAccent
                          : const Color(0xFFE5D5B0),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "COST: ${metadata.requirements.entries.map((e) => "${e.value.round()} ${e.key.toUpperCase()}").join(", ")}",
                      style: GoogleFonts.oswald(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: isGreyed
                            ? Colors.redAccent
                            : const Color(0xFFE5D5B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFieldStatus(BuildContext context, GameState state, Room room) {
    // Current crops in this "room" (field)
    final roomCrops = state.crops.where((c) => c.roomId == room.id).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusRow("SOIL TILLING:", room.tilledAmount),
          const SizedBox(height: 8),
          _statusRow("FERTILIZATION:", room.fertilizedAmount),
          if (roomCrops.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white10),
            ),
            Text(
              "ACTIVE CROPS:",
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: const Color(0xFFC4B89B),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _statusRow("GROWTH PROGRESS:", roomCrops[0].growthProgress),
            const SizedBox(height: 8),
            _statusRow("MOISTURE LEVEL:", roomCrops[0].moistureLevel),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white10),
            ),
            Text(
              "NO CROPS PLANTED",
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: Colors.white24,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusRow(String label, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                color: Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${(progress * 100).toInt()}%",
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: const Color(0xFFE5D5B0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          color: const Color(0xFFC4B89B),
          minHeight: 2,
        ),
      ],
    );
  }

  bool _isTaskAvailable(GameState state, Room room, TaskType type) {
    final metadata = TaskService.getMetadata(type);
    for (var entry in metadata.requirements.entries) {
      if ((state.resources[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }

    // Avoid double-assignment for non-repeatable room tasks if already active or queued
    final isRepeatable = type == TaskType.cook ||
        type == TaskType.research ||
        type == TaskType.archiveResearch ||
        type == TaskType.transcribeNotes;

    if (!isRepeatable) {
      final isAlreadyActiveOrQueued = state.activeTasks.any(
        (t) => t.targetId == room.id && t.type == type,
      );
      if (isAlreadyActiveOrQueued) return false;
    }

    switch (type) {
      case TaskType.cleanRoom:
        return room.dirtiness > 0.1;
      case TaskType.cleanDish:
        return (state.resources['dirty_dishes'] ?? 0) > 0;
      case TaskType.butcherAnimals:
        return (state.resources['cattle_carcass'] ?? 0) > 0;
      case TaskType.cook:
        return state.cookingQueue.isNotEmpty;
      case TaskType.research:
        return state.researchQueue.isNotEmpty;
      case TaskType.plantCrops:
        return room.isTilled;
      case TaskType.waterCrops:
      case TaskType.careForCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestCrops:
        return state.crops.where((c) => c.roomId == room.id).isNotEmpty;
      default:
        return true;
    }
  }

  void _handleTaskInteraction(
    BuildContext context,
    GameState state,
    Room room,
    TaskType type,
  ) {
    switch (type) {
      case TaskType.plantCrops:
        _showSeedSelection(context, state, room);
        break;
      case TaskType.cook:
      case TaskType.research:
        // No sub-selection anymore, just go straight to worker selection
        _showWorkerSelection(context, state, room, type);
        break;
      default:
        _showWorkerSelection(context, state, room, type);
    }
  }


  void _showSeedSelection(BuildContext context, GameState state, Room room) {
    final seedResources = state.resources.entries
        .where((e) => e.key.startsWith('seeds_') && e.value > 0)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT SEEDS TO PLANT',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              if (seedResources.isEmpty)
                const Center(child: Text("NO SEEDS AVAILABLE")),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: seedResources.length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final seed = seedResources[index];
                    final cropTypeName = seed.key.replaceFirst('seeds_', '');
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context); // Close seeds
                        _showWorkerSelection(
                          context,
                          state,
                          room,
                          TaskType.plantCrops,
                          recipeId: cropTypeName,
                        );
                      },
                      leading: const Icon(
                        Icons.grass,
                        color: Color(0xFFC4B89B),
                      ),
                      title: Text(
                        cropTypeName.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        "${seed.value} AVAILABLE",
                        style: GoogleFonts.oswald(
                          fontSize: 12,
                          color: Colors.white38,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWorkerSelection(
    BuildContext context,
    GameState state,
    Room room,
    TaskType? type, {
    bool isHousing = false,
    String? recipeId,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isHousing ? 'ASSIGN QUARTERS' : 'SELECT WORKER',
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFFE5D5B0),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.npcs
                      .where((n) => n.isResident)
                      .length,
                  separatorBuilder: (context, index) =>
                      const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final npc = state.npcs
                        .where((n) => n.isResident)
                        .toList()[index];
                    final estMinutes = type != null
                        ? state.getEstimatedTaskMinutes(npc, type)
                        : 0;
                    final efficiency = type != null
                        ? state.getTaskEfficiency(npc, type)
                        : 1.0;

                    String warning = "";
                    Color warningColor = Colors.greenAccent;
                    if (isHousing) {
                      warning = npc.assignedRoomId == room.id
                          ? "Current Quarters"
                          : "Available";
                    } else if (efficiency < 1.0) {
                      warning = "Inefficient";
                      warningColor = Colors.redAccent;
                    } else if (efficiency > 1.0) {
                      warning = "Highly Suitable";
                      warningColor = Colors.amberAccent;
                    }

                    return ListTile(
                      onTap: () {
                        if (isHousing) {
                          state.assignHousing(npc.id, room.id);
                        } else if (type != null) {
                          state.tryScheduleNpcTask(
                            npc.id,
                            type,
                            room.id,
                            recipeId: recipeId,
                          );
                        }
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      leading: const Icon(
                        Icons.person,
                        color: Color(0xFFC4B89B),
                      ),
                      title: Text(
                        npc.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: const Color(0xFFE5D5B0),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isHousing)
                            Text(
                              "EST. TIME: ${estMinutes ~/ 60}H ${estMinutes % 60}M",
                              style: GoogleFonts.oldStandardTt(
                                color: const Color(
                                  0xFFC4B89B,
                                ).withValues(alpha: 0.6),
                                fontSize: 10,
                              ),
                            ),
                          if (warning.isNotEmpty)
                            Text(
                              warning.toUpperCase(),
                              style: GoogleFonts.oldStandardTt(
                                color: warningColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white24,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          onPressed();
          Navigator.pop(context);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFC4B89B)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          backgroundColor: const Color(0xFFC4B89B).withValues(alpha: 0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE5D5B0), size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.oldStandardTt(
                      color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTaskIcon(TaskType type) {
    switch (type) {
      case TaskType.cleanRoom:
        return Icons.cleaning_services;
      case TaskType.cook:
      case TaskType.prepareMeals:
        return Icons.restaurant;
      case TaskType.research:
        return Icons.menu_book;
      case TaskType.dissect:
      case TaskType.vivisection:
      case TaskType.surgicalOperation:
      case TaskType.surgery:
        return Icons.biotech;
      case TaskType.collectEggs:
        return Icons.egg;
      case TaskType.guardCoop:
        return Icons.security;
      case TaskType.archiveResearch:
      case TaskType.transcribeNotes:
        return Icons.inventory_2;
      case TaskType.tillSoil:
      case TaskType.plantCrops:
      case TaskType.waterCrops:
      case TaskType.fertilizeSoil:
      case TaskType.careForCrops:
      case TaskType.harvestCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestGrain:
        return Icons.agriculture;
      case TaskType.restoreRoom:
        return Icons.build_outlined;
      case TaskType.rest:
        return Icons.hotel;
      case TaskType.processTimber:
      case TaskType.blacksmithing:
      case TaskType.manufacturing:
      case TaskType.invention:
        return Icons.handyman;
      case TaskType.brew:
      case TaskType.distill:
        return Icons.local_bar;
      case TaskType.hauling:
        return Icons.unarchive;
      case TaskType.useToilet:
        return Icons.wc;
      case TaskType.greetGuest:
        return Icons.hail;
      case TaskType.defendManor:
        return Icons.shield;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildClockWidget(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                state.currentDate.formattedDate.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
              Text(
                state.currentDate.formattedTime,
                style: GoogleFonts.oldStandardTt(
                  fontSize: 10,
                  color: const Color(0xFFC4B89B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
