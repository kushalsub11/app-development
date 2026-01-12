import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';
import 'booking_screen.dart';

class AdvisorDetailScreen extends StatefulWidget {
  const AdvisorDetailScreen({super.key, required this.advisor});
  final AdvisorModel advisor;

  @override
  State<AdvisorDetailScreen> createState() => _AdvisorDetailScreenState();
}

class _AdvisorDetailScreenState extends State<AdvisorDetailScreen> {
  List<ReviewModel> _reviews = [];
  bool _loadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await ApiService.getAdvisorReviews(widget.advisor.id);
    setState(() {
      _reviews = reviews;
      _loadingReviews = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final advisor = widget.advisor;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Advisor Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  advisor.user?.fullName.isNotEmpty == true
                                      ? advisor.user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  advisor.user?.fullName ?? 'Advisor',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                                if (advisor.isVerified) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: AppTheme.info, size: 22),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              advisor.specialization ?? 'Astrology',
                              style: const TextStyle(
                                color: AppTheme.greyText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                RatingStars(rating: advisor.rating.round()),
                                const SizedBox(width: 8),
                                Text(
                                  '${advisor.rating} (${advisor.totalReviews})',
                                  style: const TextStyle(color: AppTheme.greyText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatItem(
                                  label: 'Experience',
                                  value: '${advisor.experienceYears} yrs',
                                ),
                                _StatItem(
                                  label: 'Rate',
                                  value: 'Rs. ${advisor.hourlyRate.toStringAsFixed(0)}/hr',
                                ),
                                _StatItem(
                                  label: 'Reviews',
                                  value: '${advisor.totalReviews}',
                                ),
                              ],
                            ),
                            if (advisor.bio != null && advisor.bio!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 12),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'About',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.darkText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                advisor.bio!,
                                style: const TextStyle(
                                  color: AppTheme.greyText,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Book Now Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: PrimaryButton(
                          label: 'Book Consultation',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(advisor: advisor),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Reviews Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reviews (${_reviews.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_loadingReviews)
                              const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                            else if (_reviews.isEmpty)
                              const Text(
                                'No reviews yet',
                                style: TextStyle(color: Colors.white60),
                              )
                            else
                              ..._reviews.map((review) => Card(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                review.user?.fullName ?? 'User',
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                              const Spacer(),
                                              RatingStars(rating: review.rating, size: 16),
                                            ],
                                          ),
                                          if (review.comment != null) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              review.comment!,
                                              style: const TextStyle(color: AppTheme.greyText),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.accentPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.greyText)),
      ],
    );
  }
}
