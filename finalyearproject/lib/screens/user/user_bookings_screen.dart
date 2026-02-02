import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'chat_screen.dart';
import '../../services/auth_service.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
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
    final bookings = await ApiService.getMyBookings();
    setState(() {
      _currentUser = user;
      _bookings = bookings;
      _isLoading = false;
    });
  }

  Future<void> _cancelBooking(int bookingId) async {
    final success = await ApiService.updateBookingStatus(bookingId, 'cancelled');
    if (success) {
      _loadBookings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled'), backgroundColor: AppTheme.warning),
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
              'My Bookings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _bookings.isEmpty
                    ? const EmptyState(
                        icon: Icons.calendar_today,
                        title: 'No Bookings Yet',
                        subtitle: 'Your consultation bookings will appear here.',
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
                                        onPressed: () => _cancelBooking(b.id),
                                        child: const Text('Cancel', style: TextStyle(color: AppTheme.error)),
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
                                                      otherUserName: 'Astrologer',
                                                      currentUserId: _currentUser!.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                                              child: const Text('Join Chat'),
                                            ),
                                          if (b.consultationType != 'chat')
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(color: AppTheme.info.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                              child: Row(
                                                children: [
                                                  Icon(b.consultationType == 'video' ? Icons.videocam : Icons.phone, size: 16, color: AppTheme.info),
                                                  const SizedBox(width: 8),
                                                  Text(b.consultationType.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.info)),
                                                ],
                                              ),
                                            ),
                                        ]
                                      : b.status == 'completed'
                                          ? [
                                              TextButton(
                                                onPressed: () => _showReviewDialog(b),
                                                child: const Text('Review', style: TextStyle(color: AppTheme.accentPurple)),
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

  void _showReviewDialog(BookingModel booking) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingStars(
                rating: rating,
                size: 32,
                onRatingChanged: (r) => setDialogState(() => rating = r),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService.createReview({
                  'booking_id': booking.id,
                  'advisor_id': booking.advisorId,
                  'rating': rating,
                  'comment': commentController.text,
                });
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Review submitted!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
