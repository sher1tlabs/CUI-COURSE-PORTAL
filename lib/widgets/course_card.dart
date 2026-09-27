import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/local_data_service.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback onViewSections;

  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
    required this.onViewSections,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataService = LocalDataService();
    final prereqStatus = dataService.checkPrerequisites(course);
    final isRegistered = dataService.isCourseRegistered(course.code);
    final sections = dataService.getSectionsForCourse(course.code);
    final availableSectionsCount = sections.where((s) => !s.isFull).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
          width: 1,
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Code, Badges, Registered tag
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.code,
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: BorderSide(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      '${course.creditHours} CH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isRegistered)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: BorderSide(
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Registered',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.courseType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                course.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),

              // Department
              Text(
                course.department,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),

              // Prerequisite indicator
              Row(
                children: [
                  Icon(
                    prereqStatus['passed'] == true ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                    size: 16,
                    color: prereqStatus['passed'] == true
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      prereqStatus['passed'] == true
                          ? (course.prerequisites.isEmpty ? 'No Prerequisites' : 'Prerequisites Completed')
                          : 'Missing: ${course.prerequisites.join(", ")}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: prereqStatus['passed'] == true
                            ? (isDark ? Colors.white70 : Colors.black87)
                            : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.8),

              // Bottom Actions: Sections info & View Sections Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$availableSectionsCount/${sections.length} Sections Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onViewSections,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Sections',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
