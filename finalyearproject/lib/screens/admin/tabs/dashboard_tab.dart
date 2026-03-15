import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/widgets.dart';
import '../admin_bookings_screen.dart';
import '../admin_payments_screen.dart';
import 'users_tab.dart';
import 'advisors_tab.dart';
import 'reports_tab.dart';
import 'payouts_tab.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
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
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('All Users')), body: const UsersTab()))),
                        ),
                        _DashCard(
                          icon: Icons.person_pin,
                          title: 'Advisors',
                          value: '${_stats?['total_advisors'] ?? 0}',
                          color: AppTheme.accentPurple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('All Advisors')), body: const AdvisorsTab()))),
                        ),
                        _DashCard(
                          icon: Icons.verified,
                          title: 'Verified',
                          value: '${_stats?['verified_advisors'] ?? 0}',
                          color: AppTheme.success,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Verified Advisors')), body: const AdvisorsTab()))),
                        ),
                        _DashCard(
                          icon: Icons.pending,
                          title: 'Unverified',
                          value: '${_stats?['unverified_advisors'] ?? 0}',
                          color: AppTheme.warning,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Pending Advisors')), body: const AdvisorsTab()))),
                        ),
                        _DashCard(
                          icon: Icons.calendar_today,
                          title: 'Bookings',
                          value: '${_stats?['total_bookings'] ?? 0}',
                          color: const Color(0xFF00BCD4),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen())),
                        ),
                        _DashCard(
                          icon: Icons.account_balance_wallet,
                          title: 'Total Revenue',
                          value: 'Rs. ${(_stats?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                          color: AppTheme.gold,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsScreen())),
                        ),
                        _DashCard(
                          icon: Icons.pie_chart,
                          title: 'Admin Commission',
                          value: 'Rs. ${(_stats?['admin_earnings'] ?? 0).toStringAsFixed(0)}',
                          color: AppTheme.success,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentsScreen())),
                        ),
                        _DashCard(
                          icon: Icons.payments,
                          title: 'Advisor Payouts',
                          value: 'Rs. ${(_stats?['advisor_earnings'] ?? 0).toStringAsFixed(0)}',
                          color: AppTheme.accentPurple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Payout Requests')), body: const PayoutsTab()))),
                        ),
                        _DashCard(
                          icon: Icons.report_problem,
                          title: 'Pending Reports',
                          value: '${_stats?['pending_reports'] ?? 0}',
                          color: AppTheme.error,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: const Text('Detailed Reports')), body: const ReportsTab()))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _DashCard extends StatelessWidget {
  const _DashCard({required this.icon, required this.title, required this.value, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
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
      ),
    );
  }
}
