import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room.dart';
import '../../models/npc.dart';

class RoomTile extends StatelessWidget {
  final Room room;
  final List<NPC> occupants;
  final VoidCallback onTap;
  final double? constructionProgress; // 0.0 to 1.0

  const RoomTile({
    super.key,
    required this.room,
    this.occupants = const [],
    required this.onTap,
    this.constructionProgress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          // 2.5D Depth Overlay (Simulated via Shadow and Border)
          Positioned(
            left: 4,
            top: 4,
            right: -4,
            bottom: -4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),

          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: _getRoomBackgroundColor(room.type, room.isRestored),
              border: Border.all(
                color: room.isRestored
                    ? const Color(0xFFC4B89B).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: room.isRestored
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Damask-style background pattern
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(
                      _getRoomIcon(room.type),
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: room.isRestored
                              ? const Color(0xFFE5D5B0)
                              : Colors.white24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (room.activeProjects.isNotEmpty && occupants.any((n) => n.status == NPCStatus.working))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: room.activeProjects.values.map((project) {
                              // Only show projects that have a worker assigned AND they are present (which we know by 'working' status + occupants filter)
                              final isBeingWorkedOn = occupants.any((n) => n.activeTaskId == project.taskId && n.status == NPCStatus.working);
                              if (!isBeingWorkedOn) return const SizedBox.shrink();

                              return Tooltip(
                                message:
                                    "${project.name} (${(project.progress * 100).toInt()}%)",
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.2),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.5),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Icon(
                                    _getProjectIcon(project.type),
                                    size: 12,
                                    color: Colors.amber,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (room.isRestored)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              _getRoomIcon(room.type),
                              size: 14,
                              color: const Color(
                                0xFFC4B89B,
                              ).withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                // Construction Progress Overlay
                if (constructionProgress != null && occupants.any((n) => n.status == NPCStatus.working))
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.architecture,
                            color: Colors.amber,
                            size: 28,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: LinearProgressIndicator(
                              value: constructionProgress,
                              backgroundColor: Colors.white10,
                              color: Colors.amber,
                              minHeight: 3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "CONSTRUCTING",
                            style: GoogleFonts.outfit(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Toolbox Icon (Active Work Indicator)
                if (occupants.any((n) => n.status == NPCStatus.working && n.activeTaskId != null && n.currentRoomId == room.id))
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFC4B89B).withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.build,
                        size: 14,
                        color: Color(0xFFC4B89B),
                      ),
                    ),
                  ),

                // Disrepair Overlay
                if (!room.isRestored && constructionProgress == null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.lock_clock_outlined,
                          color: Colors.white.withValues(alpha: 0.1),
                          size: 32,
                        ),
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

  IconData _getProjectIcon(ProjectType type) {
    switch (type) {
      case ProjectType.cooking:
        return Icons.soup_kitchen;
      case ProjectType.research:
        return Icons.description;
      case ProjectType.laboratory:
        return Icons.science;
      case ProjectType.craft:
        return Icons.handyman;
      case ProjectType.assembly:
        return Icons.architecture;
    }
  }

  IconData _getRoomIcon(RoomType type) {
    switch (type) {
      case RoomType.entryway:
        return Icons.door_front_door;
      case RoomType.kitchen:
        return Icons.kitchen;
      case RoomType.diningRoom:
        return Icons.restaurant;
      case RoomType.study:
        return Icons.menu_book;
      case RoomType.bedroom:
        return Icons.bed;
      case RoomType.attic:
        return Icons.inventory;
      case RoomType.basement:
        return Icons.foundation;
      case RoomType.toilet:
        return Icons.wc;
      case RoomType.butlerQuarters:
        return Icons.person;
      case RoomType.unused:
        return Icons.not_interested;
      case RoomType.laboratory:
        return Icons.biotech;
      case RoomType.chickenCoop:
        return Icons.egg_outlined;
      case RoomType.library:
        return Icons.auto_stories;
      case RoomType.field:
        return Icons.agriculture;
      case RoomType.garden:
        return Icons.local_florist;
      case RoomType.brewery:
        return Icons.liquor;
      case RoomType.distillery:
        return Icons.science;
      case RoomType.workshop:
        return Icons.handyman;
      case RoomType.granary:
        return Icons.storage;
      case RoomType.operatingRoom:
        return Icons.medical_services;
      case RoomType.pigPen:
        return Icons.pets;
      case RoomType.cattlePasture:
        return Icons.agriculture;
      case RoomType.greenhouse:
        return Icons.eco;
      case RoomType.tenement:
        return Icons.home_work;
    }
  }

  Color _getRoomBackgroundColor(RoomType type, bool isRestored) {
    if (!isRestored) return const Color(0xFF0F1113);

    switch (type) {
      case RoomType.library:
        return const Color(0xFF1A1512); // Warm mahogany/old paper
      case RoomType.study:
        return const Color(0xFF15181C); // Deep ink blue
      case RoomType.kitchen:
        return const Color(0xFF1D1A16); // Hearth warm
      case RoomType.field:
        return const Color(0xFF161C15); // Damp grass
      case RoomType.garden:
        return const Color(0xFF181C15); // Lush green
      case RoomType.brewery:
        return const Color(0xFF1D1814); // Ale/Copper
      case RoomType.distillery:
        return const Color(0xFF16191D); // Steel/Glass
      case RoomType.workshop:
        return const Color(0xFF1E1A17); // Sawdust/Wood
      case RoomType.granary:
        return const Color(0xFF1C1A14); // Grain/Straw
      case RoomType.pigPen:
        return const Color(0xFF1D1A16); // Mud/Wood
      case RoomType.cattlePasture:
        return const Color(0xFF161C15); // Grass
      case RoomType.greenhouse:
        return const Color(0xFF1A2218); // Modern glass/green
      case RoomType.tenement:
        return const Color(0xFF1E1612); // Brick/Wood
      default:
        return const Color(0xFF1A1D21);
    }
  }
}
