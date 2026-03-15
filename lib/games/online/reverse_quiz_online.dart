import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class ReverseQuizOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const ReverseQuizOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<ReverseQuizOnline> createState() => _ReverseQuizOnlineState();
}

class _ReverseQuizOnlineState extends State<ReverseQuizOnline> {
  String display = 'في انتظار المضيف...';

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('quiz_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        if (move['type'] == 'start_game' || move['type'] == 'generate_new') {
          display = move['questions'][move['pointer']]['answer'];
        } else if (move['type'] == 'flip_card') {
          // _isFlipped removed
        }
      });
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('quiz_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🔄 الأسئلة المعكوسة (أونلاين)',
      backgroundColor: const Color(0xFF00838F),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(display, textAlign: TextAlign.center, style: TextStyle(fontSize: 30, color: Colors.white)),
          if (widget.isHost) ElevatedButton(onPressed: _next, child: const Text('التالي'))
        ]),
      ),
    );
  }

  void _next() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'type': 'generate_new', 'pointer': 0, 'game': 'reverse_quiz'}});
  }
}
