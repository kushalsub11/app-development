import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../../screens/user/chat_screen.dart';
import '../../screens/user/user_bookings_screen.dart';
import '../../screens/advisor/advisor_bookings_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await ApiService.getMyNotifications();
    if (mounted) {
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    await ApiService.markNotificationAsRead(id);
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: n.isRead ? AppTheme.greyText.withOpacity(0.1) : AppTheme.accentPurple.withOpacity(0.1),
                            child: Icon(
                              n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                              color: n.isRead ? AppTheme.greyText : AppTheme.accentPurple,
                            ),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(n.message, style: const TextStyle(fontSize: 13, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(n.createdAt.split('T')[0], style: const TextStyle(fontSize: 11, color: AppTheme.greyText)),
                            ],
                          ),
                          onTap: () async {
                            if (!n.isRead) _markRead(n.id);
                            
                            if (n.notificationType == 'booking' && n.referenceId != null) {
                              final bookingId = int.tryParse(n.referenceId!);
                              if (bookingId != null) {
                                final user = await AuthService.getSavedUser();
                                if (user?.role == 'advisor') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvisorBookingsScreen()));
                                } else {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UserBookingsScreen()));
                                }
                              }
                            } else if (n.notificationType == 'chat' && n.referenceId != null) {
                              final roomId = int.tryParse(n.referenceId!);
                              if (roomId != null) {
                                setState(() => _isLoading = true);
                                final rooms = await ApiService.getInquiryChats();
                                final room = rooms.firstWhere((r) => r.id == roomId, orElse: () => ChatRoomModel(
                                  id: roomId, userId: 0, advisorId: 0, isActive: true, createdAt: '', messages: []
                                ));
                                
                                if (room.userId != 0) {
                                   final user = await AuthService.getSavedUser();
                                   if (user != null) {
                                      final isUser = user.id == room.userId;
                                      final otherName = isUser ? room.advisorName ?? 'Advisor' : room.userName ?? 'User';
                                      
                                      // If it's a booking chat, we ideally need the booking model.
                                      // For now, if bookingId is null, we can pass a dummy booking for pre-booking.
                                      BookingModel booking;
                                      if (room.bookingId != null) {
                                        final b = await ApiService.getBookingById(room.bookingId!);
                                        booking = b ?? BookingModel(id: 0, userId: 0, advisorId: 0, bookingDate: '', startTime: '', endTime: '', status: '', consultationType: '', amount: 0);
                                      } else {
                                        booking = BookingModel(id: 0, userId: room.userId, advisorId: room.advisorId, bookingDate: '', startTime: '', endTime: '', status: '', consultationType: '', amount: 0);
                                      }
                                      
                                      setState(() => _isLoading = false);
                                      if (mounted) {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                                          booking: booking,
                                          otherUserName: otherName,
                                          currentUserId: user.id,
                                          roomId: room.id,
                                          preloadedRoom: room,
                                        )));
                                      }
                                   }
                                } else {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
          const SizedBox(height: 8),
          const Text('You will receive system updates here.', style: TextStyle(color: AppTheme.greyText)),
        ],
      ),
    );
  }
}
