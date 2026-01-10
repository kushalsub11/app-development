import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sajelo Guru',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF4B2396),
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool obscureLoginPassword = true;
  bool obscureRegisterPassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5C2DB2), Color(0xFF3B1C78)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: isLogin
                            ? _LoginCard(
                                key: const ValueKey('login'),
                                obscurePassword: obscureLoginPassword,
                                onTogglePassword: () {
                                  setState(() {
                                    obscureLoginPassword =
                                        !obscureLoginPassword;
                                  });
                                },
                              )
                            : _RegisterCard(
                                key: const ValueKey('register'),
                                obscurePassword: obscureRegisterPassword,
                                onTogglePassword: () {
                                  setState(() {
                                    obscureRegisterPassword =
                                        !obscureRegisterPassword;
                                  });
                                },
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account?"
                              : 'Already have an account?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isLogin = !isLogin;
                            });
                          },
                          child: Text(
                            isLogin ? 'Create New Account' : 'Login',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFFFE45C),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (_) => const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            color: Color(0xFFFFE45C),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE54E),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.brightness_2_rounded,
              color: Color(0xFF9124C9),
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Sajelo Guru',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Astrology Companion',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    super.key,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardTitle(title: 'Welcome Back'),
        const SizedBox(height: 20),
        const _InputField(
          hintText: 'Email Address',
          prefixIcon: Icons.email_rounded,
        ),
        const SizedBox(height: 14),
        _InputField(
          hintText: 'Password',
          prefixIcon: Icons.lock_rounded,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword ? Icons.visibility_rounded : Icons.visibility_off,
              color: const Color(0xFF58546B),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFA127D3),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 22),
        const _PrimaryButton(label: 'Login'),
      ],
    );
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    super.key,
    required this.obscurePassword,
    required this.onTogglePassword,
  });

  final bool obscurePassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardTitle(title: 'Create Account'),
        const SizedBox(height: 20),
        const _InputField(
          hintText: 'Full Name',
          prefixIcon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),
        const _InputField(
          hintText: 'Email Address',
          prefixIcon: Icons.email_rounded,
        ),
        const SizedBox(height: 14),
        _InputField(
          hintText: 'Create Password',
          prefixIcon: Icons.lock_rounded,
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              obscurePassword ? Icons.visibility_rounded : Icons.visibility_off,
              color: const Color(0xFF58546B),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _InputField(
          hintText: 'Phone Number',
          prefixIcon: Icons.call_rounded,
        ),
        const SizedBox(height: 22),
        const _PrimaryButton(label: 'Register'),
      ],
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF22202A),
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF747180),
          fontSize: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFFCFCFF),
        prefixIcon: Icon(
          prefixIcon,
          color: const Color(0xFF58546B),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF9A96A8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFA127D3),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB028C9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
