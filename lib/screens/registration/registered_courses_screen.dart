import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import 'section_selection_screen.dart';
import 'course_details_screen.dart';

class RegisteredCoursesScreen extends StatelessWidget {
  final VoidCallback? onNavigateToRegistration;

  const RegisteredCoursesScreen({super.key, this.onNavigateToRegistration});

  void _confirmDrop(BuildContext context, LocalDataService dataService, String courseCode, String courseTitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Drop $courseCode?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              courseTitle,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'This course will be removed from your current semester registration. Credit hours will be adjusted.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              dataService.dropCourse(courseCode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dropped $courseCode successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Drop Course'),
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
        final registrations = dataService.registrations;
        final totalCredits = dataService.totalRegisteredCreditHours;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Courses'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Summary Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Fall 2026 Registration',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            '${registrations.length} Courses Registered',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$totalCredits / ${dataService.maxCreditHours} CH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Course List
                Expanded(
                  child: registrations.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 54,
                                  color: isDark ? const Color(0xFF555555) : const Color(0xFF9E9E9E),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No Courses Registered',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'You haven\'t registered for any courses for Fall 2026 yet.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: onNavigateToRegistration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? Colors.white : Colors.black,
                                    foregroundColor: isDark ? Colors.black : Colors.white,
                                  ),
                                  child: const Text('Register Courses'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: registrations.length,
                          itemBuilder: (context, index) {
                            final reg = registrations[index];
                            final course = dataService.getCourseByCode(reg.courseCode);
                            final section = dataService.getSectionById(reg.sectionId);
                            if (course == null || section == null) return const SizedBox.shrink();

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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white : Colors.black,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            course.code,
                                            style: TextStyle(
                                              color: isDark ? Colors.black : Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${course.creditHours} CH',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      course.title,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${section.sectionName} • ${section.instructor}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${section.days.join(" / ")} • ${section.startTime} - ${section.endTime}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${section.room})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),

                                    // Action buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => CourseDetailsScreen(course: course),
                                              ),
                                            );
                                          },
                                          child: const Text('View Details'),
                                        ),
                                        const SizedBox(width: 4),
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => SectionSelectionScreen(
                                                  course: course,
                                                  isChangingSection: true,
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('Change Section', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 6),
                                        TextButton(
                                          onPressed: () => _confirmDrop(context, dataService, course.code, course.title),
                                          style: TextButton.styleFrom(
                                            foregroundColor: const Color(0xFFDC2626),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            minimumSize: Size.zero,
                                          ),
                                          child: const Text('Drop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
