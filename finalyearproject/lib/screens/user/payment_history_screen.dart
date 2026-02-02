import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await ApiService.getMyPayments();
    setState(() {
      _payments = payments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _payments.isEmpty
              ? const EmptyState(
                  icon: Icons.account_balance_wallet,
                  title: 'No Payments Yet',
                  subtitle: 'Your payment history will appear here once you make a booking.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final p = _payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: AppTheme.success),
                        ),
                        title: Text('Booking #${p.bookingId}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(p.paidAt != null ? p.paidAt!.split('T').first : ''),
                        trailing: Text(
                          'Rs. ${p.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.accentPurple),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
