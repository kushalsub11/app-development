import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../widgets/widgets.dart';
import '../../models/models.dart';
import '../user/user_home_screen.dart';
import '../advisor/advisor_home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.verifyRegistration(
      email: widget.email,
      otp: otp,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      final user = result['user'] as UserModel;
      if (!mounted) return;
      Widget home = user.role == 'advisor' ? const AdvisorHomeScreen() : const UserHomeScreen();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => home), (r) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read, size: 60, color: AppTheme.accentPurple),
                      const SizedBox(height: 16),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.darkText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a 6-digit code to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.greyText),
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _otpController,
                        hintText: 'Enter 6-Digit OTP',
                        prefixIcon: Icons.lock_clock,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Verify & Login',
                        isLoading: _isLoading,
                        onPressed: _verifyOtp,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back to Login', style: TextStyle(color: AppTheme.greyText)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
