import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/course_review.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import 'submit_review_screen.dart';

class CourseReviewsScreen extends StatefulWidget {
  final Course course;

  const CourseReviewsScreen({
    super.key,
    required this.course,
  });

  @override
  State<CourseReviewsScreen> createState() => _CourseReviewsScreenState();
}

class _CourseReviewsScreenState extends State<CourseReviewsScreen> {
  final ReviewService _reviewService = ReviewService.instance;

  void _showReportDialog(BuildContext context, String reviewId) {
    final reasonController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Report Feedback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason why this review violates community standards (e.g. abusive language, misinformation):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Describe the issue...',
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
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await _reviewService.reportReview(
                  reviewId: reviewId,
                  reason: reasonController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback reported for moderation.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _navigateToSubmit() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit feedback.')),
      );
      return;
    }

    final eligibility = await _reviewService.checkReviewEligibility(
      studentId: user.uid,
      courseCode: widget.course.code,
    );

    if (!mounted) return;

    if (eligibility['eligible'] != true) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF141414)
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Review Eligibility'),
          content: Text(
            eligibility['reason'] ??
                'You must be currently registered in or have completed this course to submit feedback.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubmitReviewScreen(
          course: widget.course,
          instructorId: eligibility['instructorId'] ?? '',
          instructorName: eligibility['instructorName'] ?? 'Faculty Member',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.course.code} Feedback'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToSubmit,
        icon: const Icon(Icons.rate_review_outlined, size: 18),
        label: const Text('Add Feedback', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? Colors.white : Colors.black,
        foregroundColor: isDark ? Colors.black : Colors.white,
      ),
      body: StreamBuilder<List<CourseReview>>(
        stream: _reviewService.streamCourseReviews(widget.course.code),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data ?? [];

          double avgDifficulty = 0;
          double avgWorkload = 0;
          double avgTeaching = 0;

          if (reviews.isNotEmpty) {
            avgDifficulty = reviews.fold<int>(0, (s, r) => s + r.difficulty) / reviews.length;
            avgWorkload = reviews.fold<int>(0, (s, r) => s + r.workload) / reviews.length;
            avgTeaching = reviews.fold<int>(0, (s, r) => s + r.teachingRating) / reviews.length;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge & title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Student-submitted feedback',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.course.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.course.code} • ${widget.course.creditHours} Credit Hours • ${widget.course.department}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),

                // Disclaimer box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF171717) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: BorderSide(
                      color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'These ratings are based on student feedback and are not official university evaluations. All student identities are kept strictly confidential.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Aggregated metrics card
                if (reviews.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Feedback Overview',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              '${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricItem(
                                title: 'Difficulty',
                                value: avgDifficulty.toStringAsFixed(1),
                                sublabel: CourseReview.difficultyLabel(avgDifficulty.round()),
                                isDark: isDark,
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                            Expanded(
                              child: _buildMetricItem(
                                title: 'Workload',
                                value: avgWorkload.toStringAsFixed(1),
                                sublabel: CourseReview.workloadLabel(avgWorkload.round()),
                                isDark: isDark,
                              ),
                            ),
                            Container(width: 1, height: 40, color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB)),
                            Expanded(
                              child: _buildMetricItem(
                                title: 'Teaching',
                                value: avgTeaching.toStringAsFixed(1),
                                sublabel: 'Clarity',
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Student reviews list
                Text(
                  'Anonymous Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),

                if (reviews.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141414) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 40,
                          color: isDark ? const Color(0xFF525252) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No student feedback yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first verified enrolled student to share feedback on this course.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final rev = reviews[idx];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141414) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: BorderSide(
                            color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Reviewer anonymity banner & date
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin_outlined,
                                      size: 16,
                                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Anonymous Student • ${rev.semesterId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.flag_outlined, size: 16),
                                  tooltip: 'Report feedback',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                                  onPressed: () => _showReportDialog(context, rev.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Ratings chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildBadge(
                                  'Difficulty: ${rev.difficulty}/5 (${CourseReview.difficultyLabel(rev.difficulty)})',
                                  isDark,
                                ),
                                _buildBadge(
                                  'Workload: ${rev.workload}/5 (${CourseReview.workloadLabel(rev.workload)})',
                                  isDark,
                                ),
                                _buildBadge(
                                  'Teaching: ${rev.teachingRating}/5',
                                  isDark,
                                ),
                              ],
                            ),
                            if (rev.comment.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                rev.comment,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151),
                                ),
                              ),
                            ],
                            if (rev.instructorName.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Instructor: ${rev.instructorName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required String value,
    required String sublabel,
    required bool isDark,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
        border: BorderSide(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF374151),
        ),
      ),
    );
  }
}
