import 'package:flutter/material.dart';
import '../../models/announcement.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final UniversityAnnouncement announcement;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Official Announcement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      announcement.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151),
                      ),
                    ),
                  ),
                  if (announcement.isUrgent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: BorderSide(
                          color: isDark ? const Color(0xFF991B1B) : const Color(0xFFF87171),
                        ),
                      ),
                      child: Text(
                        'URGENT NOTICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ] else if (announcement.isImportant) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2308) : const Color(0xFFFEFCE8),
                        borderRadius: BorderRadius.circular(6),
                        border: BorderSide(
                          color: isDark ? const Color(0xFF713F12) : const Color(0xFFFACC15),
                        ),
                      ),
                      child: Text(
                        'IMPORTANT NOTICE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                announcement.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.3,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              // Metadata card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: BorderSide(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Column(
                  children: [
                    _buildMetaRow('Issued by', announcement.createdBy, isDark),
                    const Divider(height: 16),
                    _buildMetaRow(
                      'Published on',
                      '${announcement.publishedAt.day}/${announcement.publishedAt.month}/${announcement.publishedAt.year}',
                      isDark,
                    ),
                    if (announcement.expiresAt != null) ...[
                      const Divider(height: 16),
                      _buildMetaRow(
                        'Valid until',
                        '${announcement.expiresAt!.day}/${announcement.expiresAt!.month}/${announcement.expiresAt!.year}',
                        isDark,
                      ),
                    ],
                    const Divider(height: 16),
                    _buildMetaRow('Scope', '${announcement.campus} • ${announcement.department}', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Official Body
              Text(
                'Notice Content',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: BorderSide(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  announcement.body,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // University official footer
              Center(
                child: Text(
                  'COMSATS University Islamabad • Official Academic Communication',
                  style: TextStyle(
                    fontSize: 11,
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

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
