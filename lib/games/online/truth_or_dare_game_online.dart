import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class TruthOrDareGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? opponentName;
  final List<dynamic>? roomPlayers;
  final String? playerName;

  const TruthOrDareGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.opponentName,
    this.roomPlayers,
    this.playerName,
  });

  @override
  State<TruthOrDareGameOnline> createState() => _TruthOrDareGameOnlineState();
}

class _TruthOrDareGameOnlineState extends State<TruthOrDareGameOnline> {
  bool _started = false;
  bool _typeChosen = false;
  String? _currentCard;
  List<String> _players = [];
  int _currentPlayer = 0;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('truth_or_dare_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        switch (move['type']) {
          case 'start_game':
            _started = true;
            _players = List<String>.from(move['players']);
            _currentPlayer = move['currentPlayer'];
            break;
          case 'pick':
            _typeChosen = true;
            _currentCard = move['currentCard'];
            break;
          case 'next':
            _typeChosen = false;
            _currentPlayer = move['currentPlayer'];
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('truth_or_dare_sync');
    super.dispose();
  }

  void _emit(String type, Map<String, dynamic> data) {
    if (!widget.isHost) return;
    SocketService().socket.emit('game_move', {
      'roomCode': widget.roomCode,
      'moveData': {'game': 'truth_or_dare', 'type': type, ...data},
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🎲 حقيقة أم جرأة (أونلاين)',
      backgroundColor: const Color(0xFFB71C1C),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: _started ? _buildGame() : _buildWaiting(),
    );
  }

  Widget _buildWaiting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 80, color: Colors.white).animate().scale(),
          const SizedBox(height: 20),
          Text(widget.isHost ? 'المضيف يسجل شلته...' : 'بانتظار المضيف يبدأ...', style: GoogleFonts.cairo(fontSize: 22, color: Colors.white)),
          if (widget.isHost) ...[
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                final p = widget.roomPlayers?.map((e) => e['name'] as String).toList() ?? ['أنت', widget.opponentName ?? 'خصم'];
                setState(() { _players = p; _started = true; });
                _emit('start_game', {'players': p, 'currentPlayer': 0, 'shuffledTruths': [], 'shuffledDares': [], 'truthIndex': 0, 'dareIndex': 0});
              },
              child: const Text('ابدأ اللعبة مع الروم!'),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildGame() {
    bool isMyTurn = _players[_currentPlayer] == widget.playerName;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('دور: ${_players[_currentPlayer]}', style: GoogleFonts.cairo(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          if (!_typeChosen) ...[
            if (isMyTurn) ...[
              const Text('اختار نوع التحدي:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => _pick(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text('حقيقة 💎')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => _pick(false), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('جرأة 🔥')),
            ] else const Text('بانتظار اختيار اللاعب...', style: TextStyle(color: Colors.white54))
          ] else ...[
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)), child: Text(_currentCard ?? 'جاري التحميل...', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 20, color: Colors.white))),
            const SizedBox(height: 30),
            if (isMyTurn) ElevatedButton(onPressed: _next, child: const Text('تم! التالي ➡️')),
          ]
        ],
      ),
    );
  }

  void _pick(bool t) {
    String card = t ? 'ما هو أكبر سر عندك؟' : 'غني أغنية مضحكة من اختيارهم!';
    setState(() { _typeChosen = true; _currentCard = card; });
    _emit('pick', {'isTruth': t, 'currentCard': card});
  }

  void _next() {
    int nextIdx = (_currentPlayer + 1) % _players.length;
    setState(() { _typeChosen = false; _currentPlayer = nextIdx; });
    _emit('next', {'currentPlayer': nextIdx});
  }
}
