import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import 'room_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SocketService().initSocket();

    SocketService().socket.on('room_created', (data) {
      if (!mounted) return;
      final roomCode = data['roomCode'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            roomCode: roomCode,
            isHost: true,
            playerName: _nameController.text,
          ),
        ),
      );
    });

    SocketService().socket.on('error_message', (data) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'])));
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('room_created');
    SocketService().socket.off('error_message');
    // Don't disconnect here in case they just went back
    super.dispose();
  }

  void _createRoom() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسمك')));
      return;
    }
    SocketService().socket.emit('create_room', {
      'playerName': _nameController.text.trim(),
    });
  }

  void _joinRoom() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسمك')));
      return;
    }
    if (_roomCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كود الغرفة')));
      return;
    }
    SocketService().socket.emit('join_room', {
      'roomCode': _roomCodeController.text.trim(),
      'playerName': _nameController.text.trim(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(
          roomCode: _roomCodeController.text.trim(),
          isHost: false,
          playerName: _nameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'اللعب أونلاين',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videogame_asset_outlined,
                size: 80,
                color: Colors.indigo.shade400,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'اسم اللاعب',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _createRoom,
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    'إنشاء غرفة جديدة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Divider(color: Colors.white24),
              const SizedBox(height: 40),
              TextField(
                controller: _roomCodeController,
                decoration: InputDecoration(
                  labelText: 'كود الغرفة',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _joinRoom,
                  icon: const Icon(Icons.login),
                  label: Text(
                    'انضمام للغرفة',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
