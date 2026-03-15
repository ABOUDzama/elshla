import 'package:flutter/material.dart';
import '../../widgets/base_game_scaffold.dart';
import '../../services/socket_service.dart';

class SongLyricsGameOnline extends StatefulWidget {
  final bool isHost;
  final String? roomCode;
  final String? playerName;
  final List<dynamic>? roomPlayers;

  const SongLyricsGameOnline({
    super.key,
    required this.isHost,
    this.roomCode,
    this.playerName,
    this.roomPlayers,
  });

  @override
  State<SongLyricsGameOnline> createState() => _SongLyricsGameOnlineState();
}

class _SongLyricsGameOnlineState extends State<SongLyricsGameOnline> {
  String prompt = 'في انتظار المضيف...';
  List<String> choices = [];
  bool? isCorrect;

  @override
  void initState() {
    super.initState();
    _setupSocket();
  }

  void _setupSocket() {
    SocketService().socket.on('song_lyrics_sync', (data) {
      if (!mounted) return;
      final move = data['moveData'];
      setState(() {
        if (move['type'] == 'start_game' || move['type'] == 'next_question') {
          prompt = move['shuffled'][move['index']]['prompt'];
          choices = List<String>.from(move['choices'].map((c) => c['answer']));
          isCorrect = null;
        } else if (move['type'] == 'select_answer') {
          // Sync logic here
        }
      });
    });
  }

  @override
  void dispose() { SocketService().socket.off('song_lyrics_sync'); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BaseGameScaffold(
      title: '🎵 أكمل الأغنية (أونلاين)',
      backgroundColor: const Color(0xFF880E4F),
      roomCode: widget.roomCode,
      myId: SocketService().socket.id,
      playerName: widget.playerName,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(prompt, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, color: Colors.white)),
          const SizedBox(height: 20),
          ...choices.map((c) => ElevatedButton(onPressed: () {}, child: Text(c))),
          if (widget.isHost) ElevatedButton(onPressed: _next, child: const Text('التالي'))
        ]),
      ),
    );
  }

  void _next() {
    SocketService().socket.emit('game_move', {'roomCode': widget.roomCode, 'moveData': {'type': 'next_question', 'index': 0, 'game': 'song_lyrics'}});
  }
}
