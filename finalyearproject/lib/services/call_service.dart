import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  static const String appId = "bcc160f2676a42e18add385c16b1ab79";

  late RtcEngine _engine;
  bool _isInitialized = false;

  Future<void> initAgora() async {
    if (_isInitialized) return;

    // 1. Request permissions (Conditional for web)
    if (!kIsWeb) {
      await [Permission.microphone, Permission.camera].request();
    }

    // 2. Create the engine
    _engine = createAgoraRtcEngine();

    // 3. Initialize the engine
    await _engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    // 4. Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("Local user ${connection.localUid} joined channel");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("Remote user $remoteUid joined channel");
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              print("Remote user $remoteUid left channel");
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print("Local user left channel");
        },
      ),
    );

    _isInitialized = true;
  }

  Future<void> joinCall({
    required String channelName,
    required String token,
    required bool isVideo,
  }) async {
    await initAgora();

    // Explicitly enable audio for all calls
    await _engine.enableAudio();

    if (isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.disableVideo();
    }

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Explicitly set media options for consistent behavior across devices
    final options = ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileCommunication,
      publishCameraTrack: isVideo,
      publishMicrophoneTrack: true,
      autoSubscribeAudio: true,
      autoSubscribeVideo: true,
    );

    await _engine.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: options,
    );
  }

  Future<void> leaveCall() async {
    if (!_isInitialized) return;
    await _engine.leaveChannel();
    await _engine.stopPreview();
    // In a real app, you might not want to release the engine immediately
    // but for simplicity we'll mark as not initialized if we release.
    // await _engine.release();
    // _isInitialized = false;
  }

  RtcEngine get engine => _engine;
}
