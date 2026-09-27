class Course {
  final String id;
  final String code;
  final String title;
  final int creditHours;
  final String department;
  final String description;
  final List<String> prerequisites;
  final List<String> corequisites;
  final String courseType; // 'Core', 'Elective', 'University Requirement'
  final int recommendedSemester;
  final bool isOffered;
  final int availableSeats;
  final int totalSeats;

  const Course({
    this.id = '',
    required this.code,
    required this.title,
    required this.creditHours,
    required this.department,
    required this.description,
    this.prerequisites = const [],
    this.corequisites = const [],
    required this.courseType,
    required this.recommendedSemester,
    this.isOffered = true,
    this.availableSeats = 45,
    this.totalSeats = 50,
  });

  factory Course.fromMap(Map<String, dynamic> map, String docId) {
    return Course(
      id: docId,
      code: map['code'] as String? ?? '',
      title: map['title'] as String? ?? '',
      creditHours: (map['creditHours'] as num?)?.toInt() ?? 3,
      department: map['department'] as String? ?? 'Computer Science',
      description: map['description'] as String? ?? '',
      prerequisites: List<String>.from(map['prerequisiteCodes'] ?? map['prerequisites'] ?? []),
      corequisites: List<String>.from(map['corequisites'] ?? []),
      courseType: map['courseType'] as String? ?? 'Core',
      recommendedSemester: (map['minimumSemester'] ?? map['recommendedSemester'] as num?)?.toInt() ?? 1,
      isOffered: map['isOffered'] as bool? ?? true,
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'title': title,
      'creditHours': creditHours,
      'department': department,
      'description': description,
      'prerequisites': prerequisites,
      'prerequisiteCodes': prerequisites,
      'corequisites': corequisites,
      'courseType': courseType,
      'recommendedSemester': recommendedSemester,
      'minimumSemester': recommendedSemester,
      'isOffered': isOffered,
      'availableSeats': availableSeats,
      'totalSeats': totalSeats,
    };
  }
}
