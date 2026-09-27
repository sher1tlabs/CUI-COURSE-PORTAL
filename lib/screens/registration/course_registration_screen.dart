import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../widgets/course_card.dart';
import 'course_details_screen.dart';
import 'section_selection_screen.dart';
import 'registered_courses_screen.dart';

class CourseRegistrationScreen extends StatefulWidget {
  const CourseRegistrationScreen({super.key});

  @override
  State<CourseRegistrationScreen> createState() => _CourseRegistrationScreenState();
}

class _CourseRegistrationScreenState extends State<CourseRegistrationScreen> {
  final _dataService = LocalDataService();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedType = 'All';
  int? _selectedCredits;
  bool _onlyAvailable = false;

  final List<String> _departments = [
    'All',
    'Computer Science',
    'Computer Engineering',
    'Mathematics',
    'Humanities',
  ];

  final List<String> _courseTypes = [
    'All',
    'Core',
    'Elective',
    'University Requirement',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Courses',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _selectedDepartment = 'All';
                            _selectedType = 'All';
                            _selectedCredits = null;
                            _onlyAvailable = false;
                          });
                          setState(() {});
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Department
                  const Text('Department', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _departments.map((dept) {
                      final isSel = _selectedDepartment == dept;
                      return ChoiceChip(
                        label: Text(dept, style: TextStyle(fontSize: 12, color: isSel ? (isDark ? Colors.black : Colors.white) : null)),
                        selected: isSel,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        onSelected: (val) {
                          setSheetState(() => _selectedDepartment = dept);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Course Type
                  const Text('Course Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _courseTypes.map((type) {
                      final isSel = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type, style: TextStyle(fontSize: 12, color: isSel ? (isDark ? Colors.black : Colors.white) : null)),
                        selected: isSel,
                        selectedColor: isDark ? Colors.white : Colors.black,
                        onSelected: (val) {
                          setSheetState(() => _selectedType = type);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Credit Hours
                  const Text('Credit Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [null, 3, 4].map((ch) {
                      final isSel = _selectedCredits == ch;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(ch == null ? 'Any' : '$ch CH', style: TextStyle(fontSize: 12, color: isSel ? (isDark ? Colors.black : Colors.white) : null)),
                          selected: isSel,
                          selectedColor: isDark ? Colors.white : Colors.black,
                          onSelected: (val) {
                            setSheetState(() => _selectedCredits = ch);
                            setState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : Colors.black,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRegistrationSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final registered = _dataService.registrations;
    final totalCredits = _dataService.totalRegisteredCreditHours;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registration Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Fall 2026',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (registered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('No courses registered yet.')),
                )
              else
                ...registered.map((r) {
                  final course = _dataService.getCourseByCode(r.courseCode);
                  final section = _dataService.getSectionById(r.sectionId);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.courseCode,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              course?.title ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                              ),
                            ),
                            if (section != null)
                              Text(
                                '${section.sectionName} • ${section.instructor}',
                                style: const TextStyle(fontSize: 11),
                              ),
                          ],
                        ),
                        Text(
                          '${course?.creditHours ?? 0} CH',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Registered:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('$totalCredits / ${_dataService.maxCreditHours} Credit Hours', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Registration saved successfully.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save & Confirm Registration'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final totalCredits = _dataService.totalRegisteredCreditHours;
        final availableCredits = _dataService.availableCreditHours;

        // Filtering
        final filteredCourses = _dataService.courses.where((course) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchCode = course.code.toLowerCase().contains(q);
            final matchTitle = course.title.toLowerCase().contains(q);
            final matchDept = course.department.toLowerCase().contains(q);
            if (!matchCode && !matchTitle && !matchDept) return false;
          }

          if (_selectedDepartment != 'All' && course.department != _selectedDepartment) {
            return false;
          }

          if (_selectedType != 'All' && course.courseType != _selectedType) {
            return false;
          }

          if (_selectedCredits != null && course.creditHours != _selectedCredits) {
            return false;
          }

          if (_onlyAvailable) {
            final sections = _dataService.getSectionsForCourse(course.code);
            if (!sections.any((s) => !s.isFull)) return false;
          }

          return true;
        }).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Course Registration'),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Registration Summary',
                onPressed: _showRegistrationSummary,
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_outline),
                tooltip: 'My Courses',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisteredCoursesScreen()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Top Credit Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fall 2026 Semester',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total Registered: $totalCredits CH',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Available: $availableCredits CH',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar & Filter trigger
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search by course code or name...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.filledTonal(
                        onPressed: _openFilterDialog,
                        icon: const Icon(Icons.tune, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                          foregroundColor: isDark ? Colors.white : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Filter Chips
                if (_selectedDepartment != 'All' || _selectedType != 'All' || _selectedCredits != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_selectedDepartment != 'All')
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Chip(
                                label: Text(_selectedDepartment, style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setState(() => _selectedDepartment = 'All'),
                              ),
                            ),
                          if (_selectedType != 'All')
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Chip(
                                label: Text(_selectedType, style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setState(() => _selectedType = 'All'),
                              ),
                            ),
                          if (_selectedCredits != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Chip(
                                label: Text('$_selectedCredits CH', style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setState(() => _selectedCredits = null),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                // Courses List
                Expanded(
                  child: filteredCourses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: isDark ? const Color(0xFF555555) : const Color(0xFF9E9E9E),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No courses found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try clearing your filters or search keyword.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredCourses.length,
                          itemBuilder: (context, index) {
                            final course = filteredCourses[index];
                            return CourseCard(
                              course: course,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CourseDetailsScreen(course: course),
                                  ),
                                );
                              },
                              onViewSections: () {
                                final prereq = _dataService.checkPrerequisites(course);
                                if (prereq['passed'] != true) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
                                      title: const Text('Prerequisite Not Completed'),
                                      content: Text(
                                        'You cannot register for ${course.code} because the required prerequisite has not been completed.\n\n${prereq['message']}',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  return;
                                }

                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SectionSelectionScreen(course: course),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
