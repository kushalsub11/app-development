import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/api_config.dart';
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

  void _showReportDialog(BuildContext context) {
    String selectedReason = 'Inappropriate Behavior';
    final descController = TextEditingController();
    bool isSubmitting = false;

    final reasons = [
      'Inappropriate Behavior',
      'Fake Credentials',
      'No Show / Did Not Attend',
      'Harassment or Abuse',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Report Advisor',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.darkText),
              ),
              const SizedBox(height: 4),
              const Text(
                'Help us keep the community safe. Reports are reviewed by admins.',
                style: TextStyle(color: AppTheme.greyText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setModalState(() => selectedReason = v ?? selectedReason),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Please describe the issue...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final result = await ApiService.createReport({
                                'reported_advisor_id': widget.advisor.id,
                                'reason': selectedReason,
                                'description': descController.text.isEmpty ? null : descController.text,
                              });
                              setModalState(() => isSubmitting = false);
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (result['success'] == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Report submitted. Our team will review it.'),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Failed to submit report.'),
                                    backgroundColor: AppTheme.error,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Report', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white),
                      tooltip: 'Report Advisor',
                      onPressed: () => _showReportDialog(context),
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
                                color: AppTheme.gold,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: (advisor.user?.profileImage != null && advisor.user!.profileImage!.isNotEmpty)
                                    ? Image.network(
                                        ApiConfig.getImageUrl(advisor.user!.profileImage!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildInitialPlaceholder(advisor),
                                      )
                                    : _buildInitialPlaceholder(advisor),
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
                            if (advisor.religion != null && advisor.religion!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${advisor.religion} Practitioner',
                                style: const TextStyle(
                                  color: AppTheme.accentPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
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
                            if (advisor.isPhysicalAvailable) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentPurple.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.1)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: AppTheme.accentPurple, size: 20),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Physical Consultation Available',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: AppTheme.darkText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (advisor.officeAddress != null && advisor.officeAddress!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        advisor.officeAddress!,
                                        style: TextStyle(
                                          color: AppTheme.darkText.withOpacity(0.8),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Reviews (${_reviews.length})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_reviews.length > 3)
                                  TextButton(
                                    onPressed: () {
                                      // Optional: Show all reviews in a new screen or expanded list
                                    },
                                    child: const Text('See All', style: TextStyle(color: AppTheme.gold)),
                                  ),
                              ],
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
                              ..._reviews.map((review) => Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppTheme.accentPurple.withValues(alpha: 0.1),
                                              child: Text(
                                                review.user?.fullName.isNotEmpty == true ? review.user!.fullName[0].toUpperCase() : '?',
                                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentPurple),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    review.user?.fullName ?? 'Anonymous',
                                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        review.createdAt?.split('T').first ?? '',
                                                        style: const TextStyle(color: AppTheme.greyText, fontSize: 11),
                                                      ),
                                                      if (review.consultationType != null) ...[
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          review.consultationType!.toUpperCase(),
                                                          style: const TextStyle(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RatingStars(rating: review.rating, size: 14),
                                          ],
                                        ),
                                        if (review.comment != null && review.comment!.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Text(
                                            review.comment!,
                                            style: const TextStyle(color: AppTheme.darkText, fontSize: 13, height: 1.4),
                                          ),
                                        ],
                                        if (review.advisorReply != null && review.advisorReply!.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentPurple.withValues(alpha: 0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.1)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.reply, size: 14, color: AppTheme.accentPurple),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Reply from ${advisor.user?.fullName ?? 'Advisor'}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.accentPurple),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  review.advisorReply!,
                                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, height: 1.4),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
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
  Widget _buildInitialPlaceholder(AdvisorModel advisor) {
    return Center(
      child: Text(
        advisor.user?.fullName.isNotEmpty == true ? advisor.user!.fullName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
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
