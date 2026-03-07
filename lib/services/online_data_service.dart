import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OnlineDataService {
  // Gist URL for the JSON data. (Will be replaced with an actual Gist link later)
  static const String _dataUrl =
      'https://gist.githubusercontent.com/ABOUDzama/64349b5223537e182a787005a8793758/raw/games.json';
  static const String _lastSyncKey = 'last_sync_date';
  static const String _gamesDataKey = 'games_data_cache';

  /// Fetch data from internet and save it locally if it's a new day or forced
  static Future<String> syncData({bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);

      if (!force && lastSyncStr != null) {
        final lastSync = DateTime.parse(lastSyncStr);
        final now = DateTime.now();
        // If already synced today, skip
        if (lastSync.year == now.year &&
            lastSync.month == now.month &&
            lastSync.day == now.day) {
          return 'already_synced'; // Already up to date
        }
      }

      // Check internet connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none) &&
          connectivityResult.length == 1) {
        return 'no_internet'; // No internet
      }

      // Fetch from URL
      final response = await http.get(Uri.parse(_dataUrl));

      if (response.statusCode == 200) {
        // Save the raw JSON string
        final data = response.body;
        // Verify it's valid JSON
        jsonDecode(data);

        await prefs.setString(_gamesDataKey, data);
        await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
        return 'success';
      }
      return 'server_error';
    } catch (e) {
      debugPrint('Error syncing data: $e');
      return 'error';
    }
  }

  /// Get the cached data for a specific game
  static Future<Map<String, dynamic>?> getGameData(String gameKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_gamesDataKey);

      if (dataStr != null) {
        final Map<String, dynamic> allData = jsonDecode(dataStr);
        if (allData.containsKey(gameKey)) {
          return allData[gameKey] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error reading game data: $e');
      return null;
    }
  }
}
