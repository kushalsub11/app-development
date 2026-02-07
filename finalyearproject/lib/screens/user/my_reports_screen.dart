import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<ReportModel> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await ApiService.getMyReports();
    setState(() {
      _reports = reports;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _reports.isEmpty
              ? const EmptyState(
                  icon: Icons.report,
                  title: 'All Clear!',
                  subtitle: 'Reports you file against advisors will appear here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final r = _reports[index];
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
                                Icon(
                                  r.status == 'pending' ? Icons.timer : Icons.done_all,
                                  color: r.status == 'pending' ? AppTheme.warning : AppTheme.success,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: r.status == 'pending' ? AppTheme.warning : AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(r.reportedAdvisorName ?? 'Advisor #${r.reportedAdvisorId}', 
                                style: const TextStyle(fontSize: 13, color: AppTheme.greyText, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(r.reason, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            if (r.description != null) ...[
                              const SizedBox(height: 4),
                              Text(r.description!, style: const TextStyle(color: AppTheme.greyText)),
                            ],
                            if (r.adminNotes != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightPurple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('Admin: ${r.adminNotes}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
