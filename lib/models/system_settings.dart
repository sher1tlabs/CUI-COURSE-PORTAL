class SystemSettings {
  final bool isRegistrationOpen;
  final String semester;
  final String academicYear;
  final String startDate;
  final String endDate;
  final int maxCreditHours;
  final int minCreditHours;
  final String addDropDeadline;

  const SystemSettings({
    this.isRegistrationOpen = true,
    this.semester = 'Spring 2026',
    this.academicYear = '2025-2026',
    this.startDate = 'Feb 10, 2026',
    this.endDate = 'Feb 28, 2026',
    this.maxCreditHours = 18,
    this.minCreditHours = 12,
    this.addDropDeadline = 'Feb 28, 2026, 11:59 PM',
  });

  factory SystemSettings.fromMap(Map<String, dynamic> map) {
    return SystemSettings(
      isRegistrationOpen: map['isRegistrationOpen'] as bool? ?? true,
      semester: map['semester'] as String? ?? 'Spring 2026',
      academicYear: map['academicYear'] as String? ?? '2025-2026',
      startDate: map['startDate'] as String? ?? 'Feb 10, 2026',
      endDate: map['endDate'] as String? ?? 'Feb 28, 2026',
      maxCreditHours: (map['maxCreditHours'] as num?)?.toInt() ?? 18,
      minCreditHours: (map['minCreditHours'] as num?)?.toInt() ?? 12,
      addDropDeadline: map['addDropDeadline'] as String? ?? 'Feb 28, 2026, 11:59 PM',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isRegistrationOpen': isRegistrationOpen,
      'semester': semester,
      'academicYear': academicYear,
      'startDate': startDate,
      'endDate': endDate,
      'maxCreditHours': maxCreditHours,
      'minCreditHours': minCreditHours,
      'addDropDeadline': addDropDeadline,
    };
  }
}
