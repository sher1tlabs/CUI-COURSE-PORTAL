class Student {
  final String id;
  final String name;
  final String registrationNumber;
  final String email;
  final String phoneNumber;
  final String program;
  final String campus;
  final String batch;
  final int semester;
  final double cgpa;
  final int completedCreditHours;
  final String academicStanding;
  final String avatarUrl;

  const Student({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.email,
    this.phoneNumber = '+92 300 1234567',
    required this.program,
    required this.campus,
    this.batch = 'FA23',
    required this.semester,
    required this.cgpa,
    this.completedCreditHours = 64,
    this.academicStanding = 'Good Standing',
    this.avatarUrl = '',
  });

  factory Student.fromMap(Map<String, dynamic> map, String docId) {
    return Student(
      id: docId,
      name: map['name'] as String? ?? 'Student',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? map['phone'] as String? ?? '',
      program: map['program'] as String? ?? 'BS Computer Science',
      campus: map['campus'] as String? ?? 'Islamabad',
      batch: map['batch'] as String? ?? 'FA23',
      semester: (map['semester'] as num?)?.toInt() ?? 1,
      cgpa: (map['cgpa'] as num?)?.toDouble() ?? 0.0,
      completedCreditHours: (map['completedCreditHours'] as num?)?.toInt() ?? 0,
      academicStanding: map['academicStanding'] as String? ?? 'Good Standing',
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'name': name,
      'registrationNumber': registrationNumber,
      'email': email,
      'phone': phoneNumber,
      'program': program,
      'campus': campus,
      'batch': batch,
      'semester': semester,
      'cgpa': cgpa,
      'completedCreditHours': completedCreditHours,
      'academicStanding': academicStanding,
      'avatarUrl': avatarUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  Student copyWith({
    String? name,
    String? phoneNumber,
    String? avatarUrl,
    int? semester,
    double? cgpa,
    int? completedCreditHours,
    String? academicStanding,
  }) {
    return Student(
      id: id,
      name: name ?? this.name,
      registrationNumber: registrationNumber,
      email: email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      program: program,
      campus: campus,
      batch: batch,
      semester: semester ?? this.semester,
      cgpa: cgpa ?? this.cgpa,
      completedCreditHours: completedCreditHours ?? this.completedCreditHours,
      academicStanding: academicStanding ?? this.academicStanding,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
