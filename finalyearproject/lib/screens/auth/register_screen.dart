import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/widgets.dart';
import '../../services/auth_service.dart';
import '../../models/models.dart';
import '../user/user_home_screen.dart';
import '../advisor/advisor_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'user';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final user = result['user'] as UserModel;
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => user.role == 'advisor'
              ? const AdvisorHomeScreen()
              : const UserHomeScreen(),
        ),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Create Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.darkText,
            ),
          ),
          const SizedBox(height: 20),
          // Role Selector
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.inputBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = 'user'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'user'
                            ? AppTheme.accentPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'User',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedRole == 'user'
                              ? Colors.white
                              : AppTheme.greyText,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = 'advisor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedRole == 'advisor'
                            ? AppTheme.accentPurple
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Advisor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _selectedRole == 'advisor'
                              ? Colors.white
                              : AppTheme.greyText,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _nameController,
            hintText: 'Full Name',
            prefixIcon: Icons.person_rounded,
            validator: (v) => v == null || v.isEmpty ? 'Enter full name' : null,
          ),
          const SizedBox(height: 14),
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
            hintText: 'Create Password',
            prefixIcon: Icons.lock_rounded,
            obscureText: _obscurePassword,
            validator: (v) =>
                v == null || v.length < 6 ? 'Min 6 characters' : null,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _phoneController,
            hintText: 'Phone Number',
            prefixIcon: Icons.call_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Register',
            isLoading: _isLoading,
            onPressed: _handleRegister,
          ),
        ],
      ),
    );
  }
}
