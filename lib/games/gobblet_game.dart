import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/base_game_scaffold.dart';
import '../widgets/game_intro_widget.dart';
import '../services/score_service.dart';
import '../services/socket_service.dart';

class Piece {
  final int player; // 1 for Red, 2 for Blue
  final int size; // 1: Small, 2: Medium, 3: Large
  Piece({required this.player, required this.size});
}

class GobbletGame extends StatefulWidget {
  final bool online;
  final bool isHost;
  final String? roomCode;
  final String? opponentName;

  const GobbletGame({
    super.key,
    this.online = false,
    this.isHost = true,
    this.roomCode,
    this.opponentName,
  });

  @override
  State<GobbletGame> createState() => _GobbletGameState();
}

class _GobbletGameState extends State<GobbletGame> {
  // 3x3 Board. Each cell is a stack of pieces.
  late List<List<List<Piece>>> _board;
  bool _showIntro = true;

  // Inventory available for each player: [smallCount, mediumCount, largeCount]
  late List<List<int>> _inventory;

  int _currentPlayer = 1; // 1: Red, 2: Blue
  bool _isGameOver = false;

  // Selection state
  // Can select from inventory (row = -1, col = size) or from board
  int? _selectedRow;
  int? _selectedCol;
  Piece? _selectedPiece;

  @override
  void initState() {
    super.initState();
    _initGame();
    if (widget.online) {
      _showIntro = false;
      SocketService().socket.on('gobblet_state_updated', _onGameMove);
      SocketService().socket.on('reset_game', _onResetGame);
    }
  }

  @override
  void dispose() {
    if (widget.online) {
      SocketService().socket.off('gobblet_state_updated', _onGameMove);
      SocketService().socket.off('reset_game', _onResetGame);
    }
    super.dispose();
  }

  void _onGameMove(dynamic data) {
    if (!mounted) return;
    String type = data['type'];
    if (type == 'tap') {
      _processTap(data['row'], data['col'], isFromNetwork: true);
    } else if (type == 'inventory') {
      _processInventorySelect(data['sizeIndex'], isFromNetwork: true);
    }
  }

  void _onResetGame(dynamic data) {
    if (!mounted) return;
    _initGame();
  }

  void _initGame() {
    setState(() {
      _board = List.generate(3, (_) => List.generate(3, (_) => []));
      // 2 small, 2 medium, 2 large per player
      _inventory = [
        [2, 2, 2], // Player 1 (Red)
        [2, 2, 2], // Player 2 (Blue)
      ];
      _currentPlayer = 1;
      _isGameOver = false;
      _selectedRow = null;
      _selectedCol = null;
      _selectedPiece = null;
    });
  }

  void _handleTap(int row, int col) {
    _processTap(row, col, isFromNetwork: false);
  }

  void _processTap(int row, int col, {required bool isFromNetwork}) {
    if (_isGameOver) return;

    if (widget.online && !isFromNetwork) {
      bool myTurn =
          (widget.isHost && _currentPlayer == 1) ||
          (!widget.isHost && _currentPlayer == 2);
      if (!myTurn) return;
    }

    setState(() {
      final targetStack = _board[row][col];
      final topPiece = targetStack.isNotEmpty ? targetStack.last : null;

      if (_selectedPiece == null) {
        // SELECTING A PIECE FROM THE BOARD IS NOW DISABLED
        // Players can only place new pieces from inventory
        return;
      } else {
        // MOVING/PLACING THE SELECTED PIECE
        bool validMove = false;

        if (topPiece == null) {
          validMove = true;
        } else if (_selectedPiece!.size > topPiece.size) {
          validMove = true;
        }

        // Check if player is trying to place it exactly where it was
        if (_selectedRow == row && _selectedCol == col) {
          // just deselect
          _selectedRow = null;
          _selectedCol = null;
          _selectedPiece = null;
          return;
        }

        if (validMove) {
          // Remove from old location
          if (_selectedRow == -1) {
            // From inventory: _selectedCol held the piece size (0=Small, 1=Med, 2=Large)
            _inventory[_currentPlayer - 1][_selectedCol!]--;
          } else {
            // From board
            _board[_selectedRow!][_selectedCol!].removeLast();
          }

          // Add to new location
          _board[row][col].add(_selectedPiece!);

          _checkWin();

          if (!_isGameOver) {
            _currentPlayer = _currentPlayer == 1 ? 2 : 1;
            _selectedRow = null;
            _selectedCol = null;
            _selectedPiece = null;
          }
        } else {
          _selectedRow = null;
          _selectedCol = null;
          _selectedPiece = null;
        }

        if (widget.online && !isFromNetwork) {
          SocketService().socket.emit('gobblet_state_updated', {
            'roomCode': widget.roomCode,
            'moveData': {'type': 'tap', 'row': row, 'col': col},
          });
        }
      }
    });
  }

  void _selectFromInventory(int sizeIndex) {
    _processInventorySelect(sizeIndex, isFromNetwork: false);
  }

  void _processInventorySelect(int sizeIndex, {required bool isFromNetwork}) {
    if (_isGameOver) return;

    if (widget.online && !isFromNetwork) {
      bool myTurn =
          (widget.isHost && _currentPlayer == 1) ||
          (!widget.isHost && _currentPlayer == 2);
      if (!myTurn) return;
    }

    if (_inventory[_currentPlayer - 1][sizeIndex] > 0) {
      setState(() {
        _selectedRow = -1; // -1 means inventory
        _selectedCol = sizeIndex;
        _selectedPiece = Piece(player: _currentPlayer, size: sizeIndex + 1);
      });

      if (widget.online && !isFromNetwork) {
        SocketService().socket.emit('gobblet_state_updated', {
          'roomCode': widget.roomCode,
          'moveData': {'type': 'inventory', 'sizeIndex': sizeIndex},
        });
      }
    }
  }

  void _checkWin() {
    // Check top pieces only
    Piece? getTop(int r, int c) =>
        _board[r][c].isNotEmpty ? _board[r][c].last : null;

    bool checkLine(Piece? p1, Piece? p2, Piece? p3) {
      if (p1 == null || p2 == null || p3 == null) return false;
      return p1.player == p2.player && p2.player == p3.player;
    }

    // Checking rows, cols, diags
    for (int i = 0; i < 3; i++) {
      if (checkLine(getTop(i, 0), getTop(i, 1), getTop(i, 2))) {
        _endGame(getTop(i, 0)!.player);
        return;
      }
      if (checkLine(getTop(0, i), getTop(1, i), getTop(2, i))) {
        _endGame(getTop(0, i)!.player);
        return;
      }
    }
    if (checkLine(getTop(0, 0), getTop(1, 1), getTop(2, 2))) {
      _endGame(getTop(0, 0)!.player);
      return;
    }
    if (checkLine(getTop(0, 2), getTop(1, 1), getTop(2, 0))) {
      _endGame(getTop(0, 2)!.player);
      return;
    }

    // Realistic draw check: All inventory pieces are used and no win detected
    bool allUsed = _inventory.every((p) => p.every((count) => count == 0));
    if (allUsed && !_isGameOver) {
      _endGame(null); // Draw
    }
  }

  void _endGame(int? winnerPlayer) {
    setState(() {
      _isGameOver = true;
    });

    if (winnerPlayer != null) {
      final scoreService = ScoreService();
      if (scoreService.players.isNotEmpty) {
        final winnerIndex = winnerPlayer - 1;
        if (winnerIndex >= 0 && winnerIndex < scoreService.players.length) {
          scoreService.addScore(scoreService.players[winnerIndex].name, 10);
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          winnerPlayer != null
              ? '🎉 مبروك اللاعب ${winnerPlayer == 1 ? "الأحمر" : "الأزرق"} فاز!'
              : 'تعادل!',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'تحب تلعب دور تاني؟',
          style: GoogleFonts.cairo(),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _initGame();
              if (widget.online) {
                SocketService().socket.emit('reset_game', {
                  'roomCode': widget.roomCode,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'العب تاني',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceWidget(Piece piece, {bool isSelected = false}) {
    double sizePx = 0;
    switch (piece.size) {
      case 1:
        sizePx = 35;
        break; // Small
      case 2:
        sizePx = 55;
        break; // Medium
      case 3:
        sizePx = 75;
        break; // Large
    }

    Color baseColor = piece.player == 1
        ? const Color(0xFFE53935)
        : const Color(0xFF1E88E5);
    Color topColor = piece.player == 1
        ? const Color(0xFFFF8A80)
        : const Color(0xFF82B1FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: sizePx,
      height: sizePx,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [topColor, baseColor],
          center: const Alignment(-0.3, -0.5),
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: isSelected ? 8 : 4,
            offset: Offset(0, isSelected ? 6 : 3),
          ),
          if (isSelected)
            BoxShadow(
              color: Colors.yellowAccent.withValues(alpha: 0.6),
              blurRadius: 15,
              spreadRadius: 5,
            ),
        ],
        border: isSelected
            ? Border.all(color: Colors.yellowAccent, width: 3)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Eyes
          Positioned(
            top: sizePx * 0.25,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEye(sizePx),
                SizedBox(width: sizePx * 0.1),
                _buildEye(sizePx),
              ],
            ),
          ),
          // Mouth (Teeth)
          Positioned(
            bottom: sizePx * 0.15,
            child: Container(
              width: sizePx * 0.6,
              height: sizePx * 0.25,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(sizePx * 0.3),
                  bottomRight: Radius.circular(sizePx * 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (index) => Container(
                    width: sizePx * 0.12,
                    height: sizePx * 0.15,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(sizePx * 0.05),
                        bottomRight: Radius.circular(sizePx * 0.05),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye(double sizePx) {
    return Container(
      width: sizePx * 0.25,
      height: sizePx * 0.25,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          margin: EdgeInsets.only(top: sizePx * 0.05, right: sizePx * 0.05),
          width: sizePx * 0.1,
          height: sizePx * 0.1,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildGridCell(int row, int col) {
    final stack = _board[row][col];
    final topPiece = stack.isNotEmpty ? stack.last : null;
    final isSelected = _selectedRow == row && _selectedCol == col;

    return GestureDetector(
      onTap: () => _handleTap(row, col),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.yellowAccent : Colors.orange.shade300,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: topPiece != null
              ? _buildPieceWidget(topPiece, isSelected: isSelected)
              : null,
        ),
      ),
    );
  }

  Widget _buildInventory(int player) {
    final isOnlineMyTurn =
        !widget.online ||
        (widget.isHost && player == 1) ||
        (!widget.isHost && player == 2);
    final isCurrent =
        _currentPlayer == player && !_isGameOver && isOnlineMyTurn;
    final color = player == 1 ? Colors.red.shade50 : Colors.blue.shade50;
    final borderColor = player == 1
        ? Colors.red.shade300
        : Colors.blue.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isCurrent ? color : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? borderColor : Colors.transparent,
          width: 3,
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.online
                ? (widget.isHost && player == 1) ||
                          (!widget.isHost && player == 2)
                      ? 'أنت (${player == 1 ? 'أحمر' : 'أزرق'})'
                      : '${widget.opponentName ?? 'المنافس'} (${player == 1 ? 'أحمر' : 'أزرق'})'
                : player == 1
                ? 'اللاعب الأحمر'
                : 'اللاعب الأزرق',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: player == 1 ? Colors.red.shade800 : Colors.blue.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (sizeIndex) {
              final count = _inventory[player - 1][sizeIndex];
              final isSelected =
                  _selectedRow == -1 &&
                  _selectedCol == sizeIndex &&
                  _currentPlayer == player;

              return GestureDetector(
                onTap: isCurrent ? () => _selectFromInventory(sizeIndex) : null,
                child: Opacity(
                  opacity: count > 0 ? 1.0 : 0.3,
                  child: Column(
                    children: [
                      _buildPieceWidget(
                        Piece(player: player, size: sizeIndex + 1),
                        isSelected: isSelected,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'x$count',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: '👾 الكبير ياكل الصغير',
        backgroundColor: Colors.orange.shade50,
        body: GameIntroWidget(
          title: 'الكبير ياكل الصغير',
          icon: '👾',
          description:
              'اللعبة الاستراتيجية الممتعة! حاول تعمل صف من تلات قطع، بس خلي بالك.. القطع الكبيرة ممكن تاكل القطع الصغيرة!\n\nمين هيعرف يسيطر على البورد؟',
          onStart: () => setState(() => _showIntro = false),
        ),
      );
    }

    return BaseGameScaffold(
      title: 'الكبير ياكل الصغير',
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Player 2 Inventory (Top)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInventory(2),
            ),

            const Spacer(),

            // Game Board
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade400,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Column(
                  children: List.generate(3, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(3, (col) {
                          return Expanded(child: _buildGridCell(row, col));
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const Spacer(),

            // Player 1 Inventory (Bottom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInventory(1),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
