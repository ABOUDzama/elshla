import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class MultiTouchScreenOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const MultiTouchScreenOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<MultiTouchScreenOnline> createState() => _MultiTouchScreenOnlineState();
}

class _MultiTouchScreenOnlineState extends State<MultiTouchScreenOnline> {
  Map<int, Offset> touches = {};
  bool isSelecting = false;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      final type = data['type'];
      setState(() {
        if (type == 'touch_update') {
          touches[data['id'].hashCode] = Offset(data['dx'].toDouble(), data['dy'].toDouble());
        } else if (type == 'touch_remove') {
          touches.remove(data['id'].hashCode);
        } else if (type == 'start_selection') {
          isSelecting = true; _countdown = data['countdown'];
        } else if (type == 'countdown_tick') {
          _countdown = data['countdown'];
        }
      });
    });
  }

  @override
  void dispose() { SocketService().socket.off('game_move'); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '👆 اختيار عشوائي (أونلاين)',
      backgroundColor: const Color(0xFF1B5E20),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('الكل يحط صباعه!', style: TextStyle(color: Colors.white, fontSize: 24)),
          if (isSelecting) Text('$_countdown', style: TextStyle(fontSize: 80, color: Colors.white)),
          Text('الموجودين: ${touches.length}', style: TextStyle(color: Colors.white70)),
        ]),
      ),
    );
  }
}
