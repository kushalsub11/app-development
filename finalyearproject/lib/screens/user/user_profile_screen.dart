import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, this.user, this.onLogout});
  final UserModel? user;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppTheme.gold,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppTheme.greyText, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Menu Items
            _ProfileMenuItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.history,
              title: 'Payment History',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.report,
              title: 'My Reports',
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Logout',
              backgroundColor: AppTheme.error,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onLogout?.call();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.goldDark),
        title: Text(title, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.greyText),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
