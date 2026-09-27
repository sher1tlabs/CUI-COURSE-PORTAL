import 'package:flutter/material.dart';
import '../models/instructor.dart';

class InstructorInfoSheet extends StatelessWidget {
  final Instructor instructor;

  const InstructorInfoSheet({super.key, required this.instructor});

  static void show(BuildContext context, Instructor instructor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => InstructorInfoSheet(instructor: instructor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      instructor.designation,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _buildRow(
            context,
            icon: Icons.account_balance_outlined,
            title: 'Department',
            value: instructor.department,
          ),
          const SizedBox(height: 12),
          _buildRow(
            context,
            icon: Icons.meeting_room_outlined,
            title: 'Faculty Office',
            value: instructor.office,
          ),
          const SizedBox(height: 12),
          _buildRow(
            context,
            icon: Icons.mail_outline,
            title: 'Official Email',
            value: instructor.email,
          ),
          const SizedBox(height: 16),
          Text(
            'Courses Taught this Year',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: instructor.coursesTaught.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required IconData icon, required String title, required String value}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
