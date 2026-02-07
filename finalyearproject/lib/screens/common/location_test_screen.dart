import 'package:flutter/material.dart';
import '../../widgets/nepal_location_picker.dart';
import '../../models/nepal_location.dart';
import '../../config/theme.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key});

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  NepalLocation? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Birthplace Picker Demo"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nepal Location Picker",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Type a district or headquarters name to see autocomplete in action. The coordinates are fetched instantly from local data.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            
            NepalLocationPicker(
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                });
                debugPrint("Selected: ${location.district} (${location.lat}, ${location.lng})");
              },
            ),
            
            const SizedBox(height: 40),
            if (_selectedLocation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.success),
                        SizedBox(width: 8),
                        Text(
                          "Selection Structured Data",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _buildDataRow("Place Name", _selectedLocation!.displayName),
                    _buildDataRow("Headquarters", _selectedLocation!.hq),
                    _buildDataRow("Province", _selectedLocation!.province),
                    _buildDataRow("Latitude", _selectedLocation!.lat.toString()),
                    _buildDataRow("Longitude", _selectedLocation!.lng.toString()),
                    const SizedBox(height: 20),
                    const Text(
                      "JSON Output:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Container(
                      margin: const EdgeInsets.top(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedLocation!.toJson().toString(),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Opacity(
                    opacity: 0.5,
                    child: Column(
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "Result will appear here",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.greyText, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppTheme.darkText, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
extension on EdgeInsets {
  static EdgeInsets top(double value) => EdgeInsets.only(top: value);
}
