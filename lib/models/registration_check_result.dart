enum CheckStatus {
  pass,
  warning,
  error,
}

class AdvisorCheckItem {
  final String title;
  final String description;
  final CheckStatus status;
  final String? courseCode;

  const AdvisorCheckItem({
    required this.title,
    required this.description,
    required this.status,
    this.courseCode,
  });
}

class RegistrationCheckResult {
  final int selectedCoursesCount;
  final int totalCreditHours;
  final int minAllowedCredits;
  final int maxAllowedCredits;
  final List<String> passedChecks;
  final List<String> warnings;
  final List<String> errors;
  final List<Map<String, String>> recommendations; // [{courseCode: '...', reason: '...'}]
  final List<AdvisorCheckItem> detailedItems;

  const RegistrationCheckResult({
    required this.selectedCoursesCount,
    required this.totalCreditHours,
    this.minAllowedCredits = 12,
    this.maxAllowedCredits = 18,
    required this.passedChecks,
    required this.warnings,
    required this.errors,
    this.recommendations = const [],
    this.detailedItems = const [],
  });

  bool get hasBlockingErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get isCleanPass => errors.isEmpty && warnings.isEmpty;
}
