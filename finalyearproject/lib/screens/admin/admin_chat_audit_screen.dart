import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AdminChatAuditScreen extends StatefulWidget {
  final int roomId;
  final String reporterName;
  final String reportedName;

  const AdminChatAuditScreen({
    super.key,
    required this.roomId,
    required this.reporterName,
    required this.reportedName,
  });

  @override
  State<AdminChatAuditScreen> createState() => _AdminChatAuditScreenState();
}

class _AdminChatAuditScreenState extends State<AdminChatAuditScreen> {
  ChatRoomModel? _room;
  bool _isLoading = true;
  final TextEditingController _interventionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final room = await ApiService.getAdminChatHistory(widget.roomId);
    if (mounted) {
      setState(() {
        _room = room;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendIntervention() async {
    if (_interventionController.text.trim().isEmpty) return;

    final success = await ApiService.sendAdminIntervention(
      widget.roomId,
      _interventionController.text.trim(),
    );

    if (success) {
      _interventionController.clear();
      _loadChatHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intervention sent successfully'), backgroundColor: AppTheme.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${widget.reporterName} vs ${widget.reportedName}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
          ],
        ),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                Expanded(
                  child: _room == null || _room!.messages.isEmpty
                      ? const Center(child: Text('No messages found in this room.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          reverse: true, // Show newest at bottom
                          itemCount: _room!.messages.length,
                          itemBuilder: (context, index) {
                            // Reverse order for display
                            final msg = _room!.messages.reversed.toList()[index];
                            final isReporter = msg.senderId == _room!.userId;
                            final isAdmin = msg.content.startsWith('[ADMIN INTERVENTION]');

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              alignment: isAdmin 
                                ? Alignment.center 
                                : isReporter ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdmin 
                                    ? Colors.orange.withOpacity(0.1)
                                    : isReporter ? Colors.white : AppTheme.accentPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: isAdmin ? Border.all(color: Colors.orange.withOpacity(0.3)) : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: isAdmin ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAdmin ? 'SYSTEM INTERVENTION' : isReporter ? widget.reporterName : widget.reportedName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isAdmin ? Colors.orange : isReporter ? Colors.blue : AppTheme.accentPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(msg.content, style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _interventionController,
                          decoration: InputDecoration(
                            hintText: 'Send Intervention Message...',
                            filled: true,
                            fillColor: Colors.grey.withOpacity(0.1),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _sendIntervention,
                        icon: const Icon(Icons.send_rounded, color: AppTheme.accentPurple),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
