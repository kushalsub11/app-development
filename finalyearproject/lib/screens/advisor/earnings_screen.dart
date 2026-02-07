import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';
import 'payout_history_screen.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ApiService.getAdvisorStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _showRequestPayoutDialog() {
    final balance = (_stats?['available_balance'] ?? 0.0) as double;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available Balance: ₹${balance.toStringAsFixed(2)}', 
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount to Cash Out',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Payment Details',
                  hintText: 'e.g. eSewa ID, Khalti ID or Bank Info',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Min payout: ₹500', style: TextStyle(fontSize: 11, color: AppTheme.greyText)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => _submitPayoutRequest(balance),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
            child: const Text('Submit Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPayoutRequest(double balance) async {
    final amountText = _amountController.text.trim();
    final details = _detailsController.text.trim();
    
    if (amountText.isEmpty || details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    
    final amount = double.tryParse(amountText);
    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum payout is ₹500')));
      return;
    }
    
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    Navigator.pop(context); // Close dialog
    setState(() => _isLoading = true);
    
    final success = await ApiService.createPayoutRequest(amount, details);
    if (success) {
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout request submitted successfully!'), backgroundColor: AppTheme.success),
        );
        _amountController.clear();
        _detailsController.clear();
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalRevenue = (_stats?['total_revenue'] ?? 0.0) as double;
    final commission = (_stats?['commission_cut'] ?? 0.0) as double;
    final netRevenue = (_stats?['net_revenue'] ?? 0.0) as double;
    final withdrawn = (_stats?['withdrawn_amount'] ?? 0.0) as double;
    final balance = (_stats?['available_balance'] ?? 0.0) as double;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('My Earnings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PayoutHistoryScreen())),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentPurple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('₹${balance.toStringAsFixed(2)}', 
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: balance >= 500 ? _showRequestPayoutDialog : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.accentPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              const Text('Revenue Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(child: _buildStatCard('Total Earned', '₹${totalRevenue.toStringAsFixed(0)}', Icons.payments, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard('Total Withdrawn', '₹${withdrawn.toStringAsFixed(0)}', Icons.outbox, Colors.orange)),
                ],
              ),
              const SizedBox(height: 20),

              // Commission Breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Earnings Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    _buildBreakdownRow('Gross Revenue', '₹${totalRevenue.toStringAsFixed(2)}'),
                    _buildBreakdownRow('System Fee (30%)', '- ₹${commission.toStringAsFixed(2)}', isNegative: true),
                    const Divider(height: 30),
                    _buildBreakdownRow('Net Earnings', '₹${netRevenue.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payout info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.info.withOpacity(0.1))
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payout requests are typically processed within 24-48 working hours.',
                        style: TextStyle(fontSize: 12, color: AppTheme.darkText),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.darkText)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.greyText)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isNegative = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 15 : 14, 
            color: isTotal ? AppTheme.darkText : AppTheme.greyText,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
            color: isNegative ? Colors.red : (isTotal ? AppTheme.accentPurple : AppTheme.darkText)
          )),
        ],
      ),
    );
  }
}
