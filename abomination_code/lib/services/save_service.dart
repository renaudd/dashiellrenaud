import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import '../state/game_state.dart';

class SaveService {
  static const int maxSlots = 3;

  static String _getFileName(int slot) => 'savegame_slot_$slot.json';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _localFile(int slot) async {
    final path = await _localPath;
    return File('$path/${_getFileName(slot)}');
  }

  static Future<void> saveGame(GameState gameState, {int slot = 1}) async {
    try {
      final file = await _localFile(slot);
      final data = gameState.toJson();

      // Add metadata
      data['metadata'] = {
        'saveTime': DateTime.now().toIso8601String(),
        'gameDate': gameState.currentDate.formattedDate,
        'gameTime': gameState.currentDate.formattedTime,
      };

      final jsonString = jsonEncode(data);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Error saving game (slot $slot): $e');
    }
  }

  static Future<Map<String, dynamic>?> loadGame({int slot = 1}) async {
    try {
      final file = await _localFile(slot);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading game (slot $slot): $e');
      return null;
    }
  }

  static Future<bool> hasSaveGame({int slot = 1}) async {
    final file = await _localFile(slot);
    return file.exists();
  }

  static Future<Map<String, dynamic>?> getSaveMetadata(int slot) async {
    try {
      final file = await _localFile(slot);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;
      return data['metadata'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Error reading metadata (slot $slot): $e');
      return null;
    }
  }

  static Future<void> deleteSave(int slot) async {
    final file = await _localFile(slot);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
