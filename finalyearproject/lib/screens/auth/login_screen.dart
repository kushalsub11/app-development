import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../user/user_home_screen.dart';
import '../advisor/advisor_home_screen.dart';
import '../admin/admin_home_screen.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final user = result['user'] as UserModel;
      if (!mounted) return;
      _navigateToHome(user);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.error,
        ),
      );
      
      if (result['message'] != null && result['message'].toString().contains('Email is not verified')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: _emailController.text.trim())),
        );
      }
    }
  }

  void _navigateToHome(UserModel user) {
    Widget home;
    switch (user.role) {
      case 'advisor':
        home = const AdvisorHomeScreen();
        break;
      case 'admin':
        home = const AdminHomeScreen();
        break;
      default:
        home = const UserHomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _emailController,
            hintText: 'Email Address',
            prefixIcon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Login',
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: AppTheme.accentPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
