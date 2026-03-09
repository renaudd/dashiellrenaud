import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/npc.dart';
import 'package:provider/provider.dart';
import '../../state/game_state.dart';
import 'character_portrait_dialog.dart';
import 'character_blob_renderer.dart';

class NpcSprite extends StatelessWidget {
  final NPC npc;
  final Offset startPos;
  final Offset endPos;
  final int occupantIndex;

  const NpcSprite({
    super.key,
    required this.npc,
    required this.startPos,
    required this.endPos,
    this.occupantIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Interpolate position based on movementProgress
    final double progress = npc.movementProgress.clamp(0.0, 1.0);
    final Offset currentPos = Offset.lerp(startPos, endPos, progress)!;

    final bool isWalking = npc.targetRoomId != null && progress < 1.0;

    return Positioned(
      left: currentPos.dx - 20, // Center the sprite (approx 40px wide)
      top: currentPos.dy - 30, // Position above the "floor"
      child: Draggable<NPC>(
        data: npc,
        feedback: Opacity(
          opacity: 0.7,
          child: _buildSpriteContent(context, isWalking, isDragging: true),
        ),
        childWhenDragging: const SizedBox.shrink(),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => CharacterPortraitDialog(npc: npc),
            );
          },
          child: _buildSpriteContent(context, isWalking),
        ),
      ),
    );
  }

  Widget _buildSpriteContent(
    BuildContext context,
    bool isWalking, {
    bool isDragging = false,
  }) {
    final state = context.watch<GameState>();
    String? statusText;

    if (npc.worldDestinationId != null && npc.worldTravelProgress < 1.0) {
      statusText = "DEPARTING FOR ${npc.worldDestinationId!.toUpperCase()}";
    } else if (npc.activeTaskId != null) {
      final tasks = state.activeTasks.where((t) => t.npcId == npc.id);
      if (tasks.isNotEmpty) {
        statusText = state.getTaskDescription(tasks.first).toUpperCase();
      }
    } else if (npc.targetRoomId != null &&
        npc.targetRoomId != npc.currentRoomId) {
      final rooms = state.rooms.where((r) => r.id == npc.targetRoomId);
      if (rooms.isNotEmpty) {
        statusText = "MOVING TO ${rooms.first.name.toUpperCase()}";
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (statusText != null && !isDragging) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.oldStandardTt(
                fontSize: 7,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            CharacterBlobRenderer(
              npc: npc,
              isWalking: isWalking,
              isIdle: !isWalking,
              size: 40,
              bubbleOffset: (occupantIndex % 2) * 15.0, // Stagger bubbles
            ),
          ],
        ),
        if (!isDragging) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              npc.name.toUpperCase(),
              style: GoogleFonts.oldStandardTt(
                fontSize: 8,
                color: npc.isPlayer
                    ? const Color(0xFFFFD700)
                    : const Color(0xFFE5D5B0),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
