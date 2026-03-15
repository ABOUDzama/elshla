import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/socket_service.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:convert';

class ChatWidget extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final List<Map<String, dynamic>> initialMessages;

  const ChatWidget({
    super.key,
    required this.roomCode,
    required this.playerName,
    required this.initialMessages,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    SocketService().socket.on('receive_chat_message', _handleIncomingMessage);
    _scrollToBottom();
  }

  @override
  void dispose() {
    SocketService().socket.off('receive_chat_message', _handleIncomingMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleIncomingMessage(dynamic data) {
    if (mounted) {
      setState(() {
        // Just trigger rebuild, the SocketService already added it to the global list
      });
      _scrollToBottom();
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final String msgId = '${DateTime.now().millisecondsSinceEpoch}_${widget.playerName}';
    final Map<String, dynamic> localMsg = {
      'roomCode': widget.roomCode,
      'message': text,
      'playerName': widget.playerName,
      'name': widget.playerName,
      'avatar': SocketService().currentAvatar, // Include my avatar
      'timestamp': DateTime.now().toIso8601String(),
      'msgId': msgId,
    };

    // Local Echo: Add to list immediately
    setState(() {
      SocketService().chatMessages.add(localMsg);
    });
    _scrollToBottom();

    // Emit to server
    SocketService().socket.emit('send_chat_message', localMsg);

    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F1A), // Deep dark purple-ish black
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          // Elegant Handle/Header
          Container(
            margin: const EdgeInsets.only(top: 15, bottom: 5),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Colors.purpleAccent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 15),
                Text(
                  'غرفة الدردشة',
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: Colors.white12, height: 1),

          // Messages List with Premium Styling
          Expanded(
            child: SocketService().chatMessages.isEmpty
                ? Center(
                    child: SingleChildScrollView( // Fix Overflow
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded, 
                              size: 70, 
                              color: Colors.blueAccent.withValues(alpha: 0.2)
                            ),
                          ),
                          const SizedBox(height: 25),
                          Text(
                            'المكان فاضي يا وحش!\nابدأ المحادثة ووريهم مين القائد 🚀',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              color: Colors.white38,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    itemCount: SocketService().chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = SocketService().chatMessages[index];
                      // Robust identity check
                      final sender = (msg['playerName'] ?? msg['name'] ?? msg['sender'] ?? '').toString().trim().toLowerCase();
                      final isMe = sender == widget.playerName.trim().toLowerCase();
                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
          ),

          // High-End Input Area
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF161625),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'اكتب حاجة عظمة...',
                        hintStyle: GoogleFonts.cairo(color: Colors.white24, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                _buildSendButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _sendMessage,
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    String timeStr = '';
    try {
      if (msg['timestamp'] != null) {
        timeStr = intl.DateFormat('hh:mm').format(DateTime.parse(msg['timestamp']));
      }
    } catch (_) {
      timeStr = '';
    }
    
    // Improved sender info extraction
    var senderName = (msg['playerName']?.toString() ?? msg['name']?.toString() ?? msg['sender']?.toString() ?? (msg['user'] is Map ? msg['user']['name']?.toString() : null) ?? 'لاعب').trim();
    if (senderName.isEmpty) senderName = 'لاعب';
    
    final avatarData = msg['avatar']?.toString() ?? (msg['user'] is Map ? msg['user']['avatar']?.toString() : null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(senderName, avatarBase64: avatarData),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 5),
                  child: Text(
                    isMe ? 'أنت' : senderName,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isMe ? Colors.blueAccent : Colors.orangeAccent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isMe 
                      ? const LinearGradient(
                          colors: [Color(0xFF2962FF), Color(0xFF6200EA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)],
                        ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isMe ? 22 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 22),
                    ),
                    boxShadow: isMe ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['message'] ?? '',
                        style: GoogleFonts.cairo(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isMe) _buildAvatar('Me', isSelf: true, avatarBase64: avatarData),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, {bool isSelf = false, String? avatarBase64}) {
    // If we have base64 data, render it
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      try {
        return Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelf ? Colors.purpleAccent.withAlpha(100) : Colors.blueAccent.withAlpha(100),
              width: 1.5,
            ),
            image: DecorationImage(
              image: MemoryImage(base64Decode(avatarBase64)),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error decoding chat avatar: $e');
        // Fallback to initials
      }
    }

    final firstChar = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        color: isSelf ? const Color(0xFF6200EA) : const Color(0xFF37474F),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white10, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          firstChar,
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

