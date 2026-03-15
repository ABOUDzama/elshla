import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ludo_models.dart';

class LudoController extends ChangeNotifier {
  final List<LudoPawn> pawns = [];
  int currentPlayerIndex = 0; // 0: Red, 1: Green, 2: Yellow, 3: Blue
  int diceValue = 1;
  bool isRolling = false;
  bool canRoll = true;
  String gameMessage = 'ابدأ اللعب! دور اللاعب الأحمر';

  final List<String> playerColors = ['red', 'green', 'yellow', 'blue'];
  final List<String> playerNames = ['الأحمر', 'الأخضر', 'الأصفر', 'الأزرق'];
  final List<Color> uiColors = [
    Colors.red,
    Colors.green,
    Colors.yellow[700]!,
    Colors.blue
  ];

  int numPlayers = 4;
  List<String> activeColors = [];
  List<String> customNames = [];

  LudoController() {
    initializeGame(4);
  }

  void initializeGame(int playersCount, {List<String>? names}) {
    numPlayers = playersCount;
    customNames = names ?? playerNames.sublist(0, numPlayers);
    activeColors = playerColors.sublist(0, numPlayers);
    pawns.clear();
    for (int p = 0; p < numPlayers; p++) {
      for (int i = 0; i < 4; i++) {
        pawns.add(LudoPawn(id: i, colorStr: playerColors[p], position: -1));
      }
    }
    currentPlayerIndex = 0;
    diceValue = 1;
    isRolling = false;
    canRoll = true;
    gameMessage = 'ابدأ اللعب! دور ${customNames[0]}';
    notifyListeners();
  }

  Future<void> rollDice() async {
    if (!canRoll || isRolling) return;

    isRolling = true;
    canRoll = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    diceValue = Random().nextInt(6) + 1;
    isRolling = false;
    
    bool hasMoves = checkAvailableMoves();
    if (!hasMoves) {
      gameMessage = 'لا توجد حركات متاحة لـ ${customNames[currentPlayerIndex]}';
      notifyListeners();
      await Future.delayed(const Duration(seconds: 1));
      nextTurn();
    } else {
      gameMessage = 'اختار قطعة لتحريكها ($diceValue)';
      notifyListeners();
    }
  }

  bool checkAvailableMoves() {
    final playerPawns = pawns
        .where((p) => p.colorStr == playerColors[currentPlayerIndex] && !p.isFinished)
        .toList();
    for (var pawn in playerPawns) {
      if (canMovePawn(pawn)) return true;
    }
    return false;
  }

  bool canMovePawn(LudoPawn pawn) {
    if (pawn.isFinished) return false;
    if (pawn.position == -1) return diceValue == 6;
    
    int nextPos = pawn.position + diceValue;
    return nextPos <= 56;
  }

  int? winnerIndex;

  void movePawn(LudoPawn pawn) {
    if (pawn.colorStr != playerColors[currentPlayerIndex] || canRoll || isRolling || winnerIndex != null) return;
    if (!canMovePawn(pawn)) return;

    if (pawn.position == -1) {
      pawn.position = 0; // Enter board
    } else {
      pawn.position += diceValue;
    }

    if (pawn.position == 56) {
      pawn.isFinished = true;
      gameMessage = 'قطعة وصلت للنهاية! 🎉';
      _checkWinCondition();
    }

    _checkCollisions(pawn);

    if (winnerIndex == null) {
      if (diceValue == 6) {
        canRoll = true;
        gameMessage = 'رمية إضافية! دور ${customNames[currentPlayerIndex]}';
      } else {
        nextTurn();
      }
    }
    notifyListeners();
  }

  void _checkWinCondition() {
    int finishedCount = pawns.where((p) => p.colorStr == playerColors[currentPlayerIndex] && p.isFinished).length;
    if (finishedCount == 4) {
      winnerIndex = currentPlayerIndex;
      gameMessage = 'مبروك! ${customNames[currentPlayerIndex]} فاز باللعبة! ✨';
    }
  }

  void _checkCollisions(LudoPawn movedPawn) {
    if (movedPawn.position > 50 || movedPawn.position < 0) return;

    final movedCoords = getCoords(movedPawn);
    
    bool isSafe = LudoPath.safeSpots.any((s) => s[0] == movedCoords[0] && s[1] == movedCoords[1]);
    if (isSafe) return;

    for (var otherPawn in pawns) {
      if (otherPawn.colorStr == movedPawn.colorStr) continue;
      if (otherPawn.position == -1 || otherPawn.position > 50) continue;

      final otherCoords = getCoords(otherPawn);
      if (movedCoords[0] == otherCoords[0] && movedCoords[1] == otherCoords[1]) {
        otherPawn.position = -1; // Send back to base
        gameMessage = 'تم ضرب قطعة الخصم! 🤛';
      }
    }
  }

  void nextTurn() {
    currentPlayerIndex = (currentPlayerIndex + 1) % numPlayers;
    canRoll = true;
    gameMessage = 'دور ${customNames[currentPlayerIndex]}';
    notifyListeners();
  }

  List<int> getCoords(LudoPawn pawn) {
    int startOffset = 0;
    List<List<int>> homePath = LudoPath.redHomePath;

    if (pawn.colorStr == 'green') {
      startOffset = LudoPath.greenStart;
      homePath = LudoPath.greenHomePath;
    } else if (pawn.colorStr == 'yellow') {
      startOffset = LudoPath.yellowStart;
      homePath = LudoPath.yellowHomePath;
    } else if (pawn.colorStr == 'blue') {
      startOffset = LudoPath.blueStart;
      homePath = LudoPath.blueHomePath;
    }

    if (pawn.position == -1) return [-1, -1];
    if (pawn.position <= 50) {
      int idx = (pawn.position + startOffset) % 52;
      return LudoPath.universalPath[idx];
    } else {
      int idx = pawn.position - 51;
      return homePath[idx];
    }
  }
}
