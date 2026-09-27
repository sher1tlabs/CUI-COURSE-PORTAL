import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'student@comsats.edu.pk');
  final _passwordController = TextEditingController(text: 'Comsats123!');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your university email and password.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Login',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in with your official university credentials',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D1212) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: BorderSide(
                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Email field
              Text(
                'University Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'e.g. sp24-bce-042@isb.comsats.edu.pk',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Password field
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Remember me & Forgot Password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: isDark ? Colors.white : Colors.black,
                          checkColor: isDark ? Colors.black : Colors.white,
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Remember me',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.white : Colors.black,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Login Button
              CustomButton(
                label: 'Sign In',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 16),

              // Don't have an account? Register
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'New student? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Trouble logging in
              Center(
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                        title: const Text('COMSATS Student Support'),
                        content: const Text(
                          'If you forgot your password or your account is locked, please visit the Academic Services Office (ASO) or email support@comsats.edu.pk.\n\nQuick Test Demo:\nEmail: student@comsats.edu.pk\nPassword: Comsats123!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Text(
                    'Having trouble logging in?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
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
