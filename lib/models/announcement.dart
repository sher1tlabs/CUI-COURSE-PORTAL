class UniversityAnnouncement {
  final String id;
  final String title;
  final String body;
  final String category; // Registration, Examination, Academic, Scholarship, Fees, Department, Events, General, Emergency
  final String priority; // Normal, Important, Urgent
  final DateTime publishedAt;
  final DateTime? expiresAt;
  final String campus; // 'All' or specific campus e.g. 'Islamabad'
  final String department; // 'All' or specific department
  final String program; // 'All' or specific program e.g. 'BS Computer Science'
  final String semester; // 'All' or specific semester
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UniversityAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.priority = 'Normal',
    required this.publishedAt,
    this.expiresAt,
    this.campus = 'All',
    this.department = 'All',
    this.program = 'All',
    this.semester = 'All',
    this.createdBy = 'COMSATS Registrar',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isUrgent => priority.toLowerCase() == 'urgent';
  bool get isImportant => priority.toLowerCase() == 'important';

  factory UniversityAnnouncement.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UniversityAnnouncement(
      id: docId,
      title: map['title'] as String? ?? 'Announcement',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      priority: map['priority'] as String? ?? 'Normal',
      publishedAt: parseDate(map['publishedAt'], DateTime.now()),
      expiresAt: parseNullableDate(map['expiresAt']),
      campus: map['campus'] as String? ?? 'All',
      department: map['department'] as String? ?? 'All',
      program: map['program'] as String? ?? 'All',
      semester: map['semester']?.toString() ?? 'All',
      createdBy: map['createdBy'] as String? ?? 'Academic Administration',
      createdAt: parseDate(map['createdAt'], DateTime.now()),
      updatedAt: parseDate(map['updatedAt'], DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'priority': priority,
      'publishedAt': publishedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'campus': campus,
      'department': department,
      'program': program,
      'semester': semester,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
