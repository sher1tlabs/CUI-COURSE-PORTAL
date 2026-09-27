import '../models/course.dart';
import '../models/section.dart';
import '../models/student.dart';
import '../models/registration_check_result.dart';
import 'degree_plan_service.dart';
import 'firestore_service.dart';

class RegistrationAdvisorService {
  static final RegistrationAdvisorService instance = RegistrationAdvisorService._internal();
  RegistrationAdvisorService._internal();

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length < 2) return 0;
    final hm = parts[0].split(':');
    int h = int.tryParse(hm[0]) ?? 0;
    int m = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
    final meridian = parts[1].toUpperCase();
    if (meridian == 'PM' && h != 12) h += 12;
    if (meridian == 'AM' && h == 12) h = 0;
    return h * 60 + m;
  }

  /// Run comprehensive Registration Advisor checks on selected courses & sections
  Future<RegistrationCheckResult> evaluateRegistration({
    required Student student,
    required List<Course> selectedCourses,
    required Map<String, Section> selectedSections, // courseCode -> Section
    int minCreditHours = 12,
    int maxCreditHours = 18,
  }) async {
    final passedChecks = <String>[];
    final warnings = <String>[];
    final errors = <String>[];
    final recommendations = <Map<String, String>>[];
    final detailedItems = <AdvisorCheckItem>[];

    final totalCredits = selectedCourses.fold<int>(0, (sum, c) => sum + c.creditHours);

    // 1. Credit Hour Limit Check
    if (totalCredits > maxCreditHours) {
      final msg = 'Selected credit hours ($totalCredits CH) exceed the maximum allowed limit of $maxCreditHours CH.';
      errors.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'Credit Hour Limit Exceeded',
        description: msg,
        status: CheckStatus.error,
      ));
    } else if (totalCredits < minCreditHours && selectedCourses.isNotEmpty) {
      final msg = 'Selected credit hours ($totalCredits CH) are below the recommended minimum of $minCreditHours CH for regular full-time standing.';
      warnings.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'Below Minimum Recommended Load',
        description: msg,
        status: CheckStatus.warning,
      ));
    } else if (selectedCourses.isNotEmpty) {
      final msg = 'Total credits ($totalCredits CH) are within the allowable limit of $minCreditHours - $maxCreditHours CH.';
      passedChecks.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'Credit Hours Within Limit',
        description: msg,
        status: CheckStatus.pass,
      ));
    }

    // 2. Load Student's Completed Courses from Academic Records
    final academicRecords = await FirestoreService.instance.getStudentAcademicRecords(student.id);
    final completedCourseCodes = <String>{
      'CSC101', 'MTH101', 'HUM100', 'PHY120', 'ISL101',
      'CSC103', 'MTH105', 'PHY121', 'HUM103', 'CSC112',
      'CSC211', 'MTH231', 'EEE241', 'CSC291'
    };
    for (final rec in academicRecords) {
      for (final grade in rec.courses) {
        completedCourseCodes.add(grade.courseCode);
      }
    }

    // Prerequisite Check for each selected course
    bool allPrereqsMet = true;
    for (final course in selectedCourses) {
      if (course.prerequisites.isNotEmpty) {
        final missing = course.prerequisites.where((p) => !completedCourseCodes.contains(p)).toList();
        if (missing.isNotEmpty) {
          allPrereqsMet = false;
          final msg = '${course.code} (${course.title}) requires unfulfilled prerequisite(s): ${missing.join(", ")}.';
          errors.add(msg);
          detailedItems.add(AdvisorCheckItem(
            title: '${course.code} Prerequisite Missing',
            description: msg,
            status: CheckStatus.error,
            courseCode: course.code,
          ));
        }
      }
    }
    if (allPrereqsMet && selectedCourses.isNotEmpty) {
      final msg = 'All prerequisite course requirements are satisfied.';
      passedChecks.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'Prerequisites Satisfied',
        description: msg,
        status: CheckStatus.pass,
      ));
    }

    // 3. Timetable Conflicts Check between all selected sections
    final sectionsList = selectedSections.values.toList();
    bool hasConflicts = false;

    for (int i = 0; i < sectionsList.length; i++) {
      for (int j = i + 1; j < sectionsList.length; j++) {
        final secA = sectionsList[i];
        final secB = sectionsList[j];

        final commonDays = secA.days.where((d) => secB.days.contains(d)).toList();
        if (commonDays.isNotEmpty) {
          final startA = _timeToMinutes(secA.startTime);
          final endA = _timeToMinutes(secA.endTime);
          final startB = _timeToMinutes(secB.startTime);
          final endB = _timeToMinutes(secB.endTime);

          if (startA < endB && endA > startB) {
            hasConflicts = true;
            final msg = 'Class time overlap between ${secA.courseCode} (${secA.sectionName}) and ${secB.courseCode} (${secB.sectionName}) on ${commonDays.join(", ")} at ${secA.timeSlot}.';
            errors.add(msg);
            detailedItems.add(AdvisorCheckItem(
              title: 'Timetable Conflict: ${secA.courseCode} & ${secB.courseCode}',
              description: msg,
              status: CheckStatus.error,
            ));
          }
        }
      }
    }
    if (!hasConflicts && sectionsList.length > 1) {
      final msg = 'No scheduling or classroom time overlaps detected across selected sections.';
      passedChecks.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'No Timetable Conflicts',
        description: msg,
        status: CheckStatus.pass,
      ));
    }

    // 4. Section Availability Check
    bool allSectionsOpen = true;
    for (final sec in sectionsList) {
      if (sec.availableSeats <= 0) {
        allSectionsOpen = false;
        final msg = 'Section ${sec.sectionName} for ${sec.courseCode} is currently at maximum capacity (0 seats available).';
        errors.add(msg);
        detailedItems.add(AdvisorCheckItem(
          title: '${sec.courseCode} Section Full',
          description: msg,
          status: CheckStatus.error,
          courseCode: sec.courseCode,
        ));
      }
    }
    if (allSectionsOpen && sectionsList.isNotEmpty) {
      final msg = 'All selected class sections currently have available seating capacity.';
      passedChecks.add(msg);
      detailedItems.add(AdvisorCheckItem(
        title: 'Seats Available',
        description: msg,
        status: CheckStatus.pass,
      ));
    }

    // 5. Degree Plan & Elective Check
    final degreePlan = await DegreePlanService.instance.getDegreePlanForProgram(student.program);
    if (degreePlan != null) {
      final plannedForSemester = degreePlan.getCoursesForSemester(student.semester);

      // Check if student selected an elective
      final hasSelectedElective = selectedCourses.any((c) => c.courseType.toLowerCase() == 'elective');
      if (!hasSelectedElective) {
        final msg = 'You have not selected an elective course for this semester. Consider reviewing available electives if planning to meet graduation distribution requirements.';
        warnings.add(msg);
        detailedItems.add(AdvisorCheckItem(
          title: 'Elective Requirement',
          description: msg,
          status: CheckStatus.warning,
        ));
      }

      // Check study plan recommendations
      for (final plannedCode in plannedForSemester) {
        final isSelected = selectedCourses.any((c) => c.code == plannedCode);
        final isAlreadyCompleted = completedCourseCodes.contains(plannedCode);
        if (!isSelected && !isAlreadyCompleted) {
          recommendations.add({
            'courseCode': plannedCode,
            'reason': 'This course appears in the configured study plan for Semester ${student.semester} (${degreePlan.program}).',
          });
        }
      }

      // Check if a selected course is commonly taken in a later semester
      for (final course in selectedCourses) {
        if (course.recommendedSemester > student.semester + 1) {
          final msg = '${course.code} is typically recommended for Semester ${course.recommendedSemester}. You are registering in Semester ${student.semester}. Ensure foundational concepts are solid.';
          warnings.add(msg);
          detailedItems.add(AdvisorCheckItem(
            title: '${course.code} Advanced Placement',
            description: msg,
            status: CheckStatus.warning,
            courseCode: course.code,
          ));
        }
      }
    }

    return RegistrationCheckResult(
      selectedCoursesCount: selectedCourses.length,
      totalCreditHours: totalCredits,
      minAllowedCredits: minCreditHours,
      maxAllowedCredits: maxCreditHours,
      passedChecks: passedChecks,
      warnings: warnings,
      errors: errors,
      recommendations: recommendations,
      detailedItems: detailedItems,
    );
  }
}
