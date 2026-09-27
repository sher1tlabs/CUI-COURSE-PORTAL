import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _inputController = TextEditingController(text: 'student@comsats.edu.pk');
  bool _isLoading = false;
  bool _submitted = false;
  String? _errorMessage;

  void _handleReset() async {
    final email = _inputController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please provide your university email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.sendPasswordReset(email);
      setState(() {
        _isLoading = false;
        _submitted = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered COMSATS email address to receive password reset instructions.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 28),

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

              if (_submitted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: BorderSide(
                      color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mark_email_read_outlined,
                        size: 36,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Instructions Sent',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'If the account exists in COMSATS portal, password reset instructions have been dispatched to your email address.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Back to Login',
                  isOutlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ] else ...[
                Text(
                  'University Email Address',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _inputController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'e.g. sp24-bce-042@isb.comsats.edu.pk',
                    prefixIcon: Icon(Icons.mail_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _handleReset,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
