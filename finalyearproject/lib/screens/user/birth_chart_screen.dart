import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../../services/location_service.dart';

class BirthChartScreen extends StatefulWidget {
  final bool isAdvisorMode;
  const BirthChartScreen({super.key, this.isAdvisorMode = false});

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _dob = DateTime(1995, 1, 1);
  TimeOfDay _tob = const TimeOfDay(hour: 12, minute: 0);
  final _pobController = TextEditingController();
  final _latController = TextEditingController(text: '27.7172');
  final _lonController = TextEditingController(text: '85.3240');
  double _timezone = 5.75;
  bool _isLoading = true;
  bool _generated = false;
  Map<String, dynamic>? _chartData;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCachedChart();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pobController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedChart() async {
    // First try to get saved user profile to check for cached chart
    final user = await ApiService.getCurrentUser();
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });

    if (user != null) {
      // Pre-fill form with stored values
      _nameController.text = user.fullName;
      if (user.pob != null) _pobController.text = user.pob!;
      if (user.lat != null) _latController.text = user.lat!.toString();
      if (user.lon != null) {
        _lonController.text = user.lon!.toString();
        // Rough inference: Nepal is roughly east of 80.0
        _timezone = user.lon! > 80.0 ? 5.75 : 5.5;
      }
      if (user.dob != null) {
        try { _dob = DateTime.parse(user.dob!); } catch (_) {}
      }
      if (user.tob != null) {
        try {
          final parts = user.tob!.split(':');
          _tob = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (_) {}
      }

      // If chart already cached, show it immediately — no API call needed!
      if (user.birthChartSvg != null && user.planetDetails != null) {
        setState(() {
          _chartData = {
            'success': true,
            'chart_svg': user.birthChartSvg,
            'details': user.planetDetails,
          };
          _generated = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdvisorMode ? 'Client Birth Chart' : 'My Birth Chart (Kundali)'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          if (_generated)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Calculation',
              onPressed: () => setState(() => _generated = false),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _generated ? _buildChartResult() : _buildChartForm(),
            ),
    );
  }

  Widget _buildChartForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Discover Your Destiny',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
          ),
          const SizedBox(height: 8),
          const Text(
             'Enter your exact birth details to calculate your personalized Vedic astrology chart.',
             style: TextStyle(color: AppTheme.greyText, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryPurple.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPremiumTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: 'Date of Birth',
                        value: '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}',
                        icon: Icons.calendar_today_outlined,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dob,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryPurple)),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _dob = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: 'Time of Birth',
                        value: _tob.format(context),
                        icon: Icons.access_time,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context, 
                            initialTime: _tob,
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppTheme.primaryPurple)),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _tob = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Autocomplete<CityModel>(
                  initialValue: TextEditingValue(text: _pobController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return LocationService.searchCities(textEditingValue.text);
                  },
                  displayStringForOption: (CityModel city) => city.toString(),
                  onSelected: (CityModel city) {
                    setState(() {
                      _pobController.text = city.name;
                      _latController.text = city.lat.toString();
                      _lonController.text = city.lon.toString();
                      _timezone = city.timezone;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if (_pobController.text != controller.text && controller.text.isEmpty) {
                      controller.text = _pobController.text;
                    }
                    return _buildPremiumTextField(
                      controller: controller,
                      focusNode: focusNode,
                      label: 'Place of Birth',
                      hint: 'Search city...',
                      icon: Icons.location_on_outlined,
                      onChanged: (v) => _pobController.text = v,
                      validator: (v) => v!.isEmpty ? 'Place is required' : null,
                    );
                  },
                ),
                
                // Hidden lat/lon fields but kept for logic
                Visibility(
                  visible: false,
                  maintainState: true,
                  child: Column(
                    children: [
                      TextFormField(controller: _latController),
                      TextFormField(controller: _lonController),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple))
            : SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _generateChart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Generate Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    FocusNode? focusNode,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.darkText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.greyText),
        prefixIcon: Icon(icon, color: AppTheme.lightPurple),
        filled: true,
        fillColor: AppTheme.primaryPurple.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryPurple, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red, width: 1)),
      ),
    );
  }

  Widget _buildDateTimePicker({required String label, required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.lightPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkText, fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateChart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dobStr = '${_dob.day.toString().padLeft(2, '0')}/${_dob.month.toString().padLeft(2, '0')}/${_dob.year}';
    final tobStr = '${_tob.hour.toString().padLeft(2, '0')}:${_tob.minute.toString().padLeft(2, '0')}';
    final lat = double.tryParse(_latController.text) ?? 27.7172;
    final lon = double.tryParse(_lonController.text) ?? 85.3240;

    final result = await ApiService.generateBirthChart(
      dob: dobStr,
      tob: tobStr,
      lat: lat,
      lon: lon,
      timezone: _timezone,
    );

    if (mounted) {
      if (result['success'] == true) {
        // Normalize details - sometimes APIs return double-encoded JSON strings
        dynamic details = result['details'];
        if (details is String) {
          try { details = jsonDecode(details); } catch (_) {}
        }

        // If it's the USER generating for THEMSELVES, save to their profile
        if (!widget.isAdvisorMode) {
          await ApiService.updateProfile({
            'dob': '${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}',
            'tob': tobStr,
            'pob': _pobController.text,
            'lat': lat,
            'lon': lon,
            'birth_chart_svg': result['chart_svg'],
            'planet_details': details is Map || details is List ? details : null,
          });
        }

        setState(() {
          _chartData = {
            'success': true,
            'chart_svg': result['chart_svg'],
            'details': details,
          };
          _generated = true;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Could not generate chart.'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  List<Widget> _buildPlanetRows() {
    if (_chartData == null || _chartData!['details'] == null) return [const Text('No data')];
    
    dynamic details = _chartData!['details'];
    
    // Safety check: if details is a String, try to decode it once more
    if (details is String) {
      try { details = jsonDecode(details); } catch (_) {}
    }
    
    if (details is List) {
      return details.map((p) {
        if (p == null || p is! Map) return const SizedBox.shrink();
        final name = p['full_name'] ?? p['name'] ?? 'Planet';
        final zodiac = p['zodiac'] ?? 'Unknown';
        final degree = p['local_degree'] ?? p['global_degree'] ?? p['full_degree'] ?? 0.0;
        final degreeStr = degree is num ? degree.toStringAsFixed(1) : degree.toString();
        return _buildChartRow(name, '$zodiac ($degreeStr°)');
      }).toList();
    } else if (details is Map) {
      // Handle the Vedic API "0", "1", "2" or planet-name keyed map
      return details.entries.map((entry) {
        final p = entry.value;
        if (p == null || p is! Map) return const SizedBox.shrink();
        final name = p['full_name'] ?? p['name'] ?? entry.key;
        final zodiac = p['zodiac'] ?? 'Unknown';
        final degree = p['local_degree'] ?? p['global_degree'] ?? p['full_degree'] ?? 0.0;
        final degreeStr = degree is num ? degree.toStringAsFixed(1) : degree.toString();
        return _buildChartRow(name, '$zodiac ($degreeStr°)');
      }).toList();
    }
    
    return [const Text('Invalid planetary data format', style: TextStyle(color: AppTheme.greyText))];
  }

  Widget _buildChartResult() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryPurple, AppTheme.primaryDark],
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.stars, size: 64, color: AppTheme.gold),
              const SizedBox(height: 16),
              Text(
                _nameController.text,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                'Birth Chart & Planetary Alignment',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8), letterSpacing: 0.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.gold, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Saved to your Profile',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Chart Visual
        if (_chartData?['chart_svg'] != null) ...[
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.primaryPurple, size: 20),
              SizedBox(width: 8),
              Text('Celestial Map', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SvgPicture.string(
                _chartData!['chart_svg'],
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
        
        // Planet Positions Table
        const Row(
          children: [
            Icon(Icons.list_alt_rounded, color: AppTheme.primaryPurple, size: 20),
            SizedBox(width: 8),
            Text('Planetary Degrees', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkText)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: const Row(
                  children: [
                    Expanded(child: Text('Planet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.greyText))),
                    Expanded(child: Text('Sign', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.greyText))),
                    Text('Degree', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.greyText)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: _buildPlanetRows(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Home'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.primaryPurple),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _generated = false),
                icon: const Icon(Icons.refresh),
                label: const Text('Recalculate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChartRow(String planet, String value) {
    // Value format is "Zodiac (Degree°)"
    final parts = value.split(' (');
    final zodiac = parts[0];
    final degree = parts.length > 1 ? parts[1].replaceAll(')', '') : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.primaryPurple.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(planet, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          Expanded(child: Text(zodiac, style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w600, fontSize: 14))),
          Text(degree, style: const TextStyle(color: AppTheme.greyText, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
