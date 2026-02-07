import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(Icons.support_agent, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Our team is here to support you 24/7',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildFAQ('How do I get verified?', 'To get verified, go to your Profile and upload a valid certification document (PDF or Image). Our admin team will review it within 24-48 hours. Once approved, you will get a "Verified" badge and appear in the browse list.'),
            _buildFAQ('When do I get my payouts?', 'You can request a payout once your balance reaches ₹500. Payouts are usually processed within 24-48 working hours depending on your chosen payment method.'),
            _buildFAQ('How is system commission calculated?', 'The platform charges a 30% commission on every booking to maintain and grow the service. You can see the detailed breakdown in your "My Earnings" page.'),
            _buildFAQ('How do I set my availability?', 'Navigate to Profile -> Availability & Slots. There you can toggle your online status and define specific time ranges for each day of the week.'),
            _buildFAQ('What if a user cancels?', 'Cancellations follow our standard platform policy. If a user cancels after a certain timeframe, a partial or full amount may be credited to your balance depending on the circumstances.'),

            const SizedBox(height: 30),
            const Text('Contact Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'Contact via WhatsApp',
              subtitle: 'Quick chat support for immediate help',
              color: const Color(0xFF25D366),
              onTap: () => _launchUrl('https://wa.me/9779766047777'), // Official support number
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.alternate_email,
              title: 'Email Support',
              subtitle: 'Send us your detailed queries',
              color: AppTheme.accentPurple,
              onTap: () => _launchUrl('mailto:sajeloguru@gmail.com'),
            ),

            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  const Text('App Version 1.0.2', style: TextStyle(color: AppTheme.greyText, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Terms of Use', style: TextStyle(fontSize: 12))),
                      const Text('|', style: TextStyle(color: AppTheme.greyText)),
                      TextButton(onPressed: () {}, child: const Text('Privacy Policy', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQ(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.darkText)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: Text(answer, style: const TextStyle(color: AppTheme.greyText, fontSize: 13, height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: AppTheme.greyText, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
