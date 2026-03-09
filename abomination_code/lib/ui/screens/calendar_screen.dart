import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/room.dart';
import '../../state/game_state.dart';
import '../widgets/horizontal_schedule_editor.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    // Start on the day that corresponds to the current game date
    final state = context.read<GameState>();
    _selectedDayIndex = (state.currentDate.day - 1) % 7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A15),
      appBar: AppBar(
        title: Text(
          'CHRONICLE OF TIME',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<GameState>(
        builder: (context, state, child) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ESTATE SCHEDULES",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: const Color(0xFFC4B89B).withValues(alpha: 0.6),
                      ),
                    ),
                    _buildDayPicker(),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.npcs.length,
                    itemBuilder: (context, index) {
                      final npc = state.npcs[index];
                      final isCoopRestored = state.rooms.any(
                        (r) => r.type == RoomType.chickenCoop && r.isRestored,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: HorizontalScheduleEditor(
                          npc: npc,
                          showHeader: index == 0,
                          showLegend: index == state.npcs.length - 1,
                          showName: true,
                          isCoopRestored: isCoopRestored,
                          dayIndex: _selectedDayIndex,
                          onScheduleChanged: (newSchedule) {
                            state.updateNpc(
                              npc.copyWith(schedule: newSchedule),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructions(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayPicker() {
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return Row(
      children: List.generate(7, (index) {
        final isSelected = index == _selectedDayIndex;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: InkWell(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC4B89B) : Colors.black26,
                border: Border.all(
                  color: isSelected ? Colors.white24 : Colors.transparent,
                ),
              ),
              child: Text(
                days[index],
                style: GoogleFonts.oldStandardTt(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.white38,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _instructionRow(Icons.touch_app, "TAP A BLOCK TO REASSIGN THAT HOUR"),
          const SizedBox(height: 8),
          _instructionRow(
            Icons.unfold_more,
            "DRAG SIDE HANDLES TO STRETCH BLOCKS",
          ),
          const SizedBox(height: 8),
          _instructionRow(
            Icons.nightlight_round,
            "GUARDING IS MORE EFFECTIVE AT NIGHT",
          ),
        ],
      ),
    );
  }

  Widget _instructionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFC4B89B)),
        const SizedBox(width: 12),
        Text(
          text,
          style: GoogleFonts.oldStandardTt(fontSize: 10, color: Colors.white38),
        ),
      ],
    );
  }
}
