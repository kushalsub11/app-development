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
                                          if (b.consultationType == 'chat')
                                            ElevatedButton(
                                              onPressed: () {
                                                if (_currentUser == null) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ChatScreen(
                                                      booking: b,
                                                      otherUserName: 'Client #${b.userId}',
                                                      currentUserId: _currentUser!.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                                              child: const Icon(Icons.chat, color: Colors.white, size: 20),
                                            ),
                                          if (b.consultationType != 'chat')
                                             Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                              child: Row(
                                                children: [
                                                  Icon(b.consultationType == 'video' ? Icons.videocam : Icons.phone, size: 16, color: AppTheme.info),
                                                  const SizedBox(width: 4),
                                                  Text(b.consultationType.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.info)),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _updateStatus(b.id, 'completed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.info,
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
