import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/course_review.dart';
import '../../services/review_service.dart';
import '../../widgets/custom_button.dart';

class SubmitReviewScreen extends StatefulWidget {
  final Course course;
  final String instructorId;
  final String instructorName;

  const SubmitReviewScreen({
    super.key,
    required this.course,
    required this.instructorId,
    required this.instructorName,
  });

  @override
  State<SubmitReviewScreen> createState() => _SubmitReviewScreenState();
}

class _SubmitReviewScreenState extends State<SubmitReviewScreen> {
  int _difficulty = 3;
  int _workload = 3;
  int _teachingRating = 4;
  int _organizationRating = 4;
  int _communicationRating = 4;
  int _supportRating = 4;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ReviewService.instance.submitReview(
        courseCode: widget.course.code,
        courseName: widget.course.title,
        instructorId: widget.instructorId.isNotEmpty ? widget.instructorId : 'inst-gen',
        instructorName: widget.instructorName,
        semesterId: 'Spring 2026',
        difficulty: _difficulty,
        workload: _workload,
        teachingRating: _teachingRating,
        organizationRating: _organizationRating,
        communicationRating: _communicationRating,
        supportRating: _supportRating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted anonymously. Thank you!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Feedback'),
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
              Text(
                'Submit Feedback',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.course.code} • ${widget.course.title}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),

              // Confidentiality notice banner
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
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your feedback is strictly anonymous. Your name, email, and registration number will never be shown to peers.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D1212) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: BorderSide(
                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Section: Course Feedback
              Text(
                'Course Experience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Difficulty',
                value: _difficulty,
                labels: ['1: Very Easy', '2: Easy', '3: Moderate', '4: Difficult', '5: Very Difficult'],
                onChanged: (val) => setState(() => _difficulty = val),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Workload',
                value: _workload,
                labels: ['1: Very Low', '2: Low', '3: Moderate', '4: High', '5: Very High'],
                onChanged: (val) => setState(() => _workload = val),
                isDark: isDark,
              ),
              const SizedBox(height: 28),

              // Section: Instructor Feedback
              Text(
                'Instructor Feedback: ${widget.instructorName}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Teaching Clarity',
                value: _teachingRating,
                labels: ['1: Poor', '2: Fair', '3: Average', '4: Good', '5: Excellent'],
                onChanged: (val) => setState(() => _teachingRating = val),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Communication & Responsiveness',
                value: _communicationRating,
                labels: ['1: Poor', '2: Fair', '3: Average', '4: Good', '5: Excellent'],
                onChanged: (val) => setState(() => _communicationRating = val),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Course Organization',
                value: _organizationRating,
                labels: ['1: Poor', '2: Fair', '3: Average', '4: Good', '5: Excellent'],
                onChanged: (val) => setState(() => _organizationRating = val),
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              _buildScaleSelector(
                title: 'Availability & Support',
                value: _supportRating,
                labels: ['1: Poor', '2: Fair', '3: Average', '4: Good', '5: Excellent'],
                onChanged: (val) => setState(() => _supportRating = val),
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Anonymous Written Comments
              Text(
                'Anonymous Written Comments (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Share constructive comments regarding course materials, exams, pacing, or assignments...',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Disclaimer: These ratings are based on student feedback and are not official university evaluations.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? const Color(0xFF737373) : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 28),

              CustomButton(
                label: 'Submit Anonymous Feedback',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleSelector({
    required String title,
    required int value,
    required List<String> labels,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE5E5E5) : const Color(0xFF374151),
              ),
            ),
            Text(
              labels[value - 1],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = rating == value;

            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(rating),
                child: Container(
                  margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF3F4F6)),
                    borderRadius: BorderRadius.circular(10),
                    border: BorderSide(
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected
                            ? (isDark ? Colors.black : Colors.white)
                            : (isDark ? const Color(0xFFA3A3A3) : const Color(0xFF4B5563)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
