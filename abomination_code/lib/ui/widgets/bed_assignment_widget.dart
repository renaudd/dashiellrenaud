import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/room.dart';
import '../../state/game_state.dart';
import '../../models/npc.dart';

class BedAssignmentWidget extends StatelessWidget {
  final Room room;

  const BedAssignmentWidget({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    if (room.beds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          "SLEEPING SPOTS:",
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: const Color(0xFFC4B89B),
          ),
        ),
        const SizedBox(height: 12),
        ...room.beds.asMap().entries.map((entry) {
          int bedIndex = entry.key;
          Bed bed = entry.value;
          return _buildBedSelection(context, bed, bedIndex);
        }),
      ],
    );
  }

  Widget _buildBedSelection(BuildContext context, Bed bed, int bedIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getBedIcon(bed.type),
                size: 16,
                color: const Color(0xFFC4B89B),
              ),
              const SizedBox(width: 10),
              Text(
                bed.type.name.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE5D5B0),
                ),
              ),
              const Spacer(),
              Text(
                bed.isShared ? "SHARED" : "NOT SHARED",
                style: GoogleFonts.oldStandardTt(
                  fontSize: 10,
                  color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: bed.assignedNpcIds.asMap().entries.map((spotEntry) {
              int spotIndex = spotEntry.key;
              String? npcId = spotEntry.value;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: spotIndex < bed.assignedNpcIds.length - 1 ? 8 : 0,
                  ),
                  child: _SlotButton(
                    room: room,
                    bedIndex: bedIndex,
                    spotIndex: spotIndex,
                    npcId: npcId,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getBedIcon(BedType type) {
    switch (type) {
      case BedType.twin:
        return Icons.single_bed;
      case BedType.queen:
      case BedType.king:
        return Icons.bed;
      case BedType.crib:
        return Icons.child_care;
    }
  }
}

class _SlotButton extends StatelessWidget {
  final Room room;
  final int bedIndex;
  final int spotIndex;
  final String? npcId;

  const _SlotButton({
    required this.room,
    required this.bedIndex,
    required this.spotIndex,
    this.npcId,
  });

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<GameState>(context);
    final NPC? npc = npcId != null 
        ? state.npcs.firstWhere((n) => n.id == npcId, orElse: () => state.npcs.first)
        : null;

    final isOccupied = npc != null && npcId != null;

    return InkWell(
      onTap: () => _showNpcSelection(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isOccupied 
                ? const Color(0xFFC4B89B).withValues(alpha: 0.5)
                : Colors.white10,
          ),
          color: isOccupied 
              ? const Color(0xFFC4B89B).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              isOccupied ? Icons.person : Icons.person_add_outlined,
              size: 20,
              color: isOccupied ? const Color(0xFFE5D5B0) : Colors.white24,
            ),
            const SizedBox(height: 4),
            Text(
              isOccupied ? npc.name.toUpperCase() : "ASSIGN",
              style: GoogleFonts.oldStandardTt(
                fontSize: 10,
                fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                color: isOccupied ? const Color(0xFFE5D5B0) : Colors.white24,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showNpcSelection(BuildContext context, GameState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) {
        final availableNpcs = state.npcs.where((n) => n.isResident).toList();
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ASSIGN SPOT',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFE5D5B0),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  if (npcId != null)
                    TextButton.icon(
                      onPressed: () {
                        state.unassignNpcFromBed(npcId!);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.person_remove, size: 16, color: Colors.redAccent),
                      label: Text(
                        "UNASSIGN",
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: availableNpcs.isEmpty
                  ? Center(
                      child: Text(
                        "NO RESIDENTS AVAILABLE",
                        style: GoogleFonts.oldStandardTt(color: Colors.white24),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: availableNpcs.length,
                      separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                      itemBuilder: (context, index) {
                        final npc = availableNpcs[index];
                        final isCurrentlyAssignedHere = npc.id == npcId;
                        final otherAssignedRoomId = npc.assignedRoomId;
                        
                        String statusText = "Available";
                        Color statusColor = Colors.greenAccent;
                        
                        if (isCurrentlyAssignedHere) {
                          statusText = "Assigned Here";
                          statusColor = Colors.greenAccent;
                        } else if (otherAssignedRoomId != null) {
                          final otherRoom = state.rooms.firstWhere((r) => r.id == otherAssignedRoomId, orElse: () => state.rooms.first);
                          statusText = "In ${otherRoom.name}";
                          statusColor = Colors.amberAccent;
                        }

                        return ListTile(
                          onTap: () {
                            state.assignNpcToBed(npc.id, room.id, bedIndex, spotIndex);
                            Navigator.pop(context);
                          },
                          leading: Icon(
                            npc.isPlayer ? Icons.stars : Icons.person,
                            color: const Color(0xFFC4B89B),
                          ),
                          title: Text(
                            npc.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFFE5D5B0),
                              fontSize: 14,
                              fontWeight: isCurrentlyAssignedHere ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            statusText.toUpperCase(),
                            style: GoogleFonts.oldStandardTt(
                              color: statusColor.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                            size: 16,
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
}
