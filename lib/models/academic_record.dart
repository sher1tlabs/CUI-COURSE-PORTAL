class SemesterCourseGrade {
  final String courseCode;
  final String courseTitle;
  final int creditHours;
  final String grade;
  final double gradePoint;
  final int marks;

  const SemesterCourseGrade({
    required this.courseCode,
    required this.courseTitle,
    required this.creditHours,
    required this.grade,
    required this.gradePoint,
    required this.marks,
  });

  factory SemesterCourseGrade.fromMap(Map<String, dynamic> map) {
    return SemesterCourseGrade(
      courseCode: map['courseCode'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      creditHours: (map['creditHours'] as num?)?.toInt() ?? 3,
      grade: map['grade'] as String? ?? 'A',
      gradePoint: (map['gradePoint'] as num?)?.toDouble() ?? 4.0,
      marks: (map['marks'] as num?)?.toInt() ?? 85,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'creditHours': creditHours,
      'grade': grade,
      'gradePoint': gradePoint,
      'marks': marks,
    };
  }
}

class AcademicRecord {
  final String id;
  final String studentId;
  final String semester;
  final String academicYear;
  final double gpa;
  final double cgpa;
  final int creditHoursEarned;
  final int creditHoursAttempted;
  final List<SemesterCourseGrade> courses;

  const AcademicRecord({
    required this.id,
    required this.studentId,
    required this.semester,
    this.academicYear = '2024-2025',
    required this.gpa,
    required this.cgpa,
    required this.creditHoursEarned,
    required this.creditHoursAttempted,
    this.courses = const [],
  });

  factory AcademicRecord.fromMap(Map<String, dynamic> map, String docId) {
    var rawCourses = map['courses'] as List? ?? [];
    List<SemesterCourseGrade> gradesList = rawCourses
        .map((c) => SemesterCourseGrade.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    return AcademicRecord(
      id: docId,
      studentId: map['studentId'] as String? ?? '',
      semester: map['semester'] as String? ?? 'Fall 2025',
      academicYear: map['academicYear'] as String? ?? '2025',
      gpa: (map['gpa'] as num?)?.toDouble() ?? 3.5,
      cgpa: (map['cgpa'] as num?)?.toDouble() ?? 3.5,
      creditHoursEarned: (map['creditHoursEarned'] as num?)?.toInt() ?? 18,
      creditHoursAttempted: (map['creditHoursAttempted'] as num?)?.toInt() ?? 18,
      courses: gradesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'semester': semester,
      'academicYear': academicYear,
      'gpa': gpa,
      'cgpa': cgpa,
      'creditHoursEarned': creditHoursEarned,
      'creditHoursAttempted': creditHoursAttempted,
      'courses': courses.map((c) => c.toMap()).toList(),
    };
  }
}
