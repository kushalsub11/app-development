import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  List<PayoutRequestModel> _payouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    final payouts = await ApiService.getMyPayoutRequests();
    if (mounted) {
      setState(() {
        _payouts = payouts;
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return AppTheme.warning;
      case 'approved': return AppTheme.success;
      case 'completed': return AppTheme.info;
      case 'rejected': return AppTheme.error;
      default: return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Cashout History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payouts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPayouts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _payouts.length,
                    itemBuilder: (context, index) {
                      final p = _payouts[index];
                      final color = _statusColor(p.status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: color.withOpacity(0.1),
                                    child: Icon(Icons.account_balance_wallet, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                                        Text(p.createdAt.split('T')[0], style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      p.status.toUpperCase(),
                                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              const Text('Payment Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                              const SizedBox(height: 4),
                              Text(p.paymentDetails, style: const TextStyle(fontSize: 13)),
                              if (p.adminNotes != null && p.adminNotes!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Admin Response:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
                                      const SizedBox(height: 4),
                                      Text(p.adminNotes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
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
          Icon(Icons.history, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No History Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
          const SizedBox(height: 8),
          const Text('Your payout requests will appear here.', style: TextStyle(color: AppTheme.greyText)),
        ],
      ),
    );
  }
}
