import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    final payments = await ApiService.getAllPaymentsAdmin();
    if (mounted) {
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = _payments.fold(0, (sum, p) => sum + (p.status == 'completed' ? p.amount : 0));
    double adminCommission = totalRevenue * 0.30;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : Column(
              children: [
                // Summary Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppTheme.accentPurple,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatTile(title: 'Gross Revenue', value: 'Rs. ${totalRevenue.toStringAsFixed(0)}', color: Colors.white),
                      ),
                      Container(width: 1, height: 40, color: Colors.white24),
                      Expanded(
                        child: _StatTile(title: 'Admin Share (30%)', value: 'Rs. ${adminCommission.toStringAsFixed(0)}', color: AppTheme.gold),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPayments,
                    child: _payments.isEmpty
                        ? const EmptyState(icon: Icons.account_balance_wallet, title: 'No Transactions', subtitle: 'No payments have been processed.')
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _payments.length,
                            itemBuilder: (context, index) {
                              final p = _payments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: p.status == 'completed' ? AppTheme.success.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                                    child: Icon(
                                      p.status == 'completed' ? Icons.check_circle_outline : Icons.error_outline,
                                      color: p.status == 'completed' ? AppTheme.success : AppTheme.error,
                                    ),
                                  ),
                                  title: Text('Rs. ${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Booking #${p.bookingId} • ${p.paymentMethod.toUpperCase()}', style: const TextStyle(fontSize: 12)),
                                      if (p.paidAt != null) Text(p.paidAt!, style: const TextStyle(fontSize: 11, color: AppTheme.greyText)),
                                    ],
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(p.status.toUpperCase(), style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold, 
                                        color: p.status == 'completed' ? AppTheme.success : AppTheme.error
                                      )),
                                      if (p.transactionId != null) 
                                        Text('ID: ${p.transactionId!.substring(0, p.transactionId!.length > 8 ? 8 : p.transactionId!.length)}...', style: const TextStyle(fontSize: 10, color: AppTheme.greyText)),
                                    ],
                                  ),
                                ),
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

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatTile({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
