import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state/game_state.dart';
import '../../models/room.dart';
import '../../services/task_service.dart';
import '../../services/construction_service.dart';
import '../widgets/manor_renderer.dart';
import '../widgets/character_portrait_dialog.dart';
import 'calendar_screen.dart';
import 'study_screen.dart';
import 'kitchen_screen.dart';
import 'library_screen.dart';
import 'laboratory_screen.dart';
import 'chicken_coop_screen.dart';
import 'world_map_screen.dart';
import 'responsibility_grid_screen.dart';
import '../widgets/time_speed_controls.dart';
import '../widgets/journal_dialog.dart';
import '../widgets/bed_assignment_widget.dart';
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
                state.resources['funds']?.toString() ?? '0',
              ),
              _resourceItem(
                Icons.forest,
                state.resources['wood']?.toString() ?? '0',
              ),
              _resourceItem(
                Icons.restaurant,
                state.resources['meat']?.toString() ?? '0',
              ),
              _resourceItem(
                Icons.egg,
                state.resources['eggs']?.toString() ?? '0',
              ),
              _resourceItem(
                Icons.grass,
                state.resources['cabbage']?.toString() ?? '0',
              ),
              const VerticalDivider(color: Colors.white10),
              IconButton(
                icon: const Icon(
                  Icons.architecture,
                  size: 18,
                  color: Color(0xFFC4B89B),
                ),
                onPressed: () => _showConstructionMenu(context),
                tooltip: 'Manor Expansion',
              ),
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
            final activeTask = state.activeTasks
                .where((t) => t.targetId == room.id)
                .firstOrNull;

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
                      room.name.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFFE5D5B0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.isRestored
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
                                "${state.npcs.firstWhere((n) => n.id == activeTask.npcId, orElse: () => state.npcs.first).name.toUpperCase()} IS CURRENTLY ${state.getTaskDescription(activeTask).toUpperCase()} (${(activeTask.minutesRemaining ~/ 60)}H ${activeTask.minutesRemaining % 60}M REMAINING)",
                                style: GoogleFonts.oldStandardTt(
                                  color: const Color(0xFFE5D5B0),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      room.detailedDescription,
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 13,
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (room.isRestored &&
                        (room.type == RoomType.study ||
                            room.type == RoomType.kitchen ||
                            room.type == RoomType.laboratory ||
                            room.type == RoomType.chickenCoop ||
                            room.type == RoomType.library))
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            if (room.type == RoomType.study) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StudyScreen(),
                                ),
                              );
                            } else if (room.type == RoomType.kitchen) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const KitchenScreen(),
                                ),
                              );
                            } else if (room.type == RoomType.laboratory) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LaboratoryScreen(room: room),
                                ),
                              );
                            } else if (room.type == RoomType.chickenCoop) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChickenCoopScreen(),
                                ),
                              );
                            } else if (room.type == RoomType.library) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LibraryScreen(room: room),
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
                            'ENTER ${room.name.toUpperCase()}',
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    if (room.type == RoomType.field ||
                        room.type == RoomType.garden)
                      _buildFieldStatus(context, state, room),
                    if (activeTask == null)
                      ...room.availableTasks.map((taskType) {
                        // Skip cleaning if already very clean
                        if (taskType == TaskType.cleanRoom &&
                            room.dirtiness < 0.05) {
                          return const SizedBox.shrink();
                        }

                        bool isAvailable = _isTaskAvailable(
                          state,
                          room,
                          taskType,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: _assignmentButton(
                            context,
                            state,
                            taskType,
                            isAvailable
                                ? () => _handleAgriculturalTask(
                                    context,
                                    state,
                                    room,
                                    taskType,
                                  )
                                : null,
                            isGreyed: !isAvailable,
                          ),
                        );
                      }),
                    if (room.isRestored &&
                        (room.type == RoomType.bedroom ||
                            room.type == RoomType.butlerQuarters ||
                            room.type == RoomType.attic ||
                            room.type == RoomType.basement))
                      BedAssignmentWidget(room: room),
                    const SizedBox(height: 24),
                    if (state.npcs.any((n) => n.currentRoomId == room.id)) ...[
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
                            .where((n) => n.currentRoomId == room.id)
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
    final label = type.displayName.toUpperCase();
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
                      "COST: ${metadata.requirements.entries.map((e) => "${e.value} ${e.key.toUpperCase()}").join(", ")}",
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

    switch (type) {
      case TaskType.plantCrops:
        return room.isTilled;
      case TaskType.waterCrops:
      case TaskType.careForCrops:
      case TaskType.harvestCabbage:
      case TaskType.harvestCrops:
        return state.crops.isNotEmpty;
      default:
        return true;
    }
  }

  void _handleAgriculturalTask(
    BuildContext context,
    GameState state,
    Room room,
    TaskType type,
  ) {
    if (type == TaskType.plantCrops) {
      _showSeedSelection(context, state, room);
    } else {
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
                          state.assignNpcToTask(
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

  void _showConstructionMenu(BuildContext context) {
    final blueprints = ConstructionService.getAvailableBlueprints();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        return Consumer<GameState>(
          builder: (context, state, child) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESTATE EXPANSION BLUEPRINTS',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFFE5D5B0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: blueprints.length,
                      itemBuilder: (context, index) {
                        final bp = blueprints[index];
                        final isBuilding = state.activeConstruction.any(
                          (p) => p.blueprint.id == bp.id,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.2),
                            ),
                            color: Colors.black.withValues(alpha: 0.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    bp.name.toUpperCase(),
                                    style: GoogleFonts.playfairDisplay(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE5D5B0),
                                    ),
                                  ),
                                  Text(
                                    "${bp.durationMinutes ~/ 60}H",
                                    style: GoogleFonts.oldStandardTt(
                                      color: const Color(0xFFC4B89B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bp.description,
                                style: GoogleFonts.oldStandardTt(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ...bp.cost.entries.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getResourceIcon(e.key),
                                            size: 12,
                                            color: const Color(0xFFC4B89B),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${e.value}",
                                            style: GoogleFonts.oldStandardTt(
                                              color: const Color(0xFFE5D5B0),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isBuilding)
                                    Text(
                                      "BUILDING...",
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.amber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  else
                                    TextButton(
                                      onPressed: () {
                                        state.startConstruction(bp);
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        "COMMENCE",
                                        style: GoogleFonts.playfairDisplay(
                                          color: const Color(0xFFC4B89B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
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
      },
    );
  }

  IconData _getResourceIcon(String res) {
    switch (res) {
      case 'funds':
        return Icons.payments;
      case 'wood':
        return Icons.forest;
      default:
        return Icons.category;
    }
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
