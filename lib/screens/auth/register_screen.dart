import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController(text: 'Hassan Ali');
  final _emailController = TextEditingController(text: 'sp24-bce-042@isb.comsats.edu.pk');
  final _regNoController = TextEditingController(text: 'SP24-BCE-042');
  final _phoneController = TextEditingController(text: '+92 300 1234567');
  final _passwordController = TextEditingController(text: 'Comsats123!');

  String _selectedProgram = 'BS Computer Science';
  String _selectedCampus = 'Islamabad';
  int _selectedSemester = 4;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _programs = [
    'BS Computer Science',
    'BS Software Engineering',
    'BS Artificial Intelligence',
    'BS Data Science',
    'BS Cyber Security',
    'BS Electrical Engineering',
  ];

  final List<String> _campuses = [
    'Islamabad',
    'Lahore',
    'Abbottabad',
    'Wah',
    'Attock',
    'Sahiwal',
    'Vehari',
  ];

  void _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _regNoController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please complete all required fields.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.registerStudent(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        registrationNumber: _regNoController.text.trim(),
        phone: _phoneController.text.trim(),
        program: _selectedProgram,
        campus: _selectedCampus,
        semester: _selectedSemester,
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
    _nameController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _phoneController.dispose();
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
                'Student Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create your COMSATS student account with official details',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

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

              // Full Name
              Text(
                'Full Name',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Hassan Ali',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // University Email
              Text(
                'Official University Email',
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
                  hintText: 'sp24-bce-042@isb.comsats.edu.pk',
                  prefixIcon: Icon(Icons.mail_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Reg Number & Phone row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Registration No',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _regNoController,
                          decoration: const InputDecoration(
                            hintText: 'SP24-BCE-042',
                            prefixIcon: Icon(Icons.badge_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: '+92 300 1234567',
                            prefixIcon: Icon(Icons.phone_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Program Dropdown
              Text(
                'Degree Program',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedProgram,
                items: _programs
                    .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (val) => setState(() => _selectedProgram = val!),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.school_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),

              // Campus & Semester
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Campus',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCampus,
                          items: _campuses
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCampus = val!),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          value: _selectedSemester,
                          items: List.generate(8, (i) => i + 1)
                              .map((s) => DropdownMenuItem(value: s, child: Text('Semester $s', style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val!),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.numbers, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  hintText: 'Minimum 6 characters',
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
              const SizedBox(height: 28),

              // Submit Button
              CustomButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Sign In',
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
            ],
          ),
        ),
      ),
    );
  }
}
