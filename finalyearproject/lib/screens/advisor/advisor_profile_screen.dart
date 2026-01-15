import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';

class AdvisorProfileScreen extends StatefulWidget {
  const AdvisorProfileScreen({super.key, this.user, this.onLogout});
  final UserModel? user;
  final VoidCallback? onLogout;

  @override
  State<AdvisorProfileScreen> createState() => _AdvisorProfileScreenState();
}

class _AdvisorProfileScreenState extends State<AdvisorProfileScreen> {
  final _bioController = TextEditingController();
  final _specController = TextEditingController();
  final _expController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _bioController.dispose();
    _specController.dispose();
    _expController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final success = await ApiService.updateAdvisorProfile({
      'bio': _bioController.text,
      'specialization': _specController.text,
      'experience_years': int.tryParse(_expController.text) ?? 0,
      'hourly_rate': double.tryParse(_rateController.text) ?? 0,
    });
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!'), backgroundColor: AppTheme.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  widget.user?.fullName.isNotEmpty == true ? widget.user!.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user?.fullName ?? 'Advisor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('⭐ Advisor', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),

            // Edit Profile Section
            if (_isEditing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _specController,
                      decoration: const InputDecoration(labelText: 'Specialization', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Hourly Rate (Rs.)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isEditing = false),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PrimaryButton(
                            label: 'Save',
                            isLoading: _isSaving,
                            onPressed: _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else ...[
              _ProfileMenuItem(
                icon: Icons.edit,
                title: 'Edit Advisor Profile',
                onTap: () => setState(() => _isEditing = true),
              ),
              _ProfileMenuItem(icon: Icons.bar_chart, title: 'My Earnings', onTap: () {}),
              _ProfileMenuItem(icon: Icons.verified, title: 'Verification Status', onTap: () {}),
              _ProfileMenuItem(icon: Icons.help, title: 'Help & Support', onTap: () {}),
            ],

            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Logout',
              backgroundColor: AppTheme.error,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure?'),
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
        title: Text(title, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.greyText),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
