import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'advisor_detail_screen.dart';
import '../../widgets/nepal_location_picker.dart';

class BrowseAdvisorsScreen extends StatefulWidget {
  const BrowseAdvisorsScreen({super.key});

  @override
  State<BrowseAdvisorsScreen> createState() => _BrowseAdvisorsScreenState();
}

class _BrowseAdvisorsScreenState extends State<BrowseAdvisorsScreen> {
  List<AdvisorModel> _advisors = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedReligion = 'All';
  String? _selectedLocation;
  bool _showOnlyFavorites = false;

  final List<String> _categories = [
    'All',
    'Puja',
    'Harauna',
    'Kundali',
    'Jyotish',
    'Vastu',
    'Marriage',
    'Career',
    'Health',
    'Education',
  ];

  final List<String> _religions = [
    'All',
    'Hindu',
    'Buddhist',
    'Kirat',
    'Christian',
    'Muslim',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    setState(() => _isLoading = true);
    
    // Fetch in parallel for speed
    final responses = await Future.wait([
      ApiService.getAdvisors(
        specialization: _selectedCategory == 'All' ? null : _selectedCategory,
        religion: _selectedReligion == 'All' ? null : _selectedReligion,
        location: _selectedLocation,
      ),
      ApiService.getFavorites(),
    ]);

    final advisors = responses[0] as List<AdvisorModel>;
    final favoriteIds = responses[1] as List<int>;

    // Sync favorites
    for (var advisor in advisors) {
      if (favoriteIds.contains(advisor.id)) {
        advisor.isFavorite = true;
      }
    }

    setState(() {
      _advisors = advisors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF381b85), // Deep purple
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(right: 8.0, top: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: _showOnlyFavorites 
                    ? AppTheme.goldDark.withOpacity(0.3) 
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: _showOnlyFavorites 
                    ? Border.all(color: AppTheme.goldDark, width: 1.5)
                    : null,
              ),
              child: IconButton(
                icon: Icon(
                  _showOnlyFavorites ? Icons.favorite : Icons.favorite_border, 
                  color: _showOnlyFavorites ? AppTheme.goldDark : Colors.white, 
                  size: 20
                ),
                onPressed: () {
                  setState(() => _showOnlyFavorites = !_showOnlyFavorites);
                  if (_showOnlyFavorites) {
                    final favCount = _advisors.where((a) => a.isFavorite).length;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Showing $favCount favorite advisors'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      )
                    );
                  }
                },
              ),
            ),
          ),
        ],
        title: const Text(
          'Browse Astrologers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      endDrawer: _buildFilterDrawer(),
      body: ResponsiveContainer(
        maxWidth: 600,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name or specialization...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onSubmitted: (val) {
                        // Logic for search can be added here or dynamically
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = category);
                            _loadAdvisors();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.goldDark : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.filter_alt, size: 16, color: AppTheme.primaryDark),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: isSelected ? AppTheme.primaryDark : Colors.white,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F7F9),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Showing ',
                                style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: _isLoading ? '...' : '${_advisors.where((a) => !_showOnlyFavorites || a.isFavorite).length}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText),
                                  ),
                                  TextSpan(text: _showOnlyFavorites ? ' favorite available advisors' : ' advisors available right now'),
                                ],
                              ),
                            ),
                            if (_selectedLocation != null || _selectedReligion != 'All' || _showOnlyFavorites)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedReligion = 'All';
                                    _selectedLocation = null;
                                    _showOnlyFavorites = false;
                                  });
                                  _loadAdvisors();
                                },
                                child: const Text('Clear Filters', style: TextStyle(color: AppTheme.accentPurple, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _advisors.isEmpty
                                ? const Center(child: Text('No advisors found for the selected filters.'))
                                : ListView.builder(
                                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 4),
                                    itemCount: _advisors.where((a) => !_showOnlyFavorites || a.isFavorite).length,
                                    itemBuilder: (context, index) {
                                      final filteredList = _advisors.where((a) => !_showOnlyFavorites || a.isFavorite).toList();
                                      final advisor = filteredList[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: _CustomAdvisorCard(
                                          advisor: advisor,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => AdvisorDetailScreen(advisor: advisor),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Advanced Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  const Text('Religion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _religions.map((r) {
                      final isSelected = _selectedReligion == r;
                      return ChoiceChip(
                        label: Text(r),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _selectedReligion = r),
                        selectedColor: AppTheme.accentPurple.withOpacity(0.2),
                        labelStyle: TextStyle(color: isSelected ? AppTheme.accentPurple : Colors.black),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text('Location (Nepal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  NepalLocationPicker(
                    initialValue: _selectedLocation,
                    label: "Search District",
                    onLocationSelected: (loc) {
                      setState(() => _selectedLocation = loc.district);
                    },
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(_selectedLocation!),
                      onDeleted: () => setState(() => _selectedLocation = null),
                      deleteIcon: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = 'All';
                          _selectedReligion = 'All';
                          _selectedLocation = null;
                        });
                        _loadAdvisors();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Apply Filters',
                      onPressed: () {
                        _loadAdvisors();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomAdvisorCard extends StatefulWidget {
  final AdvisorModel advisor;
  final VoidCallback onTap;

  const _CustomAdvisorCard({
    required this.advisor,
    required this.onTap,
  });

  @override
  State<_CustomAdvisorCard> createState() => _CustomAdvisorCardState();
}

class _CustomAdvisorCardState extends State<_CustomAdvisorCard> {
  @override
  Widget build(BuildContext context) {
    final advisor = widget.advisor;
    final name = advisor.user?.fullName ?? 'Unknown Advisor';
    final specialization = advisor.specialization ?? 'Astrology Specialist';
    final rating = advisor.rating.toStringAsFixed(1);
    final reviews = advisor.totalReviews;
    final experience = advisor.experienceYears;
    final rate = advisor.hourlyRate.toInt();
    
    final isAvailable = advisor.isOnline;
    final statusColor = isAvailable ? const Color(0xFFE2F6EB) : const Color(0xFFFFF7E3);
    final statusTextColor = isAvailable ? const Color(0xFF00C853) : const Color(0xFFFDB000);
    final statusText = isAvailable ? 'Online' : 'Offline';
    final statusIcon = isAvailable ? Icons.check_circle : Icons.timer;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 65,
                        height: 65,
                        color: Colors.grey[200],
                        child: advisor.user?.profileImage != null
                            ? Image.network(ApiConfig.getImageUrl(advisor.user!.profileImage!), fit: BoxFit.cover)
                            : Icon(Icons.person, size: 30, color: Colors.grey[400]),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          size: 20,
                          color: statusTextColor,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final prev = advisor.isFavorite;
                              setState(() {
                                advisor.isFavorite = !prev; // Optimistic UI
                              });
                              final success = await ApiService.toggleFavorite(advisor.id);
                              if (!success) {
                                setState(() {
                                  advisor.isFavorite = prev; // Revert on failure
                                });
                              }
                            },
                            child: Icon(
                              advisor.isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: advisor.isFavorite ? Colors.red : AppTheme.inputBorder,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization,
                        style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (advisor.religion != null)
                        Text(
                          advisor.religion!,
                          style: TextStyle(fontSize: 11, color: AppTheme.accentPurple, fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.goldDark, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' ($reviews)',
                            style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.work_outline, color: AppTheme.inputBorder, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '$experience years',
                            style: const TextStyle(fontSize: 11, color: AppTheme.greyText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Rs. $rate',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.darkText,
                            ),
                          ),
                          const TextSpan(
                            text: '/session',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.lightPurple : AppTheme.inputBorder.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      isAvailable ? 'Book Now' : 'Unavailable',
                      style: TextStyle(
                        color: isAvailable ? Colors.white : AppTheme.darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
