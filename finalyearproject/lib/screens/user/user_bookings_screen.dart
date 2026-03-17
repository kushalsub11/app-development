import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'chat_screen.dart';

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

  Future<void> _initiatePayment(BookingModel b) async {
    setState(() => _isLoading = true);
    final khaltiResult = await ApiService.initiateKhaltiPayment(b.id);
    setState(() => _isLoading = false);

    if (khaltiResult != null && khaltiResult['payment_url'] != null) {
      final url = Uri.parse(khaltiResult['payment_url']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showVerifyDialog(b.id, khaltiResult['pidx']);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch payment URL')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initiate Khalti payment')),
        );
      }
    }
  }

  void _showVerifyDialog(int bookingId, String pidx) {
    bool isVerifying = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Verify Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please verify your payment after completing the transaction in Khalti.'),
              if (isVerifying) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setDialogState(() => isVerifying = true);
                      final res = await ApiService.verifyKhaltiPayment(pidx, bookingId);
                      setDialogState(() => isVerifying = false);
                      
                      if (res != null && res['success']) {
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadBookings();
                          _showSuccessPopup();
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res?['message'] ?? 'Payment not confirmed yet. Please wait a moment.'),
                              backgroundColor: AppTheme.error,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Verified!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.darkText),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your payment is confirmed. You can now join the session at the scheduled time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.greyText, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChatWithTimeLock(BookingModel booking) {
    final scheduledDT = booking.scheduledDateTime;
    final now = DateTime.now();

    if (scheduledDT != null && now.isBefore(scheduledDT)) {
      // Not time yet — show informational dialog
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
          title: Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.accentPurple),
              const SizedBox(width: 8),
              const Text('Chat Not Open Yet'),
            ],
          ),
          content: Text(
            'Your session with the astrologer starts at '
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

    // Time has come — open the chat screen
    if (_currentUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: booking,
          otherUserName: booking.advisorName ?? 'Astrologer',
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
                              status: b.status == 'requested' ? 'Waiting' : (b.status == 'accepted' ? 'Approved' : b.status),
                              consultationType: b.consultationType,
                              amount: b.amount,
                              meetingLocation: b.meetingLocation,
                              actions: b.status == 'requested'
                                  ? [
                                      const Text('Waiting for Guru...', style: TextStyle(color: AppTheme.goldDark, fontStyle: FontStyle.italic, fontSize: 13, fontWeight: FontWeight.w600)),
                                      TextButton(
                                        onPressed: () => _cancelBooking(b.id),
                                        child: const Text('Cancel', style: TextStyle(color: AppTheme.error)),
                                      ),
                                    ]
                                  : b.status == 'accepted'
                                      ? [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _getPaymentTimeoutText(b.acceptedAt),
                                                style: const TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              ElevatedButton(
                                                onPressed: () => _initiatePayment(b),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, padding: const EdgeInsets.symmetric(horizontal: 20)),
                                                child: Text('Pay Rs. ${b.amount.toInt()}'),
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: () => _cancelBooking(b.id),
                                            child: const Text('Cancel', style: TextStyle(color: AppTheme.error)),
                                          ),
                                        ]
                                  : b.status == 'confirmed'
                                      ? [
                                          ElevatedButton(
                                            onPressed: () {
                                              if (_currentUser == null) return;
                                              _openChatWithTimeLock(b);
                                            },
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
                                            child: Text(b.consultationType == 'chat' ? 'Join Chat' : 'Join Session'),
                                          ),
                                        ]
                                      : b.status == 'completed'
                                          ? [
                                              if (!b.isReviewed)
                                                ElevatedButton(
                                                  onPressed: () => _showReviewDialog(b),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.goldDark,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  ),
                                                  child: const Text('Rate & Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                                )
                                              else
                                                const Text('Reviewed', style: TextStyle(color: AppTheme.success, fontSize: 13, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
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

  String _getPaymentTimeoutText(String? acceptedAtStr) {
    if (acceptedAtStr == null) return '';
    try {
      final acceptedAt = DateTime.parse(acceptedAtStr).toLocal();
      final now = DateTime.now();
      final diff = now.difference(acceptedAt);
      final remaining = const Duration(minutes: 5) - diff;

      if (remaining.isNegative) return 'Expired';
      
      final mins = remaining.inMinutes;
      final secs = remaining.inSeconds % 60;
      return 'Pay within $mins:${secs.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
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
                _loadBookings(); // Reload to hide the review button
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
