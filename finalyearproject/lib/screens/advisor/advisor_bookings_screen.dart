import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AdvisorBookingsScreen extends StatefulWidget {
  const AdvisorBookingsScreen({super.key});

  @override
  State<AdvisorBookingsScreen> createState() => _AdvisorBookingsScreenState();
}

class _AdvisorBookingsScreenState extends State<AdvisorBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await ApiService.getAdvisorBookings();
    setState(() {
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
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
