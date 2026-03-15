import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../models/ludo_models.dart';
import '../../services/socket_service.dart';

class LudoGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const LudoGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<LudoGameOnline> createState() => _LudoGameOnlineState();
}

class _LudoGameOnlineState extends State<LudoGameOnline> {
  // Game State
  final List<LudoPawn> _pawns = [];
  int _currentPlayerIndex = 0; // 0: Red, 1: Green, 2: Yellow, 3: Blue
  int _diceValue = 1;
  bool _isRolling = false;
  bool _canRoll = false;
  String _gameMessage = 'في انتظار بدء اللعبة...';
  
  // My player info

  final List<String> _playerColors = ['red', 'green', 'yellow', 'blue'];
  final List<Color> _uiColors = [Colors.red, Colors.green, Colors.yellow[700]!, Colors.blue];
  final List<String> _playerNames = ['الأحمر', 'الأخضر', 'الأصفر', 'الأزرق'];

  void _updatePlayerNames() {
    if (widget.roomPlayers != null && widget.roomPlayers!.isNotEmpty) {
      for (int i = 0; i < widget.roomPlayers!.length && i < 4; i++) {
        _playerNames[i] = widget.roomPlayers![i]['name'] ?? _playerNames[i];
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _updatePlayerNames();
    _initializePawns();
    _setupSocketListeners();
    
    // If host, start the game logic
    if (widget.isHost) {
      _startGame();
    }
  }

  void _initializePawns() {
    _pawns.clear();
    for (int p = 0; p < 4; p++) {
      for (int i = 0; i < 4; i++) {
        _pawns.add(LudoPawn(id: i, colorStr: _playerColors[p], position: -1));
      }
    }
  }

  void _setupSocketListeners() {
    final socket = SocketService().socket;

    socket.on('game_started', (data) {
      if (mounted) {
        setState(() {
          // Find my index (usually assigned by server or determined by join order)
          // For simplicity, let's assume host is Red (0) and others follow
          // In a real app, you'd get this from the room data
          _gameMessage = 'بدأت اللعبة! دور اللاعب الأحمر';
          _canRoll = (widget.isHost && _currentPlayerIndex == 0);
        });
      }
    });

    socket.on('dice_rolled', (data) {
      if (mounted) {
        setState(() {
          _isRolling = true;
        });
        Future.delayed(800.milliseconds, () {
          if (mounted) {
            setState(() {
              _diceValue = data['value'];
              _isRolling = false;
              _gameMessage = 'اللاعب $_playerNames[_currentPlayerIndex] حصل على $_diceValue';
            });
          }
        });
      }
    });

    socket.on('pawn_moved', (data) {
      if (mounted) {
        int pawnIdx = data['pawnIndex'];
        int newPos = data['newPosition'];
        setState(() {
          _pawns[pawnIdx].position = newPos;
          if (newPos == 56) _pawns[pawnIdx].isFinished = true;
          _checkColissions(_pawns[pawnIdx]);
          _diceValue = data['diceValue']; // Needed for '6' logic
          
          if (_diceValue != 6) {
             _currentPlayerIndex = (_currentPlayerIndex + 1) % 4;
          }
          
          _canRoll = (widget.isHost && _currentPlayerIndex == 0) || (!widget.isHost && _currentPlayerIndex != 0); // Simplified
          // Actually, we need exact player assignment. For now, let's simulate.
          _gameMessage = 'دور اللاعب ${_playerNames[_currentPlayerIndex]}';
        });
      }
    });
  }

  void _startGame() {
     SocketService().socket.emit('start_game_logic', {'roomCode': widget.roomCode});
  }

  void _rollDice() {
    if (!_canRoll || _isRolling) return;
    
    int val = Random().nextInt(6) + 1;
    SocketService().socket.emit('roll_dice', {
      'roomCode': widget.roomCode,
      'value': val,
    });
    
    setState(() {
      _canRoll = false; // Wait for move
    });
  }

  void _movePawn(LudoPawn pawn) {
    if (!_canMovePawn(pawn)) return;
    // Only my turn
    // if (_currentPlayerIndex != _myPlayerIndex) return; 

    int pawnIdx = _pawns.indexOf(pawn);
    int newPos = pawn.position == -1 ? 0 : pawn.position + _diceValue;

    SocketService().socket.emit('move_pawn', {
      'roomCode': widget.roomCode,
      'pawnIndex': pawnIdx,
      'newPosition': newPos,
      'diceValue': _diceValue,
    });
  }

  // Reuse logic from offline
  bool _canMovePawn(LudoPawn pawn) {
    if (pawn.isFinished) return false;
    if (pawn.colorStr != _playerColors[_currentPlayerIndex]) return false;
    if (pawn.position == -1) return _diceValue == 6;
    return (pawn.position + _diceValue) <= 56;
  }

  void _checkColissions(LudoPawn movedPawn) {
    if (movedPawn.position > 50 || movedPawn.position < 0) return;
    final movedCoords = _getCoords(movedPawn);
    bool isSafe = LudoPath.safeSpots.any((s) => s[0] == movedCoords[0] && s[1] == movedCoords[1]);
    if (isSafe) return;

    for (var otherPawn in _pawns) {
      if (otherPawn.colorStr == movedPawn.colorStr) continue;
      if (otherPawn.position == -1 || otherPawn.position > 50) continue;
      final otherCoords = _getCoords(otherPawn);
      if (movedCoords[0] == otherCoords[0] && movedCoords[1] == otherCoords[1]) {
        setState(() {
          otherPawn.position = -1;
        });
      }
    }
  }

  List<int> _getCoords(LudoPawn pawn) {
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

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🎲 لودو أونلاين',
      backgroundColor: Colors.transparent,
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                _buildInfoBar(),
                _buildBoardArea(),
                _buildDiceArea(),
              ],
            ),
            if (_gameMessage.contains('فاز')) _buildWinnerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
          BoxShadow(color: _uiColors[_currentPlayerIndex].withValues(alpha: 0.2), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              boxShadow: [BoxShadow(color: _uiColors[_currentPlayerIndex].withValues(alpha: 0.5), blurRadius: 10)],
            ),
            child: CircleAvatar(
              backgroundColor: _uiColors[_currentPlayerIndex], 
              radius: 12,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white.withValues(alpha: 0.6), Colors.transparent],
                    center: const Alignment(-0.3, -0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Text(
            _gameMessage,
            style: GoogleFonts.cairo(
              color: Colors.white, 
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              shadows: [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardArea() {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(builder: (context, constraints) {
              double cellSize = constraints.maxWidth / 15;
              return Stack(
                children: [
                  _LudoGrid(cellSize: cellSize),
                  _LudoBases(cellSize: cellSize, playerColors: _playerColors),
                  _LudoHomeStripes(cellSize: cellSize),
                  _LudoPawnsLayer(
                    cellSize: cellSize, 
                    pawns: _pawns, 
                    currentPlayerIndex: _currentPlayerIndex,
                    canRoll: _canRoll,
                    playerColors: _playerColors,
                    onPawnTap: _movePawn,
                    canMovePawn: _canMovePawn,
                    getCoords: _getCoords,
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDiceArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LudoDiceWidget(
            diceValue: _diceValue, 
            isRolling: _isRolling, 
            activeColor: _uiColors[_currentPlayerIndex],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _uiColors[_currentPlayerIndex].withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: ElevatedButton(
              onPressed: _canRoll ? _rollDice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _uiColors[_currentPlayerIndex],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 10,
              ),
              child: Text('ارمِ النرد', style: GoogleFonts.cairo(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber)
                .animate(onPlay: (c) => c.repeat())
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds)
                .shimmer(),
            const SizedBox(height: 20),
            Text(
              'الفائز هو!',
              style: GoogleFonts.cairo(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              _playerNames[_currentPlayerIndex],
              style: GoogleFonts.cairo(
                fontSize: 48, 
                color: _uiColors[_currentPlayerIndex], 
                fontWeight: FontWeight.w900,
                shadows: [const Shadow(color: Colors.white, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('خروج', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

}

class _LudoGrid extends StatelessWidget {
  final double cellSize;
  const _LudoGrid({required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
      itemCount: 225,
      itemBuilder: (context, index) {
        int x = index % 15;
        int y = index ~/ 15;
        
        Color cellColor = Colors.white.withValues(alpha: 0.1);
        bool isPath = (x >= 6 && x <= 8) || (y >= 6 && y <= 8);

        if (!isPath) return Container();

        BoxDecoration decoration = BoxDecoration(
          color: cellColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        );

        if (x == 7 && y > 0 && y < 6) {
          decoration = decoration.copyWith(gradient: LinearGradient(colors: [Colors.green.shade400.withValues(alpha: 0.6), Colors.green.shade900.withValues(alpha: 0.4)]));
        }
        if (x == 7 && y > 8 && y < 14) {
          decoration = decoration.copyWith(gradient: LinearGradient(colors: [Colors.blue.shade400.withValues(alpha: 0.6), Colors.blue.shade900.withValues(alpha: 0.4)]));
        }
        if (y == 7 && x > 0 && x < 6) {
          decoration = decoration.copyWith(gradient: LinearGradient(colors: [Colors.red.shade400.withValues(alpha: 0.6), Colors.red.shade900.withValues(alpha: 0.4)]));
        }
        if (y == 7 && x > 8 && x < 14) {
          decoration = decoration.copyWith(gradient: LinearGradient(colors: [Colors.yellow.shade400.withValues(alpha: 0.6), Colors.yellow.shade900.withValues(alpha: 0.4)]));
        }
        
        if (x == 1 && y == 6) decoration = decoration.copyWith(color: Colors.red.shade600, boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 8 && y == 1) decoration = decoration.copyWith(color: Colors.green.shade600, boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 13 && y == 8) decoration = decoration.copyWith(color: Colors.yellow.shade800, boxShadow: [BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 6 && y == 13) decoration = decoration.copyWith(color: Colors.blue.shade600, boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 10)]);

        if (x >= 6 && x <= 8 && y >= 6 && y <= 8) return Container();

        return Container(
          decoration: decoration,
          child: (x == 1 && y == 6 || x == 8 && y == 1 || x == 13 && y == 8 || x == 6 && y == 13)
              ? Center(child: Icon(Icons.stars, size: cellSize * 0.7, color: Colors.white.withValues(alpha: 0.8)))
              : null,
        );
      },
    );
  }
}

class _LudoBases extends StatelessWidget {
  final double cellSize;
  final List<String> playerColors;
  const _LudoBases({required this.cellSize, required this.playerColors});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBase(0, 0, Colors.red.shade600),
        _buildBase(9, 0, Colors.green.shade600),
        _buildBase(9, 9, Colors.yellow.shade700),
        _buildBase(0, 9, Colors.blue.shade600),
      ],
    );
  }

  Widget _buildBase(int x, int y, Color color) {
    return Positioned(
      left: x * cellSize,
      top: y * cellSize,
      child: Container(
        width: cellSize * 6,
        height: cellSize * 6,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(4, 4))],
        ),
        child: Center(
          child: Container(
            width: cellSize * 4.8,
            height: cellSize * 4.8,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(cellSize * 0.4),
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)]),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
              )),
            ),
          ),
        ),
      ),
    );
  }
}

class _LudoHomeStripes extends StatelessWidget {
  final double cellSize;
  const _LudoHomeStripes({required this.cellSize});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 6 * cellSize,
      top: 6 * cellSize,
      child: Container(
        width: cellSize * 3,
        height: cellSize * 3,
        decoration: const BoxDecoration(color: Colors.white),
        child: CustomPaint(size: Size(cellSize * 3, cellSize * 3), painter: HomeCenterPainter()),
      ),
    );
  }
}

class _LudoPawnsLayer extends StatelessWidget {
  final double cellSize;
  final List<LudoPawn> pawns;
  final int currentPlayerIndex;
  final bool canRoll;
  final List<String> playerColors;
  final Function(LudoPawn) onPawnTap;
  final bool Function(LudoPawn) canMovePawn;
  final List<int> Function(LudoPawn) getCoords;

  const _LudoPawnsLayer({
    required this.cellSize, 
    required this.pawns, 
    required this.currentPlayerIndex, 
    required this.canRoll,
    required this.playerColors,
    required this.onPawnTap,
    required this.canMovePawn,
    required this.getCoords,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> pawnWidgets = [];
    Map<String, List<LudoPawn>> stackMap = {};
    for (var pawn in pawns) {
      if (pawn.isFinished) continue;
      String key = pawn.position == -1 ? 'base_${pawn.colorStr}_${pawn.id}' : '${getCoords(pawn)[0]}_${getCoords(pawn)[1]}';
      stackMap.putIfAbsent(key, () => []).add(pawn);
    }
    stackMap.forEach((key, stack) {
      for (int i = 0; i < stack.length; i++) {
        var pawn = stack[i];
        List<int> coords;
        if (pawn.position == -1) {
          int bx = 0, by = 0;
          if (pawn.colorStr == 'red') { bx = 1; by = 1; }
          if (pawn.colorStr == 'green') { bx = 10; by = 1; }
          if (pawn.colorStr == 'yellow') { bx = 10; by = 10; }
          if (pawn.colorStr == 'blue') { bx = 1; by = 10; }
          coords = [(bx + (pawn.id % 2) * 2.2).toInt(), (by + (pawn.id ~/ 2) * 2.2).toInt()];
        } else {
          coords = getCoords(pawn);
        }
        pawnWidgets.add(AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          left: coords[0] * cellSize + (i * 2),
          top: coords[1] * cellSize + (i * 2),
          child: GestureDetector(
            onTap: () => onPawnTap(pawn),
            child: _LudoPawnWidget(
              pawn: pawn, 
              cellSize: cellSize, 
              activeColor: playerColors[currentPlayerIndex],
              canRoll: canRoll,
              canMove: canMovePawn(pawn),
            ),
          ),
        ));
      }
    });
    return Stack(children: pawnWidgets);
  }
}

class _LudoPawnWidget extends StatelessWidget {
  final LudoPawn pawn;
  final double cellSize;
  final String activeColor;
  final bool canRoll;
  final bool canMove;

  const _LudoPawnWidget({
    required this.pawn, 
    required this.cellSize, 
    required this.activeColor, 
    required this.canRoll,
    required this.canMove,
  });

  @override
  Widget build(BuildContext context) {
    Color pColor = Colors.red;
    if (pawn.colorStr == 'green') pColor = Colors.green;
    if (pawn.colorStr == 'yellow') pColor = Colors.yellow[700]!;
    if (pawn.colorStr == 'blue') pColor = Colors.blue;

    bool isActive = pawn.colorStr == activeColor && !canRoll && canMove;

    return Container(
      width: cellSize * 1.1,
      height: cellSize * 1.1,
      decoration: BoxDecoration(
        gradient: RadialGradient(colors: [isActive ? Colors.white : pColor.withValues(alpha: 0.9), pColor.withValues(alpha: 0.6)], center: const Alignment(-0.3, -0.3)),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(3, 5))],
        border: Border.all(color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6), width: 2),
      ),
      child: isActive ? Center(child: const Icon(Icons.bolt, size: 14, color: Colors.white).animate(onPlay: (c) => c.repeat()).scale().shimmer()) : null,
    );
  }
}

class _LudoDiceWidget extends StatelessWidget {
  final int diceValue;
  final bool isRolling;
  final Color activeColor;

  const _LudoDiceWidget({required this.diceValue, required this.isRolling, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, Colors.grey.shade200]),
      ),
      child: Center(
        child: isRolling 
          ? CircularProgressIndicator(color: activeColor, strokeWidth: 3)
          : _buildDiceFace(diceValue, activeColor),
      ),
    ).animate(target: isRolling ? 1 : 0).shake();
  }

  Widget _buildDiceFace(int val, Color color) {
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.all(12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(9, (i) {
        bool show = false;
        if (val == 1) show = i == 4;
        if (val == 2) show = i == 0 || i == 8;
        if (val == 3) show = i == 0 || i == 4 || i == 8;
        if (val == 4) show = i == 0 || i == 2 || i == 6 || i == 8;
        if (val == 5) show = i == 0 || i == 2 || i == 4 || i == 6 || i == 8;
        if (val == 6) show = i == 0 || i == 2 || i == 3 || i == 5 || i == 6 || i == 8;
        return Center(child: Container(width: 8, height: 8, decoration: BoxDecoration(color: show ? color : Colors.transparent, shape: BoxShape.circle)));
      }),
    );
  }
}

class HomeCenterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    _draw(canvas, size, 0, 0, size.width/2, size.height/2, 0, size.height, Colors.red, paint);
    _draw(canvas, size, 0, 0, size.width, 0, size.width/2, size.height/2, Colors.green, paint);
    _draw(canvas, size, size.width, 0, size.width, size.height, size.width/2, size.height/2, Colors.yellow[700]!, paint);
    _draw(canvas, size, 0, size.height, size.width/2, size.height/2, size.width, size.height, Colors.blue, paint);
  }
  void _draw(Canvas c, Size s, double x1, double y1, double x2, double y2, double x3, double y3, Color col, Paint p) {
    p.color = col;
    c.drawPath(Path()..moveTo(x1,y1)..lineTo(x2,y2)..lineTo(x3,y3)..close(), p);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
