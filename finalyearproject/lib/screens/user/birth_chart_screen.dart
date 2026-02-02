import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../services/api_service.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({super.key});

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime _dob = DateTime(1995, 1, 1);
  TimeOfDay _tob = const TimeOfDay(hour: 12, minute: 0);
  final _pobController = TextEditingController();
  final _latController = TextEditingController(text: '27.7172'); // Default Kathmandu
  final _lonController = TextEditingController(text: '85.3240'); // Default Kathmandu
  bool _isLoading = false;
  bool _generated = false;
  Map<String, dynamic>? _chartData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birth Chart (Kundali)'),
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
            'Generate your Horoscope',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkText),
          ),
          const SizedBox(height: 8),
          const Text(
             'Enter your birth details to get personalized insights from the stars.',
             style: TextStyle(color: AppTheme.greyText),
          ),
          const SizedBox(height: 30),
          
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 20),

          // Date of Birth
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppTheme.goldDark),
            title: const Text('Date of Birth'),
            subtitle: Text('${_dob.year}-${_dob.month.toString().padLeft(2, '0')}-${_dob.day.toString().padLeft(2, '0')}'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dob = picked);
            },
          ),
          const Divider(),

          // Time of Birth
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time, color: AppTheme.goldDark),
            title: const Text('Time of Birth'),
            subtitle: Text(_tob.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _tob);
              if (picked != null) setState(() => _tob = picked);
            },
          ),
          const Divider(),
          const SizedBox(height: 10),

          TextFormField(
            controller: _pobController,
            decoration: const InputDecoration(
              labelText: 'Place of Birth',
              hintText: 'City, Country',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Place is required' : null,
          ),
          TextFormField(
            controller: _latController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Latitude',
              prefixIcon: Icon(Icons.map),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Latitude required' : null,
          ),
          const SizedBox(height: 20),

          TextFormField(
            controller: _lonController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Longitude',
              prefixIcon: Icon(Icons.explore),
              border: OutlineInputBorder(),
            ),
            validator: (v) => v!.isEmpty ? 'Longitude required' : null,
          ),
          const SizedBox(height: 40),

          _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PrimaryButton(
                label: 'Generate Now',
                onPressed: _generateChart,
              ),
        ],
      ),
    );
  }

  Future<void> _generateChart() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dobStr = '${_dob.day.toString().padLeft(2, '0')}/${_dob.month.toString().padLeft(2, '0')}/${_dob.year}';
    final tobStr = '${_tob.hour.toString().padLeft(2, '0')}:${_tob.minute.toString().padLeft(2, '0')}';

    final result = await ApiService.generateBirthChart(
      dob: dobStr,
      tob: tobStr,
      lat: double.tryParse(_latController.text) ?? 27.7172,
      lon: double.tryParse(_lonController.text) ?? 85.3240,
    );

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _chartData = result;
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
    
    // Vedic Astro API returns planet details as a MAP or a LIST depending on endpoint
    // We'll handle it generically
    final details = _chartData!['details'];
    
    if (details is List) {
      return details.map((p) {
        return _buildChartRow(p['name'] ?? 'Planet', '${p['zodiac']} (${p['full_degree']?.toStringAsFixed(1) ?? '0'}°)');
      }).toList();
    } else if (details is Map) {
      return details.entries.map((entry) {
        final p = entry.value;
        return _buildChartRow(entry.key, '${p['zodiac']} (${p['full_degree']?.toStringAsFixed(1) ?? '0'}°)');
      }).toList();
    }
    
    return [const Text('Unknown data format')];
  }

  Widget _buildChartResult() {
    return Column(
      children: [
        const Icon(Icons.stars, size: 80, color: AppTheme.gold),
        const SizedBox(height: 20),
        Text(
          'Chart for ${_nameController.text}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your chart has been generated based on current alignments.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.greyText),
        ),
        const SizedBox(height: 30),
        
        // Chart Image (using SVG for web/mobile)
        if (_chartData?['chart_url'] != null)
          Container(
            height: 300,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(_chartData?['chart_url'], fit: BoxFit.contain,
                 errorBuilder: (_, __, ___) => const Center(child: Text('Note: Chart rendered as SVG. Use a browser to view if not visible here.')),
              ),
            ),
          ),
        
        // Planet Details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: _buildPlanetRows(),
          ),
        ),
        const SizedBox(height: 30),
        
        PrimaryButton(
          label: 'Back to Home',
          backgroundColor: AppTheme.greyText,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildChartRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
