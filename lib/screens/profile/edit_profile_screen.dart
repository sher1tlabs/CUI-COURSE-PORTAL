import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../widgets/custom_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _dataService = LocalDataService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _dataService.currentStudent.name);
    _phoneController = TextEditingController(text: _dataService.currentStudent.phoneNumber);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    _dataService.updateProfile(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final student = _dataService.currentStudent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'S',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Editable fields
              Text(
                'Display Name',
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
                  hintText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20),
                ),
              ),
              const SizedBox(height: 16),

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
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 24),

              // Locked official fields notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Registration Number (${student.registrationNumber}), Degree Program (${student.program}), and Campus cannot be changed by student. Please contact the Registrar Office for corrections.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              CustomButton(
                label: 'Save Changes',
                onPressed: _saveProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
