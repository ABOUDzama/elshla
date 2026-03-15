import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import '../services/settings_service.dart';
import '../services/haptic_service.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<Map<String, dynamic>> _friends = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    
    SocketService().socket.on('social_info_received', (data) {
      if (!mounted) return;
      setState(() {
        _friends = List<Map<String, dynamic>>.from(data['friends']);
        _isLoading = false;
      });
    });

    SocketService().onFriendsUpdated = () {
      _loadData();
    };
  }

  void _loadData() {
    SocketService().socket.emit('get_social_info');
  }

  @override
  void dispose() {
    SocketService().socket.off('social_info_received');
    _searchController.dispose();
    super.dispose();
  }

  void _sendRequest() {
    final targetId = _searchController.text.trim();
    if (targetId.isEmpty) return;
    if (targetId == SettingsService.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكنك إضافة نفسك! 😂')),
      );
      return;
    }
    SocketService().socket.emit('send_friend_request', {'targetUserId': targetId});
    _searchController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال طلب الصداقة! 📩')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030303),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('الأصدقاء 🤝', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // My ID display
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('كودك التعريفي:', style: GoogleFonts.cairo(color: Colors.white54, fontSize: 12)),
                      Text(SettingsService.userId, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Copy ID
                    HapticService.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الكود! 📋')));
                  },
                  icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                )
              ],
            ),
          ),

          // Search / Add
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'أدخل كود صديقك هنا...',
                hintStyle: const TextStyle(color: Colors.white38),
                fillColor: Colors.white.withAlpha(8),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  onPressed: _sendRequest,
                  icon: const Icon(Icons.person_add_rounded, color: Colors.blueAccent),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Friends List
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty 
                  ? Center(child: Text('لا يوجد أصدقاء بعد. أضف بعضهم! ✨', style: GoogleFonts.cairo(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _friends.length,
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        return _buildFriendCard(friend);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final bool isOnline = friend['isOnline'] == true;
    final String? avatar = friend['avatar'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOnline ? Colors.green.withAlpha(40) : Colors.white10),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueGrey,
                  image: avatar != null 
                    ? DecorationImage(image: MemoryImage(base64Decode(avatar)), fit: BoxFit.cover)
                    : null,
                ),
                child: avatar == null 
                  ? const Icon(Icons.person, color: Colors.white70) 
                  : null,
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend['name'], style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(isOnline ? 'متصل الآن' : 'غير متصل', style: GoogleFonts.cairo(color: isOnline ? Colors.green : Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          if (isOnline)
            ElevatedButton(
              onPressed: () {
                // This would be filtered by current room context
                // If I'm in a room, send invite
                if (SocketService().currentRoomCode != null) {
                  SocketService().socket.emit('invite_to_room', {
                    'targetUserId': friend['userId'],
                    'roomCode': SocketService().currentRoomCode
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم إرسال دعوة لـ ${friend['name']}! ✉️')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب أن تكون في غرفة أولاً لترسل دعوة!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleArray(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text('دعوة', style: GoogleFonts.cairo(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class RoundedRectangleArray extends OutlinedBorder {
  final BorderRadius borderRadius;
  const RoundedRectangleArray({required this.borderRadius});
  
  @override
  OutlinedBorder copyWith({BorderSide? side}) => this;
  
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();
  
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }
  
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}
  
  @override
  ShapeBorder scale(double t) => this;
}
