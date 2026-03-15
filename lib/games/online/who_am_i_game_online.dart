import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class WhoAmIGameOnline extends StatefulWidget {
  final bool isHost;
  final String roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const WhoAmIGameOnline({
    super.key,
    required this.isHost,
    required this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<WhoAmIGameOnline> createState() => _WhoAmIGameOnlineState();
}

class _WhoAmIGameOnlineState extends State<WhoAmIGameOnline> {
  bool _gameStarted = false;
  int _hintsRevealed = 0;
  bool _answered = false;
  int _currentIndex = 0;
  int _currentPlayerTurn = 0;
  List<String> hints = [];

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('who_am_i_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        if (move['type'] == 'start_game') {
          _gameStarted = true; 
          _currentPlayerTurn = move['currentPlayerTurn'] ?? 0;
          _currentIndex = move['currentIndex'] ?? 0;
          if (move['shuffled'] != null && _currentIndex < move['shuffled'].length) {
            hints = List<String>.from(move['shuffled'][_currentIndex]['hints']);
          }
        } else if (move['type'] == 'next_card') {
          _currentPlayerTurn = move['currentPlayerTurn']; 
          _currentIndex = move['currentIndex'] ?? (_currentIndex + 1);
          _hintsRevealed = 0; 
          _answered = false;
          if (move['shuffled'] != null && _currentIndex < move['shuffled'].length) {
             hints = List<String>.from(move['shuffled'][_currentIndex]['hints']);
          } else if (data['shuffled'] != null && _currentIndex < data['shuffled'].length) {
             hints = List<String>.from(data['shuffled'][_currentIndex]['hints']);
          }
        } else if (move['type'] == 'reveal_hint') {
          _hintsRevealed++;
        } else if (move['type'] == 'show_answer') {
          _answered = true;
        }
      });
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('who_am_i_sync');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isMyTurn = (widget.roomPlayers != null && _currentPlayerTurn < widget.roomPlayers!.length)
        ? widget.roomPlayers![_currentPlayerTurn]['name'] == widget.playerName : false;

    return BaseGameScaffold(
      title: '👤 مين أنا؟ (أونلاين)',
      backgroundColor: const Color(0xFF6A1B9A),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: _gameStarted ? _buildGame(isMyTurn) : _buildWaiting(isMyTurn),
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
          isMyTurn ? 'دورك تحزر مين أنت! 🤔' : 'اللاعب $pName بيحاول يحزر',
          style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20), 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), 
          child: Column(children: [
            if (_answered) 
              Text('أنت كنت: (الاسم هنا)', style: const TextStyle(fontSize: 24, color: Colors.purple, fontWeight: FontWeight.bold)) 
            else 
              const Text('???', style: TextStyle(fontSize: 40, color: Colors.grey)),
            const Divider(),
            if (hints.isEmpty) 
              const Text('بانتظار التلميحات...')
            else 
              ...List.generate(_hintsRevealed, (i) => i < hints.length ? Text('• ${hints[i]}', style: const TextStyle(fontSize: 18)) : const SizedBox.shrink()),
          ]),
        ),
        const SizedBox(height: 30),
        if (widget.isHost) ...[
          if (!_answered) ...[
            ElevatedButton(onPressed: _reveal, child: const Text('تلميح 💡')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: _showAnswer, style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('كشف الإجابة ✅')),
          ] else 
            ElevatedButton(onPressed: _next, child: const Text('التالي ➡️')),
        ] else if (!isMyTurn) 
          const Text('المضيف يتحكم في التلميحات...', style: TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildWaiting(bool isMyTurn) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (widget.isHost) ElevatedButton(onPressed: _start, child: const Text('ابدأ اللعبة'))
      else const Text('بانتظار المضيف يبدأ...', style: TextStyle(color: Colors.white))
    ]);
  }

  void _start() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {
        'game': 'who_am_i', 
        'type': 'start_game', 
        'shuffled': [{'name': 'ميسي', 'hints': ['لاعب كرة قدم', 'أرجنتيني', 'رقم 10']}], 
        'currentIndex': 0, 
        'currentPlayerTurn': 0
      }
    });
  }

  void _reveal() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {'game': 'who_am_i', 'type': 'reveal_hint'}
    });
  }

  void _showAnswer() {
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {'game': 'who_am_i', 'type': 'show_answer'}
    });
  }

  void _next() {
    int nextTurn = (_currentPlayerTurn + 1) % (widget.roomPlayers?.length ?? 1);
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode, 
      'moveData': {
        'game': 'who_am_i', 
        'type': 'next_card', 
        'currentPlayerTurn': nextTurn,
        'currentIndex': _currentIndex + 1
      }
    });
  }
}
