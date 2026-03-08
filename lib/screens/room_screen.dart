import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import '../games/xo_game.dart';
import '../games/seega_game.dart';
import '../games/gobblet_game.dart';

class RoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String playerName;
  final String? avatarBase64;

  const RoomScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    required this.playerName,
    this.avatarBase64,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  List<Map<String, dynamic>> _players = [];

  @override
  void initState() {
    super.initState();

    // Set initial player immediately
    _players = [
      {
        'name': widget.playerName,
        'avatar': widget.avatarBase64,
        'isHost': widget.isHost,
        'id': SocketService().socket.id,
      },
    ];

    SocketService().socket.on('players_updated', (data) {
      if (!mounted) return;
      final List<dynamic> rawPlayers = data['players'];
      setState(() {
        _players = rawPlayers.map((p) => Map<String, dynamic>.from(p)).toList();
      });
    });

    SocketService().socket.on('game_selected', (data) {
      if (!mounted) return;
      _navigateToGame(data['gameName']);
    });

    SocketService().socket.on('player_left', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'غادر لاعب الغرفة'),
          backgroundColor: Colors.orange.shade700,
        ),
      );
    });

    SocketService().socket.on('room_closed', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'أُغلقت الغرفة'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('players_updated');
    SocketService().socket.off('game_selected');
    SocketService().socket.off('player_left');
    SocketService().socket.off('room_closed');
    super.dispose();
  }

  void _selectGame(String gameName) {
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انتظر انضمام لاعب آخر على الأقل')),
      );
      return;
    }
    SocketService().socket.emit('select_game', {
      'roomCode': widget.roomCode,
      'gameName': gameName,
    });
    _navigateToGame(gameName);
  }

  void _navigateToGame(String gameName) {
    // Find opponent (first non-self player)
    final opponent = _players.firstWhere(
      (p) => p['id'] != SocketService().socket.id,
      orElse: () => {'name': 'المنافس'},
    );
    final opponentName = opponent['name'] as String?;

    Widget? gameScreen;
    switch (gameName) {
      case 'xo':
        gameScreen = TicTacToeGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: opponentName,
        );
        break;
      case 'seega':
        gameScreen = SeegaGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: opponentName,
        );
        break;
      case 'gobblet':
        gameScreen = GobbletGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: opponentName,
        );
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => gameScreen!),
    );
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الكود! 📋'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady = _players.length >= 2;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Room code card
                    _buildRoomCodeCard(),
                    const SizedBox(height: 28),

                    // Players section title
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_rounded,
                          color: Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'اللاعبون (${_players.length})',
                          style: GoogleFonts.cairo(
                            color: Colors.white54,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (!isReady)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.orange.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'بانتظار لاعبين',
                                  style: GoogleFonts.cairo(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'جاهز للبدء',
                                  style: GoogleFonts.cairo(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Players list
                    ..._players.map((p) => _buildPlayerCard(p)),

                    // Empty slots
                    if (_players.isEmpty || _players.length == 1)
                      _buildEmptySlot(),

                    const SizedBox(height: 32),

                    // Game selection (host only)
                    if (widget.isHost) ...[
                      Text(
                        isReady
                            ? '🎮 اختر اللعبة لتبدأ:'
                            : '🎮 ستظهر الألعاب بعد انضمام لاعب آخر',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isReady ? Colors.white : Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _GameTile(
                        title: 'إكس أو',
                        subtitle: 'XO Classic',
                        emoji: '❌⭕',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        ),
                        onTap: isReady ? () => _selectGame('xo') : null,
                      ),
                      const SizedBox(height: 12),
                      _GameTile(
                        title: 'سيجَا',
                        subtitle: 'لعبة استراتيجية',
                        emoji: '♟️',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        onTap: isReady ? () => _selectGame('seega') : null,
                      ),
                      const SizedBox(height: 12),
                      _GameTile(
                        title: 'الكبير ياكل الصغير',
                        subtitle: 'Gobblet',
                        emoji: '🔴🔵',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        onTap: isReady ? () => _selectGame('gobblet') : null,
                      ),
                    ] else ...[
                      // Guest message
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            const Text('⏳', style: TextStyle(fontSize: 40)),
                            const SizedBox(height: 12),
                            Text(
                              'بانتظار المضيف لاختيار اللعبة...',
                              style: GoogleFonts.cairo(
                                color: Colors.white60,
                                fontSize: 17,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          ),
          Text(
            'غرفة الانتظار',
            style: GoogleFonts.cairo(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (widget.isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '👑 مضيف',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withAlpha(40),
            const Color(0xFF8B5CF6).withAlpha(40),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6366F1).withAlpha(80)),
      ),
      child: Column(
        children: [
          Text(
            'كود الغرفة',
            style: GoogleFonts.cairo(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            widget.roomCode,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Color(0xFF818CF8),
              letterSpacing: 10,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _copyCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'انسخ الكود وشاركه مع أصحابك',
                    style: GoogleFonts.cairo(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final bool isMe = player['id'] == SocketService().socket.id;
    final bool isHost = player['isHost'] == true;
    final String? avatarB64 = player['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? const Color(0xFF6366F1).withAlpha(25)
            : Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? const Color(0xFF6366F1).withAlpha(80) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                    : [Colors.teal.shade700, Colors.teal.shade400],
              ),
            ),
            child: avatarB64 != null
                ? ClipOval(
                    child: Image.memory(
                      base64Decode(avatarB64),
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      (player['name'] as String).isNotEmpty
                          ? (player['name'] as String)[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player['name'] as String? ?? 'لاعب',
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(أنت)',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF818CF8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isHost)
                  Text(
                    '👑 مضيف',
                    style: GoogleFonts.cairo(color: Colors.amber, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.circle, color: Colors.green, size: 12),
        ],
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withAlpha(10),
              border: Border.all(
                color: Colors.white24,
                style: BorderStyle.solid,
              ),
            ),
            child: const Icon(
              Icons.person_add_rounded,
              color: Colors.white24,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'بانتظار لاعب...',
            style: GoogleFonts.cairo(color: Colors.white30, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ─── Game Tile Widget ───────────────────────────────────
class _GameTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const _GameTile({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: onTap != null
                ? gradient
                : const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF1E293B)],
                  ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: onTap != null
                ? [
                    BoxShadow(
                      color: gradient.colors.first.withAlpha(80),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
