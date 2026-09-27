import 'package:flutter/material.dart';

class RegistrationStatusCard extends StatelessWidget {
  final bool isOpen;
  final DateTime deadline;
  final String semester;
  final VoidCallback onRegisterTap;

  const RegistrationStatusCard({
    super.key,
    required this.isOpen,
    required this.deadline,
    this.semester = 'Fall 2026',
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top tag & status pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      semester,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6))
                        : (isDark ? const Color(0xFF2D1212) : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(8),
                    border: BorderSide(
                      color: isOpen
                          ? (isDark ? Colors.white24 : Colors.black12)
                          : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isOpen
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deadline info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: BorderSide(
                  color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 18,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Deadline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        'September 30, 2026 • 11:59 PM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isOpen ? onRegisterTap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isOpen ? 'Register Courses' : 'Registration Closed',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
