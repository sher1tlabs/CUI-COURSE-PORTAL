import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/section.dart';
import '../../models/registration_check_result.dart';
import '../../services/auth_service.dart';
import '../../services/local_data_service.dart';
import '../../services/registration_advisor_service.dart';
import '../../widgets/custom_button.dart';

class RegistrationAdvisorScreen extends StatefulWidget {
  final List<Course>? targetCourses;
  final Map<String, Section>? targetSections;
  final VoidCallback? onConfirmRegistration;

  const RegistrationAdvisorScreen({
    super.key,
    this.targetCourses,
    this.targetSections,
    this.onConfirmRegistration,
  });

  @override
  State<RegistrationAdvisorScreen> createState() => _RegistrationAdvisorScreenState();
}

class _RegistrationAdvisorScreenState extends State<RegistrationAdvisorScreen> {
  final _advisorService = RegistrationAdvisorService.instance;
  final _dataService = LocalDataService();

  RegistrationCheckResult? _result;
  bool _isLoading = true;
  bool _acknowledgedWarnings = false;

  @override
  void initState() {
    super.initState();
    _runEvaluation();
  }

  void _runEvaluation() async {
    setState(() => _isLoading = true);

    final student = AuthService.instance.currentStudent ?? _dataService.currentStudent;

    // Use passed courses/sections or derive from student's registered/selected courses
    List<Course> evalCourses = widget.targetCourses ?? [];
    Map<String, Section> evalSections = widget.targetSections ?? {};

    if (evalCourses.isEmpty) {
      // Evaluate currently registered courses
      final regs = _dataService.registrations;
      evalCourses = regs
          .map((r) => _dataService.getCourseByCode(r.courseCode))
          .whereType<Course>()
          .toList();

      for (final r in regs) {
        final sec = _dataService.getSectionById(r.sectionId);
        if (sec != null) {
          evalSections[r.courseCode] = sec;
        }
      }
    }

    final res = await _advisorService.evaluateRegistration(
      student: student,
      selectedCourses: evalCourses,
      selectedSections: evalSections,
      minCreditHours: _dataService.minCreditHours,
      maxCreditHours: _dataService.maxCreditHours,
    );

    if (!mounted) return;
    setState(() {
      _result = res;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Advisor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: BorderSide(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Registration Check',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              _buildStatusBadge(_result!),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatBox(
                                'Selected Courses',
                                '${_result!.selectedCoursesCount}',
                                isDark,
                              ),
                              const SizedBox(width: 12),
                              _buildStatBox(
                                'Credit Hours',
                                '${_result!.totalCreditHours} / ${_result!.maxAllowedCredits}',
                                isDark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Advisory Disclaimer
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF171717) : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: BorderSide(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.help_outline,
                            size: 16,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Registration Advisor provides informational checks based on the data available in the portal. Confirm your registration requirements with the university/department when necessary.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 1. BLOCKING ISSUES (ERRORS)
                    if (_result!.hasBlockingErrors) ...[
                      Row(
                        children: [
                          const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Blocking Issues (${_result!.errors.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.errors.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2D1212) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: BorderSide(
                                color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✕  ', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    _result!.errors[idx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 2. WARNINGS
                    if (_result!.hasWarnings) ...[
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Informational Warnings (${_result!.warnings.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.warnings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2B1D0C) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: BorderSide(
                                color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('⚠  ', style: TextStyle(color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    _result!.warnings[idx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 3. PASSED CHECKS
                    if (_result!.passedChecks.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Passed Checks (${_result!.passedChecks.length})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.passedChecks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F2416) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: BorderSide(
                                color: isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('✓  ', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    _result!.passedChecks[idx],
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 4. STUDY PLAN RECOMMENDATIONS
                    if (_result!.recommendations.isNotEmpty) ...[
                      Text(
                        'Recommended for your semester',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.recommendations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final rec = _result!.recommendations[idx];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141414) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: BorderSide(
                                color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rec['courseCode']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    rec['reason']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Acknowledge checkbox if there are warnings
                    if (_result!.hasWarnings && !_result!.hasBlockingErrors) ...[
                      Row(
                        children: [
                          Checkbox(
                            value: _acknowledgedWarnings,
                            activeColor: isDark ? Colors.white : Colors.black,
                            checkColor: isDark ? Colors.black : Colors.white,
                            onChanged: (val) => setState(() => _acknowledgedWarnings = val ?? false),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _acknowledgedWarnings = !_acknowledgedWarnings),
                              child: Text(
                                'I acknowledge the above informational warnings and wish to proceed.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFFD4D4D4) : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Button
                    if (widget.onConfirmRegistration != null) ...[
                      CustomButton(
                        label: _result!.hasBlockingErrors
                            ? 'Cannot Register (Resolve Issues)'
                            : 'Confirm & Finalize Registration',
                        onPressed: _result!.hasBlockingErrors || (_result!.hasWarnings && !_acknowledgedWarnings)
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                widget.onConfirmRegistration!();
                              },
                      ),
                    ] else ...[
                      CustomButton(
                        label: 'Done',
                        isOutlined: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBadge(RegistrationCheckResult res) {
    if (res.hasBlockingErrors) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: BorderSide(color: const Color(0xFFF87171)),
        ),
        child: const Text(
          'ISSUES FOUND',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
        ),
      );
    }
    if (res.hasWarnings) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: BorderSide(color: const Color(0xFFFBBF24)),
        ),
        child: const Text(
          'WARNINGS',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: BorderSide(color: const Color(0xFF86EFAC)),
      ),
      child: const Text(
        'ALL CHECKS PASSED',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
