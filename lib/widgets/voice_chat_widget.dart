import 'package:flutter/material.dart';
import '../services/voice_chat_service.dart';

class VoiceChatWidget extends StatefulWidget {
  final String roomCode;
  final String myId;

  const VoiceChatWidget({
    super.key,
    required this.roomCode,
    required this.myId,
  });

  @override
  State<VoiceChatWidget> createState() => _VoiceChatWidgetState();
}

class _VoiceChatWidgetState extends State<VoiceChatWidget> {
  final VoiceChatService _voiceService = VoiceChatService();

  @override
  void initState() {
    super.initState();
    _voiceService.onStreamUpdate = () {
      if (mounted) setState(() {});
    };
    if (!_voiceService.isInitialized) {
       _voiceService.init(widget.roomCode, widget.myId);
       // Wait a bit to ensure initialization is done before calling
       Future.delayed(const Duration(seconds: 2), () {
          if (mounted) _voiceService.makeCall(widget.roomCode, widget.myId);
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMuted = _voiceService.isMuted;
    bool isConnected = _voiceService.remoteStream != null;

    return GestureDetector(
      onTap: () {
        _voiceService.toggleMute();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMuted ? Colors.redAccent.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMuted ? Icons.mic_off : Icons.mic,
              color: Colors.white,
              size: 20,
            ),
            if (isConnected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.people,
                color: Colors.white,
                size: 16,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
