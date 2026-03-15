import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class BalanceGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const BalanceGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<BalanceGameOnline> createState() => _BalanceGameOnlineState();
}

class _BalanceGameOnlineState extends State<BalanceGameOnline> {
  bool isPlaying = false;
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('game_move', (data) {
      if (!mounted) return;
      if (data['type'] == 'start_game') {
        setState(() { isPlaying = true; results = []; });
      } else if (data['type'] == 'player_lost') {
        setState(() => results.add({'name': data['name'], 'score': data['score']}));
      }
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('game_move');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '⚖️ الميزان (أونلاين)',
      backgroundColor: Colors.teal,
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: isPlaying ? _buildGame() : _buildWaiting(),
      ),
    );
  }

  Widget _buildGame() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('العب الآن على موبايلك!', style: TextStyle(fontSize: 24, color: Colors.white)),
      const SizedBox(height: 20),
      ...results.map((r) => Text('${r['name']}: ${r['score']} ث', style: TextStyle(color: Colors.amber)))
    ]);
  }

  Widget _buildWaiting() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ اللعبة'))
      else const Text('بانتظار المضيف...', style: TextStyle(color: Colors.white))
    ]);
  }

  void _start() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'type': 'start_game'}});
  }
}
