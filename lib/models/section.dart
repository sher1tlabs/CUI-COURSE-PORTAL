class Section {
  final String id;
  final String courseId;
  final String courseCode;
  final String sectionName;
  final String instructor;
  final String instructorId;
  final List<String> days; // e.g. ['Monday', 'Wednesday']
  final String startTime; // e.g. '09:00 AM'
  final String endTime;   // e.g. '10:30 AM'
  final String timeSlot;  // e.g. '09:00 AM - 10:30 AM'
  final String room;
  final int totalSeats;
  final int availableSeats;
  final int enrolledCount;

  const Section({
    required this.id,
    this.courseId = '',
    required this.courseCode,
    required this.sectionName,
    required this.instructor,
    required this.instructorId,
    required this.days,
    required this.startTime,
    required this.endTime,
    this.timeSlot = '',
    required this.room,
    required this.totalSeats,
    required this.availableSeats,
    this.enrolledCount = 0,
  });

  bool get isFull => availableSeats <= 0;

  factory Section.fromMap(Map<String, dynamic> map, String docId, {String courseId = ''}) {
    final start = map['startTime'] as String? ?? '08:30 AM';
    final end = map['endTime'] as String? ?? '10:00 AM';
    final total = (map['capacity'] ?? map['totalSeats'] as num?)?.toInt() ?? 50;
    final enrolled = (map['enrolledCount'] as num?)?.toInt() ?? 0;
    final avail = (map['availableSeats'] as num?)?.toInt() ?? (total - enrolled);

    return Section(
      id: docId,
      courseId: courseId.isNotEmpty ? courseId : (map['courseId'] as String? ?? ''),
      courseCode: map['courseCode'] as String? ?? '',
      sectionName: map['sectionCode'] ?? map['sectionName'] as String? ?? 'BCS-4A',
      instructor: map['instructorName'] ?? map['instructor'] as String? ?? 'Faculty Member',
      instructorId: map['instructorId'] as String? ?? 'inst-1',
      days: List<String>.from(map['days'] ?? ['Monday', 'Wednesday']),
      startTime: start,
      endTime: end,
      timeSlot: map['timeSlot'] as String? ?? '$start - $end',
      room: map['room'] as String? ?? 'CS Block - 101',
      totalSeats: total,
      availableSeats: avail > 0 ? avail : 0,
      enrolledCount: enrolled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseCode': courseCode,
      'sectionCode': sectionName,
      'sectionName': sectionName,
      'instructorName': instructor,
      'instructorId': instructorId,
      'days': days,
      'startTime': startTime,
      'endTime': endTime,
      'timeSlot': timeSlot.isNotEmpty ? timeSlot : '$startTime - $endTime',
      'room': room,
      'capacity': totalSeats,
      'totalSeats': totalSeats,
      'enrolledCount': enrolledCount,
      'availableSeats': availableSeats,
      'isFull': isFull,
    };
  }

  Section copyWith({
    int? availableSeats,
    int? enrolledCount,
  }) {
    return Section(
      id: id,
      courseId: courseId,
      courseCode: courseCode,
      sectionName: sectionName,
      instructor: instructor,
      instructorId: instructorId,
      days: days,
      startTime: startTime,
      endTime: endTime,
      timeSlot: timeSlot,
      room: room,
      totalSeats: totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      enrolledCount: enrolledCount ?? this.enrolledCount,
    );
  }
}
