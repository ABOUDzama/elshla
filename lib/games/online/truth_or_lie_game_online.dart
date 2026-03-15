import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class TruthOrLieGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const TruthOrLieGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<TruthOrLieGameOnline> createState() => _TruthOrLieGameOnlineState();
}

class _TruthOrLieGameOnlineState extends State<TruthOrLieGameOnline> {
  bool _showExplanation = false;
  String _displayedText = "في انتظار المضيف...";
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('truth_or_lie_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        if (move['type'] == 'start_game' || move['type'] == 'next_question') {
          _started = true; _showExplanation = false;
          _displayedText = move['currentData'][move['shuffledIndices'][move['currentIndex']]]['statement'];
        } else if (move['type'] == 'handle_answer') {
          _showExplanation = true;
          // Result normally calculated on client or received
        }
      });
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('truth_or_lie_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🤔 حقيقة أو هبد؟ (أونلاين)',
      backgroundColor: const Color(0xFF0F172A),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _started ? _buildGame() : _buildWaiting(),
      ),
    );
  }

  Widget _buildGame() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_displayedText, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Colors.white)),
        const SizedBox(height: 40),
        if (!_showExplanation) ...[
          if (widget.isHost) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            ElevatedButton(onPressed: () => _answer(true), child: const Text('حقيقة')),
            const SizedBox(width: 20),
            ElevatedButton(onPressed: () => _answer(false), child: const Text('هبد')),
          ]) else const Text('بانتظار إجابة المضيف...', style: TextStyle(color: Colors.white70))
        ] else if (widget.isHost) ElevatedButton(onPressed: _next, child: const Text('التالي'))
      ],
    );
  }

  Widget _buildWaiting() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ اللعبة'))
      else const Text('بانتظار المضيف...', style: TextStyle(color: Colors.white))
    ]);
  }

  void _start() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 'moveData': {'game': 'truth_or_lie', 'type': 'start_game', 'shuffledIndices': [0], 'currentIndex': 0, 'currentData': [{'statement': 'معلومة تجريبية'}]}
    });
  }

  void _answer(bool t) {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'game': 'truth_or_lie', 'type': 'handle_answer', 'userSaidTruth': t}});
  }

  void _next() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'game': 'truth_or_lie', 'type': 'next_question', 'currentIndex': 0}});
  }
}
