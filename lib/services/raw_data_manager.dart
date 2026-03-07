import 'online_data_service.dart';

class RawDataManager {
  /// Helper to fetch game data
  /// It first checks if there is updated data from OnlineDataService.
  /// If none exists, it falls back to the provided default local data.
  static Future<Map<String, dynamic>> getGameData(
      String gameKey, Map<String, dynamic> defaultData) async {
    final onlineData = await OnlineDataService.getGameData(gameKey);
    
    if (onlineData != null && onlineData.isNotEmpty) {
      return onlineData;
    }
    
    // Fallback to local
    return defaultData;
  }
  
  /// Helper to fetch a list of items for a game
  static Future<List<dynamic>> getGameList(
      String gameKey, List<dynamic> defaultList) async {
    // We assume the online data structure wraps the list in a key named 'items'
    // e.g {"who_am_i": {"items": [ ... ] } }
    final onlineData = await OnlineDataService.getGameData(gameKey);
    
    if (onlineData != null && onlineData.containsKey('items')) {
      final items = onlineData['items'];
      if (items is List && items.isNotEmpty) {
        return items;
      }
    }
    
    // Fallback to local
    return defaultList;
  }
}
