import '../services/combat_manager.dart';

class CombatLogEntry {
  final String message;
  final CombatSide? side;
  final DateTime timestamp;

  CombatLogEntry({
    required this.message,
    this.side,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
