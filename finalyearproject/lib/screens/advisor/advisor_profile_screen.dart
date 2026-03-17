import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../widgets/nepal_location_picker.dart';
import '../../services/api_service.dart';
import 'earnings_screen.dart';
import 'availability_settings_screen.dart';
import 'help_support_screen.dart';
import 'advisor_reviews_screen.dart';

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
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _officeController = TextEditingController();
  String? _selectedReligion;
  bool _isPhysicalAvailable = false;

  final List<String> _religions = ['Hindu', 'Buddhist', 'Kirat', 'Christian', 'Muslim', 'Others'];
  final List<String> _specializations = ['Puja', 'Harauna', 'Kundali', 'Jyotish', 'Vastu', 'Marriage', 'Career', 'Health', 'Education'];

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImg = false;
  bool _isUploadingCert = false;
  UserModel? _updatedUser;
  AdvisorModel? _advisorProfile;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _updatedUser = widget.user;
    _loadAdvisorProfile();
  }

  Future<void> _loadAdvisorProfile() async {
    final profile = await ApiService.getMyAdvisorProfile();
    if (mounted && profile != null) {
      setState(() {
        _advisorProfile = profile;
        _bioController.text = profile.bio ?? '';
        _specController.text = profile.specialization ?? '';
        _expController.text = profile.experienceYears.toString();
        _rateController.text = profile.hourlyRate.toString();
        _locationController.text = profile.location ?? '';
        _contactController.text = profile.contactNumber ?? '';
        _officeController.text = profile.officeAddress ?? '';
        _selectedReligion = profile.religion;
        _isPhysicalAvailable = profile.isPhysicalAvailable;
        if (profile.birthday != null) {
          try {
            _birthday = DateTime.parse(profile.birthday!);
          } catch (_) {}
        }
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _specController.dispose();
    _expController.dispose();
    _rateController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _officeController.dispose();
    super.dispose();
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated!'), backgroundColor: AppTheme.success),
      );
    }
  }

  Future<void> _pickAndUploadCertificate() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isUploadingCert = true);
    final advisor = await ApiService.uploadAdvisorCertificate(image.path);
    setState(() {
      _isUploadingCert = false;
      if (advisor != null) _advisorProfile = advisor;
    });

    if (mounted) {
      if (advisor != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate uploaded! Sent to admin for verification.'),
            backgroundColor: AppTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload certificate.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Widget _buildPlaceholder() {
    final displayedUser = _updatedUser ?? widget.user;
    return Center(
      child: Text(
        displayedUser?.fullName.isNotEmpty == true ? displayedUser!.fullName[0].toUpperCase() : '?',
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final Map<String, dynamic> data = {
      'bio': _bioController.text,
      'specialization': _specController.text,
      'experience_years': int.tryParse(_expController.text) ?? 0,
      'hourly_rate': double.tryParse(_rateController.text) ?? 0,
      'location': _locationController.text,
      'contact_number': _contactController.text,
      'is_physical_available': _isPhysicalAvailable,
      'office_address': _officeController.text,
      'religion': _selectedReligion,
    };
    if (_birthday != null) {
      data['birthday'] = '${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}';
    }

    final success = await ApiService.updateAdvisorProfile(data);
    if (success) await _loadAdvisorProfile();
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

  Widget _buildVerificationBadge() {
    final status = _advisorProfile?.verificationStatus ?? 'pending';
    final isBlocked = _advisorProfile?.isBlocked ?? false;

    Color color;
    String label;
    IconData icon;

    if (isBlocked) {
      color = AppTheme.error;
      label = '🚫 Blocked by Admin';
      icon = Icons.block;
    } else if (status == 'approved') {
      color = AppTheme.success;
      label = '✅ Verified';
      icon = Icons.verified;
    } else if (status == 'rejected') {
      color = AppTheme.error;
      label = '❌ Rejected';
      icon = Icons.cancel;
    } else {
      color = AppTheme.warning;
      label = '⏳ Pending Verification';
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
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
            // Profile Photo
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
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                    ),
                    child: ClipOval(
                      child: _isUploadingImg
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : profileImgUrl != null && profileImgUrl.isNotEmpty
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
                    decoration: BoxDecoration(color: AppTheme.accentPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              displayedUser?.fullName ?? 'Advisor',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
            ),
            const SizedBox(height: 8),
            _buildVerificationBadge(),
            const SizedBox(height: 24),

            // Certificate Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Professional Certificate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.darkText)),
                  const SizedBox(height: 8),
                  if (_advisorProfile?.certificatePdf != null)
                    Row(
                      children: [
                        const Icon(Icons.image, color: AppTheme.accentPurple),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Certificate Image uploaded', style: TextStyle(color: AppTheme.greyText))),
                      ],
                    )
                  else
                    const Text('No certificate uploaded yet.', style: TextStyle(color: AppTheme.greyText)),
                  const SizedBox(height: 12),
                  _isUploadingCert
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          onPressed: _pickAndUploadCertificate,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(_advisorProfile?.certificatePdf != null ? 'Replace Certificate Image' : 'Upload Certificate Image'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentPurple),
                        ),
                  const SizedBox(height: 4),
                  const Text(
                    'After uploading, your profile will be sent to admin for verification.',
                    style: TextStyle(fontSize: 11, color: AppTheme.greyText, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                    TextField(controller: _bioController, maxLines: 3, decoration: const InputDecoration(labelText: 'Bio', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _specializations.contains(_specController.text) ? _specController.text : null,
                      items: _specializations.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => _specController.text = v ?? ''),
                      decoration: const InputDecoration(labelText: 'Specialization (Service Type)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _religions.contains(_selectedReligion) ? _selectedReligion : null,
                      items: _religions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (v) => setState(() => _selectedReligion = v),
                      decoration: const InputDecoration(labelText: 'Religion', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    NepalLocationPicker(
                      label: "Current Location",
                      initialValue: _locationController.text,
                      onLocationSelected: (loc) {
                        _locationController.text = loc.district;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _contactController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    // Birthday Picker
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _birthday ?? DateTime(1990),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _birthday = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake, color: AppTheme.goldDark),
                            const SizedBox(width: 12),
                            Text(
                              _birthday != null
                                  ? 'Birthday: ${_birthday!.year}-${_birthday!.month.toString().padLeft(2, '0')}-${_birthday!.day.toString().padLeft(2, '0')}'
                                  : 'Select Birthday',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _expController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Experience (years)', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _rateController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Hourly Rate (Rs.)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    // Physical Consultation Toggle
                    SwitchListTile(
                      title: const Text('Available for Physical Consultation', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Let users know if you have a physical office/puja place'),
                      value: _isPhysicalAvailable,
                      activeThumbColor: AppTheme.accentPurple,
                      onChanged: (val) => setState(() => _isPhysicalAvailable = val),
                    ),
                    if (_isPhysicalAvailable) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _officeController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Office/Place Address',
                          hintText: 'e.g. Pashupatinath Area, Kathmandu',
                          prefixIcon: Icon(Icons.business_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
                        const SizedBox(width: 12),
                        Expanded(child: PrimaryButton(label: 'Save', isLoading: _isSaving, onPressed: _saveProfile)),
                      ],
                    ),
                  ],
                ),
              )
            else ...[
              _ProfileMenuItem(icon: Icons.edit, title: 'Edit Advisor Profile', onTap: () => setState(() => _isEditing = true)),
              _ProfileMenuItem(icon: Icons.bar_chart, title: 'My Earnings', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EarningsScreen()));
              }),
              _ProfileMenuItem(icon: Icons.reviews_outlined, title: 'Customer Reviews', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AdvisorReviewsScreen()));
              }),
              _ProfileMenuItem(icon: Icons.verified, title: 'Verification Status', onTap: () {
                final status = _advisorProfile?.verificationStatus ?? 'pending';
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Status: $status')));
              }),
              _ProfileMenuItem(icon: Icons.help, title: 'Help & Support', onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
              }),
              _ProfileMenuItem(
                icon: Icons.access_time_filled, 
                title: 'Availability & Slots', 
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AvailabilitySettingsScreen(profile: _advisorProfile!)),
                  );
                  if (result == true) _loadAdvisorProfile();
                }
              ),
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
                        onPressed: () { Navigator.pop(ctx); widget.onLogout?.call(); },
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
