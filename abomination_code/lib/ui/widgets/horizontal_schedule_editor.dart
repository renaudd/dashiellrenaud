import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/npc.dart';
import '../../models/schedule.dart';

class HorizontalScheduleEditor extends StatelessWidget {
  final NPC npc;
  final Function(NPCSchedule) onScheduleChanged;
  final bool showHeader;
  final bool showLegend;
  final bool showName;
  final bool isCoopRestored;
  final int dayIndex;

  const HorizontalScheduleEditor({
    super.key,
    required this.npc,
    required this.onScheduleChanged,
    this.showHeader = true,
    this.showLegend = true,
    this.showName = false,
    this.isCoopRestored = false,
    this.dayIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = _getGroupedBlocks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _buildTimeHeaders(),
        const SizedBox(height: 4),
        Row(
          children: [
            if (showName)
              SizedBox(
                width: 100,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    npc.name.toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC4B89B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: blocks
                      .map((block) => _buildBlock(context, block))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
        if (showLegend) ...[const SizedBox(height: 16), _buildLegend()],
      ],
    );
  }

  Widget _buildTimeHeaders() {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          if (showName) const SizedBox(width: 100),
          Expanded(
            child: Row(
              children: List.generate(
                24,
                (i) => Expanded(
                  child: Center(
                    child: Text(
                      i.toString().padLeft(2, '0'),
                      style: GoogleFonts.oldStandardTt(
                        fontSize: 8,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_GroupedBlock> _getGroupedBlocks() {
    final result = <_GroupedBlock>[];
    if (npc.schedule.blocks.isEmpty) return result;

    final baseHour = dayIndex * 24;
    var currentActivity = npc.schedule.getActivityForHour(baseHour);
    var startHourIndex = baseHour;

    for (int i = 1; i < 24; i++) {
      final hourIndex = baseHour + i;
      final activity = npc.schedule.getActivityForHour(hourIndex);
      if (activity != currentActivity) {
        result.add(
          _GroupedBlock(
            activity: currentActivity,
            startHourIndex: startHourIndex,
            duration: hourIndex - startHourIndex,
          ),
        );
        currentActivity = activity;
        startHourIndex = hourIndex;
      }
    }

    result.add(
      _GroupedBlock(
        activity: currentActivity,
        startHourIndex: startHourIndex,
        duration: (baseHour + 24) - startHourIndex,
      ),
    );

    return result;
  }

  Widget _buildBlock(BuildContext context, _GroupedBlock block) {
    return Expanded(
      flex: block.duration,
      child: DragTarget<DraggableBlockData>(
        onAcceptWithDetails: (details) {
          _handleBlockDrop(block, details.data);
        },
        builder: (context, candidateData, rejectedData) {
          return LongPressDraggable<DraggableBlockData>(
            data: DraggableBlockData(
              activity: block.activity,
              duration: block.duration,
              startHourIndex: block.startHourIndex,
            ),
            feedback: Material(
              color: Colors.transparent,
              child: Container(
                width: 100, // Fixed width for feedback
                height: 40,
                decoration: BoxDecoration(
                  color: _getActivityColor(
                    block.activity,
                  ).withValues(alpha: 0.5),
                  border: Border.all(color: _getActivityColor(block.activity)),
                ),
                child: Center(
                  child: Text(
                    block.activity.name.toUpperCase(),
                    style: GoogleFonts.oldStandardTt(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              color: Colors.black12,
            ),
            child: GestureDetector(
              onTap: () => _showActivityPicker(context, block.startHourIndex),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: _getActivityColor(
                    block.activity,
                  ).withValues(alpha: 0.3),
                  border: Border.all(
                    color: candidateData.isNotEmpty
                        ? Colors.white
                        : _getActivityColor(
                            block.activity,
                          ).withValues(alpha: 0.5),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: RotatedBox(
                        quarterTurns: block.duration < 3 ? 1 : 0,
                        child: Text(
                          block.activity.name.toUpperCase(),
                          style: GoogleFonts.oldStandardTt(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _getActivityColor(block.activity),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    // Resize Handles
                    if (block.activity.isStretchable) ...[
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: _ResizeHandle(
                          onDrag: (delta) =>
                              _handleResize(block, delta, isLeft: true),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 10,
                        child: _ResizeHandle(
                          onDrag: (delta) =>
                              _handleResize(block, delta, isLeft: false),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleBlockDrop(
    _GroupedBlock targetBlock,
    DraggableBlockData draggedData,
  ) {
    if (draggedData.startHourIndex == targetBlock.startHourIndex) return;

    final newBlocks = List<ScheduleBlock>.from(npc.schedule.blocks);

    // Simple swap logic for the duration of the dragged block
    // If dragging "Eat" (1h) onto "Work" (4h), "Eat" moves to the target hour,
    // and "Work" (or whatever was there) moves to the original hour.

    final draggedActivity = draggedData.activity;

    // Find what's at the target hour
    // For simplicity, we swap the specific hour(s)
    for (int i = 0; i < draggedData.duration; i++) {
      final draggedHour = draggedData.startHourIndex + i;
      final targetHour = targetBlock.startHourIndex + i;

      final temp = newBlocks[targetHour].activity;
      newBlocks[targetHour] = ScheduleBlock(
        hourIndex: targetHour,
        activity: draggedActivity,
      );
      newBlocks[draggedHour] = ScheduleBlock(
        hourIndex: draggedHour,
        activity: temp,
      );
    }

    onScheduleChanged(NPCSchedule(blocks: newBlocks));
  }

  void _handleResize(
    _GroupedBlock block,
    double delta, {
    required bool isLeft,
  }) {
    final int hourDelta = delta.toInt();
    if (hourDelta == 0) return;

    final newBlocks = List<ScheduleBlock>.from(npc.schedule.blocks);
    final minDuration = block.activity.minDurationHours;

    if (isLeft) {
      final newStart = (block.startHourIndex + hourDelta)
          .clamp(
            dayIndex * 24,
            block.startHourIndex + block.duration - minDuration,
          )
          .toInt();
      for (int i = block.startHourIndex; i < newStart; i++) {
        newBlocks[i] = ScheduleBlock(
          hourIndex: i,
          activity: ScheduleActivity.leisure,
        );
      }
      for (int i = newStart; i < block.startHourIndex; i++) {
        newBlocks[i] = ScheduleBlock(hourIndex: i, activity: block.activity);
      }
    } else {
      final newEnd = (block.startHourIndex + block.duration + hourDelta)
          .clamp(block.startHourIndex + minDuration, (dayIndex + 1) * 24)
          .toInt();
      for (int i = block.startHourIndex + block.duration; i < newEnd; i++) {
        newBlocks[i] = ScheduleBlock(hourIndex: i, activity: block.activity);
      }
      for (int i = newEnd; i < block.startHourIndex + block.duration; i++) {
        newBlocks[i] = ScheduleBlock(
          hourIndex: i,
          activity: ScheduleActivity.leisure,
        );
      }
    }

    onScheduleChanged(NPCSchedule(blocks: newBlocks));
  }

  void _showActivityPicker(BuildContext context, int hourIndex) {
    final hourOfDay = hourIndex % 24;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A15),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "REASSIGN HOUR $hourOfDay:00",
              style: GoogleFonts.playfairDisplay(
                color: const Color(0xFFE5D5B0),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScheduleActivity.values
                  .where(
                    (act) =>
                        act.isImplemented &&
                        (act != ScheduleActivity.guardCoop || isCoopRestored),
                  )
                  .map(
                    (act) => ActionChip(
                      backgroundColor: Colors.black26,
                      label: Text(
                        act.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white70,
                        ),
                      ),
                      onPressed: () {
                        final newBlocks = List<ScheduleBlock>.from(
                          npc.schedule.blocks,
                        );
                        final duration = act.defaultDurationHours;

                        if (act == ScheduleActivity.guardCoop) {
                          // Force night hours 22:00 to 02:00
                          // Need to handle day wrap if necessary, but keep it within 7 days
                          final baseDayStart = (hourIndex ~/ 24) * 24;

                          for (int i = 22; i < 24; i++) {
                            final idx = baseDayStart + i;
                            if (idx < 168) {
                              newBlocks[idx] = ScheduleBlock(
                                hourIndex: idx,
                                activity: act,
                              );
                            }
                          }
                          for (int i = 0; i < 2; i++) {
                            final idx = baseDayStart + i;
                            if (idx < 168) {
                              newBlocks[idx] = ScheduleBlock(
                                hourIndex: idx,
                                activity: act,
                              );
                            }
                          }
                        } else {
                          for (int i = 0; i < duration; i++) {
                            final targetIndex = hourIndex + i;
                            if (targetIndex < 168) {
                              newBlocks[targetIndex] = ScheduleBlock(
                                hourIndex: targetIndex,
                                activity: act,
                              );
                            }
                          }
                        }

                        onScheduleChanged(NPCSchedule(blocks: newBlocks));
                        Navigator.pop(context);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: ScheduleActivity.values
          .map(
            (act) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, color: _getActivityColor(act)),
                const SizedBox(width: 4),
                Text(
                  act.name.toUpperCase(),
                  style: const TextStyle(fontSize: 8, color: Colors.white38),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Color _getActivityColor(ScheduleActivity activity) {
    switch (activity) {
      case ScheduleActivity.sleep:
        return Colors.indigoAccent;
      case ScheduleActivity.work:
        return Colors.redAccent;
      case ScheduleActivity.eat:
        return Colors.greenAccent;
      case ScheduleActivity.leisure:
        return Colors.amberAccent;
      case ScheduleActivity.prayer:
        return Colors.purpleAccent;
      case ScheduleActivity.study:
        return Colors.blueAccent;
      case ScheduleActivity.guardCoop:
        return Colors.orangeAccent;
      case ScheduleActivity.cleanRoom:
        return Colors.tealAccent;
      case ScheduleActivity.cook:
        return Colors.brown;
    }
  }
}

class _GroupedBlock {
  final ScheduleActivity activity;
  final int startHourIndex;
  final int duration;
  _GroupedBlock({
    required this.activity,
    required this.startHourIndex,
    required this.duration,
  });
}

class DraggableBlockData {
  final ScheduleActivity activity;
  final int duration;
  final int startHourIndex;

  DraggableBlockData({
    required this.activity,
    required this.duration,
    required this.startHourIndex,
  });
}

class _ResizeHandle extends StatefulWidget {
  final Function(double) onDrag;
  const _ResizeHandle({required this.onDrag});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _accumulated = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _accumulated += details.primaryDelta!;
        // Rough threshold for 1 hour jump (assume 24 hours across ~300px = ~12px/hour)
        if (_accumulated.abs() > 12) {
          widget.onDrag(_accumulated > 0 ? 1 : -1);
          _accumulated = 0;
        }
      },
      child: Container(
        color: Colors.white.withValues(alpha: 0.1),
        child: const Center(
          child: Icon(Icons.drag_handle, size: 10, color: Colors.white24),
        ),
      ),
    );
  }
}
