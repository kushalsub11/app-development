import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

class AdvisorReviewsScreen extends StatefulWidget {
  const AdvisorReviewsScreen({super.key});

  @override
  State<AdvisorReviewsScreen> createState() => _AdvisorReviewsScreenState();
}

class _AdvisorReviewsScreenState extends State<AdvisorReviewsScreen> {
  List<ReviewModel> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await ApiService.getMyReviewsForAdvisor();
    if (mounted) {
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    }
  }

  void _showReplyDialog(ReviewModel review) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reply to Review'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Type your response to the user...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              final success = await ApiService.replyToReview(review.id, controller.text.trim());
              if (success) {
                _loadReviews();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply submitted successfully!'), backgroundColor: AppTheme.success));
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit reply.'), backgroundColor: AppTheme.error));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentPurple),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _reviews.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) return _buildRatingSummary();
                      final r = _reviews[index - 1];
                      return _ReviewCard(
                        review: r,
                        onReply: () => _showReplyDialog(r),
                      );
                    },
                  ),
                ),
    );
  }


  Widget _buildRatingSummary() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    final totalReviews = _reviews.length;
    final averageRating = _reviews.map((r) => r.rating).reduce((a, b) => a + b) / totalReviews;
    
    // Count each star
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in _reviews) {
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                    RatingBarIndicator(
                      rating: averageRating,
                      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 20.0,
                    ),
                    const SizedBox(height: 4),
                    Text('$totalReviews reviews', style: const TextStyle(color: AppTheme.greyText)),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = counts[star] ?? 0;
                    final percent = totalReviews > 0 ? count / totalReviews : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                backgroundColor: Colors.grey.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(star >= 4 ? AppTheme.success : (star >= 3 ? AppTheme.gold : AppTheme.error)),
                                minHeight: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews_outlined, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Reviews Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.greyText)),
          const SizedBox(height: 8),
          const Text('Customer feedback will appear here.', style: TextStyle(color: AppTheme.greyText)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onReply});
  final ReviewModel review;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.gold.withOpacity(0.2),
                child: Text(
                  review.user?.fullName.isNotEmpty == true ? review.user!.fullName[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppTheme.goldDark, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.user?.fullName ?? 'Anonymous User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        Text(review.createdAt?.split('T')[0] ?? '', style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
                        if (review.consultationType != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.accentPurple.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(review.consultationType!.toUpperCase(), style: const TextStyle(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              RatingBarIndicator(
                rating: review.rating.toDouble(),
                itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 18.0,
                direction: Axis.horizontal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            Text(review.comment!, style: const TextStyle(fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
          ],
          
          if (review.advisorReply != null && review.advisorReply!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentPurple.withOpacity(0.1))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Reply:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.accentPurple)),
                  const SizedBox(height: 4),
                  Text(review.advisorReply!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  if (review.repliedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(review.repliedAt!.split('T')[0], style: const TextStyle(fontSize: 10, color: AppTheme.greyText)),
                    ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onReply,
                icon: const Icon(Icons.reply, size: 18),
                label: const Text('Reply to customer'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentPurple,
                  backgroundColor: AppTheme.accentPurple.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
