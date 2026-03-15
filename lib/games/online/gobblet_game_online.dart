import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class Piece {
  final int player; // 1 for Red, 2 for Blue
  final int size; // 1: Small, 2: Medium, 3: Large
  Piece({required this.player, required this.size});
}

class GobbletGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const GobbletGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<GobbletGameOnline> createState() => _GobbletGameOnlineState();
}

class _GobbletGameOnlineState extends State<GobbletGameOnline> {
  late List<List<List<Piece>>> _board;
  late List<List<int>> _inventory;
  int _currentPlayer = 1;
  bool _isGameOver = false;
  int? _selectedRow;
  int? _selectedCol;
  Piece? _selectedPiece;

  @override
  void initState() {
    super.initState();
    _initGame();
    SocketService().socket.on('gobblet_state_updated', _onGameMove);
    SocketService().socket.on('reset_game', _onResetGame);
  }


  @override
  void dispose() {
    SocketService().socket.off('gobblet_state_updated', _onGameMove);
    SocketService().socket.off('reset_game', _onResetGame);
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
      _inventory = [
        [2, 2, 2],
        [2, 2, 2],
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

    if (!isFromNetwork) {
      bool myTurn = (widget.isHost && _currentPlayer == 1) || (!widget.isHost && _currentPlayer == 2);
      if (!myTurn) return;
    }

    setState(() {
      final targetStack = _board[row][col];
      final topPiece = targetStack.isNotEmpty ? targetStack.last : null;

      if (_selectedPiece == null) {
        return;
      } else {
        bool validMove = false;
        if (topPiece == null || _selectedPiece!.size > topPiece.size) {
          validMove = true;
        }

        if (_selectedRow == row && _selectedCol == col) {
          _selectedRow = null;
          _selectedCol = null;
          _selectedPiece = null;
          return;
        }

        if (validMove) {
          if (_selectedRow == -1) {
            _inventory[_currentPlayer - 1][_selectedCol!]--;
          } else {
            _board[_selectedRow!][_selectedCol!].removeLast();
          }
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

        if (!isFromNetwork) {
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
    if (!isFromNetwork) {
      bool myTurn = (widget.isHost && _currentPlayer == 1) || (!widget.isHost && _currentPlayer == 2);
      if (!myTurn) return;
    }

    if (_inventory[_currentPlayer - 1][sizeIndex] > 0) {
      setState(() {
        _selectedRow = -1;
        _selectedCol = sizeIndex;
        _selectedPiece = Piece(player: _currentPlayer, size: sizeIndex + 1);
      });
      if (!isFromNetwork) {
        SocketService().socket.emit('gobblet_state_updated', {
          'roomCode': widget.roomCode,
          'moveData': {'type': 'inventory', 'sizeIndex': sizeIndex},
        });
      }
    }
  }

  void _checkWin() {
    Piece? getTop(int r, int c) => _board[r][c].isNotEmpty ? _board[r][c].last : null;
    bool checkLine(Piece? p1, Piece? p2, Piece? p3) {
      if (p1 == null || p2 == null || p3 == null) return false;
      return p1.player == p2.player && p2.player == p3.player;
    }

    for (int i = 0; i < 3; i++) {
      if (checkLine(getTop(i, 0), getTop(i, 1), getTop(i, 2))) { _endGame(getTop(i, 0)!.player); return; }
      if (checkLine(getTop(0, i), getTop(1, i), getTop(2, i))) { _endGame(getTop(0, i)!.player); return; }
    }
    if (checkLine(getTop(0, 0), getTop(1, 1), getTop(2, 2))) { _endGame(getTop(0, 0)!.player); return; }
    if (checkLine(getTop(0, 2), getTop(1, 1), getTop(2, 0))) { _endGame(getTop(0, 2)!.player); return; }

    if (_inventory.every((p) => p.every((count) => count == 0)) && !_isGameOver) { _endGame(null); }
  }

  void _endGame(int? winnerPlayer) {
    setState(() => _isGameOver = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          winnerPlayer != null ? '🎉 مبروك اللاعب ${winnerPlayer == 1 ? "الأحمر" : "الأزرق"} فاز!' : 'تعادل!',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold), textAlign: TextAlign.center,
        ),
        content: Text('تحب تلعب دور تاني؟', style: GoogleFonts.cairo(), textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _initGame();
              SocketService().socket.emit('reset_game', {'roomCode': widget.roomCode});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: Text('العب تاني', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceWidget(Piece piece, {bool isSelected = false}) {
    double sizePx = 0;
    switch (piece.size) {
      case 1: sizePx = 35; break;
      case 2: sizePx = 55; break;
      case 3: sizePx = 75; break;
    }
    Color baseColor = piece.player == 1 ? const Color(0xFFE53935) : const Color(0xFF1E88E5);
    Color topColor = piece.player == 1 ? const Color(0xFFFF8A80) : const Color(0xFF82B1FF);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), width: sizePx, height: sizePx,
      decoration: BoxDecoration(
        color: baseColor, shape: BoxShape.circle,
        gradient: RadialGradient(colors: [topColor, baseColor], center: const Alignment(-0.3, -0.5), radius: 0.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: isSelected ? 8 : 4, offset: Offset(0, isSelected ? 6 : 3)),
          if (isSelected) BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 5),
        ],
        border: isSelected ? Border.all(color: Colors.yellowAccent, width: 3) : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: sizePx * 0.25, child: Row(mainAxisSize: MainAxisSize.min, children: [_buildEye(sizePx), SizedBox(width: sizePx * 0.1), _buildEye(sizePx)])),
          Positioned(bottom: sizePx * 0.15, child: Container(width: sizePx * 0.6, height: sizePx * 0.25, decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(sizePx * 0.3), bottomRight: Radius.circular(sizePx * 0.3))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (index) => Container(width: sizePx * 0.12, height: sizePx * 0.15, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(sizePx * 0.05), bottomRight: Radius.circular(sizePx * 0.05)))))))),
        ],
      ),
    );
  }

  Widget _buildEye(double sizePx) {
    return Container(width: sizePx * 0.25, height: sizePx * 0.25, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Center(child: Container(margin: EdgeInsets.only(top: sizePx * 0.05, right: sizePx * 0.05), width: sizePx * 0.1, height: sizePx * 0.1, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))));
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: 'الكبير ياكل الصغير (أونلاين)',
      backgroundColor: Colors.orange.shade50,
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildInventory(2)),
            const Spacer(),
            Container(margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.shade400, borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))]), child: AspectRatio(aspectRatio: 1, child: Column(children: List.generate(3, (row) => Expanded(child: Row(children: List.generate(3, (col) => Expanded(child: _buildGridCell(row, col))))))))),
            const Spacer(),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _buildInventory(1)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCell(int row, int col) {
    final stack = _board[row][col];
    final topPiece = stack.isNotEmpty ? stack.last : null;
    final isSelected = _selectedRow == row && _selectedCol == col;
    return GestureDetector(onTap: () => _handleTap(row, col), child: Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? Colors.yellowAccent : Colors.orange.shade300, width: isSelected ? 4 : 2), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))]), child: Center(child: topPiece != null ? _buildPieceWidget(topPiece, isSelected: isSelected) : null)));
  }

  Widget _buildInventory(int player) {
    final isOnlineMyTurn = (widget.isHost && player == 1) || (!widget.isHost && player == 2);
    final isCurrent = _currentPlayer == player && !_isGameOver && isOnlineMyTurn;
    final color = player == 1 ? Colors.red.shade50 : Colors.blue.shade50;
    final borderColor = player == 1 ? Colors.red.shade300 : Colors.blue.shade300;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(color: isCurrent ? color : Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: isCurrent ? borderColor : Colors.transparent, width: 3)),
      child: Column(
        children: [
          Text((widget.isHost && player == 1) || (!widget.isHost && player == 2) ? 'أنت (${player == 1 ? 'أحمر' : 'أزرق'})' : '${widget.opponentName ?? 'المنافس'} (${player == 1 ? 'أحمر' : 'أزرق'})', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold, color: player == 1 ? Colors.red.shade800 : Colors.blue.shade800)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(3, (sizeIndex) {
            final count = _inventory[player - 1][sizeIndex];
            final isSelected = _selectedRow == -1 && _selectedCol == sizeIndex && _currentPlayer == player;
            return GestureDetector(onTap: isCurrent ? () => _selectFromInventory(sizeIndex) : null, child: Opacity(opacity: count > 0 ? 1.0 : 0.3, child: Column(children: [_buildPieceWidget(Piece(player: player, size: sizeIndex + 1), isSelected: isSelected), const SizedBox(height: 4), Text('x$count', style: GoogleFonts.cairo(fontWeight: FontWeight.bold))])));
          })),
        ],
      ),
    );
  }
}
