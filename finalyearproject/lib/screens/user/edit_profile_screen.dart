import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import '../../widgets/nepal_location_picker.dart';
import '../../services/location_service.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _pobController;
  late TextEditingController _latController;
  late TextEditingController _lonController;

  DateTime? _dob;
  TimeOfDay? _tob;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _pobController = TextEditingController(text: widget.user.pob ?? '');
    _latController = TextEditingController(text: widget.user.lat?.toString() ?? '');
    _lonController = TextEditingController(text: widget.user.lon?.toString() ?? '');

    if (widget.user.dob != null) {
      try {
        _dob = DateTime.parse(widget.user.dob!);
      } catch (e) {
        debugPrint('Error parsing DOB: $e');
      }
    }

    if (widget.user.tob != null) {
      try {
        final parts = widget.user.tob!.split(':');
        _tob = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (e) {
        debugPrint('Error parsing TOB: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pobController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ApiService.updateProfile({
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'pob': _pobController.text.trim(),
      'dob': _dob != null ? DateFormat('yyyy-MM-dd').format(_dob!) : null,
      'tob': _tob != null ? '${_tob!.hour.toString().padLeft(2, '0')}:${_tob!.minute.toString().padLeft(2, '0')}' : null,
      'lat': double.tryParse(_latController.text),
      'lon': double.tryParse(_lonController.text),
    });

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: AppTheme.success),
      );
      // We force a refresh of the user state by popping back the context.
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.darkText),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  hintText: 'Full Name',
                  prefixIcon: Icons.person,
                  validator: (v) => v == null || v.isEmpty ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Phone Number',
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Birth Details Section
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Birth Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryDark)),
                ),
                const Divider(),
                
                // DOB Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, color: AppTheme.goldDark),
                  title: const Text('Date of Birth'),
                  subtitle: Text(_dob == null ? 'Not set' : DateFormat('yyyy-MM-dd').format(_dob!)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dob ?? DateTime(1995, 1, 1),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _dob = picked);
                  },
                ),
                
                // TOB Picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: AppTheme.goldDark),
                  title: const Text('Time of Birth'),
                  subtitle: Text(_tob == null ? 'Not set' : _tob!.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _tob ?? const TimeOfDay(hour: 12, minute: 0),
                    );
                    if (picked != null) setState(() => _tob = picked);
                  },
                ),
                const Divider(),
                const SizedBox(height: 16),
                
                NepalLocationPicker(
                  initialValue: _pobController.text,
                  onLocationSelected: (loc) {
                    setState(() {
                      _pobController.text = loc.district;
                      _latController.text = loc.lat.toString();
                      _lonController.text = loc.lng.toString();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Lat/Lon Fields (Read-only or manual)
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _latController,
                        hintText: 'Latitude',
                        prefixIcon: Icons.map,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _lonController,
                        hintText: 'Longitude',
                        prefixIcon: Icons.explore,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save Changes',
                  isLoading: _isLoading,
                  onPressed: _handleUpdate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
