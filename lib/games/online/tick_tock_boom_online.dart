import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class TickTockBoomOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const TickTockBoomOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<TickTockBoomOnline> createState() => _TickTockBoomOnlineState();
}

class _TickTockBoomOnlineState extends State<TickTockBoomOnline> {
  bool isPlaying = false;
  bool hasExploded = false;
  String currentLetter = '';
  String currentCategory = '';
  int _currentPlayerTurn = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('tick_tock_boom_sync', (data) {
      if (!mounted) return;
      final action = data['action'];
      setState(() {
        if (action == 'start_round') {
          currentCategory = data['currentCategory']; 
          currentLetter = data['currentLetter'];
          _currentPlayerTurn = data['currentPlayerTurn'] ?? 0;
          isPlaying = true; 
          hasExploded = false;
        } else if (action == 'explode') {
          isPlaying = false; 
          hasExploded = true;
          _currentPlayerTurn = data['currentPlayerTurn'] ?? _currentPlayerTurn;
        } else if (action == 'next_player') {
          _currentPlayerTurn = data['currentPlayerTurn'];
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    SocketService().socket.off('tick_tock_boom_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '💣 قنبلة الحروف (أونلاين)',
      backgroundColor: hasExploded ? Colors.black : const Color(0xFFC62828),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: isPlaying ? _buildGame(isMyTurn) : _buildWaiting(isMyTurn),
      ),
    );
  }

  Widget _buildGame(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] : 'اللاعب';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isMyTurn ? 'دورك تمسك القنبلة! 💣' : 'القنبلة مع: $pName 🏃‍♂️',
          style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        Text(currentCategory, style: const TextStyle(fontSize: 24, color: Colors.white70)),
        Text(currentLetter, style: const TextStyle(fontSize: 100, color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),
        const Icon(Icons.timer, size: 80, color: Colors.white),
        if (isMyTurn) ...[
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _passBomb(), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('مرر القنبلة! ➡️'),
          ),
        ]
      ],
    );
  }

  Widget _buildWaiting(bool isMyTurn) {
    String pName = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] : 'اللاعب';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasExploded) ...[
          Text('بوم! 💥', style: const TextStyle(fontSize: 40, color: Colors.red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('خسر: $pName', style: const TextStyle(fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 30),
        ],
        if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ الجولة'))
        else const Text('بانتظار المضيف...', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  void _start() {
    SocketService().socket.emit('tick_tock_boom_sync', {
      'roomCode': widget.roomCode, 
      'action': 'start_round', 
      'currentCategory': 'منوعات', 
      'currentLetter': 'أ', 
      'explosionTime': 15,
      'currentPlayerTurn': _currentPlayerTurn
    });
  }

  void _passBomb() {
    int nextIdx = (_currentPlayerTurn + 1) % (widget.roomPlayers?.length ?? 1);
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'action': 'pass_bomb',
      'nextPlayerIndex': nextIdx,
      'gameName': 'tick_tock_boom'
    });
  }
}
