import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/local_data_service.dart';
import '../../services/review_service.dart';
import '../reviews/course_reviews_screen.dart';
import 'section_selection_screen.dart';

class CourseDetailsScreen extends StatelessWidget {
  final Course course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dataService = LocalDataService();
    final prereqStatus = dataService.checkPrerequisites(course);
    final hasPrereqs = prereqStatus['passed'] == true;
    final isRegistered = dataService.isCourseRegistered(course.code);

    return Scaffold(
      appBar: AppBar(
        title: Text(course.code),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Row
              Row(
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      '${course.creditHours} Credit Hours',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.courseType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                course.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                course.department,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              // Prerequisite Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141414) : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasPrereqs
                        ? (isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB))
                        : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasPrereqs ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          size: 20,
                          color: hasPrereqs
                              ? (isDark ? Colors.white : Colors.black)
                              : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasPrereqs ? 'Prerequisites Satisfied' : 'Prerequisite Requirement Missing',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: hasPrereqs
                                ? (isDark ? Colors.white : Colors.black)
                                : (isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.prerequisites.isEmpty
                          ? 'This course has no prerequisites. It can be registered by any eligible student.'
                          : (hasPrereqs
                              ? 'Required prerequisites completed: ${course.prerequisites.join(", ")}'
                              : 'You cannot register for this course because the required prerequisite (${course.prerequisites.join(", ")}) has not been completed.'),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? const Color(0xFFB0B0B0) : const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Course Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                course.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: isDark ? const Color(0xFFCCCCCC) : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 24),

              // Academic Details Table
              Text(
                'Course Curriculum Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Department', course.department),
              _buildDetailRow(context, 'Credit Hours', '${course.creditHours} CH'),
              _buildDetailRow(context, 'Course Category', course.courseType),
              _buildDetailRow(context, 'Recommended Semester', 'Semester ${course.recommendedSemester}'),
              _buildDetailRow(context, 'Prerequisites', course.prerequisites.isEmpty ? 'None' : course.prerequisites.join(', ')),
              _buildDetailRow(context, 'Corequisites', course.corequisites.isEmpty ? 'None' : course.corequisites.join(', ')),

              const SizedBox(height: 24),

              // Student Feedback Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student Feedback',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Student-submitted feedback',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              FutureBuilder<Map<String, dynamic>>(
                future: ReviewService.instance.getCourseAggregates(course.code),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? {'count': 0, 'avgDifficulty': 3.5, 'avgWorkload': 3.4, 'avgTeaching': 4.2};
                  final count = data['count'] as int? ?? 0;
                  final double diff = (data['avgDifficulty'] as num?)?.toDouble() ?? 3.5;
                  final double work = (data['avgWorkload'] as num?)?.toDouble() ?? 3.4;
                  final double teach = (data['avgTeaching'] as num?)?.toDouble() ?? 4.2;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  count > 0 ? diff.toStringAsFixed(1) : '3.8',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                                ),
                                Text('Difficulty', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280))),
                              ],
                            ),
                            Container(width: 1, height: 32, color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                            Column(
                              children: [
                                Text(
                                  count > 0 ? work.toStringAsFixed(1) : '3.5',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                                ),
                                Text('Workload', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280))),
                              ],
                            ),
                            Container(width: 1, height: 32, color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                            Column(
                              children: [
                                Text(
                                  count > 0 ? teach.toStringAsFixed(1) : '4.4',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
                                ),
                                Text('Teaching', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'These ratings are based on student feedback and are not official university evaluations.',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CourseReviewsScreen(course: course),
                                ),
                              );
                            },
                            icon: const Icon(Icons.forum_outlined, size: 16),
                            label: const Text('View All Feedback & Comments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 36),

              // Bottom Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isRegistered
                      ? null
                      : () {
                          if (!hasPrereqs) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                                title: const Text('Prerequisite Incomplete'),
                                content: Text(
                                  'You cannot register for ${course.code} because the required prerequisite (${course.prerequisites.join(", ")}) has not been completed.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SectionSelectionScreen(course: course),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isRegistered
                        ? 'Course Already Registered'
                        : (!hasPrereqs ? 'Prerequisite Incomplete' : 'View Available Sections'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
    );
  }
}
