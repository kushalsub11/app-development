import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'advisor_bookings_screen.dart';
import 'advisor_profile_screen.dart';
import '../user/birth_chart_screen.dart';
import 'payout_history_screen.dart';
import '../common/notification_screen.dart';

class AdvisorHomeScreen extends StatefulWidget {
  const AdvisorHomeScreen({super.key});

  @override
  State<AdvisorHomeScreen> createState() => _AdvisorHomeScreenState();
}

class _AdvisorHomeScreenState extends State<AdvisorHomeScreen> {
  int _currentIndex = 0;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getSavedUser();
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _AdvisorHomeTab(user: _user),
      const AdvisorBookingsScreen(),
      AdvisorProfileScreen(user: _user, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.accentPurple,
        unselectedItemColor: AppTheme.greyText,
        selectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    // Navigate back to auth screen - using pushAndRemoveUntil with main App
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}

class _AdvisorHomeTab extends StatefulWidget {
  const _AdvisorHomeTab({this.user});
  final UserModel? user;

  @override
  State<_AdvisorHomeTab> createState() => _AdvisorHomeTabState();
}

class _AdvisorHomeTabState extends State<_AdvisorHomeTab> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadUnreadCount();
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

  Future<void> _loadUnreadCount() async {
    final count = await ApiService.getUnreadNotificationCount();
    if (mounted) {
      setState(() => _unreadNotifications = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      child: Stack(
        children: [
          // Purple Top Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF381b85),
              ),
            ),
          ),
          
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.gold,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.goldDark, width: 2),
                          image: widget.user?.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(widget.user!.profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.user?.profileImage == null
                            ? Center(
                                child: Text(
                                  widget.user?.fullName.isNotEmpty == true ? widget.user!.fullName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              widget.user?.fullName ?? 'Advisor',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationScreen()),
                              );
                              _loadUnreadCount();
                            },
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Insight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Your Dashboard',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Keep track of your performance and bookings here. Use the actions below for management.',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Layer
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.calendar_today, title: 'Bookings', value: '${_stats?['total_bookings'] ?? 0}', color: AppTheme.info)),
                      const SizedBox(width: 14),
                      Expanded(child: _StatCard(icon: Icons.star, title: 'Rating', value: '${_stats?['rating'] ?? 0.0}', color: AppTheme.goldDark)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.reviews, title: 'Reviews', value: '${_stats?['total_reviews'] ?? 0}', color: AppTheme.success)),
                      const SizedBox(width: 14),
                      Expanded(child: _StatCard(icon: Icons.account_balance_wallet, title: 'Available', value: '₹${(_stats?['available_balance'] ?? 0).toStringAsFixed(0)}', color: AppTheme.goldDark)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiddleActionButton(
                          context: context,
                          icon: Icons.auto_graph_rounded,
                          label: 'Client Kundali',
                          color: AppTheme.goldDark,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => BirthChartScreen(isAdvisorMode: true)),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _buildMiddleActionButton(
                          context: context,
                          icon: Icons.payments_rounded,
                          label: 'Cashout',
                          color: AppTheme.success,
                          onTap: () => _showCashoutDialog(context),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _buildMiddleActionButton(
                          context: context,
                          icon: Icons.history_rounded,
                          label: 'History',
                          color: AppTheme.info,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const PayoutHistoryScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleActionButton({required BuildContext context, required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.darkText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCashoutDialog(BuildContext context) {
    final amountController = TextEditingController();
    final detailsController = TextEditingController();
    final available = (_stats?['available_balance'] ?? 0.0).toDouble();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Cashout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available Balance: ₹${available.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (Min. 500)',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Payment Details (Bank/Khalti)',
                hintText: 'Account number or ID',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount < 500) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum cashout is 500 RS')));
                return;
              }
              if (amount > available) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                return;
              }
              if (detailsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide payment details')));
                return;
              }

              final success = await ApiService.createPayoutRequest(amount, detailsController.text);
              if (success) {
                Navigator.pop(ctx);
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted!'), backgroundColor: AppTheme.success));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit request'), backgroundColor: AppTheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.value, required this.color});
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.darkText)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
        ],
      ),
    );
  }
}
