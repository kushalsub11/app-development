import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../config/api_config.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const _DashboardTab(),
      const _ManageUsersTab(),
      const _ManageAdvisorsTab(),
      const _ManageReportsTab(),
      const _ManagePayoutsTab(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.accentPurple,
        unselectedItemColor: AppTheme.greyText,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Advisors'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Payouts'),
        ],
      ),
    );
  }
}

// ---------- Dashboard Tab ----------
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ApiService.getAdminDashboard();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text('Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppTheme.gold),
                        onPressed: () async {
                          await AuthService.logout();
                          if (!context.mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.3,
                    children: [
                      _DashCard(
                        icon: Icons.people,
                        title: 'Total Users',
                        value: '${_stats?['total_users'] ?? 0}',
                        color: AppTheme.info,
                      ),
                      _DashCard(
                        icon: Icons.person_pin,
                        title: 'Advisors',
                        value: '${_stats?['total_advisors'] ?? 0}',
                        color: AppTheme.accentPurple,
                      ),
                      _DashCard(
                        icon: Icons.verified,
                        title: 'Verified',
                        value: '${_stats?['verified_advisors'] ?? 0}',
                        color: AppTheme.success,
                      ),
                      _DashCard(
                        icon: Icons.pending,
                        title: 'Unverified',
                        value: '${_stats?['unverified_advisors'] ?? 0}',
                        color: AppTheme.warning,
                      ),
                      _DashCard(
                        icon: Icons.calendar_today,
                        title: 'Bookings',
                        value: '${_stats?['total_bookings'] ?? 0}',
                        color: const Color(0xFF00BCD4),
                      ),
                      _DashCard(
                        icon: Icons.account_balance_wallet,
                        title: 'Total Revenue',
                        value: 'Rs. ${(_stats?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                        color: AppTheme.gold,
                      ),
                      _DashCard(
                        icon: Icons.pie_chart,
                        title: 'Admin Commission',
                        value: 'Rs. ${(_stats?['admin_earnings'] ?? 0).toStringAsFixed(0)}',
                        color: AppTheme.success,
                      ),
                      _DashCard(
                        icon: Icons.payments,
                        title: 'Advisor Payouts',
                        value: 'Rs. ${(_stats?['advisor_earnings'] ?? 0).toStringAsFixed(0)}',
                        color: AppTheme.accentPurple,
                      ),
                      _DashCard(
                        icon: Icons.report_problem,
                        title: 'Pending Reports',
                        value: '${_stats?['pending_reports'] ?? 0}',
                        color: AppTheme.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.icon, required this.title, required this.value, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }
}

// ---------- Manage Users Tab ----------
class _ManageUsersTab extends StatefulWidget {
  const _ManageUsersTab();

  @override
  State<_ManageUsersTab> createState() => _ManageUsersTabState();
}

class _ManageUsersTabState extends State<_ManageUsersTab> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await ApiService.getAllUsers();
    setState(() {
      _users = users;
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
            child: Text('Manage Users', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.lightPurple,
                            child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${user.email}\nRole: ${user.role}'),
                          isThreeLine: true,
                          trailing: Switch(
                            value: user.isActive,
                            onChanged: (_) async {
                              await ApiService.toggleUserActive(user.id);
                              _loadUsers();
                            },
                            activeThumbColor: AppTheme.success,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------- Manage Advisors Tab ----------
class _ManageAdvisorsTab extends StatefulWidget {
  const _ManageAdvisorsTab();

  @override
  State<_ManageAdvisorsTab> createState() => _ManageAdvisorsTabState();
}

class _ManageAdvisorsTabState extends State<_ManageAdvisorsTab> {
  List<AdvisorModel> _advisors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    final advisors = await ApiService.getAllAdvisorsAdmin();
    setState(() {
      _advisors = advisors;
      _isLoading = false;
    });
  }

  Color _statusColor(String status, bool isBlocked) {
    if (isBlocked) return AppTheme.error;
    switch (status) {
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }

  String _statusLabel(String status, bool isBlocked) {
    if (isBlocked) return 'BLOCKED';
    switch (status) {
      case 'approved': return 'VERIFIED';
      case 'rejected': return 'REJECTED';
      default: return 'PENDING';
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
            child: Text('Manage Advisors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _advisors.length,
                    itemBuilder: (context, index) {
                      final a = _advisors[index];
                      final statusColor = _statusColor(a.verificationStatus, a.isBlocked);
                      final statusLabel = _statusLabel(a.verificationStatus, a.isBlocked);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.2),
                                    child: Icon(
                                      a.isBlocked ? Icons.block : (a.isVerified ? Icons.verified : Icons.pending),
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a.user?.fullName ?? 'Advisor #${a.id}',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                        ),
                                        Text(
                                          a.specialization ?? 'General',
                                          style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),

                              // Details
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              if (a.location != null && a.location!.isNotEmpty)
                                _DetailRow(icon: Icons.location_on, text: a.location!),
                              if (a.contactNumber != null && a.contactNumber!.isNotEmpty)
                                _DetailRow(icon: Icons.phone, text: a.contactNumber!),
                              if (a.birthday != null && a.birthday!.isNotEmpty)
                                _DetailRow(icon: Icons.cake, text: a.birthday!),
                              _DetailRow(icon: Icons.star, text: '${a.rating} rating | ${a.totalReviews} reviews'),

                              // Certificate PDF Link
                              if (a.certificatePdf != null) ...[
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: () {
                                    // Open the certificate URL
                                    _viewCertificate(context, a.certificatePdf!);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.image, color: Colors.blue, size: 18),
                                        SizedBox(width: 8),
                                        Text('View Certificate Photo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],

                              // Action Buttons
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: a.isBlocked ? null : () async {
                                        await ApiService.verifyAdvisor(a.id);
                                        _loadAdvisors();
                                      },
                                      icon: Icon(
                                        a.isVerified ? Icons.close : Icons.verified,
                                        size: 16,
                                      ),
                                      label: Text(a.isVerified ? 'Unverify' : 'Verify'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: a.isVerified ? AppTheme.warning : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(a.isBlocked ? 'Unblock Advisor' : 'Block Advisor'),
                                            content: Text(a.isBlocked
                                                ? 'Unblock ${a.user?.fullName}? They will appear on the platform again.'
                                                : 'Block ${a.user?.fullName}? They will be removed from public listing.'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: a.isBlocked ? AppTheme.success : AppTheme.error,
                                                ),
                                                child: Text(a.isBlocked ? 'Unblock' : 'Block'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await ApiService.blockAdvisor(a.id);
                                          _loadAdvisors();
                                        }
                                      },
                                      icon: Icon(a.isBlocked ? Icons.lock_open : Icons.block, size: 16),
                                      label: Text(a.isBlocked ? 'Unblock' : 'Block'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: a.isBlocked ? AppTheme.success : AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _viewCertificate(BuildContext context, String path) {
    // Ensure the path starts with a slash if not already
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConfig.baseUrl}$cleanPath';
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Text('Failed to load image', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.greyText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.greyText))),
        ],
      ),
    );
  }
}


// ---------- Manage Reports Tab ----------
class _ManageReportsTab extends StatefulWidget {
  const _ManageReportsTab();

  @override
  State<_ManageReportsTab> createState() => _ManageReportsTabState();
}

class _ManageReportsTabState extends State<_ManageReportsTab> {
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
                : _reports.isEmpty
                    ? const EmptyState(icon: Icons.report, title: 'No Reports', subtitle: 'All clear!')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _reports.length,
                        itemBuilder: (context, index) {
                          final r = _reports[index];
                          return _ReportCard(
                            report: r,
                            onRefresh: _loadReports,
                          );
                        },
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
            // Header
            Row(
              children: [
                const Icon(Icons.report_problem, color: AppTheme.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.reason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: r.status == 'pending'
                        ? AppTheme.warning.withOpacity(0.15)
                        : AppTheme.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    r.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: r.status == 'pending' ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Advisor: ${r.reportedAdvisorName ?? "ID: ${r.reportedAdvisorId}"}', style: const TextStyle(color: AppTheme.darkText, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('Reported By: ${r.reporterName ?? "ID: ${r.reporterId}"}', style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            if (r.description != null) ...[
              const SizedBox(height: 6),
              Text(r.description!, style: const TextStyle(color: AppTheme.darkText, fontSize: 13)),
            ],
            if (r.adminNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.lightPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Admin Note: ${r.adminNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ),
            ],

            if (r.status == 'pending') ...[
              const SizedBox(height: 12),
              // Admin notes input toggle
              GestureDetector(
                onTap: () => setState(() => _showNotes = !_showNotes),
                child: Text(
                  _showNotes ? '▲ Hide Notes' : '▼ Add Admin Notes (optional)',
                  style: const TextStyle(color: AppTheme.accentPurple, fontSize: 13),
                ),
              ),
              if (_showNotes) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Write admin notes...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(10),
                  ),
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
                  // Block Advisor Button
                  ElevatedButton.icon(
                    onPressed: _isActing ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Block Advisor?'),
                          content: Text('Block advisor #${r.reportedAdvisorId}? They will be removed from the platform.'),
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
                        await ApiService.updateReport(r.id, {
                          'status': 'resolved',
                          'admin_notes': _notesController.text.isEmpty ? 'Advisor blocked' : _notesController.text,
                        });
                        setState(() => _isActing = false);
                        widget.onRefresh();
                      }
                    },
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Block Advisor'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isActing ? null : () async {
                      setState(() => _isActing = true);
                      await ApiService.updateReport(r.id, {
                        'status': 'resolved',
                        'admin_notes': _notesController.text.isEmpty ? 'Resolved by admin' : _notesController.text,
                      });
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

// ---------- Manage Payouts Tab ----------
class _ManagePayoutsTab extends StatefulWidget {
  const _ManagePayoutsTab();

  @override
  State<_ManagePayoutsTab> createState() => _ManagePayoutsTabState();
}

class _ManagePayoutsTabState extends State<_ManagePayoutsTab> {
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                const Text('Payout Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_payouts.where((p) => p.status == 'pending').length} Pending',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _payouts.isEmpty
                    ? const EmptyState(icon: Icons.payments, title: 'No Payouts', subtitle: 'No withdrawal requests yet.')
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppTheme.warning;
      case 'approved': return AppTheme.success;
      case 'completed': return AppTheme.info;
      case 'rejected': return AppTheme.error;
      default: return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payout;
    final statusColor = _statusColor(p.status);

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
                CircleAvatar(
                  backgroundColor: AppTheme.lightPurple.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppTheme.accentPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.advisor?.user?.fullName ?? 'Advisor #${p.advisorId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Amount: ₹${p.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Payment Details:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
            Text(p.paymentDetails, style: const TextStyle(fontSize: 14)),
            if (p.adminNotes != null) ...[
              const SizedBox(height: 8),
              Text('Note: ${p.adminNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.greyText)),
            ],
            if (p.status == 'pending') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Add admin notes (optional)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isActing ? null : () => _updateStatus('rejected'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isActing ? null : () => _updateStatus('approved'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ] else if (p.status == 'approved') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isActing ? null : () => _updateStatus('completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.info),
                  child: const Text('Mark as Completed'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isActing = true);
    final success = await ApiService.updatePayoutStatus(widget.payout.id, status, notes: _notesController.text);
    setState(() => _isActing = false);
    if (success) {
      widget.onRefresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update payout')));
    }
  }
}

