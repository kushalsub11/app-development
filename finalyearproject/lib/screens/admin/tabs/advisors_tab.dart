import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';
import '../../../config/api_config.dart';

class AdvisorsTab extends StatefulWidget {
  const AdvisorsTab({super.key});

  @override
  State<AdvisorsTab> createState() => _AdvisorsTabState();
}

class _AdvisorsTabState extends State<AdvisorsTab> {
  List<AdvisorModel> _advisors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdvisors();
  }

  Future<void> _loadAdvisors() async {
    final advisors = await ApiService.getAllAdvisorsAdmin();
    setState(() {
      _advisors = advisors;
      _isLoading = false;
    });
  }

  Color _statusColor(String status, bool isBlocked) {
    if (isBlocked) return AppTheme.error;
    switch (status) {
      case 'approved': return AppTheme.success;
      case 'rejected': return AppTheme.error;
      default: return AppTheme.warning;
    }
  }

  String _statusLabel(String status, bool isBlocked) {
    if (isBlocked) return 'BLOCKED';
    switch (status) {
      case 'approved': return 'VERIFIED';
      case 'rejected': return 'REJECTED';
      default: return 'PENDING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text('Manage Advisors', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : RefreshIndicator(
                    onRefresh: _loadAdvisors,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _advisors.length,
                      itemBuilder: (context, index) {
                        final a = _advisors[index];
                        final statusColor = _statusColor(a.verificationStatus, a.isBlocked);
                        final statusLabel = _statusLabel(a.verificationStatus, a.isBlocked);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: statusColor.withOpacity(0.2),
                                      child: Icon(
                                        a.isBlocked ? Icons.block : (a.isVerified ? Icons.verified : Icons.pending),
                                        color: statusColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.user?.fullName ?? 'Advisor #${a.id}',
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                          ),
                                          Text(
                                            a.specialization ?? 'General',
                                            style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                if (a.location != null && a.location!.isNotEmpty)
                                  _DetailRow(icon: Icons.location_on, text: a.location!),
                                if (a.contactNumber != null && a.contactNumber!.isNotEmpty)
                                  _DetailRow(icon: Icons.phone, text: a.contactNumber!),
                                _DetailRow(icon: Icons.star, text: '${a.rating} rating | ${a.totalReviews} reviews'),

                                if (a.certificatePdf != null) ...[
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: () => _viewCertificate(context, a.certificatePdf!),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image, color: Colors.blue, size: 18),
                                          SizedBox(width: 8),
                                          Text('View Certificate Photo', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: a.isBlocked ? null : () async {
                                          await ApiService.verifyAdvisor(a.id);
                                          _loadAdvisors();
                                        },
                                        icon: Icon(
                                          a.isVerified ? Icons.close : Icons.verified,
                                          size: 16,
                                        ),
                                        label: Text(a.isVerified ? 'Unverify' : 'Verify'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: a.isVerified ? AppTheme.warning : AppTheme.success,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(a.isBlocked ? 'Unblock Advisor' : 'Block Advisor'),
                                              content: Text(a.isBlocked
                                                  ? 'Unblock ${a.user?.fullName}? They will appear on the platform again.'
                                                  : 'Block ${a.user?.fullName}? They will be removed from public listing.'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: a.isBlocked ? AppTheme.success : AppTheme.error,
                                                  ),
                                                  child: Text(a.isBlocked ? 'Unblock' : 'Block'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ApiService.blockAdvisor(a.id);
                                            _loadAdvisors();
                                          }
                                        },
                                        icon: Icon(a.isBlocked ? Icons.lock_open : Icons.block, size: 16),
                                        label: Text(a.isBlocked ? 'Unblock' : 'Block'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: a.isBlocked ? AppTheme.success : AppTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _viewCertificate(BuildContext context, String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '${ApiConfig.baseUrl}$cleanPath';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.network(
                fullUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: const Text('Failed to load image', style: TextStyle(color: Colors.red)),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.greyText),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.greyText))),
        ],
      ),
    );
  }
}
