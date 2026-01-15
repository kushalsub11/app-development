import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import 'advisor_bookings_screen.dart';
import 'advisor_profile_screen.dart';

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

class _AdvisorHomeTab extends StatelessWidget {
  const _AdvisorHomeTab({this.user});
  final UserModel? user;

  @override
  Widget build(BuildContext context) {
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
                          image: user?.profileImage != null
                              ? DecorationImage(
                                  image: NetworkImage(user!.profileImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.profileImage == null
                            ? Center(
                                child: Text(
                                  user?.fullName.isNotEmpty == true ? user!.fullName[0].toUpperCase() : '?',
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
                              user?.fullName ?? 'Advisor',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Dashboard Insight Card
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
                          'Your Daily Summary',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'You have 2 upcoming consultations today. Keep inspiring those seeking guidance and answers.',
                          style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Overlapping Middle Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiddleActionButton(
                        icon: Icons.calendar_month,
                        label: 'Schedule',
                        color: AppTheme.accentPurple,
                        onTap: () {},
                        context: context,
                      ),
                      _buildMiddleActionButton(
                        icon: Icons.monetization_on,
                        label: 'Earnings',
                        color: AppTheme.goldDark,
                        onTap: () {},
                        context: context,
                      ),
                      _buildMiddleActionButton(
                        icon: Icons.chat_bubble,
                        label: 'Messages',
                        color: const Color(0xFF904CEE),
                        onTap: () {},
                        context: context,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Quick Stats Header
                  const Text('Quick Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText)),
                  const SizedBox(height: 14),

                  // Quick Stats Layer
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.calendar_today, title: 'Bookings', value: '12', color: AppTheme.info)),
                      const SizedBox(width: 14),
                      Expanded(child: _StatCard(icon: Icons.star, title: 'Rating', value: '4.8', color: AppTheme.goldDark)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.chat_bubble, title: 'Chats', value: '38', color: AppTheme.success)),
                      const SizedBox(width: 14),
                      Expanded(child: _StatCard(icon: Icons.account_balance_wallet, title: 'Revenue', value: '₹4k', color: AppTheme.accentPurple)),
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
        width: MediaQuery.of(context).size.width * 0.28,
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
