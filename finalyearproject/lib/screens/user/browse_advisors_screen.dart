import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'advisor_detail_screen.dart';

class BrowseAdvisorsScreen extends StatefulWidget {
  const BrowseAdvisorsScreen({super.key});

  @override
  State<BrowseAdvisorsScreen> createState() => _BrowseAdvisorsScreenState();
}

class _BrowseAdvisorsScreenState extends State<BrowseAdvisorsScreen> {
  List<AdvisorModel> _advisors = [];
  bool _isLoading = true;

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
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Find Advisors',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 16),
            child: Text(
              'Browse verified astrologers',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _advisors.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search,
                        title: 'No Advisors Found',
                        subtitle: 'There are no verified advisors available at the moment.',
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAdvisors,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _advisors.length,
                          itemBuilder: (context, index) {
                            final advisor = _advisors[index];
                            return AdvisorCard(
                              name: advisor.user?.fullName ?? 'Unknown',
                              specialization: advisor.specialization ?? 'Astrology',
                              rating: advisor.rating,
                              totalReviews: advisor.totalReviews,
                              hourlyRate: advisor.hourlyRate,
                              isVerified: advisor.isVerified,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdvisorDetailScreen(advisor: advisor),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
