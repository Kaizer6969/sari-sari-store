import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class SaveManager {
  static const String _saveKey = 'sari_sari_save_v1';

  /// I-save ang progress sa local storage ng phone
  static Future<bool> saveGame(GameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = state.serialize();
      return await prefs.setString(_saveKey, jsonString);
    } catch (e) {
      debugPrint('Error saving game: $e');
      return false;
    }
  }

  /// I-load ang naunang laro mula sa local storage
  static Future<GameState?> loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_saveKey);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      return GameState.deserialize(jsonString);
    } catch (e) {
      debugPrint('Error loading game: $e');
      return null;
    }
  }

  /// Tingnan kung may existing save data sa phone
  static Future<bool> hasSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_saveKey);
    } catch (e) {
      return false;
    }
  }

  /// I-reset o burahin ang save data
  static Future<bool> deleteSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_saveKey);
    } catch (e) {
      return false;
    }
  }
}
