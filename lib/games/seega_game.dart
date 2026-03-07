import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/base_game_scaffold.dart';
import '../services/score_service.dart';
import '../services/socket_service.dart';
import '../widgets/game_intro_widget.dart';

class SeegaGame extends StatefulWidget {
  final bool online;
  final bool isHost;
  final String? roomCode;
  final String? opponentName;

  const SeegaGame({
    super.key,
    this.online = false,
    this.isHost = true,
    this.roomCode,
    this.opponentName,
  });

  @override
  State<SeegaGame> createState() => _SeegaGameState();
}

class _SeegaGameState extends State<SeegaGame> {
  List<int> board = List.filled(9, 0);
  int currentPlayer = 1;
  int piecesPlaced1 = 0;
  int piecesPlaced2 = 0;
  int? selectedIndex;
  String? winner;
  bool isPlacementPhase = true;
  bool _showIntro = true;

  @override
  void initState() {
    super.initState();
    if (widget.online) {
      _showIntro = false;
      SocketService().socket.on('game_move', _onGameMove);
      SocketService().socket.on('reset_game', _onResetGame);
    }
  }

  @override
  void dispose() {
    if (widget.online) {
      SocketService().socket.off('game_move', _onGameMove);
      SocketService().socket.off('reset_game', _onResetGame);
    }
    super.dispose();
  }

  void _onGameMove(dynamic data) {
    if (!mounted) return;
    int index = data['index'];
    _processTap(index, isFromNetwork: true);
  }

  void _onResetGame(dynamic data) {
    if (!mounted) return;
    _localReset();
  }

  void _handleTap(int index) {
    _processTap(index, isFromNetwork: false);
  }

  void _processTap(int index, {required bool isFromNetwork}) {
    if (winner != null) return;

    if (widget.online && !isFromNetwork) {
      bool myTurn =
          (widget.isHost && currentPlayer == 1) ||
          (!widget.isHost && currentPlayer == 2);
      if (!myTurn) return;
    }

    if (isPlacementPhase) {
      _handlePlacement(index);
    } else {
      _handleMovement(index);
    }

    if (widget.online && !isFromNetwork) {
      SocketService().socket.emit('game_move', {
        'roomCode': widget.roomCode,
        'moveData': {'index': index},
      });
    }
  }

  void _handlePlacement(int index) {
    if (board[index] != 0) return;
    setState(() {
      board[index] = currentPlayer;
      if (currentPlayer == 1) {
        piecesPlaced1++;
      } else {
        piecesPlaced2++;
      }
      if (piecesPlaced1 == 3 && piecesPlaced2 == 3) isPlacementPhase = false;
      currentPlayer = currentPlayer == 1 ? 2 : 1;
    });
  }

  void _handleMovement(int index) {
    if (selectedIndex == null) {
      if (board[index] == currentPlayer) setState(() => selectedIndex = index);
    } else {
      if (_isAdjacent(selectedIndex!, index) && board[index] == 0) {
        setState(() {
          board[index] = currentPlayer;
          board[selectedIndex!] = 0;
          selectedIndex = null;
          _checkWinner();
          currentPlayer = currentPlayer == 1 ? 2 : 1;
        });
      } else if (board[index] == currentPlayer) {
        setState(() => selectedIndex = index);
      }
    }
  }

  bool _isAdjacent(int from, int to) {
    int rowFrom = from ~/ 3, colFrom = from % 3;
    int rowTo = to ~/ 3, colTo = to % 3;
    return (rowFrom == rowTo && (colFrom - colTo).abs() == 1) ||
        (colFrom == colTo && (rowFrom - rowTo).abs() == 1);
  }

  void _checkWinner() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (var line in lines) {
      if (board[line[0]] != 0 &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        setState(() => winner = board[line[0]] == 1 ? 'الأحمر' : 'الأزرق');

        // Award points
        final scoreService = ScoreService();
        if (scoreService.players.isNotEmpty) {
          final winnerIndex = board[line[0]] == 1 ? 0 : 1;
          if (winnerIndex < scoreService.players.length) {
            scoreService.addScore(scoreService.players[winnerIndex].name, 10);
          }
        }
        return;
      }
    }
  }

  void _localReset() {
    setState(() {
      board = List.filled(9, 0);
      currentPlayer = 1;
      piecesPlaced1 = 0;
      piecesPlaced2 = 0;
      selectedIndex = null;
      winner = null;
      isPlacementPhase = true;
    });
  }

  void _resetGame() {
    _localReset();
    if (widget.online) {
      SocketService().socket.emit('reset_game', {'roomCode': widget.roomCode});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '🎮 لعبة السيجا التاريخية',
        backgroundColor: const Color(0xFF3E2723),
        body: GameIntroWidget(
          title: 'السيجا التاريخية',
          icon: '🎮',
          description:
              'اللعبة القديمة الأصيلة اللي محتاجة ذكاء وتخطيط! السجا هي لعبة مصرية عريقة.. وزع حصواتك وفكر إزاي تحاصر خصمك وتكسب!',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    return BaseGameScaffold(
      title: '🎮 لعبة السيجا التاريخية',
      backgroundColor: const Color(0xFF3E2723), // Darker Brown
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: _resetGame,
        ),
      ],
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              const Color(0xFF5D4037),
              const Color(0xFF3E2723),
              const Color(0xFF21130D), // Much darker for contrast
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  Text(
                    isPlacementPhase ? 'مرحلة التوزيع' : 'مرحلة التحريك',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    isPlacementPhase
                        ? 'حط حصواتك الـ 3 في الأماكن الفاضية'
                        : 'حرك حصواتك جنب بعض عشان تكسب',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),
            const SizedBox(height: 20),
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    winner != null
                        ? 'المنتصر: $winner! 🏆'
                        : widget.online
                        ? (((widget.isHost && currentPlayer == 1) ||
                                  (!widget.isHost && currentPlayer == 2))
                              ? 'دور حجر الألماس'
                              : 'دور ${widget.opponentName ?? 'المنافس'}')
                        : 'دور الحجر: ${currentPlayer == 1 ? 'الأحمر' : 'الأزرق'}',
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: winner != null
                          ? Colors.amberAccent
                          : (currentPlayer == 1
                                ? Colors.redAccent.shade100
                                : Colors.blueAccent.shade100),
                    ),
                  ),
                )
                .animate(key: ValueKey(winner ?? currentPlayer.toString()))
                .scale()
                .fadeIn(),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D1B17),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: const Color(0xFF1E100D),
                      width: 12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        offset: const Offset(8, 8),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                        ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final value = board[index];
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () => _handleTap(index),
                        child: AnimatedContainer(
                          duration: 250.ms,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1A1A1A,
                            ).withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.amber : Colors.white10,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: value == 0
                                ? null
                                : Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.3, -0.3),
                                        radius: 0.9,
                                        colors: value == 1
                                            ? [
                                                const Color(
                                                  0xFFEF9A9A,
                                                ), // light red
                                                const Color(0xFFD32F2F), // red
                                                const Color(
                                                  0xFF8B0000,
                                                ), // dark red
                                              ]
                                            : [
                                                const Color(
                                                  0xFF90CAF9,
                                                ), // light blue
                                                const Color(0xFF1976D2), // blue
                                                const Color(
                                                  0xFF0D47A1,
                                                ), // dark blue
                                              ],
                                      ),
                                      border: Border.all(
                                        color: value == 1
                                            ? const Color(0xFFFFCDD2)
                                            : const Color(0xFFBBDEFB),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: value == 1
                                              ? Colors.red.withValues(
                                                  alpha: 0.6,
                                                )
                                              : Colors.blue.withValues(
                                                  alpha: 0.6,
                                                ),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ).animate().scale(
                                    curve: Curves.elasticOut,
                                    duration: 600.ms,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            if (winner != null)
              ElevatedButton(
                onPressed: _resetGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D4037),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إعادة التحدي',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.amberAccent,
                  ),
                ),
              ).animate().fadeIn().scale(),
          ],
        ),
      ),
    );
  }
}
