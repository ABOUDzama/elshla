import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/base_game_scaffold.dart';
import '../services/socket_service.dart';

enum PieceSize { small, medium, large }

enum PlayerType { p1, p2 }

class GobbletPiece {
  final PlayerType owner;
  final PieceSize size;
  final int id; // to uniquely identify pieces in drag/drop

  GobbletPiece({required this.owner, required this.size, required this.id});

  Map<String, dynamic> toJson() => {
    'owner': owner.index,
    'size': size.index,
    'id': id,
  };

  factory GobbletPiece.fromJson(Map<String, dynamic> json) {
    return GobbletPiece(
      owner: PlayerType.values[json['owner']],
      size: PieceSize.values[json['size']],
      id: json['id'],
    );
  }
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
  // The board is 3x3. Each cell can hold a stack of pieces.
  List<List<List<GobbletPiece>>> board = List.generate(
    3,
    (i) => List.generate(3, (j) => []),
  );

  // Each player starts with 2 of each size
  List<GobbletPiece> p1Inventory = [];
  List<GobbletPiece> p2Inventory = [];

  PlayerType currentPlayer = PlayerType.p1;
  String? winnerMessage;
  bool _showIntro = true;

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
    int idCounter = 0;
    p1Inventory = [
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.small,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.small,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.medium,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.medium,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.large,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p1,
        size: PieceSize.large,
        id: idCounter++,
      ),
    ];
    p2Inventory = [
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.small,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.small,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.medium,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.medium,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.large,
        id: idCounter++,
      ),
      GobbletPiece(
        owner: PlayerType.p2,
        size: PieceSize.large,
        id: idCounter++,
      ),
    ];
    board = List.generate(3, (i) => List.generate(3, (j) => []));
    currentPlayer = PlayerType.p1;
    winnerMessage = null;
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      if (data['type'] == 'gobblet_state_updated') {
        setState(() {
          // Decode board
          List<dynamic> bData = data['board'];
          for (int i = 0; i < 3; i++) {
            for (int j = 0; j < 3; j++) {
              board[i][j] = (bData[i][j] as List)
                  .map((p) => GobbletPiece.fromJson(p))
                  .toList();
            }
          }
          // Decode inventories
          p1Inventory = (data['p1Inventory'] as List)
              .map((p) => GobbletPiece.fromJson(p))
              .toList();
          p2Inventory = (data['p2Inventory'] as List)
              .map((p) => GobbletPiece.fromJson(p))
              .toList();

          currentPlayer = PlayerType.values[data['currentPlayer']];
          winnerMessage = data['winnerMessage'];
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
        'type': 'gobblet_state_updated',
        'board': board
            .map(
              (row) => row
                  .map((cell) => cell.map((p) => p.toJson()).toList())
                  .toList(),
            )
            .toList(),
        'p1Inventory': p1Inventory.map((p) => p.toJson()).toList(),
        'p2Inventory': p2Inventory.map((p) => p.toJson()).toList(),
        'currentPlayer': currentPlayer.index,
        'winnerMessage': winnerMessage,
      },
    });
  }

  bool get _isMyTurn {
    if (!widget.online) return true;
    if (widget.isHost && currentPlayer == PlayerType.p1) return true;
    if (!widget.isHost && currentPlayer == PlayerType.p2) return true;
    return false;
  }

  bool _canPlacePiece(GobbletPiece piece, int row, int col) {
    if (winnerMessage != null) return false;
    List<GobbletPiece> cellStack = board[row][col];
    if (cellStack.isEmpty) return true;

    // Can only place if our piece is strictly larger than the top piece
    GobbletPiece topPiece = cellStack.last;
    if (piece.size == PieceSize.large && topPiece.size != PieceSize.large)
      return true;
    if (piece.size == PieceSize.medium && topPiece.size == PieceSize.small)
      return true;

    return false;
  }

  void _handlePieceDropped(
    GobbletPiece piece,
    int toRow,
    int toCol, {
    int? fromRow,
    int? fromCol,
  }) {
    if (!_isMyTurn) return;
    if (piece.owner != currentPlayer) return;
    if (!_canPlacePiece(piece, toRow, toCol)) return;

    setState(() {
      // Remove from source
      if (fromRow != null && fromCol != null) {
        board[fromRow][fromCol].removeLast();
      } else {
        // Remove from inventory
        if (currentPlayer == PlayerType.p1) {
          p1Inventory.removeWhere((p) => p.id == piece.id);
        } else {
          p2Inventory.removeWhere((p) => p.id == piece.id);
        }
      }

      // Add to destination
      board[toRow][toCol].add(piece);

      // Check win condition BEFORE passing turn.
      // Moving a piece could reveal an opponent's piece and make THEM win!
      _checkWinCondition();

      if (winnerMessage == null) {
        currentPlayer = currentPlayer == PlayerType.p1
            ? PlayerType.p2
            : PlayerType.p1;
      }
      _emitState();
    });
  }

  void _checkWinCondition() {
    PlayerType? visibleOwner(int r, int c) {
      if (board[r][c].isEmpty) return null;
      return board[r][c].last.owner;
    }

    bool checkLine(
      PlayerType? a,
      int r1,
      int c1,
      int r2,
      int c2,
      int r3,
      int c3,
    ) {
      if (a == null) return false;
      return a == visibleOwner(r1, c1) &&
          a == visibleOwner(r2, c2) &&
          a == visibleOwner(r3, c3);
    }

    List<PlayerType> winners = [];

    for (int i = 0; i < 3; i++) {
      // Rows
      PlayerType? rowOwner = visibleOwner(i, 0);
      if (checkLine(rowOwner, i, 0, i, 1, i, 2))
        if (!winners.contains(rowOwner!)) winners.add(rowOwner);
      // Cols
      PlayerType? colOwner = visibleOwner(0, i);
      if (checkLine(colOwner, 0, i, 1, i, 2, i))
        if (!winners.contains(colOwner!)) winners.add(colOwner);
    }
    // Diagonals
    PlayerType? d1Owner = visibleOwner(0, 0);
    if (checkLine(d1Owner, 0, 0, 1, 1, 2, 2))
      if (!winners.contains(d1Owner!)) winners.add(d1Owner);
    PlayerType? d2Owner = visibleOwner(0, 2);
    if (checkLine(d2Owner, 0, 2, 1, 1, 2, 0))
      if (!winners.contains(d2Owner!)) winners.add(d2Owner);

    if (winners.length == 1) {
      winnerMessage = winners.first == PlayerType.p1
          ? "فاز اللاعب الأحمر!"
          : "فاز اللاعب الأزرق!";
    } else if (winners.length == 2) {
      winnerMessage = "تعادل مفاجئ!";
    } else {
      // Check for normal draw (all pieces used, no winner)
      if (p1Inventory.isEmpty && p2Inventory.isEmpty) {
        bool allCellsFull = board.every(
          (row) => row.every((cell) => cell.isNotEmpty),
        );
        if (allCellsFull) {
          winnerMessage = "تعادل!";
        }
      }
    }
  }

  Widget _buildPieceWidget(
    GobbletPiece piece, {
    bool isDraggable = false,
    int? row,
    int? col,
  }) {
    Color c = piece.owner == PlayerType.p1
        ? Colors.redAccent
        : Colors.blueAccent;
    double s = 30.0;
    if (piece.size == PieceSize.medium) s = 50.0;
    if (piece.size == PieceSize.large) s = 70.0;

    Widget pWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
    );

    if (!isDraggable) return pWidget;

    bool canDrag =
        _isMyTurn && piece.owner == currentPlayer && winnerMessage == null;
    return canDrag
        ? Draggable<GobbletPiece>(
            data: piece,
            feedback: Material(color: Colors.transparent, child: pWidget),
            childWhenDragging: Opacity(opacity: 0.3, child: pWidget),
            child: pWidget,
          )
        : pWidget;
  }

  Widget _buildInventory(PlayerType type) {
    List<GobbletPiece> inv = type == PlayerType.p1 ? p1Inventory : p2Inventory;
    String title = type == PlayerType.p1 ? "أحمر (أنت)" : "أزرق (المنافس)";
    if (widget.online && !widget.isHost) {
      title = type == PlayerType.p1 ? "أحمر (المنافس)" : "أزرق (أنت)";
    } else if (!widget.online) {
      title = type == PlayerType.p1 ? "الأحمر" : "الأزرق";
    }

    Color c = type == PlayerType.p1
        ? Colors.red.withOpacity(0.1)
        : Colors.blue.withOpacity(0.1);
    Color bColor = type == PlayerType.p1 ? Colors.redAccent : Colors.blueAccent;

    bool isHighlight = currentPlayer == type && winnerMessage == null;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlight ? c : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? bColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: inv
                .map(
                  (p) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: _buildPieceWidget(p, isDraggable: true),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return BaseGameScaffold(
        title: 'الكبير ياكل الصغير',
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
        ? "دور الأحمر"
        : "دور الأزرق";
    if (winnerMessage != null) turnText = winnerMessage!;

    return BaseGameScaffold(
      title: 'الكبير ياكل الصغير',
      backgroundColor: Colors.brown[50]!,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            turnText,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: winnerMessage != null ? Colors.green : Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildInventory(PlayerType.p2), // Top inventory
          const SizedBox(height: 20),

          // Board
          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.width * 0.85,
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.brown[400],
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                int row = index ~/ 3;
                int col = index % 3;
                List<GobbletPiece> stack = board[row][col];

                return DragTarget<GobbletPiece>(
                  onWillAcceptWithDetails: (details) {
                    GobbletPiece piece = details.data;
                    // Prevent dropping on the same cell we dragged from
                    if (stack.isNotEmpty && stack.last.id == piece.id)
                      return false;
                    return _canPlacePiece(piece, row, col);
                  },
                  onAcceptWithDetails: (details) {
                    GobbletPiece piece = details.data;
                    int? fromR, fromC;
                    for (int r = 0; r < 3; r++) {
                      for (int c = 0; c < 3; c++) {
                        if (board[r][c].isNotEmpty &&
                            board[r][c].last.id == piece.id) {
                          fromR = r;
                          fromC = c;
                          break;
                        }
                      }
                    }
                    _handlePieceDropped(
                      piece,
                      row,
                      col,
                      fromRow: fromR,
                      fromCol: fromC,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    bool isHovering = candidateData.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? Colors.brown[600]
                            : Colors.brown[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: stack.isEmpty
                            ? const SizedBox()
                            : _buildPieceWidget(
                                stack.last,
                                isDraggable: true,
                                row: row,
                                col: col,
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          _buildInventory(PlayerType.p1), // Bottom inventory

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
