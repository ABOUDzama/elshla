import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'socket_service.dart';

class VoiceChatService {
  static final VoiceChatService _instance = VoiceChatService._internal();
  factory VoiceChatService() => _instance;
  VoiceChatService._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isMuted = false;
  bool _isInitialized = false;

  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;
  MediaStream? get remoteStream => _remoteStream;

  // Callback to notify UI of stream changes
  Function()? onStreamUpdate;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ]
  };

  void init(String roomCode, String myId) async {
    if (_isInitialized) return;

    var status = await Permission.microphone.request();
    if (!status.isGranted) return;

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _peerConnection = await createPeerConnection(_configuration);

    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      SocketService().socket.emit('webrtc_ice_candidate', {
        'roomCode': roomCode,
        'candidate': candidate.toMap(),
        'callerId': myId,
      });
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      onStreamUpdate?.call();
    };

    _setupSignaling(roomCode, myId);
    _isInitialized = true;
    onStreamUpdate?.call();
  }

  void _setupSignaling(String roomCode, String myId) {
    SocketService().socket.on('webrtc_offer', (data) async {
       if (data['callerId'] == myId) return; // Ignore own offer
       var offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
       await _peerConnection?.setRemoteDescription(offer);
       
       var answer = await _peerConnection?.createAnswer();
       await _peerConnection?.setLocalDescription(answer!);
       
       SocketService().socket.emit('webrtc_answer', {
         'roomCode': roomCode,
         'answer': answer?.toMap(),
         'callerId': myId,
       });
    });

    SocketService().socket.on('webrtc_answer', (data) async {
       if (data['callerId'] == myId) return;
       var answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
       await _peerConnection?.setRemoteDescription(answer);
    });

    SocketService().socket.on('webrtc_ice_candidate', (data) async {
       if (data['callerId'] == myId) return;
       var candidate = RTCIceCandidate(
         data['candidate']['candidate'],
         data['candidate']['sdpMid'],
         data['candidate']['sdpMLineIndex']
       );
       await _peerConnection?.addCandidate(candidate);
    });
  }

  Future<void> makeCall(String roomCode, String myId) async {
    if (_peerConnection == null) return;
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    SocketService().socket.emit('webrtc_offer', {
      'roomCode': roomCode,
      'offer': offer.toMap(),
      'callerId': myId,
    });
  }

  void toggleMute() {
    if (_localStream != null) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
      _isMuted = !_isMuted;
      onStreamUpdate?.call();
    }
  }

  void dispose() {
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.dispose();
    _isInitialized = false;
    _remoteStream = null;
    _localStream = null;
    _peerConnection = null;
    
    // Remove listeners
    SocketService().socket.off('webrtc_offer');
    SocketService().socket.off('webrtc_answer');
    SocketService().socket.off('webrtc_ice_candidate');
  }
}
