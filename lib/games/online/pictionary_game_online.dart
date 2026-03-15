import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class PictionaryGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const PictionaryGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<PictionaryGameOnline> createState() => _PictionaryGameOnlineState();
}

class _PictionaryGameOnlineState extends State<PictionaryGameOnline> {
  List<Offset?> points = [];

  @override
  void initState() {
    super.initState();
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      if (data['type'] == 'draw_point') {
        setState(() {
          final dx = data['dx'];
          final dy = data['dy'];
          points.add(dx == null ? null : Offset(dx.toDouble() * 300, dy.toDouble() * 300)); // Sample scaling
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🎨 ارسم وخمّن (أونلاين)',
      backgroundColor: const Color(0xFF303F9F),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: Container(
          width: 300, height: 300, color: Colors.white,
          child: CustomPaint(painter: RemotePainter(points)),
        ),
      ),
    );
  }
}

class RemotePainter extends CustomPainter {
  final List<Offset?> points;
  RemotePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = Colors.black..strokeWidth = 4;
    for (int i = 0; i < points.length - 1; i++) {
       if (points[i] != null && points[i+1] != null) canvas.drawLine(points[i]!, points[i+1]!, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
