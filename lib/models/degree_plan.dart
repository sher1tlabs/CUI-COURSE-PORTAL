class SemesterPlan {
  final int semester;
  final List<String> courses;
  final List<String> electives;

  const SemesterPlan({
    required this.semester,
    required this.courses,
    this.electives = const [],
  });

  factory SemesterPlan.fromMap(Map<String, dynamic> map) {
    return SemesterPlan(
      semester: (map['semester'] as num?)?.toInt() ?? 1,
      courses: List<String>.from(map['courses'] ?? []),
      electives: List<String>.from(map['electives'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'semester': semester,
      'courses': courses,
      'electives': electives,
    };
  }
}

class DegreePlan {
  final String id;
  final String program;
  final String campus;
  final int totalCreditHours;
  final List<SemesterPlan> semesters;
  final List<String> generalElectives;

  const DegreePlan({
    required this.id,
    required this.program,
    this.campus = 'All',
    this.totalCreditHours = 133,
    required this.semesters,
    this.generalElectives = const [],
  });

  factory DegreePlan.fromMap(Map<String, dynamic> map, String docId) {
    final rawSemesters = map['semesters'] as List? ?? [];
    final parsedSemesters = rawSemesters
        .map((s) => SemesterPlan.fromMap(Map<String, dynamic>.from(s as Map)))
        .toList();

    return DegreePlan(
      id: docId,
      program: map['program'] as String? ?? 'BS Computer Science',
      campus: map['campus'] as String? ?? 'All',
      totalCreditHours: (map['totalCreditHours'] as num?)?.toInt() ?? 133,
      semesters: parsedSemesters,
      generalElectives: List<String>.from(map['electives'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'program': program,
      'campus': campus,
      'totalCreditHours': totalCreditHours,
      'semesters': semesters.map((s) => s.toMap()).toList(),
      'electives': generalElectives,
    };
  }

  /// Get the planned courses for a specific semester
  List<String> getCoursesForSemester(int semesterNum) {
    for (final s in semesters) {
      if (s.semester == semesterNum) {
        return s.courses;
      }
    }
    return [];
  }
}
