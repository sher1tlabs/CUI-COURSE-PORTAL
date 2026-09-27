class Instructor {
  final String id;
  final String name;
  final String designation;
  final String department;
  final List<String> coursesTaught;
  final String office;
  final String email;
  final String phone;

  const Instructor({
    required this.id,
    required this.name,
    required this.designation,
    required this.department,
    required this.coursesTaught,
    required this.office,
    required this.email,
    this.phone = '+92 51 9247000',
  });

  factory Instructor.fromMap(Map<String, dynamic> map, String docId) {
    return Instructor(
      id: docId,
      name: map['name'] as String? ?? 'Faculty Member',
      designation: map['designation'] as String? ?? 'Assistant Professor',
      department: map['department'] as String? ?? 'Computer Science',
      coursesTaught: List<String>.from(map['coursesTaught'] ?? []),
      office: map['office'] as String? ?? 'Faculty Block A',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '+92 51 9247000',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'designation': designation,
      'department': department,
      'coursesTaught': coursesTaught,
      'office': office,
      'email': email,
      'phone': phone,
    };
  }
}
