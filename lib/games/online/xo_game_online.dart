import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class TicTacToeGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const TicTacToeGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<TicTacToeGameOnline> createState() => _TicTacToeGameOnlineState();
}

class _TicTacToeGameOnlineState extends State<TicTacToeGameOnline> {
  List<String> board = List.filled(9, '');
  bool isXTurn = true;
  String? winner;
  bool isDraw = false;
  List<int>? winningLine;

  @override
  void initState() {
    super.initState();
    SocketService().socket.on('game_move', _onGameMove);
    SocketService().socket.on('reset_game', _onResetGame);
  }


  @override
  void dispose() {
    SocketService().socket.off('game_move', _onGameMove);
    SocketService().socket.off('reset_game', _onResetGame);
    super.dispose();
  }

  void _onGameMove(dynamic data) {
    if (!mounted) return;
    int index = data['index'];
    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      isXTurn = !isXTurn;
      _checkWinner();
    });
  }

  void _onResetGame(dynamic data) {
    if (!mounted) return;
    _localReset();
  }

  void _handleTap(int index) {
    if (board[index] != '' || winner != null) return;

    bool myTurn = (widget.isHost && isXTurn) || (!widget.isHost && !isXTurn);
    if (!myTurn) return;

    setState(() {
      board[index] = isXTurn ? 'X' : 'O';
      isXTurn = !isXTurn;
      _checkWinner();
    });

    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode,
      'moveData': {'index': index},
    });
  }

  void _checkWinner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // Rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // Cols
      [0, 4, 8], [2, 4, 6], // Diagonals
    ];

    for (var line in lines) {
      if (board[line[0]] != '' &&
          board[line[0]] == board[line[1]] &&
          board[line[0]] == board[line[2]]) {
        setState(() {
          winner = board[line[0]];
          winningLine = line;
        });
        return;
      }
    }

    if (!board.contains('')) {
      setState(() {
        isDraw = true;
      });
    }
  }

  void _localReset() {
    setState(() {
      board = List.filled(9, '');
      isXTurn = true;
      winner = null;
      isDraw = false;
      winningLine = null;
    });
  }

  void _resetGame() {
    _localReset();
    SocketService().socket.emit('reset_game', {'roomCode': widget.roomCode});
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '✏️ صبورة إكس أو (أونلاين)',
      backgroundColor: const Color(0xFF0D1B12),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          onPressed: _resetGame,
        ),
      ],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF0D1B12), const Color(0xFF08120C)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  winner != null
                      ? 'الفائز: $winner ✨'
                      : isDraw
                      ? 'تعادل! 🤝'
                      : ((widget.isHost && isXTurn) || (!widget.isHost && !isXTurn)
                            ? 'دورك'
                            : 'دور ${widget.opponentName ?? 'المنافس'}'),
                  style: GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: -0.2, end: 0),

            const SizedBox(height: 50),

            Padding(
              padding: const EdgeInsets.all(30.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: ChalkGridPainter(),
                    ),
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                          ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        final value = board[index];
                        return GestureDetector(
                          onTap: () => _handleTap(index),
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: value == ''
                                  ? null
                                  : Text(
                                      value,
                                      style: GoogleFonts.permanentMarker(
                                        fontSize: 70,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        shadows: [
                                          Shadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(2, 2),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn().scale(
                                      begin: const Offset(0.5, 0.5),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (winningLine != null)
                      CustomPaint(
                        size: Size.infinite,
                        painter: WinLinePainter(winningLine!),
                      ).animate().fadeIn(duration: 400.ms),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            if (winner != null || isDraw)
              TextButton.icon(
                onPressed: _resetGame,
                icon: const Icon(
                  Icons.cleaning_services_rounded,
                  color: Colors.white70,
                ),
                label: Text(
                  'امسح الصبورة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  side: const BorderSide(color: Colors.white38),
                ),
              ).animate().fadeIn().scale(),
          ],
        ),
      ),
    );
  }
}

class ChalkGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    double thirdW = size.width / 3;
    double thirdH = size.height / 3;

    canvas.drawLine(Offset(thirdW, 10), Offset(thirdW + 2, size.height - 10), paint);
    canvas.drawLine(Offset(thirdW * 2, 12), Offset(thirdW * 2 - 2, size.height - 8), paint);
    canvas.drawLine(Offset(10, thirdH), Offset(size.width - 10, thirdH - 2), paint);
    canvas.drawLine(Offset(8, thirdH * 2), Offset(size.width - 12, thirdH * 2 + 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WinLinePainter extends CustomPainter {
  final List<int> line;
  WinLinePainter(this.line);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    double cellW = size.width / 3;
    double cellH = size.height / 3;

    Offset getOffset(int index) {
      double x = (index % 3) * cellW + cellW / 2;
      double y = (index ~/ 3) * cellH + cellH / 2;
      return Offset(x, y);
    }

    Offset start = getOffset(line[0]);
    Offset end = getOffset(line[2]);

    Offset direction = (end - start);
    start = start - direction * 0.1;
    end = end + direction * 0.1;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
