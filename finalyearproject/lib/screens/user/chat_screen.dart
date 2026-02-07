import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../calling_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';


class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String otherUserName;
  final int currentUserId;
  final int? roomId;
  final ChatRoomModel? preloadedRoom;

  const ChatScreen({
    super.key,
    required this.booking,
    required this.otherUserName,
    required this.currentUserId,
    this.roomId,
    this.preloadedRoom,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  ChatRoomModel? _room;
  bool _isLoading = true;
  WebSocketChannel? _channel;
  List<ChatMessageModel> _messages = [];
  StreamSubscription? _subscription;
  // BUG FIX: guard against multiple incoming call dialogs
  bool _isCallDialogShowing = false;
  bool _isConnected = false;
  bool _isExpired = false;
  Timer? _expiryTimer;


  @override
  void initState() {
    super.initState();
    _checkExpiry();
    _initializeChat();
    _startExpiryTimer();
  }

  void _checkExpiry() {
    if (widget.booking.id == 0) return; // Ignore for pre-booking
    final endTime = widget.booking.endDateTime;
    if (endTime != null && DateTime.now().isAfter(endTime)) {
      if (mounted) {
        setState(() => _isExpired = true);
      }
    }
  }

  void _startExpiryTimer() {
    if (widget.booking.id == 0) return; // Ignore for pre-booking
    final endTime = widget.booking.endDateTime;
    if (endTime == null) return;

    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (DateTime.now().isAfter(endTime)) {
        timer.cancel();
        if (mounted) {
          setState(() => _isExpired = true);
        }
      }
    });
  }


  Future<void> _initializeChat() async {
    if (widget.preloadedRoom != null) {
      setState(() {
        _room = widget.preloadedRoom;
        _messages = widget.preloadedRoom!.messages;
        _isLoading = false;
      });
      _scrollToBottom();
      _connectWebSocket(widget.preloadedRoom!.id);
      return;
    }
    
    // If it's a pre-booking chat, the roomId should be provided and we can get it from pre-booking api
    if (widget.roomId != null && widget.booking.id == 0) {
       // Typically, we already have the room data from ApiService.getOrCreatePreBookingRoom which returns JSON.
       // However, to keep it simple if we only passed roomId, we could fetch it again.
       // But we pass preloadedRoom or rely on the Websocket directly.
       // Let's modify to assume preloadedRoom is passed if it's pre-booking.
       setState(() => _isLoading = false);
       _connectWebSocket(widget.roomId!);
       return;
    }

    final room = await ApiService.getOrCreateChatRoom(widget.booking.id);
    if (room != null) {
      setState(() {
        _room = room;
        _messages = room.messages;
        _isLoading = false;
      });
      _scrollToBottom();
      _connectWebSocket(room.id);
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load chat. Try again.')),
        );
      }
    }
  }

  Future<void> _connectWebSocket(int roomId) async {
    final token = await AuthService.getToken();
    if (token == null) return;

    final wsUrl = Uri.parse('${ApiConfig.chatWs}/$roomId').replace(
      queryParameters: {'token': token},
    );
    
    try {
      // BUG FIX: Cancel previous subscription before starting a new one
      await _subscription?.cancel();

      _channel = WebSocketChannel.connect(wsUrl);
      setState(() => _isConnected = true);

      _subscription = _channel!.stream.listen((message) {
        final decoded = jsonDecode(message);
        final msgType = decoded['type'] ?? 'chat';
        
        if (msgType == 'chat') {
          final newMsg = ChatMessageModel.fromJson(decoded);
          if (!mounted) return;
          setState(() => _messages.add(newMsg));
          _scrollToBottom();
        } else if (msgType == 'call_invite') {
          if (decoded['sender_id'] != widget.currentUserId) {
            if (!mounted) return;

            // BUG FIX: Only show ONE dialog at a time
            if (!_isCallDialogShowing) {
              _isCallDialogShowing = true;
              // Dismiss any existing snackbars first
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _showIncomingCallDialog(decoded);
            }
          }
        } else if (msgType == 'call_reject') {
          if (decoded['sender_id'] != widget.currentUserId) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call was rejected')),
            );
          }
        } else if (msgType == 'call_end') {
          // Remote party ended the call — close the calling screen on this side
          if (decoded['sender_id'] != widget.currentUserId) {
            if (!mounted) return;
            // Pop the calling screen if it's on top
            if (Navigator.canPop(context)) {
              Navigator.of(context).popUntil((route) {
                return route.settings.name == null || !(route.settings.name?.contains('calling') ?? false);
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The other party ended the call')),
            );
          }
        }
      }, onError: (error) {
        print('WebSocket Error: $error');
        if (!mounted) return;
        setState(() => _isConnected = false);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _connectWebSocket(roomId);
        });
      }, onDone: () {
        print('WebSocket Disconnected');
        if (!mounted) return;
        setState(() => _isConnected = false);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _connectWebSocket(roomId);
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnected = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channel == null) return;
    
    final message = jsonEncode({'type': 'chat', 'content': text});
    _channel!.sink.add(message);
    _messageController.clear();
  }

  Future<void> _pickAndSendImage() async {
    if (_isExpired || _channel == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress for faster upload
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    final imageUrl = await ApiService.uploadChatImage(image.path);
    setState(() => _isLoading = false);

    if (imageUrl != null) {
      final message = jsonEncode({
        'type': 'chat',
        'message_type': 'image',
        'content': imageUrl,
      });
      _channel!.sink.add(message);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image. Please try again.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showIncomingCallDialog(Map<String, dynamic> data) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              data['call_type'] == 'video' ? Icons.videocam : Icons.call,
              color: AppTheme.accentPurple,
            ),
            const SizedBox(width: 10),
            Text("Incoming ${data['call_type']} Call"),
          ],
        ),
        content: Text("${widget.otherUserName} is calling you. Would you like to accept?"),
        actions: [
          TextButton(
            onPressed: () {
              _isCallDialogShowing = false;
              Navigator.pop(dialogContext);
              _channel?.sink.add(jsonEncode({
                "type": "call_reject",
                "room_id": _room?.id,
              }));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Call rejected')),
                );
              }
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              _isCallDialogShowing = false;
              Navigator.pop(dialogContext);
              
              // Send accept signal
              _channel?.sink.add(jsonEncode({
                "type": "call_accept",
                "room_id": _room?.id,
              }));

              // Get Agora token
              setState(() => _isLoading = true);
              final response = await ApiService.initiateCall(widget.booking.id, data['call_type']);
              setState(() => _isLoading = false);

              if (response != null && mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CallingScreen(
                      channelName: response['channel_name'],
                      token: response['token'],
                      isVideo: data['call_type'] == 'video',
                      remoteUserName: widget.otherUserName,
                      callLogId: response['call_log_id'],
                      wsChannel: _channel,
                      roomId: _room?.id,
                      booking: widget.booking,
                    ),
                  ),
                );

                _initializeChat(); 
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to join call.')),
                );
              }
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateCall(String type) async {
    setState(() => _isLoading = true);
    final response = await ApiService.initiateCall(widget.booking.id, type);
    setState(() => _isLoading = false);

    if (response != null) {
      // Send invite signal via WS
      _channel?.sink.add(jsonEncode({
        "type": "call_invite",
        "call_type": type,
        "room_id": _room?.id,
      }));

      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallingScreen(
              channelName: response['channel_name'],
              token: response['token'],
              isVideo: type == 'video',
              remoteUserName: widget.otherUserName,
              callLogId: response['call_log_id'],
              wsChannel: _channel,
              roomId: _room?.id,
              booking: widget.booking,
            ),
          ),
        );

        _initializeChat(); 
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start call. Check if a call is already active or your internet connection.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showReportDialog() {
    final reasonController = TextEditingController();
    final descController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Report Advisor'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  hintText: 'e.g. Unprofessional behavior',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Provide more details...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide a reason')),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final result = await ApiService.createReport({
                        'reported_advisor_id': widget.booking.advisorId,
                        'reason': reasonController.text.trim(),
                        'description': descController.text.trim(),
                      });

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['success']
                                ? 'Report submitted successfully'
                                : 'Failed to submit report: ${result['message']}'),
                            backgroundColor: result['success'] ? AppTheme.success : AppTheme.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    _expiryTimer?.cancel();
    _channel?.sink.close();
    super.dispose();

  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isMe = msg.senderId == widget.currentUserId;
    final timeStr = DateFormat('hh:mm a').format(DateTime.parse(msg.timestamp).toLocal());
    
    // Determine which image to show
    String? avatarPath = isMe ? null : (widget.booking.advisorImage ?? widget.booking.userImage);
    // Note: This logic depends on who the "other" person is. 
    // If current user is advisor, other is client. If current user is client, other is advisor.

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
              backgroundImage: avatarPath != null 
                  ? NetworkImage(ApiConfig.getImageUrl(avatarPath)) 
                  : null,
              child: avatarPath == null 
                  ? Text(widget.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 12))
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.accentPurple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (msg.messageType == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: ApiConfig.getImageUrl(msg.content),
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        fit: BoxFit.cover,
                        maxWidthDiskCache: 1000,
                      ),
                    )
                  else
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: isMe ? Colors.white : AppTheme.darkText,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : AppTheme.greyText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            // Optional: current user avatar
            const SizedBox(width: 32), // Spacer to maintain alignment if no avatar
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              backgroundImage: (widget.booking.advisorImage != null || widget.booking.userImage != null)
                  ? NetworkImage(ApiConfig.getImageUrl(widget.booking.advisorImage ?? widget.booking.userImage))
                  : null,
              child: (widget.booking.advisorImage == null && widget.booking.userImage == null)
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isConnected ? 'Online' : 'Connecting...', 
                        style: const TextStyle(fontSize: 11, color: Colors.white70)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.call, color: _isExpired ? Colors.white38 : Colors.white),
              onPressed: _isExpired ? null : () => _initiateCall('voice'),
            ),
            IconButton(
              icon: Icon(Icons.videocam, color: _isExpired ? Colors.white38 : Colors.white),
              onPressed: _isExpired ? null : () => _initiateCall('video'),
            ),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report_problem, color: AppTheme.error, size: 20),
                      SizedBox(width: 8),
                      Text('Report Advisor'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),
                // Message Input Box
                _isExpired
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                          children: [
                            const Text(
                              'Consultation time has ended.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Find advisor and go to detail
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.goldDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Book Again to Continue'),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.image_outlined, color: AppTheme.greyText),
                                      onPressed: _pickAndSendImage,
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _messageController,
                                        textInputAction: TextInputAction.send,
                                        keyboardType: TextInputType.text,
                                        onSubmitted: (value) {
                                          if (value.trim().isNotEmpty) _sendMessage();
                                        },
                                        decoration: const InputDecoration(
                                          hintText: 'Type a message...',
                                          hintStyle: TextStyle(color: AppTheme.greyText),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: _sendMessage,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentPurple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
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
