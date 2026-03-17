import 'package:flutter/material.dart';
import '../config/theme.dart';

// ---------- Custom Text Field ----------
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.focusNode,
    this.onChanged,
  });

  final String hintText;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: AppTheme.greyText),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// ---------- Primary Button ----------
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label),
      ),
    );
  }
}

// ---------- Advisor Card ----------
class AdvisorCard extends StatelessWidget {
  const AdvisorCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.totalReviews,
    required this.hourlyRate,
    required this.isVerified,
    this.onTap,
  });

  final String name;
  final String specialization;
  final double rating;
  final int totalReviews;
  final double hourlyRate;
  final bool isVerified;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.darkText,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Icon(Icons.verified, color: AppTheme.info, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialization,
                      style: const TextStyle(color: AppTheme.greyText, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Hiding rating and reviews as per user request
                        /*
                        const Icon(Icons.star, color: AppTheme.gold, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$rating ($totalReviews reviews)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.greyText),
                        ),
                        */
                        const Spacer(),
                        Text(
                          'Rs. ${hourlyRate.toStringAsFixed(0)}/hr',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Booking Card ----------
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.consultationType,
    required this.amount,
    this.meetingLocation,
    this.onTap,
    this.actions,
  });

  final String bookingDate;
  final String startTime;
  final String endTime;
  final String status;
  final String consultationType;
  final double amount;
  final String? meetingLocation;
  final VoidCallback? onTap;
  final List<Widget>? actions;

  Color get statusColor {
    switch (status) {
      case 'confirmed':
        return AppTheme.success;
      case 'completed':
        return AppTheme.info;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  IconData get typeIcon {
    switch (consultationType) {
      case 'voice':
        return Icons.phone;
      case 'video':
        return Icons.videocam;
      case 'physical':
        return Icons.location_on;
      default:
        return Icons.chat;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(typeIcon, color: AppTheme.accentPurple),
                  const SizedBox(width: 8),
                  Text(
                    consultationType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentPurple,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.greyText),
                  const SizedBox(width: 6),
                  Text(bookingDate, style: const TextStyle(color: AppTheme.greyText)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: AppTheme.greyText),
                  const SizedBox(width: 6),
                  Text('$startTime - $endTime', style: const TextStyle(color: AppTheme.greyText)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Rs. ${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- Rating Stars ----------
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onRatingChanged,
  });

  final int rating;
  final double size;
  final ValueChanged<int>? onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1) : null,
          child: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: AppTheme.gold,
            size: size,
          ),
        );
      }),
    );
  }
}

// ---------- Loading Indicator ----------
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message = 'Loading...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppTheme.accentPurple),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.greyText)),
        ],
      ),
    );
  }
}

// ---------- Empty State ----------
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppTheme.inputBorder),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.greyText),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
// ---------- Responsive Container ----------
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 450,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
// ---------- Status Badge ----------
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
      case 'completed':
        return AppTheme.success;
      case 'cancelled':
      case 'rejected':
      case 'error':
        return AppTheme.error;
      case 'pending':
        return AppTheme.warning;
      case 'ongoing':
      case 'active':
        return AppTheme.info;
      default:
        return AppTheme.greyText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: statusColor,
        ),
      ),
    );
  }
}
