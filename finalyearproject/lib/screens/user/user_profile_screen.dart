import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import 'payment_history_screen.dart';
import 'my_reports_screen.dart';
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, this.user, this.onLogout});
  final UserModel? user;
  final VoidCallback? onLogout;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isUploadingImg = false;
  UserModel? _updatedUser;

  @override
  void initState() {
    super.initState();
    _updatedUser = widget.user;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingImg = true);
    final user = await ApiService.uploadProfileImage(image.path);
    setState(() {
      _isUploadingImg = false;
      if (user != null) _updatedUser = user;
    });
    if (user != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated!'), backgroundColor: AppTheme.success),
      );
    }
  }

  Widget _buildPlaceholder() {
    final displayedUser = _updatedUser ?? widget.user;
    return Center(
      child: Text(
        displayedUser?.fullName.isNotEmpty == true ? displayedUser!.fullName[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedUser = _updatedUser ?? widget.user;
    final String? profileImgUrl = ApiConfig.getImageUrl(displayedUser?.profileImage);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar with edit
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.gold,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: _isUploadingImg
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : (profileImgUrl != null && profileImgUrl.isNotEmpty)
                              ? Image.network(profileImgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder())
                              : _buildPlaceholder(),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppTheme.accentPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayedUser?.fullName ?? 'User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
            const SizedBox(height: 6),
            Text(
              displayedUser?.email ?? '',
              style: TextStyle(color: AppTheme.greyText, fontSize: 15),
            ),
            const SizedBox(height: 30),

            // Menu Items
            _ProfileMenuItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () async {
                if (displayedUser != null) {
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: displayedUser))
                  );
                  if (result == true) {
                    final updated = await ApiService.getCurrentUser();
                    if (updated != null && mounted) {
                      setState(() => _updatedUser = updated);
                    }
                  }
                }
              },
            ),
            _ProfileMenuItem(
              icon: Icons.lock,
              title: 'Change Password',
              onTap: () {
                _showChangePasswordDialog();
              },
            ),
            _ProfileMenuItem(
              icon: Icons.history,
              title: 'Payment History',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()));
              },
            ),
            _ProfileMenuItem(
              icon: Icons.report,
              title: 'My Reports',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReportsScreen()));
              },
            ),
            _ProfileMenuItem(
              icon: Icons.help,
              title: 'Help & Support',
              onTap: () {
                _showHelpDialog();
              },
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
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          widget.onLogout?.call();
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

  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (newController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppTheme.error),
                        );
                        return;
                      }
                      if (newController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: AppTheme.error),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      final result = await ApiService.changePassword(
                        oldController.text,
                        newController.text,
                      );

                      if (mounted) {
                        setDialogState(() => isSubmitting = false);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? (result['success'] ? 'Password updated' : 'Update failed')),
                            backgroundColor: result['success'] ? AppTheme.success : AppTheme.error,
                          ),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance?', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Our support team is available 24/7 to help you with payment issues, report disputes, or technical difficulties.'),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, size: 20, color: AppTheme.accentPurple),
                SizedBox(width: 8),
                Text('sajeloguru@gmail.com'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 20, color: AppTheme.accentPurple),
                SizedBox(width: 8),
                Text('+977-9766047777'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.title, this.onTap});
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
        title: Text(title, style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.greyText),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
