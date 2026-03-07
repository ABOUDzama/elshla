import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import '../games/xo_game.dart';
import '../games/seega_game.dart';
import '../games/gobblet_game.dart';

class RoomScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final String playerName;

  const RoomScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    required this.playerName,
  });

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String? guestName;
  bool isReady = false;

  @override
  void initState() {
    super.initState();

    SocketService().socket.on('player_joined', (data) {
      if (!mounted) return;
      setState(() {
        guestName = widget.isHost ? data['guestName'] : data['hostName'];
        isReady = true;
      });
    });

    SocketService().socket.on('game_selected', (data) {
      if (!mounted) return;
      _navigateToGame(data['gameName']);
    });

    SocketService().socket.on('player_left', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('player_joined');
    SocketService().socket.off('game_selected');
    SocketService().socket.off('player_left');
    super.dispose();
  }

  void _selectGame(String gameName) {
    if (!isReady) return;
    SocketService().socket.emit('select_game', {
      'roomCode': widget.roomCode,
      'gameName': gameName,
    });
    _navigateToGame(gameName);
  }

  void _navigateToGame(String gameName) {
    Widget gameScreen;
    switch (gameName) {
      case 'xo':
        gameScreen = TicTacToeGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: guestName,
        );
        break;
      case 'seega':
        gameScreen = SeegaGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: guestName,
        );
        break;
      case 'gobblet':
        gameScreen = GobbletGame(
          online: true,
          isHost: widget.isHost,
          roomCode: widget.roomCode,
          opponentName: guestName,
        );
        break;
      default:
        return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => gameScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'غرفة الانتظار',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  children: [
                    const Text(
                      'كود الغرفة',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.roomCode,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigoAccent,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              isReady
                  ? Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 60,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'تم انضمام المنافس: $guestName',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const CircularProgressIndicator(color: Colors.teal),
                        const SizedBox(height: 20),
                        Text(
                          'أرسل الكود لصديقك لينضم...',
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 50),
              if (widget.isHost && isReady) ...[
                Text(
                  'اختر اللعبة لنبدأ التحدي:',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _GameButton(
                  title: 'إكس أو (XO)',
                  color: Colors.blueAccent,
                  icon: Icons.close,
                  onTap: () => _selectGame('xo'),
                ),
                const SizedBox(height: 15),
                _GameButton(
                  title: 'سيجَا (Seega)',
                  color: Colors.orangeAccent,
                  icon: Icons.grid_3x3,
                  onTap: () => _selectGame('seega'),
                ),
                const SizedBox(height: 15),
                _GameButton(
                  title: 'الكبير ياكل الصغير',
                  color: Colors.purpleAccent,
                  icon: Icons.sports_esports,
                  onTap: () => _selectGame('gobblet'),
                ),
              ] else if (!widget.isHost && isReady) ...[
                const SizedBox(height: 30),
                Text(
                  'بانتظار الهوست لاختيار اللعبة...',
                  style: GoogleFonts.cairo(fontSize: 18, color: Colors.white54),
                ),
                const SizedBox(height: 20),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GameButton({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(
          title,
          style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
