import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/base_game_scaffold.dart';
import '../services/socket_service.dart';

enum PlayerType { p1, p2, empty }

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
  // Seega is played on a 5x5 board.
  // We represent the board as a 2D list.
  List<List<PlayerType>> board = List.generate(
    5,
    (i) => List.generate(5, (j) => PlayerType.empty),
  );

  // Phase 1: Players drop pieces on the board (24 pieces total, 12 each).
  // The center square (2,2) must remain empty in Phase 1.
  // Phase 2: Players move pieces (up/down/left/right). A piece is captured if surrounded on opposite sides.
  bool isPhaseDrop = true;
  int dropCountP1 = 0;
  int dropCountP2 = 0;

  PlayerType currentPlayer = PlayerType.p1;
  String? winnerMessage;
  bool _showIntro = true;

  // For Phase 2 movement
  int? selectedRow;
  int? selectedCol;

  @override
  void initState() {
    super.initState();
    _initGame();
    if (widget.online) {
      _showIntro = false;
      _setupSocket();
    }
  }

  void _initGame() {
    board = List.generate(5, (i) => List.generate(5, (j) => PlayerType.empty));
    isPhaseDrop = true;
    dropCountP1 = 0;
    dropCountP2 = 0;
    currentPlayer = PlayerType.p1;
    winnerMessage = null;
    selectedRow = null;
    selectedCol = null;
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      if (data['type'] == 'seega_state_updated') {
        setState(() {
          List<dynamic> bData = data['board'];
          for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
              board[i][j] = PlayerType.values[bData[i][j]];
            }
          }
          isPhaseDrop = data['isPhaseDrop'];
          dropCountP1 = data['dropCountP1'];
          dropCountP2 = data['dropCountP2'];
          currentPlayer = PlayerType.values[data['currentPlayer']];
          winnerMessage = data['winnerMessage'];
          selectedRow = data['selectedRow'];
          selectedCol = data['selectedCol'];
        });
      }
    });

    SocketService().socket.on('reset_game', (data) {
      if (!mounted) return;
      setState(() {
        _initGame();
      });
    });
  }

  void _emitState() {
    if (!widget.online || widget.roomCode == null) return;
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode,
      'moveData': {
        'type': 'seega_state_updated',
        'board': board
            .map((row) => row.map((cell) => cell.index).toList())
            .toList(),
        'isPhaseDrop': isPhaseDrop,
        'dropCountP1': dropCountP1,
        'dropCountP2': dropCountP2,
        'currentPlayer': currentPlayer.index,
        'winnerMessage': winnerMessage,
        'selectedRow': selectedRow,
        'selectedCol': selectedCol,
      },
    });
  }

  bool get _isMyTurn {
    if (!widget.online) return true;
    if (widget.isHost && currentPlayer == PlayerType.p1) return true;
    if (!widget.isHost && currentPlayer == PlayerType.p2) return true;
    return false;
  }

  void _handleCellTap(int row, int col) {
    if (!_isMyTurn) return;
    if (winnerMessage != null) return;

    setState(() {
      if (isPhaseDrop) {
        // Phase 1: Dropping pieces
        if (row == 2 && col == 2) {
          // Cannot place in center
          return;
        }
        if (board[row][col] != PlayerType.empty) {
          return; // Cell occupied
        }

        board[row][col] = currentPlayer;

        if (currentPlayer == PlayerType.p1)
          dropCountP1++;
        else
          dropCountP2++;

        if (dropCountP1 + dropCountP2 == 24) {
          isPhaseDrop = false; // Transition to Phase 2
        }

        currentPlayer = (currentPlayer == PlayerType.p1)
            ? PlayerType.p2
            : PlayerType.p1;
      } else {
        // Phase 2: Moving Pieces
        if (selectedRow == null && selectedCol == null) {
          // Select a piece
          if (board[row][col] == currentPlayer) {
            selectedRow = row;
            selectedCol = col;
          }
        } else {
          // Try to move
          if (board[row][col] == currentPlayer) {
            // Change selection to another own piece
            selectedRow = row;
            selectedCol = col;
            return;
          }

          // Verify adjacency (non-diagonal)
          if (board[row][col] == PlayerType.empty) {
            int rDiff = (row - selectedRow!).abs();
            int cDiff = (col - selectedCol!).abs();

            if ((rDiff == 1 && cDiff == 0) || (rDiff == 0 && cDiff == 1)) {
              // Valid move
              board[row][col] = currentPlayer;
              board[selectedRow!][selectedCol!] = PlayerType.empty;

              // Check Captures around the NEW position
              _checkCaptures(row, col);

              // Deselect
              selectedRow = null;
              selectedCol = null;

              _checkWinCondition();
              if (winnerMessage == null) {
                currentPlayer = (currentPlayer == PlayerType.p1)
                    ? PlayerType.p2
                    : PlayerType.p1;
              }
            }
          }
        }
      }
      _emitState();
    });
  }

  void _checkCaptures(int r, int c) {
    // A piece is captured if it is sandwiched between two of the opponent's pieces linearly
    PlayerType opp = (currentPlayer == PlayerType.p1)
        ? PlayerType.p2
        : PlayerType.p1;

    // The center cell (2,2) is safe in traditional Seega

    // Check UP
    if (r - 2 >= 0 &&
        board[r - 1][c] == opp &&
        board[r - 2][c] == currentPlayer) {
      if (!(r - 1 == 2 && c == 2)) {
        board[r - 1][c] = PlayerType.empty;
      }
    }
    // Check DOWN
    if (r + 2 <= 4 &&
        board[r + 1][c] == opp &&
        board[r + 2][c] == currentPlayer) {
      if (!(r + 1 == 2 && c == 2)) {
        board[r + 1][c] = PlayerType.empty;
      }
    }
    // Check LEFT
    if (c - 2 >= 0 &&
        board[r][c - 1] == opp &&
        board[r][c - 2] == currentPlayer) {
      if (!(r == 2 && c - 1 == 2)) {
        board[r][c - 1] = PlayerType.empty;
      }
    }
    // Check RIGHT
    if (c + 2 <= 4 &&
        board[r][c + 1] == opp &&
        board[r][c + 2] == currentPlayer) {
      if (!(r == 2 && c + 1 == 2)) {
        board[r][c + 1] = PlayerType.empty;
      }
    }
  }

  void _checkWinCondition() {
    if (isPhaseDrop) return; // Cant win during drop phase

    int p1Count = 0;
    int p2Count = 0;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (board[i][j] == PlayerType.p1) p1Count++;
        if (board[i][j] == PlayerType.p2) p2Count++;
      }
    }

    // A player wins if the opponent has only 1 piece left (since 2 are required to surround)
    if (p1Count < 2)
      winnerMessage = "فاز اللاعب الأزرق!";
    else if (p2Count < 2)
      winnerMessage = "فاز اللاعب البرتقالي!";
  }

  Widget _buildPiece(PlayerType type, {bool isSelected = false}) {
    if (type == PlayerType.empty) return const SizedBox();

    Color c = type == PlayerType.p1 ? Colors.orange : Colors.blue;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.all(isSelected ? 0 : 5),
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2)),
        ],
        border: isSelected
            ? Border.all(color: Colors.white, width: 3)
            : Border.all(color: Colors.transparent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: 'سيجة',
        backgroundColor: Colors.brown[50]!,
        body: Center(
          child: ElevatedButton(
            onPressed: () => setState(() => _showIntro = false),
            child: Text('ابدأ اللعب', style: GoogleFonts.cairo(fontSize: 24)),
          ),
        ),
      );
    }

    String turnText = currentPlayer == PlayerType.p1
        ? "دور البرتقالي"
        : "دور الأزرق";
    if (winnerMessage != null) {
      turnText = winnerMessage!;
    } else {
      if (isPhaseDrop)
        turnText += " (مرحلة الإنزال)";
      else
        turnText += " (مرحلة التحريك والأكل)";
    }

    int p1Tokens = 0;
    int p2Tokens = 0;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (board[i][j] == PlayerType.p1) p1Tokens++;
        if (board[i][j] == PlayerType.p2) p2Tokens++;
      }
    }

    return BaseGameScaffold(
      title: 'سيجة (Seega)',
      backgroundColor: Colors.brown[50]!,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            turnText,
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: winnerMessage != null ? Colors.greenAccent : Colors.white,
            ),
          ),
          if (!isPhaseDrop) ...[
            const SizedBox(height: 10),
            Text(
              "البرتقالي متبقي: $p1Tokens | الأزرق متبقي: $p2Tokens",
              style: GoogleFonts.cairo(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 30),

          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown, width: 6),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                int row = index ~/ 5;
                int col = index % 5;
                bool isCenter = (row == 2 && col == 2);
                bool isSelected = (selectedRow == row && selectedCol == col);

                PlayerType cellState = board[row][col];

                return GestureDetector(
                  onTap: () => _handleCellTap(row, col),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.brown.withOpacity(0.3),
                        width: 1,
                      ),
                      color: isCenter
                          ? Colors.red.withOpacity(0.3)
                          : (isSelected ? Colors.white30 : Colors.transparent),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isCenter)
                          Icon(
                            Icons.star,
                            color: Colors.brown.withOpacity(0.2),
                            size: 40,
                          ),
                        _buildPiece(cellState, isSelected: isSelected),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
          if (winnerMessage != null && widget.isHost)
            ElevatedButton(
              onPressed: () {
                _initGame();
                if (widget.online) {
                  SocketService().socket.emit('reset_game', {
                    'roomCode': widget.roomCode,
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
              child: Text(
                'لعب مرة أخرى',
                style: GoogleFonts.cairo(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
