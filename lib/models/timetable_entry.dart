class TimetableEntry {
  final String id;
  final String courseCode;
  final String courseTitle;
  final String sectionName;
  final String instructor;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final int creditHours;

  const TimetableEntry({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.sectionName,
    required this.instructor,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.creditHours,
  });
}
