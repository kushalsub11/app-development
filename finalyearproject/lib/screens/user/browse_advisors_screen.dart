import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import 'advisor_detail_screen.dart';

class BrowseAdvisorsScreen extends StatefulWidget {
  const BrowseAdvisorsScreen({super.key});

  @override
  State<BrowseAdvisorsScreen> createState() => _BrowseAdvisorsScreenState();
}

class _BrowseAdvisorsScreenState extends State<BrowseAdvisorsScreen> {
  List<AdvisorModel> _advisors = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Vedic Astrology',
    'Tarot Reading',
    'Numerology',
    'Palmistry',
  ];

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    final advisors = await ApiService.getAdvisors();
    setState(() {
      _advisors = advisors;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF381b85), // Deep purple from the image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Browse Astrologers',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite, color: Colors.white, size: 20),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Search and Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              children: [
                // Search Bar
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
                  ),
                ),
                const SizedBox(height: 16),
                
                // Categories List
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
                        onTap: () => setState(() => _selectedCategory = category),
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

          // Main White Container for List
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7F9), // Light background matching image
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
                    // Result count and Sort Row
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
                                  text: _isLoading ? '...' : '${_advisors.length}',
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.darkText),
                                ),
                                const TextSpan(text: ' advisors'),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.sort, size: 16, color: AppTheme.lightPurple),
                              const SizedBox(width: 4),
                              const Text(
                                'Sort by',
                                style: TextStyle(
                                  color: AppTheme.lightPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),

                    // Advisor List
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 4),
                              itemCount: _advisors.length,
                              itemBuilder: (context, index) {
                                final advisor = _advisors[index];
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
    );
  }
}

class _CustomAdvisorCard extends StatelessWidget {
  final AdvisorModel advisor;
  final VoidCallback onTap;

  const _CustomAdvisorCard({
    required this.advisor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine dynamic properties (Mocking for UI representation using real variables where possible)
    final name = advisor.user?.fullName ?? 'Unknown Advisor';
    final specialization = advisor.specialization ?? 'Astrology Specialist';
    final rating = advisor.rating.toStringAsFixed(1);
    final reviews = advisor.totalReviews;
    final experience = advisor.experienceYears;
    final rate = advisor.hourlyRate.toInt();
    
    // UI states usually returned from backend, applying conditional logic
    final isAvailable = true; // Hardcoded UI mockup logic to match picture, usually would depend on advisor schedule
    final statusColor = isAvailable ? const Color(0xFFE2F6EB) : const Color(0xFFFFF7E3);
    final statusTextColor = isAvailable ? const Color(0xFF00C853) : const Color(0xFFFDB000);
    final statusText = isAvailable ? 'Available' : 'Busy';
    final statusIcon = isAvailable ? Icons.check_circle : Icons.timer;

    return GestureDetector(
      onTap: onTap,
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
            // Top Row (Image & Detail Header)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Status Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 65,
                        height: 65,
                        color: Colors.grey[200],
                        child: advisor.user?.profileImage != null
                            ? Image.network(advisor.user!.profileImage!, fit: BoxFit.cover)
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

                // Name & Details
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
                          const Icon(Icons.favorite_border, color: AppTheme.inputBorder, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialization,
                        style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Stats Row
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.goldDark, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            '$rating',
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
            
            // Bottom Row (Price & Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Availability left
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
                            text: '₹$rate',
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
                // Book Now button right
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
