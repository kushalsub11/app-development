import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

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
                        title: 'Revenue',
                        value: 'Rs. ${(_stats?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                        color: AppTheme.gold,
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
                            activeColor: AppTheme.success,
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
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: a.isVerified ? AppTheme.success : AppTheme.warning,
                            child: Icon(
                              a.isVerified ? Icons.verified : Icons.pending,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            a.user?.fullName ?? 'Advisor #${a.id}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${a.specialization ?? "N/A"}\nRating: ${a.rating} | Reviews: ${a.totalReviews}',
                          ),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            onPressed: () async {
                              await ApiService.verifyAdvisor(a.id);
                              _loadAdvisors();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: a.isVerified ? AppTheme.warning : AppTheme.success,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: Text(a.isVerified ? 'Unverify' : 'Verify'),
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
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Reports', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
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
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.report_problem, color: AppTheme.warning),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(r.reason, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                                  if (r.description != null) ...[
                                    const SizedBox(height: 8),
                                    Text(r.description!, style: const TextStyle(color: AppTheme.greyText)),
                                  ],
                                  const SizedBox(height: 10),
                                  if (r.status == 'pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () async {
                                            await ApiService.updateReport(r.id, {'status': 'dismissed'});
                                            _loadReports();
                                          },
                                          child: const Text('Dismiss', style: TextStyle(color: AppTheme.greyText)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await ApiService.updateReport(r.id, {'status': 'resolved', 'admin_notes': 'Resolved by admin'});
                                            _loadReports();
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                          child: const Text('Resolve'),
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
}
