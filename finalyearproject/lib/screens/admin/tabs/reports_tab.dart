import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../admin_chat_audit_screen.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await ApiService.getAllReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_reports.where((r) => r.status == 'pending').length} Pending',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _loadReports,
                    child: _reports.isEmpty
                        ? const EmptyState(icon: Icons.report, title: 'No Reports', subtitle: 'All clear!')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _reports.length,
                            itemBuilder: (context, index) {
                              return _ReportCard(
                                report: _reports[index],
                                onRefresh: _loadReports,
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

class _ReportCard extends StatefulWidget {
  const _ReportCard({required this.report, required this.onRefresh});
  final ReportModel report;
  final VoidCallback onRefresh;

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  final _notesController = TextEditingController();
  bool _showNotes = false;
  bool _isActing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem, color: AppTheme.warning),
                const SizedBox(width: 8),
                Expanded(child: Text(r.reason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.status == 'pending' ? AppTheme.warning.withOpacity(0.15) : AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: r.status == 'pending' ? AppTheme.warning : AppTheme.success),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Advisor: ${r.reportedAdvisorName ?? "ID: ${r.reportedAdvisorId}"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Reported By: ${r.reporterName ?? "ID: ${r.reporterId}"}', style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            
            if (r.description != null) ...[
              const SizedBox(height: 6),
              Text(r.description!, style: const TextStyle(fontSize: 13)),
            ],

            if (r.roomId != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminChatAuditScreen(
                              roomId: r.roomId!,
                              reporterName: r.reporterName ?? 'User',
                              reportedName: r.reportedAdvisorName ?? 'Advisor',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('View Evidence'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPurple,
                        side: const BorderSide(color: AppTheme.accentPurple),
                      ),
                    ),
                  ),
                  if (r.bookingId != null && r.status == 'pending') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isActing ? null : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Refund User?'),
                              content: Text('Cancel booking #${r.bookingId} and refund the payment?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                                  child: const Text('Refund & Cancel'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            setState(() => _isActing = true);
                            final success = await ApiService.refundBookingPayment(r.bookingId!);
                            if (success) {
                              await ApiService.updateReport(r.id, {
                                'status': 'resolved',
                                'admin_notes': 'Payment refunded to user due to valid report.'
                              });
                              widget.onRefresh();
                            }
                            if (mounted) setState(() => _isActing = false);
                          }
                        },
                        icon: const Icon(Icons.money_off, size: 16),
                        label: const Text('Refund'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (r.status == 'pending') ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _showNotes = !_showNotes),
                child: Text(_showNotes ? '▲ Hide Notes' : '▼ Add Admin Notes (optional)', style: const TextStyle(color: AppTheme.accentPurple, fontSize: 13)),
              ),
              if (_showNotes) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(hintText: 'Write admin notes...', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: _isActing ? null : () async {
                      setState(() => _isActing = true);
                      await ApiService.updateReport(r.id, {
                        'status': 'dismissed',
                        'admin_notes': _notesController.text.isEmpty ? null : _notesController.text,
                      });
                      setState(() => _isActing = false);
                      widget.onRefresh();
                    },
                    child: const Text('Dismiss', style: TextStyle(color: AppTheme.greyText)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isActing ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Block Advisor?'),
                          content: Text('Block advisor #${r.reportedAdvisorId}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                              child: const Text('Block'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        setState(() => _isActing = true);
                        await ApiService.blockAdvisor(r.reportedAdvisorId);
                        await ApiService.updateReport(r.id, {'status': 'resolved', 'admin_notes': 'Advisor blocked'});
                        setState(() => _isActing = false);
                        widget.onRefresh();
                      }
                    },
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Block'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isActing ? null : () async {
                      setState(() => _isActing = true);
                      await ApiService.updateReport(r.id, {'status': 'resolved', 'admin_notes': 'Resolved by admin'});
                      setState(() => _isActing = false);
                      widget.onRefresh();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                    child: const Text('Resolve'),
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
