import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

class PayoutsTab extends StatefulWidget {
  const PayoutsTab({super.key});

  @override
  State<PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends State<PayoutsTab> {
  List<PayoutRequestModel> _payouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayouts();
  }

  Future<void> _loadPayouts() async {
    final payouts = await ApiService.getAllPayoutRequestsAdmin();
    setState(() {
      _payouts = payouts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Manage Payouts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _loadPayouts,
                    child: _payouts.isEmpty
                      ? const EmptyState(icon: Icons.payments, title: 'No Payout Requests', subtitle: 'Everything is paid up!')
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _payouts.length,
                          itemBuilder: (context, index) {
                            final p = _payouts[index];
                            return _PayoutCard(
                              payout: p,
                              onRefresh: _loadPayouts,
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

class _PayoutCard extends StatefulWidget {
  const _PayoutCard({required this.payout, required this.onRefresh});
  final PayoutRequestModel payout;
  final VoidCallback onRefresh;

  @override
  State<_PayoutCard> createState() => _PayoutCardState();
}

class _PayoutCardState extends State<_PayoutCard> {
  final _notesController = TextEditingController();
  bool _isActing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payout;
    final isPending = p.status == 'pending';
    
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
                Text('Rs. ${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.accentPurple)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.status == 'pending' ? AppTheme.warning.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.status == 'pending' ? AppTheme.warning : AppTheme.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Advisor ID: ${p.advisorId}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Payment Details: ${p.paymentDetails}', style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
            if (p.adminNotes != null) ...[
              const SizedBox(height: 8),
              Text('Note: ${p.adminNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(hintText: 'Admin Notes (Txn ID, etc.)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isActing ? null : () async {
                        setState(() => _isActing = true);
                        await ApiService.updatePayoutStatus(p.id, 'rejected', notes: _notesController.text);
                        widget.onRefresh();
                      },
                      child: const Text('Reject', style: TextStyle(color: AppTheme.error)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isActing ? null : () async {
                        setState(() => _isActing = true);
                        await ApiService.updatePayoutStatus(p.id, 'completed', notes: _notesController.text);
                        widget.onRefresh();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      child: const Text('Mark Paid'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
