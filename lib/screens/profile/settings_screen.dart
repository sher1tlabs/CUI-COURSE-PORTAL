import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionHeader('Preferences'),
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Course registration, deadline alerts, schedule changes',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _buildSwitchTile(
              title: 'Biometric Login',
              subtitle: 'Use Fingerprint / Face ID for faster sign in',
              value: _biometricEnabled,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Language', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                    title: const Text('Select Language'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ['English', 'Urdu'].map((lang) {
                        return RadioListTile<String>(
                          title: Text(lang),
                          value: lang,
                          groupValue: _selectedLanguage,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLanguage = val);
                              Navigator.of(ctx).pop();
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 32),

            _buildSectionHeader('Support & Legal'),
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Help Center & FAQ',
              onTap: () {
                _showInfoDialog('Help Center', 'For assistance with course registration or timetable disputes, contact the Academic Services Office or student coordinator.');
              },
            ),
            _buildActionTile(
              icon: Icons.headset_mic_outlined,
              title: 'Contact Support',
              onTap: () {
                _showInfoDialog('Contact Support', 'Email: registrar@isb.comsats.edu.pk\nPhone: +92 51 9247000\nHours: Mon-Fri 08:30 AM - 04:30 PM');
              },
            ),
            _buildActionTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {
                _showInfoDialog('Terms of Service', 'COMSATS University Islamabad Portal terms apply. Any unauthorized tampering with registrations is subject to disciplinary action.');
              },
            ),
            _buildActionTile(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              onTap: () {
                _showInfoDialog('Privacy Policy', 'Your academic data is protected according to Higher Education Commission (HEC) and COMSATS University confidentiality protocols.');
              },
            ),
            const Divider(height: 32),

            _buildSectionHeader('About Application'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Version', style: TextStyle(fontSize: 14)),
                  Text(
                    '1.0.0 (Build 42)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280))),
      value: value,
      activeColor: isDark ? Colors.white : Colors.black,
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  void _showInfoDialog(String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
