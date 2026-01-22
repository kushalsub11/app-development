import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../services/call_service.dart';
import '../services/api_service.dart';
import '../config/theme.dart';

class CallingScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isVideo;
  final String remoteUserName;
  final int callLogId;

  const CallingScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.isVideo,
    required this.remoteUserName,
    required this.callLogId,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final CallService _callService = CallService();
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  Future<void> _initEngine() async {
    try {
      await _callService.initAgora();
      
      // Override event handlers for UI updates
      _callService.engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            if (mounted) {
              setState(() {
                _localUserJoined = true;
              });
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
              _startTimer();
            }
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            if (mounted) {
              setState(() {
                _remoteUid = null;
              });
              _stopTimer();
            }
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            if (mounted) {
              setState(() {
                _localUserJoined = false;
                _remoteUid = null;
              });
              Navigator.pop(context);
            }
          },
          onError: (ErrorCodeType err, String msg) {
            print("Agora Error: $err, $msg");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Agora Error: $msg')),
              );
            }
          },
        ),
      );

      await _callService.joinCall(
        channelName: widget.channelName,
        token: widget.token,
        isVideo: widget.isVideo,
      );
    } catch (e) {
      print("Call Initialization Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _callService.engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleCamera() {
    if (!widget.isVideo) return;
    setState(() {
      _isCameraOff = !_isCameraOff;
    });
    _callService.engine.enableLocalVideo(!_isCameraOff);
  }

  void _onSwitchCamera() {
    _callService.engine.switchCamera();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _onHangUp() async {
    _stopTimer();
    // Report duration to backend
    await ApiService.endCall(widget.callLogId, _seconds);
    await _callService.leaveCall();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _stopTimer();
    _callService.leaveCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video
          Center(
            child: _remoteUid != null && widget.isVideo
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _callService.engine,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(channelId: widget.channelName),
                    ),
                  )
                : _buildPlaceholder(widget.remoteUserName),
          ),
          
          // Local Video (Thumbnail)
          if (widget.isVideo && _localUserJoined && !_isCameraOff)
            Positioned(
              right: 20,
              top: 50,
              width: 120,
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _callService.engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                ),
              ),
            ),
          
          // Bottom Controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  onPressed: _onToggleMute,
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : Colors.white24,
                ),
                _buildControlButton(
                  onPressed: _onHangUp,
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 32,
                ),
                if (widget.isVideo) ...[
                  _buildControlButton(
                    onPressed: _onToggleCamera,
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    color: _isCameraOff ? Colors.red : Colors.white24,
                  ),
                  _buildControlButton(
                    onPressed: _onSwitchCamera,
                    icon: Icons.switch_camera,
                    color: Colors.white24,
                  ),
                ],
              ],
            ),
          ),
          
          // Name & Call status overlay
          Positioned(
            top: 60,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _remoteUid != null ? _formatDuration(_seconds) : "Calling...",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppTheme.accentPurple.withOpacity(0.3),
          child: Text(
            name[0],
            style: const TextStyle(fontSize: 48, color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Voice Call",
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    double size = 24,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
