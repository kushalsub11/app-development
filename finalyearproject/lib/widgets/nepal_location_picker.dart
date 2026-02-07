import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nepal_location.dart';
import '../config/theme.dart';

class NepalLocationPicker extends StatefulWidget {
  final Function(NepalLocation) onLocationSelected;
  final String? initialValue;
  final String label;
  final String hint;

  const NepalLocationPicker({
    super.key,
    required this.onLocationSelected,
    this.initialValue,
    this.label = "Birthplace",
    this.hint = "Search city or district in Nepal",
  });

  @override
  State<NepalLocationPicker> createState() => _NepalLocationPickerState();
}

class _NepalLocationPickerState extends State<NepalLocationPicker> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  
  OverlayEntry? _overlayEntry;
  List<NepalLocation> _allLocations = [];
  List<NepalLocation> _filteredLocations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue ?? "";
    _loadLocations();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      } else if (_controller.text.isNotEmpty) {
        _showOverlay();
      }
    });
  }

  Future<void> _loadLocations() async {
    try {
      final String response = await rootBundle.loadString('assets/data/nepal_places.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _allLocations = data.map((e) => NepalLocation.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading nepal places: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterLocations(String query) {
    if (query.isEmpty) {
      _hideOverlay();
      return;
    }

    final String lowerQuery = query.toLowerCase();
    setState(() {
      _filteredLocations = _allLocations.where((loc) {
        return loc.district.toLowerCase().contains(lowerQuery) ||
               loc.province.toLowerCase().contains(lowerQuery) ||
               loc.hq.toLowerCase().contains(lowerQuery);
      }).toList();
    });

    if (_filteredLocations.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.inputBorder.withOpacity(0.3)),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  ..._filteredLocations.map((loc) => ListTile(
                    title: Text(loc.district, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                    subtitle: Text("${loc.hq}, ${loc.province}"),
                    onTap: () {
                      _controller.text = loc.district;
                      widget.onLocationSelected(loc);
                      _hideOverlay();
                      _focusNode.unfocus();
                    },
                  )),
                  if (_filteredLocations.isEmpty)
                    ListTile(
                      leading: const Icon(Icons.add_location_alt, color: AppTheme.accentPurple),
                      title: Text("Use \"${_controller.text}\""),
                      subtitle: const Text("Location not in local list - coordinates will be null"),
                      onTap: () {
                        widget.onLocationSelected(NepalLocation(
                          district: _controller.text,
                          province: "Manual Entry",
                          hq: "",
                          lat: 0.0,
                          lng: 0.0,
                        ));
                        _hideOverlay();
                        _focusNode.unfocus();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _filterLocations,
            style: const TextStyle(color: AppTheme.darkText),
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: const Icon(Icons.location_on, color: AppTheme.accentPurple),
              suffixIcon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                : IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _controller.clear();
                      _hideOverlay();
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
