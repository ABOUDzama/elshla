import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';
import 'dart:async';

class OddOneOutOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? opponentName;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const OddOneOutOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.opponentName,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<OddOneOutOnline> createState() => _OddOneOutOnlineState();
}

class _OddOneOutOnlineState extends State<OddOneOutOnline> {
  bool answered = false;
  int lives = 3;
  int timeLeft = 10;
  List<String> _items = [];
  Timer? _timer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('odd_one_out_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        if (move['type'] == 'start_game' || move['type'] == 'next_question') {
          _started = true; answered = false; 
          _items = List<String>.from(move['shuffledItems']);
          // _oddOne assignment removed
          timeLeft = 10; _startTimer();
        } else if (move['type'] == 'pick_answer') {
          answered = true; _timer?.cancel();
        }
      });
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft <= 0) {
        t.cancel();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SocketService().socket.off('odd_one_out_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🔎 طلع الغريب (أونلاين)',
      backgroundColor: const Color(0xFFE65100),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _started ? _buildGame() : _buildWaiting(),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search, size: 80, color: Colors.white),
        if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ اللعبة'))
        else const Text('بانتظار المضيف...', style: TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildGame() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$timeLeft', style: TextStyle(fontSize: 40, color: Colors.white)),
        const SizedBox(height: 30),
        Wrap(spacing: 20, children: _items.map((i) => ElevatedButton(onPressed: () => _pick(i), child: Text(i))).toList()),
      ],
    );
  }

  void _start() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 'moveData': {'game': 'odd_one_out', 'type': 'start_game', 'shuffledItems': ['🍎', '🍌', '🥕'], 'currentIndex': 0, 'pointer': 0, 'timeLeft': 10}
    });
  }

  void _pick(String i) {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 'moveData': {'game': 'odd_one_out', 'type': 'pick_answer', 'answer': i}
    });
  }
}
