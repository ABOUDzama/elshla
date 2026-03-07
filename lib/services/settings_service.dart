import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _vibrationEnabledKey = 'vibration_enabled';
  static const String _githubTokenKey = 'github_token';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isSoundEnabled => _prefs?.getBool(_soundEnabledKey) ?? true;
  static bool get isVibrationEnabled =>
      _prefs?.getBool(_vibrationEnabledKey) ?? true;

  static Future<void> setSoundEnabled(bool value) async {
    await _prefs?.setBool(_soundEnabledKey, value);
  }

  static Future<void> setVibrationEnabled(bool value) async {
    await _prefs?.setBool(_vibrationEnabledKey, value);
  }

  static Future<int> getHighScore(String gameId) async {
    return _prefs?.getInt('highscore_$gameId') ?? 0;
  }

  static Future<void> setHighScore(String gameId, int score) async {
    int currentHighScore = await getHighScore(gameId);
    if (score > currentHighScore) {
      await _prefs?.setInt('highscore_$gameId', score);
    }
  }

  // --- Players Roster ---
  static const String _savedPlayersKey = 'saved_players_roster';

  static List<String> getSavedPlayers() {
    return _prefs?.getStringList(_savedPlayersKey) ?? [];
  }

  static Future<void> savePlayers(List<String> players) async {
    await _prefs?.setStringList(_savedPlayersKey, players);
  }

  // --- GitHub AI Token ---
  // Note: Do NOT put any real token here. Set it via the Settings screen.
  static const String _defaultToken = '';

  static String get githubToken {
    final token = _prefs?.getString(_githubTokenKey);
    if (token == null || token.isEmpty) {
      return _defaultToken;
    }
    return token;
  }

  static Future<void> setGithubToken(String token) async {
    await _prefs?.setString(_githubTokenKey, token);
  }

  static bool get isAiEnabled => githubToken.isNotEmpty;
}
