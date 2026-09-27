import 'package:flutter/material.dart';
import '../models/section.dart';

class SectionCard extends StatelessWidget {
  final Section section;
  final bool isSelected;
  final bool isRegistered;
  final bool hasConflict;
  final String? conflictMessage;
  final VoidCallback onSelect;
  final VoidCallback onInstructorTap;

  const SectionCard({
    super.key,
    required this.section,
    this.isSelected = false,
    this.isRegistered = false,
    this.hasConflict = false,
    this.conflictMessage,
    required this.onSelect,
    required this.onInstructorTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFull = section.isFull;

    Color borderColor;
    if (isSelected || isRegistered) {
      borderColor = isDark ? Colors.white : Colors.black;
    } else if (hasConflict) {
      borderColor = isDark ? const Color(0xFF991B1B) : const Color(0xFFEF4444);
    } else {
      borderColor = isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5);
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderColor,
          width: isSelected || isRegistered ? 1.6 : 1,
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Section name, Seat pill, conflict badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      section.sectionName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (isRegistered) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current Section',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFull
                        ? (isDark ? const Color(0xFF2D1515) : const Color(0xFFFEE2E2))
                        : (isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(8),
                    border: BorderSide(
                      color: isFull
                          ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5))
                          : (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    isFull ? 'Full (0 seats)' : '${section.availableSeats}/${section.totalSeats} Seats',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFull
                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Instructor row
            InkWell(
              onTap: onInstructorTap,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      section.instructor,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 13,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Schedule: Days & Time
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  section.days.join(' / '),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.access_time,
                  size: 15,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  '${section.startTime} - ${section.endTime}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Room
            Row(
              children: [
                Icon(
                  Icons.room_outlined,
                  size: 16,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Room: ${section.room}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),

            // Conflict warning if any
            if (hasConflict && conflictMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D1212) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: BorderSide(
                    color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        conflictMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isFull || isRegistered || hasConflict) ? null : onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                  disabledForegroundColor: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isRegistered
                      ? 'Already Registered'
                      : isFull
                          ? 'Section Full'
                          : hasConflict
                              ? 'Schedule Conflict'
                              : 'Select Section',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
