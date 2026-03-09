import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/save_service.dart';
import '../../state/game_state.dart';
import 'package:provider/provider.dart';

class SaveGameDialog extends StatelessWidget {
  const SaveGameDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseSaveLoadDialog(
      title: 'DOCUMENT PROGRESS',
      onSlotSelected: (slot) async {
        final state = context.read<GameState>();
        await SaveService.saveGame(state, slot: slot);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Experiment progress documented in Slot $slot.'),
              backgroundColor: const Color(0xFF241F1A),
            ),
          );
        }
      },
      actionLabel: 'SAVE',
    );
  }
}

class LoadGameDialog extends StatelessWidget {
  final Function(int slot) onSlotSelected;

  const LoadGameDialog({super.key, required this.onSlotSelected});

  @override
  Widget build(BuildContext context) {
    return _BaseSaveLoadDialog(
      title: 'RESTORE EXPERIMENT',
      onSlotSelected: onSlotSelected,
      actionLabel: 'LOAD',
      requireExistence: true,
    );
  }
}

class _BaseSaveLoadDialog extends StatelessWidget {
  final String title;
  final String actionLabel;
  final Function(int slot) onSlotSelected;
  final bool requireExistence;

  const _BaseSaveLoadDialog({
    required this.title,
    required this.actionLabel,
    required this.onSlotSelected,
    this.requireExistence = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1612),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                color: const Color(0xFFE5D5B0),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white10),
            const SizedBox(height: 24),
            ...List.generate(SaveService.maxSlots, (index) {
              final slot = index + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SlotButton(
                  slot: slot,
                  actionLabel: actionLabel,
                  onPressed: () => onSlotSelected(slot),
                  requireExistence: requireExistence,
                ),
              );
            }),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFC4B89B),
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotButton extends StatefulWidget {
  final int slot;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool requireExistence;

  const _SlotButton({
    required this.slot,
    required this.actionLabel,
    required this.onPressed,
    this.requireExistence = false,
  });

  @override
  State<_SlotButton> createState() => _SlotButtonState();
}

class _SlotButtonState extends State<_SlotButton> {
  Map<String, dynamic>? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final meta = await SaveService.getSaveMetadata(widget.slot);
    if (mounted) {
      setState(() {
        _metadata = meta;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(color: Color(0xFFC4B89B))));
    }

    final hasSave = _metadata != null;
    final isDisabled = widget.requireExistence && !hasSave;

    return OutlinedButton(
      onPressed: isDisabled ? null : widget.onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(20),
        side: BorderSide(
          color: isDisabled
              ? Colors.white10
              : const Color(0xFFC4B89B).withValues(alpha: 0.5),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        backgroundColor: Colors.black.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          _buildSlotNumber(),
          const SizedBox(width: 20),
          Expanded(child: _buildSlotInfo(hasSave)),
          const Icon(Icons.chevron_right, color: Color(0xFFC4B89B), size: 16),
        ],
      ),
    );
  }

  Widget _buildSlotNumber() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFFC4B89B).withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          widget.slot.toString(),
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            color: const Color(0xFFE5D5B0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSlotInfo(bool hasSave) {
    if (!hasSave) {
      return Text(
        'EMPTY SLOT',
        style: GoogleFonts.outfit(
          color: Colors.white24,
          letterSpacing: 2,
          fontSize: 14,
        ),
      );
    }

    final saveTime = DateTime.parse(_metadata!['saveTime']);
    final formattedRealTime = DateFormat('yyyy-MM-dd HH:mm').format(saveTime);
    final gameDate = _metadata!['gameDate'] ?? 'Unknown Date';
    final gameTime = _metadata!['gameTime'] ?? 'Unknown Time';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$gameDate - $gameTime'.toUpperCase(),
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFE5D5B0),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'LAST DOCUMENTED: $formattedRealTime',
          style: GoogleFonts.outfit(
            color: const Color(0xFFC4B89B).withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
