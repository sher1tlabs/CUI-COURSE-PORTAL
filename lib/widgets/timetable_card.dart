import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';

class TimetableCard extends StatelessWidget {
  final TimetableEntry entry;

  const TimetableCard({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Time Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: BorderSide(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    entry.startTime.split(' ')[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    entry.startTime.split(' ').length > 1 ? entry.startTime.split(' ')[1] : '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 2,
                    height: 14,
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.endTime.split(' ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Right Course Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.courseCode,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          entry.sectionName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.courseTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.instructor,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.room_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Room: ${entry.room}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
