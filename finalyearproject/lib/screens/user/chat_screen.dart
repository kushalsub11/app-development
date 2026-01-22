import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../../services/call_service.dart';
import '../calling_screen.dart';


class ChatScreen extends StatefulWidget {
  final BookingModel booking;
  final String otherUserName;
  final int currentUserId;

  const ChatScreen({
    super.key,
    required this.booking,
    required this.otherUserName,
    required this.currentUserId,
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

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // 1. Fetch chat history and room metadata
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
      _channel = WebSocketChannel.connect(wsUrl);
      
      setState(() => _isConnected = true);

      _channel!.stream.listen((message) {
        final decoded = jsonDecode(message);
        final msgType = decoded['type'] ?? 'chat';
        print('--- WS SIGNAL --- Type: $msgType, Sender: ${decoded['sender_id']}'); 
        
        if (msgType == 'chat') {
          final newMsg = ChatMessageModel.fromJson(decoded);
          if (!mounted) return;
          setState(() {
            _messages.add(newMsg);
          });
          _scrollToBottom();
        } else if (msgType == 'call_invite') {
          print('--- SIGNAL --- Invite from ${decoded['sender_id']} reaching ${widget.currentUserId}');
          if (decoded['sender_id'] != widget.currentUserId) {
            print('--- SIGNAL --- Triggering Incoming Call Alert UI...');
            if (!mounted) return;

            // 1. Show the main popup dialog
            _showIncomingCallDialog(decoded);

            // 2. Fallback: Show a banner at the bottom with an "ANSWER" button
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Incoming ${decoded['call_type']} Call from ${widget.otherUserName}"),
                duration: const Duration(seconds: 30), // Stay 30s until they click
                action: SnackBarAction(
                  label: "ANSWER",
                  textColor: Colors.greenAccent,
                  onPressed: () => _showIncomingCallDialog(decoded), // Re-trigger dialog if they missed it
                ),
              ),
            );
          }
        } else if (msgType == 'call_reject') {
          if (decoded['sender_id'] != widget.currentUserId) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Call was rejected')),
            );
          }
        }
      }, onError: (error) {
        print('WebSocket Error: $error');
        if (!mounted) return;
        setState(() => _isConnected = false);
        // Auto-reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _connectWebSocket(roomId);
        });
      }, onDone: () {
        print('WebSocket Disconnected');
        if (!mounted) return;
        setState(() => _isConnected = false);
        // Auto-reconnect after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) _connectWebSocket(roomId);
        });
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConnected = false);
    }
  }

  bool _isConnected = false;

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _channel == null) return;
    
    // Always send as JSON so the backend doesn't have to "guess" the format
    final message = jsonEncode({
      'type': 'chat',
      'content': text,
    });
    
    _channel!.sink.add(message);
    _messageController.clear();
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
    
    // Check if a dialog is already showing or if the state is unstable
    print('--- SIGNAL --- Preparing to show dialog for call type: ${data['call_type']}');

    showDialog(
      context: context,
      barrierDismissible: false,
              _channel?.sink.add(jsonEncode({
                "type": "call_reject",
                "room_id": _room?.id,
              }));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call rejected')),
              );
            },
            child: const Text("Reject", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPurple,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              
              // 1. Send accept signal via WS
              _channel?.sink.add(jsonEncode({
                "type": "call_accept",
                "room_id": _room?.id,
              }));

              // 2. Initiate to get the same channel token
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
      // 1. Send invite signal via WS
      _channel?.sink.add(jsonEncode({
        "type": "call_invite",
        "call_type": type,
        "room_id": _room?.id,
      }));

      // 2. Open calling screen
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
            ),
          ),
        );
        _initializeChat(); 
      }
    } else if (mounted) {
      // Check if it failed because of "already in progress"
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start call. Check if a call is already active or your internet connection.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isMe = msg.senderId == widget.currentUserId;
    final timeStr = DateFormat('hh:mm a').format(DateTime.parse(msg.timestamp).toLocal());

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
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
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
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
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () => _initiateCall('voice'),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () => _initiateCall('video'),
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
                Container(
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
                          child: TextField(
                            controller: _messageController,
                            textInputAction: TextInputAction.send,
                            keyboardType: TextInputType.text,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                _sendMessage();
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(color: AppTheme.greyText),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
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
