import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/theme.dart';
import '../services/api_service.dart';
import '../services/call_service.dart';
import '../models/models.dart';

class CallingScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final bool isVideo;
  final String remoteUserName;
  final int callLogId;
  final int? roomId;
  final WebSocketChannel? wsChannel;
  final BookingModel? booking;

  const CallingScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.isVideo,
    required this.remoteUserName,
    required this.callLogId,
    this.wsChannel,
    this.roomId,
    this.booking,
  });


  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  final CallService _callService = CallService();
  bool _joined = false;
  bool _remoteJoined = false;
  bool _muted = false;
  bool _speakerOn = false;
  bool _cameraOff = false;
  int _callDuration = 0;
  int? _remoteUid;
  Timer? _timer;
  final _stopwatch = Stopwatch();
  bool _isHangingUp = false;
  Timer? _sessionTimer;


  @override
  void initState() {
    super.initState();
    _initCall();
  }

  Future<void> _initCall() async {
    await _callService.initAgora();

    // Register event handlers to track remote user status
    _callService.engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() => _joined = true);
            _stopwatch.start();
            _timer = Timer.periodic(const Duration(seconds: 1), (_) {
              if (mounted) setState(() => _callDuration = _stopwatch.elapsed.inSeconds);
            });
            _startSessionTimer();
          }
        },

        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) {
            setState(() {
              _remoteJoined = true;
              _remoteUid = remoteUid;
            });
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          // Remote user hung up — auto-end on this side too
          if (mounted) {
            setState(() => _remoteJoined = false);
            _onHangUp();
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('Left channel');
        },
      ),
    );

    await _callService.joinCall(
      channelName: widget.channelName,
      token: widget.token,
      isVideo: widget.isVideo,
    );
  }

  void _startSessionTimer() {
    if (widget.booking == null) return;
    
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final endTime = widget.booking!.endDateTime;
      if (endTime != null && DateTime.now().isAfter(endTime)) {
        timer.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session time expired. Call ending automatically.'),
              backgroundColor: AppTheme.error,
            ),
          );
          _onHangUp();
        }
      }
    });
  }

  Future<void> _onHangUp() async {

    if (_isHangingUp) return;
    _isHangingUp = true;

    // Send call_end signal to the other party via WebSocket
    if (widget.wsChannel != null && widget.roomId != null) {
      try {
        widget.wsChannel!.sink.add(jsonEncode({
          "type": "call_end",
          "room_id": widget.roomId,
        }));
      } catch (_) {}
    }

    _timer?.cancel();
    _sessionTimer?.cancel();
    _stopwatch.stop();

    final duration = _stopwatch.elapsed.inSeconds;

    await _callService.leaveCall();
    await ApiService.endCall(widget.callLogId, duration);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionTimer?.cancel();
    _callService.leaveCall();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video View (if video call)
          if (widget.isVideo && _joined) ...[
            // Remote Video (full screen)
            if (_remoteJoined && _remoteUid != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _callService.engine,
                  canvas: VideoCanvas(uid: _remoteUid),
                  connection: RtcConnection(channelId: widget.channelName),
                ),
              ),
            // Local video (small preview)
            Positioned(
              top: 80,
              right: 16,
              child: Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _callService.engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Call UI Overlay
          Container(
            decoration: BoxDecoration(
              gradient: widget.isVideo && _remoteJoined
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xCC000000), Colors.transparent, Color(0xCC000000)],
                      stops: [0.0, 0.5, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A0949), Color(0xFF3A1F6B)],
                    ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                // Remote User Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPurple.withOpacity(0.4),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.remoteUserName.isNotEmpty ? widget.remoteUserName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 42, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _joined
                      ? (_remoteJoined ? _formatDuration(_callDuration) : 'Ringing...')
                      : 'Connecting...',
                  style: const TextStyle(fontSize: 16, color: Colors.white60),
                ),

                const Spacer(),

                // Call Control Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(
                        icon: _muted ? Icons.mic_off : Icons.mic,
                        label: _muted ? 'Unmute' : 'Mute',
                        onTap: () {
                          _callService.engine.muteLocalAudioStream(!_muted);
                          setState(() => _muted = !_muted);
                        },
                      ),
                      // End Call Button
                      GestureDetector(
                        onTap: _onHangUp,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 34),
                        ),
                      ),
                      if (widget.isVideo)
                        _CallButton(
                          icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                          label: _cameraOff ? 'Cam Off' : 'Cam On',
                          onTap: () {
                            _callService.engine.muteLocalVideoStream(!_cameraOff);
                            setState(() => _cameraOff = !_cameraOff);
                          },
                        )
                      else
                        _CallButton(
                          icon: _speakerOn ? Icons.volume_up : Icons.volume_down,
                          label: _speakerOn ? 'Speaker' : 'Earpiece',
                          onTap: () {
                            _callService.engine.setEnableSpeakerphone(!_speakerOn);
                            setState(() => _speakerOn = !_speakerOn);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CallButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
