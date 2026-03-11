import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/npc.dart';
import '../../models/relationship.dart';
import '../../state/game_state.dart';
import '../../services/task_service.dart';
import 'character_blob_renderer.dart';

class ResidentBar extends StatefulWidget {
  final NPC npc;

  const ResidentBar({super.key, required this.npc});

  @override
  State<ResidentBar> createState() => _ResidentBarState();
}

class _ResidentBarState extends State<ResidentBar> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    "Stats",
    "Relations",
    "Schedule",
    "Combat",
    "Records",
  ];

  @override
  Widget build(BuildContext context) {
    const Color parchmentBg = Color(0xFFE5D5B0);
    const Color brassBorder = Color(0xFFC4B89B);
    const Color inkColor = Color(0xFF2E241F);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: parchmentBg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
        border: Border.all(color: brassBorder, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Name Box + Tabs
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Left Name Box
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ), // Compressed padding
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: brassBorder, width: 2),
                        bottom: BorderSide(color: brassBorder, width: 2),
                      ),
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    child: Center(
                      child: Text(
                        widget.npc.name.toUpperCase(),
                        style: GoogleFonts.playfairDisplay(
                          color: inkColor,
                          fontSize: 18, // Slightly smaller
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                // Header Tab Bar
                Expanded(flex: 7, child: _buildTabBar(brassBorder, inkColor)),
              ],
            ),
          ),

          // Main Content Area (Now a single dense row)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: SizedBox(
              height:
                  180, // Fixed height to avoid IntrinsicHeight + Expanded crash
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Portrait
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 100,
                        height: 120,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -40,
                              top: -40,
                              child: CharacterBlobRenderer(
                                npc: widget.npc,
                                size: 170,
                                isIdle: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  _buildDivider(inkColor.withValues(alpha: 0.2)),

                  // 2) Task Info
                  Expanded(flex: 4, child: _buildTaskInfoColumn(inkColor)),

                  _buildDivider(inkColor.withValues(alpha: 0.2)),

                  // 3 & 4) Attributes & Statuses
                  Expanded(
                    flex: 11,
                    child: _buildTabContent(inkColor, brassBorder),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(Color borderColor, Color inkColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                ), // Compressed padding
                decoration: BoxDecoration(
                  color: isSelected ? Colors.transparent : Colors.black26,
                  border: Border(
                    right: BorderSide(color: borderColor, width: 0.5),
                    bottom: isSelected
                        ? const BorderSide(color: Colors.transparent, width: 0)
                        : BorderSide(color: borderColor, width: 1),
                  ),
                ),
                child: Center(
                  child: Text(
                    _tabs[index].toUpperCase(),
                    style: GoogleFonts.playfairDisplay(
                      color: isSelected
                          ? inkColor
                          : inkColor.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Container(
      width: 1,
      height: 140, // Taller to match 120px attribute bars
      margin: const EdgeInsets.symmetric(horizontal: 12), // Tighter margin
      color: color.withValues(alpha: 0.15),
    );
  }

  Widget _buildTaskInfoColumn(Color inkColor) {
    final activeIntent = widget.npc.intentQueue.isNotEmpty
        ? widget.npc.intentQueue.first
        : null;
    final nextIntent = widget.npc.intentQueue.length > 1
        ? widget.npc.intentQueue[1]
        : null;

    final state = Provider.of<GameState>(context, listen: false);
    final activeRoom = activeIntent?.targetRoomId != null
        ? state.rooms.firstWhere((r) => r.id == activeIntent!.targetRoomId, orElse: () => state.rooms.first).name
        : null;
    final nextRoom = nextIntent?.targetRoomId != null
        ? state.rooms.firstWhere((r) => r.id == nextIntent!.targetRoomId, orElse: () => state.rooms.first).name
        : null;

    final remaining =
        activeIntent?.minutesRemaining ??
        activeIntent?.expectedDurationMin ??
        0;
    final hours = remaining ~/ 60;
    final mins = remaining % 60;
    final durationText = hours > 0 ? "$hours HR $mins MIN" : "$mins MIN";

    final activeActionText = activeIntent?.action.displayName.toUpperCase() ?? "WAITING AT ENTRY";
    final activeDisplay = activeRoom != null ? "$activeActionText ($activeRoom)" : activeActionText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          durationText,
          style: GoogleFonts.oldStandardTt(
            color: inkColor.withValues(alpha: 0.6),
            fontSize: 11, // Smaller for density
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          activeDisplay,
          style: GoogleFonts.playfairDisplay(
            color: inkColor,
            fontSize: 14, // Smaller for density
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionLabel(
          "Present Task:",
          activeIntent?.action.displayName ?? "Idle",
          activeRoom,
          inkColor,
        ),
        _buildActionLabel(
          "Upcoming Task:",
          nextIntent?.action.displayName ?? "Pending",
          nextRoom,
          inkColor,
          isDim: true,
        ),
      ],
    );
  }

  Widget _buildActionLabel(
    String label,
    String value,
    String? roomName,
    Color inkColor, {
    bool isDim = false,
  }) {
    final displayValue = roomName != null ? "$value ($roomName)" : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.oldStandardTt(
              color: inkColor.withValues(alpha: 0.4),
              fontSize: 8, // Smaller for density
              fontStyle: FontStyle.italic,
            ),
          ),
          Text(
            displayValue.toUpperCase(),
            style: GoogleFonts.playfairDisplay(
              color: isDim ? inkColor.withValues(alpha: 0.5) : inkColor,
              fontSize: 10, // Smaller for density
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // _buildInfoRow removed as it's replaced by _buildActionLabel

  Widget _buildTabContent(Color inkColor, Color borderColor) {
    return Consumer<GameState>(
      builder: (context, state, child) {
        switch (_activeTabIndex) {
          case 0: // Stats
            return _buildStatsTab(inkColor);
          case 1: // Relations
            return _buildRelationsTab(inkColor, state);
          case 2: // Schedule
            return _buildScheduleTab(inkColor, state);
          case 3: // Combat
            return _buildCombatTab(inkColor);
          case 4: // Records
            return _buildRecordsTab(inkColor);
          default:
            return Container();
        }
      },
    );
  }

  Widget _buildStatsTab(Color inkColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Attributes (Reduced flex from 8 to 6)
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttrBar(
                    "Strength",
                    Icons.fitness_center,
                    (widget.npc.stats['strength'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Endurance",
                    Icons.water_drop,
                    (widget.npc.stats['endurance'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Dexterity",
                    Icons.pan_tool,
                    (widget.npc.stats['dexterity'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Intelligence",
                    Icons.psychology,
                    (widget.npc.stats['intelligence'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Perception",
                    Icons.visibility,
                    (widget.npc.stats['perception'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Judgment",
                    Icons.gavel,
                    (widget.npc.stats['judgment'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Temperament",
                    Icons.balance,
                    (widget.npc.stats['temperament'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Courage",
                    Icons.shield,
                    (widget.npc.stats['courage'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Beauty",
                    Icons.auto_awesome,
                    (widget.npc.stats['beauty'] ?? 0) / 100,
                    inkColor,
                  ),
                  _buildAttrBar(
                    "Hygiene",
                    Icons.clean_hands,
                    (widget.npc.stats['hygiene'] ?? 0) / 100,
                    inkColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        VerticalDivider(width: 24, color: inkColor.withValues(alpha: 0.1)),

        // Right Column: Statuses (Widened flex from 2 to 4)
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVitalBar(
                "Health",
                Icons.add,
                widget.npc.energy / 100,
                inkColor,
                Colors.red[800]!,
              ), // Cross (Health)
              _buildVitalBar(
                "Mood",
                Icons.sentiment_very_satisfied,
                widget.npc.satisfaction / 100,
                inkColor,
                Colors.amber[800]!,
              ), // Happy
              _buildVitalBar(
                "Hunger",
                Icons.restaurant,
                widget.npc.hunger / 100,
                inkColor,
                Colors.orange[800]!,
                invert: true,
              ), // Fork/Knife
              _buildVitalBar(
                "Digestion",
                Icons.view_headline,
                widget.npc.digestion / 100,
                inkColor,
                Colors.green[800]!,
              ), // Intestine
              _buildVitalBar(
                "Energy",
                Icons.hotel,
                widget.npc.energy / 100,
                inkColor,
                Colors.blue[800]!,
              ), // Zzz (Energy)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVitalBar(
    String label,
    IconData icon,
    double value,
    Color inkColor,
    Color barColor, {
    bool invert = false,
  }) {
    double displayValue = invert ? (1.0 - value) : value;
    return Tooltip(
      message: "$label: ${(value * 100).toInt()}%",
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 14, color: inkColor.withValues(alpha: 0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 6, // Slightly taller for better visibility
                decoration: BoxDecoration(
                  border: Border.all(
                    color: inkColor.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: LinearProgressIndicator(
                  value: displayValue.clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    barColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttrBar(
    String label,
    IconData icon,
    double value,
    Color inkColor,
  ) {
    // Recalibrate to 0-10 scale (where 3 is normal, 6+ is superhuman)
    final int displayValue = (value * 10).toInt();
    return Tooltip(
      message: "$label: $displayValue",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              border: Border.all(color: inkColor.withValues(alpha: 0.2)),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 8,
              height: 120 * value.clamp(0.0, 1.0),
              color: inkColor.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Icon(icon, size: 14, color: inkColor.withValues(alpha: 0.7)),
        ],
      ),
    );
  }

  Widget _buildRelationsTab(Color inkColor, GameState state) {
    final residents = state.npcs.where((n) => n.isResident).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Social Standing & Inter-Resident Dynamics",
          style: GoogleFonts.playfairDisplay(
            color: inkColor,
            fontSize: 10,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: residents.isEmpty || widget.npc.relationships.isEmpty
              ? Center(
                  child: Text(
                    "No significant social bonds recorded.",
                    style: GoogleFonts.oldStandardTt(
                      color: inkColor.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: residents.length,
                  itemBuilder: (context, index) {
                    final other = residents[index];
                    if (other.id == widget.npc.id) {
                      return const SizedBox.shrink();
                    }

                    final rel =
                        widget.npc.relationships[other.id] ?? Relationship();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        border: Border.all(
                          color: inkColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            other.name.toUpperCase(),
                            style: GoogleFonts.playfairDisplay(
                              color: inkColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Divider(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRelEntry(
                                  "Admiration",
                                  rel.admiration,
                                  Colors.blue,
                                  inkColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRelEntry(
                                  "Respect",
                                  rel.respect,
                                  Colors.purple,
                                  inkColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: _buildRelEntry(
                                  "Fear",
                                  rel.fear,
                                  Colors.red,
                                  inkColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildRelEntry(
                                  "Attraction",
                                  rel.attraction,
                                  Colors.pink,
                                  inkColor,
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
    );
  }

  Widget _buildRelEntry(String label, double val, Color color, Color inkColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.oswald(
                color: inkColor.withValues(alpha: 0.6),
                fontSize: 8,
              ),
            ),
            Text(
              val.toStringAsFixed(1),
              style: GoogleFonts.oswald(
                color: inkColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: 3,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.1)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (val / 5.0).clamp(0.0, 1.0),
            child: Container(color: color.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordsTab(Color inkColor) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Biographical Dossier",
            style: GoogleFonts.playfairDisplay(
              color: inkColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.03),
              border: Border.all(color: inkColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              widget.npc.bio.isNotEmpty
                  ? widget.npc.bio
                  : "No detailed biography available in the archives.",
              style: GoogleFonts.oldStandardTt(
                color: inkColor,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecordGrid(inkColor),
        ],
      ),
    );
  }

  Widget _buildRecordGrid(Color inkColor) {
    final data = [
      ["Age", "${widget.npc.age} years"],
      ["Gender", widget.npc.gender],
      ["Nationality", widget.npc.nationality],
      ["Religion", widget.npc.religion],
      ["Hometown", widget.npc.hometown],
      ["Background", widget.npc.background],
      ["Social Group", widget.npc.group.name],
      ["Orientation", widget.npc.sexualOrientation.name],
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: data
          .map(
            (d) => SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d[0].toUpperCase(),
                    style: GoogleFonts.oswald(
                      color: inkColor.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    d[1],
                    style: GoogleFonts.playfairDisplay(
                      color: inkColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildScheduleTab(Color inkColor, GameState state) {
    final bedRoom = state.rooms.firstWhere(
      (r) => r.id == widget.npc.assignedRoomId,
      orElse: () => state.rooms.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Operational Directive & Routine",
              style: GoogleFonts.playfairDisplay(
                color: inkColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: inkColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                widget.npc.status.name.toUpperCase(),
                style: GoogleFonts.oswald(
                  color: inkColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Assigned Location & Needs
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSchedInfo(
                      "Assigned Bed",
                      bedRoom.name.toUpperCase(),
                      Icons.hotel,
                      inkColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "DAILY CONSUMPTION",
                      style: GoogleFonts.oswald(
                        color: inkColor.withValues(alpha: 0.4),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...widget.npc.diet.dailyRequirements.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          "• ${e.value}x ${e.key.name.toUpperCase()}",
                          style: GoogleFonts.oldStandardTt(
                            color: inkColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 24),
              // Right: Active Tasks (Intent Queue)
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TASK QUEUE",
                      style: GoogleFonts.oswald(
                        color: inkColor.withValues(alpha: 0.4),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: widget.npc.intentQueue.isEmpty
                          ? Text(
                              "No pending directives.",
                              style: GoogleFonts.oldStandardTt(
                                color: inkColor.withValues(alpha: 0.2),
                                fontSize: 9,
                              ),
                            )
                          : ListView.builder(
                              itemCount: widget.npc.intentQueue.length,
                              itemBuilder: (context, idx) {
                                final intent = widget.npc.intentQueue[idx];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        "${idx + 1}.",
                                        style: GoogleFonts.oswald(
                                          color: inkColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          intent.action.name.toUpperCase(),
                                          style: GoogleFonts.playfairDisplay(
                                            color: idx == 0
                                                ? inkColor
                                                : inkColor.withValues(
                                                    alpha: 0.3,
                                                  ),
                                            fontSize: 10,
                                            fontWeight: idx == 0
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchedInfo(
    String label,
    String value,
    IconData icon,
    Color inkColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.oswald(
            color: inkColor.withValues(alpha: 0.4),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 12, color: inkColor.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.playfairDisplay(
                color: inkColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombatTab(Color inkColor) {
    // Derived stats for initial mockup representation
    final str = widget.npc.stats['strength'] ?? 30;
    final end = widget.npc.stats['endurance'] ?? 30;
    final dex = widget.npc.stats['dexterity'] ?? 30;
    final per = widget.npc.stats['perception'] ?? 30;

    final atk = (str * 0.8 + dex * 0.2).toInt();
    final hlt = (end * 10).toInt();
    final spd = (dex / 20.0).toStringAsFixed(1);
    final rng = (per / 40.0).toStringAsFixed(1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Side: Combat Stats & Level
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              border: Border.all(color: inkColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: inkColor.withValues(alpha: 0.1),
                        border: Border.all(
                          color: inkColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        (widget.npc.age / 15).toInt().toString(), // Mock Level
                        style: GoogleFonts.oswald(
                          color: inkColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.npc.role.toUpperCase(),
                            style: GoogleFonts.oswald(
                              color: inkColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "UNIT CLASS",
                            style: GoogleFonts.oldStandardTt(
                              color: inkColor.withValues(alpha: 0.5),
                              fontSize: 7,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildCombatStatLine("ATK", "$atk", inkColor),
                _buildCombatStatLine("HLT", "$hlt", inkColor),
                _buildCombatStatLine("SPD", spd, inkColor),
                _buildCombatStatLine("RNG", rng, inkColor),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: null, // Disabled in mockup
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: inkColor.withValues(alpha: 0.2)),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 24),
                    ),
                    child: Text(
                      "UPGRADE",
                      style: GoogleFonts.oswald(
                        color: inkColor.withValues(alpha: 0.3),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right Side: Ability & Gear/Inventory
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "EQUIPPED GEAR & INVENTORY",
                style: GoogleFonts.oswald(
                  color: inkColor.withValues(alpha: 0.4),
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: widget.npc.inventory.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.02),
                          border: Border.all(
                            color: inkColor.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            "NO ITEMS CARRIED",
                            style: GoogleFonts.oldStandardTt(
                              color: inkColor.withValues(alpha: 0.2),
                              fontSize: 8,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: widget.npc.inventory.length,
                        itemBuilder: (context, idx) {
                          final item = widget.npc.inventory[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              border: Border.all(
                                color: inkColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 10,
                                  color: inkColor.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name.toUpperCase(),
                                    style: GoogleFonts.playfairDisplay(
                                      color: inkColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "Q${item.quality.toStringAsFixed(1)}",
                                  style: GoogleFonts.oswald(
                                    color: inkColor.withValues(alpha: 0.4),
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCombatStatLine(String label, String value, Color inkColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.oswald(
              color: inkColor.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.oswald(
              color: inkColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
