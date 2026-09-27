import 'package:flutter/material.dart';

class CreditProgressCard extends StatelessWidget {
  final int registeredCredits;
  final int minCredits;
  final int maxCredits;
  final String semester;

  const CreditProgressCard({
    super.key,
    required this.registeredCredits,
    this.minCredits = 12,
    this.maxCredits = 18,
    this.semester = 'Fall 2026',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (registeredCredits / maxCredits).clamp(0.0, 1.0);
    final meetsMin = registeredCredits >= minCredits;

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
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Semester Credit Hours',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    semester,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Big Number: 15 / 18 CH
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$registeredCredits',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  ' / $maxCredits',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Credit Hours',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Minimalist Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bounds metadata
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      meetsMin ? Icons.check_circle : Icons.info_outline,
                      size: 14,
                      color: meetsMin
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Min: $minCredits CH ${meetsMin ? "(Satisfied)" : "(Need ${minCredits - registeredCredits} more)"}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Max: $maxCredits CH',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
