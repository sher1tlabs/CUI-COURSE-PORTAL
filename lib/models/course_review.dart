class CourseReview {
  final String id;
  final String studentId;
  final String courseCode;
  final String courseName;
  final String instructorId;
  final String instructorName;
  final String semesterId;
  final int difficulty; // 1-5 (1: Very Easy, 5: Very Difficult)
  final int workload; // 1-5 (1: Very Low, 5: Very High)
  final int teachingRating; // 1-5 (Teaching clarity / quality)
  final int organizationRating; // 1-5
  final int communicationRating; // 1-5
  final int supportRating; // 1-5 (Availability/support)
  final String comment;
  final bool anonymous;
  final String status; // 'published', 'pending', 'hidden', 'flagged'
  final DateTime createdAt;
  final DateTime updatedAt;

  const CourseReview({
    required this.id,
    required this.studentId,
    required this.courseCode,
    required this.courseName,
    required this.instructorId,
    this.instructorName = '',
    required this.semesterId,
    required this.difficulty,
    required this.workload,
    required this.teachingRating,
    this.organizationRating = 4,
    this.communicationRating = 4,
    this.supportRating = 4,
    this.comment = '',
    this.anonymous = true,
    this.status = 'published',
    required this.createdAt,
    required this.updatedAt,
  });

  factory CourseReview.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return CourseReview(
      id: docId,
      studentId: map['studentId'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      courseName: map['courseName'] as String? ?? '',
      instructorId: map['instructorId'] as String? ?? '',
      instructorName: map['instructorName'] as String? ?? '',
      semesterId: map['semesterId'] as String? ?? 'Spring 2026',
      difficulty: (map['difficulty'] as num?)?.toInt() ?? 3,
      workload: (map['workload'] as num?)?.toInt() ?? 3,
      teachingRating: (map['teachingRating'] as num?)?.toInt() ?? 4,
      organizationRating: (map['organizationRating'] as num?)?.toInt() ?? 4,
      communicationRating: (map['communicationRating'] as num?)?.toInt() ?? 4,
      supportRating: (map['supportRating'] as num?)?.toInt() ?? 4,
      comment: map['comment'] as String? ?? '',
      anonymous: map['anonymous'] as bool? ?? true,
      status: map['status'] as String? ?? 'published',
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'courseCode': courseCode,
      'courseName': courseName,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'semesterId': semesterId,
      'difficulty': difficulty,
      'workload': workload,
      'teachingRating': teachingRating,
      'organizationRating': organizationRating,
      'communicationRating': communicationRating,
      'supportRating': supportRating,
      'comment': comment,
      'anonymous': anonymous,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String difficultyLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Easy';
      case 2:
        return 'Easy';
      case 3:
        return 'Moderate';
      case 4:
        return 'Difficult';
      case 5:
        return 'Very Difficult';
      default:
        return 'Moderate';
    }
  }

  static String workloadLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Moderate';
    }
  }
}
