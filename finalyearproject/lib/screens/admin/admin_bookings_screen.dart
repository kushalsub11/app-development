import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final bookings = await ApiService.getAllBookings();
    if (mounted) {
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('All Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: _bookings.isEmpty
                  ? const EmptyState(icon: Icons.calendar_today, title: 'No Bookings', subtitle: 'No one has booked yet.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final b = _bookings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Booking #${b.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                                    StatusBadge(status: b.status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: AppTheme.accentPurple),
                                    const SizedBox(width: 8),
                                    Text('User: ${b.userName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, size: 16, color: AppTheme.gold),
                                    const SizedBox(width: 8),
                                    Text('Advisor: ${b.advisorName}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 16, color: AppTheme.greyText),
                                    const SizedBox(width: 8),
                                    Text(b.bookingDate, style: const TextStyle(color: AppTheme.darkText)),
                                    const Spacer(),
                                    const Icon(Icons.access_time, size: 16, color: AppTheme.greyText),
                                    const SizedBox(width: 8),
                                    Text('${b.startTime} (${b.durationMins} min)', style: const TextStyle(color: AppTheme.darkText)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Amount: Rs. ${b.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accentPurple)),
                                    if (b.status == 'confirmed')
                                      TextButton.icon(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Cancel & Refund?'),
                                              content: Text('Do you want to refund booking #${b.id}?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                                  child: const Text('Yes, Refund'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            final success = await ApiService.refundBookingPayment(b.id);
                                            if (success) {
                                              _loadBookings();
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment refunded successfully')));
                                              }
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.money_off, size: 14, color: AppTheme.error),
                                        label: const Text('Refund', style: TextStyle(color: AppTheme.error, fontSize: 12)),
                                      )
                                    else
                                      Text('Type: ${b.consultationType.toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
