import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../services/auth_service.dart';
import '../auth/welcome_screen.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const ProfileScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout?'),
        content: const Text('Are you sure you want to log out of your COMSATS account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await AuthService.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataService = LocalDataService();

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final student = dataService.currentStudent;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Student Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Top Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      child: Text(
                        student.name.isNotEmpty ? student.name[0] : 'S',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.registrationNumber,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            student.program,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Edit Profile Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile & Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION 1: Student Information
                _buildSectionTitle('Student Information', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildRow('Full Name', student.name, isDark),
                    _buildRow('Registration No.', student.registrationNumber, isDark),
                    _buildRow('University Email', student.email, isDark),
                    _buildRow('Phone Number', student.phoneNumber, isDark),
                    _buildRow('Degree Program', student.program, isDark),
                    _buildRow('Campus', student.campus, isDark),
                    _buildRow('Batch', student.batch, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 2: Academic Information
                _buildSectionTitle('Academic Information', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    _buildRow('Current Semester', 'Semester ${student.semester}', isDark),
                    _buildRow('Cumulative GPA (CGPA)', '${student.cgpa} / 4.00', isDark),
                    _buildRow('Completed Credit Hours', '${student.completedCreditHours} CH', isDark),
                    _buildRow('Academic Standing', student.academicStanding, isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 3: Settings & Preferences
                _buildSectionTitle('Preferences', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    if (onToggleTheme != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          size: 20,
                        ),
                        title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isDarkMode ? 'Monochrome Dark' : 'Monochrome Light',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Switch(
                          value: isDarkMode,
                          activeColor: isDark ? Colors.white : Colors.black,
                          onChanged: (_) => onToggleTheme!(),
                        ),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.tune, size: 20),
                      title: const Text('More Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Notifications, Language, Biometrics', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // SECTION 4: Account Actions
                _buildSectionTitle('Account', isDark),
                _buildInfoCard(
                  isDark: isDark,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset, size: 20),
                      title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset instructions sent to university email.')),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout, size: 20, color: Color(0xFFDC2626)),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                      onTap: () => _confirmLogout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required bool isDark, required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
