import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/npc.dart';
import '../../models/body_part.dart';
import '../../services/combat_service.dart';
import '../../state/game_state.dart';
import 'package:provider/provider.dart';

class AnatomyDialog extends StatelessWidget {
  final NPC npc;

  const AnatomyDialog({super.key, required this.npc});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1A15),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ANATOMICAL STATUS: ${npc.name.toUpperCase()}",
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: const Color(0xFFE5D5B0),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ROLE: ${npc.role.toUpperCase()} | STATUS: ${npc.status.name.toUpperCase()}",
              style: GoogleFonts.oldStandardTt(
                fontSize: 12,
                color: const Color(0xFFC4B89B),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white10),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: npc.bodyParts
                      .map((bp) => _buildBodyPartRow(bp))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    final state = Provider.of<GameState>(
                      context,
                      listen: false,
                    );
                    final damagedNpc = CombatService.applyDamage(npc);
                    state.updateNpc(damagedNpc);
                  },
                  icon: const Icon(
                    Icons.flash_on,
                    color: Colors.orange,
                    size: 14,
                  ),
                  label: Text(
                    "SIMULATE INJURY",
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CLOSE",
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFFC4B89B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartRow(BodyPart bp) {
    final Color healthColor = _getHealthColor(bp.health);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bp.name.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: bp.isAttached ? const Color(0xFFE5D5B0) : Colors.red,
                ),
              ),
              Text(
                "${bp.health.toStringAsFixed(0)}%",
                style: GoogleFonts.oldStandardTt(
                  color: healthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (!bp.isAttached)
            Text(
              "AMPUTATED / SEVERED",
              style: GoogleFonts.oldStandardTt(
                color: Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            )
          else ...[
            LinearProgressIndicator(
              value: bp.health / 100,
              backgroundColor: Colors.white10,
              color: healthColor,
              minHeight: 2,
            ),
            if (bp.wounds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: bp.wounds.map((w) => _buildWoundTag(w)).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildWoundTag(Wound w) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        color: Colors.red.withValues(alpha: 0.1),
      ),
      child: Text(
        w.type.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.red,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getHealthColor(double health) {
    if (health > 70) return Colors.green;
    if (health > 30) return Colors.orange;
    return Colors.red;
  }
}
