import 'package:flutter/material.dart';

class PlayerScore {
  final String name;
  int score;

  PlayerScore({required this.name, this.score = 0});
}

class ScoreService extends ChangeNotifier {
  static final ScoreService _instance = ScoreService._internal();
  factory ScoreService() => _instance;
  ScoreService._internal();

  final List<PlayerScore> _players = [];

  List<PlayerScore> get players => List.unmodifiable(_players);

  void setPlayers(List<String> names) {
    _players.clear();
    for (var name in names) {
      _players.add(PlayerScore(name: name));
    }
    notifyListeners();
  }

  void addScore(String name, int points) {
    final index = _players.indexWhere((p) => p.name == name);
    if (index != -1) {
      _players[index].score += points;
      notifyListeners();
    }
  }

  void resetScores() {
    for (var p in _players) {
      p.score = 0;
    }
    notifyListeners();
  }

  void clearSession() {
    _players.clear();
    notifyListeners();
  }

  List<PlayerScore> get rankedPlayers {
    final ranked = List<PlayerScore>.from(_players);
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }
}
