import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/section.dart';
import '../../services/local_data_service.dart';
import '../../widgets/section_card.dart';
import '../../widgets/instructor_info_sheet.dart';

class SectionSelectionScreen extends StatefulWidget {
  final Course course;
  final bool isChangingSection;

  const SectionSelectionScreen({
    super.key,
    required this.course,
    this.isChangingSection = false,
  });

  @override
  State<SectionSelectionScreen> createState() => _SectionSelectionScreenState();
}

class _SectionSelectionScreenState extends State<SectionSelectionScreen> {
  final _dataService = LocalDataService();

  void _confirmAndRegister(Section section) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isChangingSection) {
      // Change section confirmation
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change to ${section.sectionName}?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.course.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text('Instructor: ${section.instructor}'),
              Text('Schedule: ${section.days.join(" / ")} (${section.startTime} - ${section.endTime})'),
              Text('Room: ${section.room}'),
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
                final result = _dataService.changeSection(widget.course.code, section.id);
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'])),
                  );
                  Navigator.of(context).pop();
                } else {
                  _showErrorDialog(result['message']);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Confirm Change'),
            ),
          ],
        ),
      );
      return;
    }

    // Normal Registration Confirmation Dialog
    final currentCredits = _dataService.totalRegisteredCreditHours;
    final newTotalCredits = currentCredits + widget.course.creditHours;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Register for ${widget.course.code}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text('${section.sectionName} • ${widget.course.creditHours} Credit Hours'),
            Text('Instructor: ${section.instructor}'),
            Text('${section.days.join(" / ")} • ${section.startTime} - ${section.endTime}'),
            Text('Room: ${section.room}'),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Current total:'),
                Text('$currentCredits credit hours', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New total:'),
                Text('$newTotalCredits credit hours', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
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
              final success = _dataService.registerCourse(widget.course.code, section.id);
              if (success) {
                _showSuccessDialog();
              } else {
                final validation = _dataService.validateRegistration(widget.course, section);
                _showErrorDialog(validation['error'] ?? 'Registration failed.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: const Text('Confirm Registration'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? Colors.white : Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: isDark ? Colors.black : Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registration Successful',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'You have successfully registered for ${widget.course.code} (${widget.course.title}). Your timetable has been updated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Back to course list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cannot Register'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final sections = _dataService.getSectionsForCourse(widget.course.code);
        final reg = _dataService.getRegistrationForCourse(widget.course.code);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isChangingSection ? 'Change Section' : 'Available Sections'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Course Summary Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.course.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            '${widget.course.creditHours} Credit Hours',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.course.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sections List
                Expanded(
                  child: sections.isEmpty
                      ? const Center(
                          child: Text('No sections available for this course.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sections.length,
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            final isCurrentSection = reg?.sectionId == section.id;
                            final conflictCheck = _dataService.checkScheduleConflict(
                              section,
                              ignoreCourseCode: widget.isChangingSection ? widget.course.code : null,
                            );
                            final hasConflict = conflictCheck['hasConflict'] == true;

                            return SectionCard(
                              section: section,
                              isRegistered: isCurrentSection,
                              hasConflict: hasConflict,
                              conflictMessage: conflictCheck['message'],
                              onSelect: () => _confirmAndRegister(section),
                              onInstructorTap: () {
                                final instructor = _dataService.getInstructorById(section.instructorId);
                                if (instructor != null) {
                                  InstructorInfoSheet.show(context, instructor);
                                }
                              },
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
