import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../user/chat_screen.dart';
import '../../services/auth_service.dart';

class AdvisorBookingsScreen extends StatefulWidget {
  const AdvisorBookingsScreen({super.key});

  @override
  State<AdvisorBookingsScreen> createState() => _AdvisorBookingsScreenState();
}

class _AdvisorBookingsScreenState extends State<AdvisorBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = await ApiService.getCurrentUser();
    final bookings = await ApiService.getAdvisorBookings();
    setState(() {
      _currentUser = user;
      _bookings = bookings;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(int bookingId, String status) async {
    final success = await ApiService.updateBookingStatus(bookingId, status);
    if (success) {
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking $status'),
          backgroundColor: status == 'confirmed' ? AppTheme.success : AppTheme.warning,
        ),
      );
    }
  }

  void _openChatWithTimeLock(BookingModel booking) {
    final scheduledDT = booking.scheduledDateTime;
    final now = DateTime.now();

    if (scheduledDT != null && now.isBefore(scheduledDT)) {
      final diff = scheduledDT.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      String timeLeft = '';
      if (hours > 0) timeLeft += '${hours}h ';
      timeLeft += '${minutes}m';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.accentPurple),
              SizedBox(width: 8),
              Text('Session Not Open Yet'),
            ],
          ),
          content: Text(
            'Your session starts at '
            '${scheduledDT.hour.toString().padLeft(2, '0')}:${scheduledDT.minute.toString().padLeft(2, '0')} '
            'on ${scheduledDT.year}-${scheduledDT.month.toString().padLeft(2, '0')}-${scheduledDT.day.toString().padLeft(2, '0')}.\n\n'
            'Opens in: $timeLeft',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    if (_currentUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: booking,
          otherUserName: booking.userName ?? 'Client #${booking.userId}',
          currentUserId: _currentUser!.id,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'Client Bookings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _bookings.isEmpty
                    ? const EmptyState(
                        icon: Icons.calendar_today,
                        title: 'No Bookings',
                        subtitle: 'Client bookings will appear here.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _bookings.length,
                          itemBuilder: (context, index) {
                            final b = _bookings[index];
                            return BookingCard(
                              bookingDate: b.bookingDate.split('T').first,
                              startTime: b.startTime,
                              endTime: b.endTime,
                              status: b.status,
                              consultationType: b.consultationType,
                              amount: b.amount,
                              meetingLocation: b.meetingLocation,
                              actions: b.status == 'pending'
                                  ? [
                                      TextButton(
                                        onPressed: () => _updateStatus(b.id, 'cancelled'),
                                        child: const Text('Reject', style: TextStyle(color: AppTheme.error)),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        onPressed: () => _updateStatus(b.id, 'confirmed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.success,
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                    ]
                                  : b.status == 'confirmed'
                                      ? [
                                          ElevatedButton(
                                            onPressed: () => _openChatWithTimeLock(b),
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                                            child: Text(b.consultationType == 'chat' ? 'Join Chat' : 'Join Session'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _updateStatus(b.id, 'completed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.info,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                            ),
                                            child: const Text('Complete'),
                                          ),
                                        ]
                                      : null,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
