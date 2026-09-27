import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Minimal Emblem / Logo Placeholder
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'CUI',
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'COMSATS\nStudent Portal',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Tagline
              Text(
                'Your university. Your courses. Your semester.\nManage your registration, timetable, and academic life in one seamless place.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),

              const Spacer(flex: 2),

              // Actions
              CustomButton(
                label: 'Login with University Email',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              CustomButton(
                label: 'Continue as Demo Student',
                isOutlined: true,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  'COMSATS University Islamabad • Official Portal',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
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
