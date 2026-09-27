class Registration {
  final String id;
  final String studentId;
  final String courseId;
  final String courseCode;
  final String courseTitle;
  final int creditHours;
  final String sectionId;
  final String sectionCode;
  final String instructorName;
  final List<String> days;
  final String timeSlot;
  final String room;
  final String semester;
  final String status; // 'Registered', 'Dropped'
  final DateTime registrationDate;

  const Registration({
    required this.id,
    required this.studentId,
    this.courseId = '',
    required this.courseCode,
    this.courseTitle = '',
    this.creditHours = 3,
    required this.sectionId,
    this.sectionCode = '',
    this.instructorName = '',
    this.days = const [],
    this.timeSlot = '',
    this.room = '',
    required this.semester,
    this.status = 'Registered',
    required this.registrationDate,
  });

  factory Registration.fromMap(Map<String, dynamic> map, String docId) {
    DateTime regDate = DateTime.now();
    if (map['registeredAt'] is String) {
      regDate = DateTime.tryParse(map['registeredAt']) ?? DateTime.now();
    } else if (map['registrationDate'] is String) {
      regDate = DateTime.tryParse(map['registrationDate']) ?? DateTime.now();
    }

    return Registration(
      id: docId,
      studentId: map['studentId'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      courseCode: map['courseCode'] as String? ?? '',
      courseTitle: map['courseTitle'] as String? ?? '',
      creditHours: (map['creditHours'] as num?)?.toInt() ?? 3,
      sectionId: map['sectionId'] as String? ?? '',
      sectionCode: map['sectionCode'] as String? ?? '',
      instructorName: map['instructorName'] as String? ?? '',
      days: List<String>.from(map['days'] ?? []),
      timeSlot: map['timeSlot'] as String? ?? '',
      room: map['room'] as String? ?? '',
      semester: map['semester'] as String? ?? 'Spring 2026',
      status: map['status'] as String? ?? 'Registered',
      registrationDate: regDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'courseCode': courseCode,
      'courseTitle': courseTitle,
      'creditHours': creditHours,
      'sectionId': sectionId,
      'sectionCode': sectionCode,
      'instructorName': instructorName,
      'days': days,
      'timeSlot': timeSlot,
      'room': room,
      'semester': semester,
      'status': status,
      'registeredAt': registrationDate.toIso8601String(),
    };
  }
}
