import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/widgets.dart';

class AvailabilitySettingsScreen extends StatefulWidget {
  final AdvisorModel profile;
  const AvailabilitySettingsScreen({super.key, required this.profile});

  @override
  State<AvailabilitySettingsScreen> createState() => _AvailabilitySettingsScreenState();
}

class _AvailabilitySettingsScreenState extends State<AvailabilitySettingsScreen> {
  late bool _isOnline;
  late bool _isVirtualAvailable;
  late bool _isPhysicalAvailable;
  Map<String, dynamic> _slots = {};
  bool _isSaving = false;

  final List<String> _days = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _isOnline = widget.profile.isOnline;
    _isVirtualAvailable = widget.profile.isVirtualAvailable;
    _isPhysicalAvailable = widget.profile.isPhysicalAvailable;
    if (widget.profile.availableSlots != null && widget.profile.availableSlots is Map) {
      _slots = Map<String, dynamic>.from(widget.profile.availableSlots);
    }
  }

  // Helper to update slots locally
  void _toggleDay(String day, bool enabled) {
    setState(() {
      if (enabled) {
        _slots[day] = [{"start": "09:00", "end": "17:00"}];
      } else {
        _slots.remove(day);
      }
    });
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    final success = await ApiService.updateAdvisorProfile({
      'is_online': _isOnline,
      'is_virtual_available': _isVirtualAvailable,
      'is_physical_available': _isPhysicalAvailable,
      'available_slots': _slots,
    });
    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability settings updated!'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update settings.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Availability Settings'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Live Visibility'),
            _buildToggleCard(
              title: 'Online Status',
              subtitle: 'When off, you are hidden from the browsing list',
              value: _isOnline,
              onChanged: (v) => setState(() => _isOnline = v),
              icon: Icons.visibility,
            ),
            const SizedBox(height: 16),
            
            _buildSectionHeader('Consultation Toggles'),
            _buildToggleCard(
              title: 'Virtual Meetings',
              subtitle: 'Accept chat, voice, and video calls',
              value: _isVirtualAvailable,
              onChanged: (v) => setState(() => _isVirtualAvailable = v),
              icon: Icons.computer,
            ),
            const SizedBox(height: 12),
            _buildToggleCard(
              title: 'Physical Meetings',
              subtitle: 'Allow users to book in-person visits',
              value: _isPhysicalAvailable,
              onChanged: (v) => setState(() => _isPhysicalAvailable = v),
              icon: Icons.location_on,
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Weekly Booking Slots'),
            const Text(
              'Set specific times when users can book you. For now, this defines your standard weekly availability.',
              style: TextStyle(fontSize: 13, color: AppTheme.greyText),
            ),
            const SizedBox(height: 12),
            ..._days.map((day) => _buildDaySlotTile(day)).toList(),
            
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _saveAvailability,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        secondary: Icon(icon, color: AppTheme.goldDark),
        value: value,
        activeColor: AppTheme.accentPurple,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDaySlotTile(String day) {
    final isEnabled = _slots.containsKey(day);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isEnabled ? AppTheme.accentPurple.withOpacity(0.2) : Colors.transparent),
      ),
      child: ExpansionTile(
        title: Text(day, style: TextStyle(fontWeight: isEnabled ? FontWeight.w700 : FontWeight.normal)),
        leading: Checkbox(
          value: isEnabled,
          onChanged: (v) => _toggleDay(day, v ?? false),
          activeColor: AppTheme.accentPurple,
        ),
        subtitle: Text(isEnabled ? 'Available' : 'Unavailable', style: TextStyle(fontSize: 12, color: isEnabled ? AppTheme.success : AppTheme.greyText)),
        children: [
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...(_slots[day] as List).map((slot) => Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppTheme.greyText),
                      const SizedBox(width: 8),
                      Text('${slot['start']} - ${slot['end']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      // In a real app, I'd add a time picker here
                    ],
                  )).toList(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Time range picker coming in next update!')));
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Time Range', style: TextStyle(fontSize: 12)),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }
}
