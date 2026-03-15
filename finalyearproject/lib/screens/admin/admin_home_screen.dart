import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/advisors_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/payouts_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const UsersTab(),
    const AdvisorsTab(),
    const ReportsTab(),
    const PayoutsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
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
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user_rounded), label: 'Advisors'),
          BottomNavigationBarItem(icon: Icon(Icons.report_gmailerrorred_rounded), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Payouts'),
        ],
      ),
    );
  }
}
