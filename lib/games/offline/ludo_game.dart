import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/offline_game_scaffold.dart';
import '../../models/ludo_models.dart';
import '../../controllers/ludo_controller.dart';
import '../../services/settings_service.dart';

class LudoGame extends StatefulWidget {
  const LudoGame({super.key});

  @override
  State<LudoGame> createState() => _LudoGameState();
}

class _LudoGameState extends State<LudoGame> {
  late LudoController _controller;
  bool _isSetup = true;
  List<String> _playerNames = [];
  final Map<String, String> _playerAvatars = {};

  @override
  void initState() {
    super.initState();
    _controller = LudoController();
    _controller.addListener(_onControllerUpdate);
    _loadAvatars();
  }

  void _loadAvatars() {
    final profiles = SettingsService.getSavedPlayersProfiles();
    for (var p in profiles) {
      _playerAvatars[p['name']!] = p['avatar']!;
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSetup) {
      return _buildSetupScreen();
    }

    return OfflineGameScaffold(
      title: '🎲 لودو بلس',
      backgroundColor: Colors.transparent,
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
            if (_controller.winnerIndex != null) _buildWinnerOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'لودو بلس',
              style: GoogleFonts.cairo(
                fontSize: 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 50),
            Text(
              'اختار عدد اللاعبين 👥',
              style: GoogleFonts.cairo(fontSize: 22, color: Colors.white70),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [2, 3, 4].map((count) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: () {
                      final names = List.generate(count, (i) => 'لاعب ${i + 1}');
                      setState(() {
                        _playerNames = names;
                        _isSetup = false;
                      });
                      _controller.initializeGame(count, names: names);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
              _controller.customNames[_controller.winnerIndex!],
              style: GoogleFonts.cairo(
                fontSize: 48, 
                color: _controller.uiColors[_controller.winnerIndex!], 
                fontWeight: FontWeight.w900,
                shadows: [const Shadow(color: Colors.white, blurRadius: 20)],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _controller.initializeGame(_controller.numPlayers);
                setState(() => _controller.winnerIndex = null);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('العب مرة تانية', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(0),
              _buildPlayerInfo(1),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              _controller.gameMessage,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerInfo(3),
              _buildPlayerInfo(2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(int index) {
    if (index >= _controller.numPlayers) return const SizedBox(width: 100);
    
    final isTurn = _controller.currentPlayerIndex == index;
    final color = _controller.uiColors[index];
    final name = _playerNames.length > index ? _playerNames[index] : _controller.customNames[index];
    final avatar = _playerAvatars[name];

    return AnimatedContainer(
      duration: 300.ms,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isTurn ? color.withValues(alpha: 0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isTurn ? color : Colors.white.withValues(alpha: 0.05), width: 2),
        boxShadow: isTurn ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)] : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: avatar != null && avatar.isNotEmpty
                ? ClipOval(child: Image.memory(base64Decode(avatar), fit: BoxFit.cover))
                : CircleAvatar(
                    backgroundColor: color,
                    child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
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
                  _LudoBases(cellSize: cellSize, controller: _controller),
                  _LudoHomeStripes(cellSize: cellSize),
                  _LudoPawnsLayer(cellSize: cellSize, controller: _controller),
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
          _LudoDiceWidget(controller: _controller),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _controller.uiColors[_controller.currentPlayerIndex].withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2),
              ],
            ),
            child: ElevatedButton(
              onPressed: _controller.canRoll ? _controller.rollDice : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _controller.uiColors[_controller.currentPlayerIndex],
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

        // 3D Path effect
        BoxDecoration decoration = BoxDecoration(
          color: cellColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        );

        // Highlight home paths with premium gradients
        if (x == 7 && y > 0 && y < 6) {
          decoration = decoration.copyWith(
            gradient: LinearGradient(colors: [Colors.green.shade400.withValues(alpha: 0.6), Colors.green.shade900.withValues(alpha: 0.4)]),
          );
        }
        if (x == 7 && y > 8 && y < 14) {
          decoration = decoration.copyWith(
            gradient: LinearGradient(colors: [Colors.blue.shade400.withValues(alpha: 0.6), Colors.blue.shade900.withValues(alpha: 0.4)]),
          );
        }
        if (y == 7 && x > 0 && x < 6) {
          decoration = decoration.copyWith(
            gradient: LinearGradient(colors: [Colors.red.shade400.withValues(alpha: 0.6), Colors.red.shade900.withValues(alpha: 0.4)]),
          );
        }
        if (y == 7 && x > 8 && x < 14) {
          decoration = decoration.copyWith(
            gradient: LinearGradient(colors: [Colors.yellow.shade400.withValues(alpha: 0.6), Colors.yellow.shade900.withValues(alpha: 0.4)]),
          );
        }
        
        // Start spots with glowing star effect
        if (x == 1 && y == 6) decoration = decoration.copyWith(color: Colors.red.shade600, boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 8 && y == 1) decoration = decoration.copyWith(color: Colors.green.shade600, boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 13 && y == 8) decoration = decoration.copyWith(color: Colors.yellow.shade800, boxShadow: [BoxShadow(color: Colors.yellow.withValues(alpha: 0.5), blurRadius: 10)]);
        if (x == 6 && y == 13) decoration = decoration.copyWith(color: Colors.blue.shade600, boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.5), blurRadius: 10)]);

        // Intersection check
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
  final LudoController controller;
  const _LudoBases({required this.cellSize, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBase(0, 0, Colors.red.shade600, Colors.red.shade100),
        _buildBase(9, 0, Colors.green.shade600, Colors.green.shade100),
        _buildBase(9, 9, Colors.yellow.shade700, Colors.yellow.shade100),
        _buildBase(0, 9, Colors.blue.shade600, Colors.blue.shade100),
      ],
    );
  }

  Widget _buildBase(int x, int y, Color color, Color bgColor) {
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
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5)],
            ),
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(cellSize * 0.4),
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.5)],
                    center: const Alignment(-0.2, -0.2),
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))],
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
        child: CustomPaint(
          size: Size(cellSize * 3, cellSize * 3),
          painter: HomeCenterPainter(),
        ),
      ),
    );
  }
}

class _LudoPawnsLayer extends StatelessWidget {
  final double cellSize;
  final LudoController controller;
  const _LudoPawnsLayer({required this.cellSize, required this.controller});

  @override
  Widget build(BuildContext context) {
    List<Widget> pawnWidgets = [];
    Map<String, List<LudoPawn>> stackMap = {};
    
    for (var pawn in controller.pawns) {
      if (pawn.isFinished) continue;
      String key = pawn.position == -1 
          ? 'base_${pawn.colorStr}_${pawn.id}' 
          : '${controller.getCoords(pawn)[0]}_${controller.getCoords(pawn)[1]}';
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
          
          double offsetX = (pawn.id % 2) * 2.2;
          double offsetY = (pawn.id ~/ 2) * 2.2;
          coords = [(bx + offsetX).toInt(), (by + offsetY).toInt()];
        } else {
          coords = controller.getCoords(pawn);
        }

        pawnWidgets.add(
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: coords[0] * cellSize + (i * 2),
            top: coords[1] * cellSize + (i * 2),
            child: GestureDetector(
              onTap: () => controller.movePawn(pawn),
              child: _LudoPawnWidget(pawn: pawn, cellSize: cellSize, controller: controller),
            ),
          ),
        );
      }
    });

    return Stack(children: pawnWidgets);
  }
}

class _LudoPawnWidget extends StatelessWidget {
  final LudoPawn pawn;
  final double cellSize;
  final LudoController controller;

  const _LudoPawnWidget({
    required this.pawn,
    required this.cellSize,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Color pColor = Colors.red;
    if (pawn.colorStr == 'green') pColor = Colors.green;
    if (pawn.colorStr == 'yellow') pColor = Colors.yellow[700]!;
    if (pawn.colorStr == 'blue') pColor = Colors.blue;

    bool isActive = pawn.colorStr == controller.playerColors[controller.currentPlayerIndex] && 
                   !controller.canRoll && 
                   controller.canMovePawn(pawn);

    Color darkerColor = Color.alphaBlend(Colors.black.withValues(alpha: 0.4), pColor);

    return Container(
      width: cellSize * 1.1,
      height: cellSize * 1.1,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [isActive ? Colors.white : pColor.withValues(alpha: 0.9), darkerColor],
          center: const Alignment(-0.3, -0.3),
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(3, 5)),
          if (isActive) BoxShadow(color: pColor.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: 2),
        ],
        border: Border.all(color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6), width: 2),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: cellSize * 0.4,
              height: cellSize * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent]),
              ),
            ),
          ),
          if (isActive) 
            Center(
              child: const Icon(Icons.bolt, size: 14, color: Colors.white)
                  .animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.3, 1.3))
                  .shimmer(duration: 1.seconds),
            )
        ],
      ),
    );
  }
}

class _LudoDiceWidget extends StatelessWidget {
  final LudoController controller;
  const _LudoDiceWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(2, 4)),
          BoxShadow(color: controller.uiColors[controller.currentPlayerIndex].withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 2),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade200],
        ),
      ),
      child: Center(
        child: controller.isRolling 
          ? CircularProgressIndicator(color: controller.uiColors[controller.currentPlayerIndex], strokeWidth: 3)
          : _buildDiceFace(controller.diceValue, controller.uiColors[controller.currentPlayerIndex]),
      ),
    ).animate(target: controller.isRolling ? 1 : 0).shake(hz: 8, curve: Curves.easeInOut);
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
        
        return Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: show ? color : Colors.transparent, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}

class HomeCenterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..style = PaintingStyle.fill;
    
    // Red triangle (Left)
    Path redPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    paint.color = Colors.red;
    canvas.drawPath(redPath, paint);

    // Green triangle (Top)
    Path greenPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height / 2)
      ..close();
    paint.color = Colors.green;
    canvas.drawPath(greenPath, paint);

    // Yellow triangle (Right)
    Path yellowPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height / 2)
      ..close();
    paint.color = Colors.yellow[700]!;
    canvas.drawPath(yellowPath, paint);

    // Blue triangle (Bottom)
    Path bluePath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();
    paint.color = Colors.blue;
    canvas.drawPath(bluePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


