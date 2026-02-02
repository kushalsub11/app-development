import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import 'browse_advisors_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'birth_chart_screen.dart';
import 'horoscope_screen.dart';
import 'advisor_detail_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
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
      _HomeTab(user: _user, onTabChange: (i) => setState(() => _currentIndex = i)),
      const BrowseAdvisorsScreen(),
      const UserBookingsScreen(),
      UserProfileScreen(user: _user, onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.accentPurple,
          unselectedItemColor: AppTheme.greyText,
          selectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const _AuthWrapper()),
      (route) => false,
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    _buildBrandHeader(),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLogin
                            ? const LoginScreen(key: ValueKey('login'))
                            : const RegisterScreen(key: ValueKey('register')),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          isLogin ? "Don't have an account?" : 'Already have an account?',
                          style: const TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => isLogin = !isLogin),
                          child: Text(
                            isLogin ? 'Create New Account' : 'Login',
                            style: const TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppTheme.gold,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.brightness_2_rounded, color: AppTheme.accentPurple, size: 38),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Sajelo Guru',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Your Astrology Companion',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({this.user, required this.onTabChange});
  final UserModel? user;
  final Function(int) onTabChange;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, String> _calendarInfo = {'nepali_date': 'Loading...', 'tithi': '', 'panchang': '', 'english_date': ''};
  List<dynamic> _horoscopes = [];
  List<AdvisorModel> _featuredAdvisors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeatured();
    _loadCalendar();
    _loadHoroscopes();
  }

  Future<void> _loadHoroscopes() async {
    final horoscopes = await ApiService.getDailyHoroscopes();
    if (mounted) setState(() => _horoscopes = horoscopes);
  }

  Future<void> _loadCalendar() async {
    final calendar = await ApiService.getDailyCalendar();
    if (mounted) setState(() => _calendarInfo = calendar);
  }

  Future<void> _loadFeatured() async {
    try {
      final advisors = await ApiService.getAdvisors();
      if (!mounted) return;
      setState(() {
        _featuredAdvisors = advisors.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => widget.onTabChange(3),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.goldDark, width: 2),
                            image: widget.user?.profileImage != null
                                ? DecorationImage(
                                    image: NetworkImage(ApiConfig.getImageUrl(widget.user!.profileImage)),
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Welcome back,', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              widget.user?.fullName ?? 'User',
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

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Icon(Icons.stars, size: 100, color: Colors.white.withOpacity(0.05)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.calendar_month, color: AppTheme.gold, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _calendarInfo['nepali_date']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _calendarInfo['tithi']!,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _calendarInfo['panchang']!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _calendarInfo['english_date']!,
                              style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildHoroscopeSection(),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiddleActionButton(
                        icon: Icons.people_alt,
                        label: 'Browse Advisors',
                        color: AppTheme.accentPurple,
                        onTap: () => widget.onTabChange(1),
                      ),
                      _buildMiddleActionButton(
                        icon: Icons.book_online,
                        label: 'My Bookings',
                        color: AppTheme.goldDark,
                        onTap: () => widget.onTabChange(2),
                      ),
                      _buildMiddleActionButton(
                        icon: Icons.chat_bubble,
                        label: 'Chat',
                        color: const Color(0xFF904CEE),
                        onTap: () => widget.onTabChange(2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Featured Astrologers',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText),
                      ),
                      GestureDetector(
                        onTap: () => widget.onTabChange(1),
                        child: const Text(
                          'View All',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.lightPurple),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _isLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      : _featuredAdvisors.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text('No featured advisors available yet.', style: TextStyle(color: AppTheme.greyText)),
                              ),
                            )
                          : Column(
                              children: _featuredAdvisors.map((advisor) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _WidgetRefCustomAdvisorCard(
                                    advisor: advisor,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AdvisorDetailScreen(advisor: advisor),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                  
                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5324A3), Color(0xFF812EBA)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Get Your Birth Chart',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Unlock personalized insights',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const BirthChartScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.goldDark,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Generate Now',
                                  style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.pie_chart, color: Colors.white24, size: 80),
                        ),
                      ],
                    ),
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

  Widget _buildHoroscopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daily Horoscopes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
            TextButton(
              onPressed: () {
                if (_horoscopes.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HoroscopeScreen(horoscopes: _horoscopes),
                    ),
                  );
                }
              },
              child: const Text('View Slider', style: TextStyle(color: AppTheme.primaryPurple, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _horoscopes.length,
            itemBuilder: (context, index) {
              final h = _horoscopes[index];
              return _buildHoroscopeItem(h);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHoroscopeItem(Map<String, dynamic> horoscope) {
    return GestureDetector(
      onTap: () => _showHoroscopeDetail(horoscope),
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                _getZodiacEmoji(horoscope['sign']),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              horoscope['sign'],
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkText),
            ),
          ],
        ),
      ),
    );
  }

  String _getZodiacEmoji(String sign) {
    final Map<String, String> emojis = {
      'मेष': '♈', 'वृष': '♉', 'मिथुन': '♊', 'कर्कट': '♋',
      'सिंह': '♌', 'कन्या': '♍', 'तुला': '♎', 'वृश्चिक': '♏',
      'धनु': '♐', 'मकर': '♑', 'कुम्भ': '♒', 'मीन': '♓',
    };
    return emojis[sign] ?? '✨';
  }

  void _showHoroscopeDetail(Map<String, dynamic> h) {
    int index = _horoscopes.indexOf(h);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HoroscopeScreen(horoscopes: _horoscopes, initialIndex: index),
      ),
    );
  }

  Widget _buildMiddleActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
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

class _WidgetRefCustomAdvisorCard extends StatelessWidget {
  final AdvisorModel advisor;
  final VoidCallback onTap;

  const _WidgetRefCustomAdvisorCard({
    required this.advisor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 65,
                    height: 65,
                    color: Colors.grey[200],
                    child: advisor.user?.profileImage != null
                        ? Image.network(advisor.user!.profileImage!, fit: BoxFit.cover)
                        : Icon(Icons.person, size: 30, color: Colors.grey[400]),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle, size: 18, color: Color(0xFF00C853)),
                  ),
                )
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          advisor.user?.fullName ?? 'Unknown',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkText),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    advisor.specialization ?? 'Astrology',
                    style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.goldDark, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        advisor.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ' (${advisor.totalReviews})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.work_outline, color: AppTheme.inputBorder, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        '${advisor.experienceYears} years exp',
                        style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFE2F6EB), borderRadius: BorderRadius.circular(20)),
                        child: const Text('Available Now', style: TextStyle(color: Color(0xFF00C853), fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '₹${advisor.hourlyRate.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.darkText)),
                            const TextSpan(text: '/session', style: TextStyle(fontSize: 11, color: AppTheme.greyText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
