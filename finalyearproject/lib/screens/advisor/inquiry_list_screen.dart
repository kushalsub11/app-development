import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../user/chat_screen.dart';

class InquiryListScreen extends StatefulWidget {
  const InquiryListScreen({super.key});

  @override
  State<InquiryListScreen> createState() => _InquiryListScreenState();
}

class _InquiryListScreenState extends State<InquiryListScreen> {
  bool _isLoading = true;
  List<ChatRoomModel> _inquiries = [];
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadInquiries();
  }

  Future<void> _loadInquiries() async {
    setState(() => _isLoading = true);
    _currentUser = await AuthService.getSavedUser();
    final results = await ApiService.getInquiryChats();
    if (mounted) {
      setState(() {
        _inquiries = results;
        _isLoading = false;
      });
    }
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
        title: const Text(
          'Inquiry Messages',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInquiries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inquiries.isEmpty
              ? _buildEmptyState()
              : _buildInquiryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.question_answer_rounded, size: 64, color: AppTheme.accentPurple),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Inquiries Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pre-booking chats from potential clients\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.greyText, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inquiries.length,
      itemBuilder: (context, index) {
        final room = _inquiries[index];
        final lastMsg = room.messages.isNotEmpty ? room.messages.last : null;
        
        // Find other user info
        final isMeAdvisor = _currentUser?.id == room.advisorId;
        final otherName = isMeAdvisor ? (room.userName ?? 'User') : (room.advisorName ?? 'Advisor');
        final otherImage = isMeAdvisor ? room.userImage : room.advisorImage;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: Colors.black12,
          child: InkWell(
            onTap: () => _openChat(room, otherName),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.accentPurple.withOpacity(0.1),
                    backgroundImage: otherImage != null 
                        ? NetworkImage(ApiConfig.getImageUrl(otherImage)) 
                        : null,
                    child: otherImage == null 
                        ? Text(otherName[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.accentPurple))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              otherName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                            ),
                            if (lastMsg != null)
                              Text(
                                _formatTime(lastMsg.timestamp),
                                style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lastMsg?.content ?? 'No messages yet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14, 
                            color: lastMsg != null ? AppTheme.greyText : AppTheme.greyText.withOpacity(0.5),
                            fontStyle: lastMsg != null ? FontStyle.normal : FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRE-BOOKING INQUIRY',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentPurple),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.greyText),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String timestamp) {
    final date = DateTime.parse(timestamp).toLocal();
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }

  void _openChat(ChatRoomModel room, String otherName) {
    // Create mock booking for ChatScreen compatibility
    final mockBooking = BookingModel(
      id: 0,
      userId: room.userId,
      advisorId: 0, // Not needed for chat details if room is preloaded
      bookingDate: DateTime.now().toString(),
      startTime: '00:00',
      endTime: '23:59',
      status: 'pending',
      consultationType: 'physical',
      amount: 0,
      advisorName: room.advisorName,
      advisorImage: room.advisorImage,
      userName: room.userName,
      userImage: room.userImage,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: mockBooking,
          otherUserName: otherName,
          currentUserId: _currentUser?.id ?? 0,
          preloadedRoom: room,
        ),
      ),
    ).then((_) => _loadInquiries());
  }
}
