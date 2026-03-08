import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/socket_service.dart';
import 'room_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  String? _avatarBase64;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();

    SocketService().initSocket();

    SocketService().socket.on('room_created', (data) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final roomCode = data['roomCode'];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            roomCode: roomCode,
            isHost: true,
            playerName: _nameController.text.trim(),
            avatarBase64: _avatarBase64,
          ),
        ),
      );
    });

    SocketService().socket.on('join_success', (data) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            roomCode: _roomCodeController.text.trim(),
            isHost: false,
            playerName: _nameController.text.trim(),
            avatarBase64: _avatarBase64,
          ),
        ),
      );
    });

    SocketService().socket.on('error_message', (data) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']),
          backgroundColor: Colors.red.shade700,
        ),
      );
    });
  }

  @override
  void dispose() {
    SocketService().socket.off('room_created');
    SocketService().socket.off('join_success');
    SocketService().socket.off('error_message');
    _nameController.dispose();
    _roomCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _avatarBase64 = base64Encode(bytes);
      });
    }
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال اسمك أولاً')));
      return false;
    }
    return true;
  }

  void _createRoom() {
    if (!_validate()) return;
    setState(() => _isLoading = true);
    SocketService().socket.emit('create_room', {
      'playerName': _nameController.text.trim(),
      'avatar': _avatarBase64,
    });
  }

  void _joinRoom() {
    if (!_validate()) return;
    if (_roomCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('الرجاء إدخال كود الغرفة')));
      return;
    }
    setState(() => _isLoading = true);
    SocketService().socket.emit('join_room', {
      'roomCode': _roomCodeController.text.trim(),
      'playerName': _nameController.text.trim(),
      'avatar': _avatarBase64,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      'اللعب أونلاين 🎮',
                      style: GoogleFonts.cairo(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Avatar picker
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.indigo.withAlpha(100),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: _avatarBase64 != null
                                  ? ClipOval(
                                      child: Image.memory(
                                        base64Decode(_avatarBase64!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 55,
                                      color: Colors.white,
                                    ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اضغط لاختيار صورة',
                        style: GoogleFonts.cairo(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: 'اسم اللاعب',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 32),

                      // Create room button
                      _buildButton(
                        label: 'إنشاء غرفة جديدة',
                        icon: Icons.add_circle_outline_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        ),
                        onTap: _isLoading ? null : _createRoom,
                      ),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white12)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'أو انضم',
                              style: GoogleFonts.cairo(color: Colors.white38),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white12)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Room code field
                      _buildTextField(
                        controller: _roomCodeController,
                        label: 'كود الغرفة',
                        icon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        letterSpacing: 8,
                        fontSize: 22,
                      ),
                      const SizedBox(height: 16),

                      // Join room button
                      _buildButton(
                        label: 'انضمام للغرفة',
                        icon: Icons.login_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F9B8E), Color(0xFF14B8A6)],
                        ),
                        onTap: _isLoading ? null : _joinRoom,
                      ),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    double? letterSpacing,
    double? fontSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlign: TextAlign.center,
        style: GoogleFonts.cairo(
          color: Colors.white,
          fontSize: fontSize ?? 16,
          letterSpacing: letterSpacing,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.cairo(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
