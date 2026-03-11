import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import '../../models/room.dart';
import '../../models/npc.dart';
import '../../models/manor_crisis.dart';
import '../../services/construction_service.dart';
import 'room_tile.dart';
import 'npc_sprite.dart';
import '../../util/manor_layout.dart';
import '../../util/manor_projection.dart';

class ManorRenderer extends StatelessWidget {
  final List<Room> rooms;
  final List<NPC> npcs;
  final List<ManorCrisis> crises;
  final List<ConstructionProject> activeConstruction;
  final Function(Room) onRoomTap;

  const ManorRenderer({
    super.key,
    required this.rooms,
    required this.npcs,
    required this.crises,
    required this.activeConstruction,
    required this.onRoomTap,
  });

  // Logical coordinate space: we'll determine height based on max floor/min floor
  static const double baseWidth = 1100;
  static const double baseHeight = 1600;

  Rect _getRoomRect(String roomId, {double scale = 1.0}) {
    final gridInfo = ManorLayout.grid[roomId];
    if (gridInfo == null) return Rect.zero;

    return ManorProjection.getRoomRect(
      gridInfo.$1, // Still project using integer floors, but x is double
      gridInfo.$2,
      gridInfo.$3,
      widthBlocks: gridInfo.$4,
      scale: scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / baseWidth;
        final actualHeight = baseHeight * scale;

        return SingleChildScrollView(
          child: Container(
            width: constraints.maxWidth,
            height: actualHeight,
            color: const Color(0xFF0A0C0E),
            child: Stack(
              children: [
                // 1. Atmospheric Depth Gradient
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF1A1D21), // Sky/Surface
                          Color(0xFF0A0C0E), // Ground
                          Color(0xFF050505), // Deep
                        ],
                        stops: [0.0, 0.4, 0.8],
                      ),
                    ),
                  ),
                ),

                // 2. Architectural Painter (Background lines & Ground Plane)
                Positioned.fill(
                  child: CustomPaint(
                    painter: ManorArchitectPainter(scale: scale),
                  ),
                ),

                // 3. Rooms
                ...rooms.map((room) {
                  final rect = _getRoomRect(room.id, scale: scale);
                  if (rect == Rect.zero) return const SizedBox.shrink();

                  return Positioned.fromRect(
                    rect: rect,
                    child: DragTarget<NPC>(
                      onWillAcceptWithDetails: (details) => true,
                      onAcceptWithDetails: (details) {
                        final npc = details.data;
                        final state = context.read<GameState>();
                        state.tryScheduleNpcTask(
                          npc.id,
                          room.defaultAction,
                          room.id,
                        );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final roomCrises = crises
                            .where((c) => c.roomId == room.id)
                            .toList();
                        final isDiscovered = roomCrises.any(
                          (c) => c.isDiscovered,
                        );

                        return Stack(
                          clipBehavior: Clip.none,
                          fit: StackFit.expand,
                          children: [
                            // 3D Depth Visual (Side/Top) - Simulated in RoomTile or here
                            Container(
                              decoration: BoxDecoration(
                                border: candidateData.isNotEmpty
                                    ? Border.all(
                                        color: Colors.blueAccent,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: RoomTile(
                                room: room,
                                onTap: () => onRoomTap(room),
                              ),
                            ),
                            if (isDiscovered)
                              Positioned.fill(
                                child: _EmergencyOverlay(crises: roomCrises),
                              ),
                          ],
                        );
                      },
                    ),
                  );
                }),

                // 4. Construction Projects
                ...activeConstruction.map((project) {
                  final bp = project.blueprint;
                  final rect = _getRoomRect(bp.id, scale: scale);
                  if (rect == Rect.zero) return const SizedBox.shrink();

                  return Positioned.fromRect(
                    rect: rect,
                    child: RoomTile(
                      room: Room.initial(
                        bp.id,
                        bp.name,
                        bp.type,
                        bp.floor,
                        width: bp.width,
                        description: bp.description,
                      ),
                      onTap: () {},
                      constructionProgress:
                          1.0 - (project.minutesRemaining / bp.durationMinutes),
                    ),
                  );
                }),

                // 5. NPCs (Overlay Layer)
                ...() {
                  final Map<String, int> roomOccupantCount = {};
                  return npcs
                      .where(
                        (n) =>
                            n.worldDestinationId == null &&
                            (n.isResident || n.currentRoomId == 'road'),
                      )
                      .map((npc) {
                        final String currentId =
                            npc.currentRoomId ?? 'entryway';
                        final int occupantIndex =
                            roomOccupantCount[currentId] ?? 0;
                        roomOccupantCount[currentId] = occupantIndex + 1;

                        final startGrid = ManorLayout.grid[currentId];
                        final String targetId = npc.targetRoomId ?? currentId;
                        final endGrid = ManorLayout.grid[targetId];

                        if (startGrid == null || endGrid == null) {
                          return const SizedBox.shrink();
                        }

                        // Center-bottom of the room face
                        final startOffset = ManorProjection.project(
                          startGrid.$1,
                          startGrid.$2,
                          startGrid.$3,
                          scale: scale,
                        );
                        final endOffset = ManorProjection.project(
                          endGrid.$1,
                          endGrid.$2,
                          endGrid.$3,
                          scale: scale,
                        );

                        // Apply horizontal jitter based on occupantIndex
                        // We want to spread them out around the center
                        final double jitter =
                            (occupantIndex - 0.5) * 30.0 * scale;

                        // Adjust to center bottom of the block
                        final Offset startPos = Offset(
                          startOffset.dx + jitter,
                          startOffset.dy -
                              (ManorProjection.blockHeight * 0.2 * scale),
                        );
                        final Offset endPos = Offset(
                          endOffset.dx + jitter,
                          endOffset.dy -
                              (ManorProjection.blockHeight * 0.2 * scale),
                        );

                        return NpcSprite(
                          npc: npc,
                          startPos: startPos,
                          endPos: endPos,
                          occupantIndex: occupantIndex,
                        );
                      });
                }(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ManorArchitectPainter extends CustomPainter {
  final double scale;

  ManorArchitectPainter({required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    final dashPaint = Paint()
      ..color = const Color(0xFFC4B89B).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    final groundPaint = Paint()
      ..color = const Color(0xFF1E1A15).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // 1. Draw Ground Plane (The "Crust")
    final groundY = ManorProjection.groundLevelY * scale;
    final path = Path()
      ..moveTo(0, groundY)
      ..lineTo(size.width, groundY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, groundPaint);

    // Architectural patterns for the crust
    for (double y = groundY; y < size.height; y += 40 * scale) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), dashPaint);
    }

    // 2. Draw Manor Skeleton (Floor beams)
    final framePaint = Paint()
      ..color = const Color(0xFFC4B89B).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale;

    for (int floor = -1; floor <= 2; floor++) {
      final left = ManorProjection.project(-3.5, floor, 0, scale: scale);
      final right = ManorProjection.project(2.5, floor, 0, scale: scale);

      // Horizontal beam
      canvas.drawLine(
        Offset(left.dx, left.dy),
        Offset(right.dx, right.dy),
        framePaint,
      );
    }

    // Vertical supports
    for (double x = -3.5; x <= 2.5; x += 1.0) {
      final top = ManorProjection.project(x, 2, 0, scale: scale);
      final bot = ManorProjection.project(x, -1, 0, scale: scale);
      
      canvas.drawLine(
        Offset(top.dx, top.dy - (ManorProjection.blockHeight * scale)),
        Offset(bot.dx, bot.dy),
        framePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EmergencyOverlay extends StatefulWidget {
  final List<ManorCrisis> crises;

  const _EmergencyOverlay({required this.crises});

  @override
  State<_EmergencyOverlay> createState() => _EmergencyOverlayState();
}

class _EmergencyOverlayState extends State<_EmergencyOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.4).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.crises.isEmpty) return const SizedBox.shrink();

    // Use the most severe crisis for the icon
    final mainCrisis = widget.crises.reduce(
      (a, b) => a.severity > b.severity ? a : b,
    );

    IconData icon;
    switch (mainCrisis.type) {
      case ManorCrisisType.fire:
        icon = Icons.local_fire_department;
        break;
      case ManorCrisisType.specimenEscape:
        icon = Icons.bug_report;
        break;
      case ManorCrisisType.intruder:
        icon = Icons.warning;
        break;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: _animation.value),
          ),
          child: Center(child: Icon(icon, color: Colors.white70, size: 24)),
        );
      },
    );
  }
}
