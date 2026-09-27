import 'package:flutter/material.dart';
import '../../services/local_data_service.dart';
import '../../widgets/credit_progress_card.dart';
import '../../widgets/registration_status_card.dart';
import '../../widgets/timetable_card.dart';
import '../registration/course_registration_screen.dart';
import '../registration/registered_courses_screen.dart';
import '../timetable/timetable_screen.dart';
import '../academic/academic_record_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final _dataService = LocalDataService();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> destinations = [
      _buildHomeDashboard(context, isDark),
      const CourseRegistrationScreen(),
      const TimetableScreen(),
      const AcademicRecordScreen(),
      ProfileScreen(
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: destinations,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Academic',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final student = _dataService.currentStudent;
        final totalCredits = _dataService.totalRegisteredCreditHours;
        final todayEntries = _dataService.getTimetableForDay('Monday'); // Default to Monday classes
        final unreadNotifs = _dataService.notifications.where((n) => !n['isRead']).length;

        return SafeArea(
          child: RefreshIndicator(
            color: isDark ? Colors.white : Colors.black,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Student Info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Morning, ${student.name.split(" ")[0]}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${student.program.split(" ")[1]} • Semester ${student.semester}\nCOMSATS University Islamabad',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      // Notification bell with unread badge
                      Stack(
                        children: [
                          IconButton.filledTonal(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                              );
                            },
                            icon: const Icon(Icons.notifications_outlined, size: 22),
                            style: IconButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                              foregroundColor: isDark ? Colors.white : Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          if (unreadNotifs > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white : Colors.black,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$unreadNotifs',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Registration Status Card
                  RegistrationStatusCard(
                    isOpen: _dataService.isRegistrationOpen,
                    deadline: _dataService.registrationDeadline,
                    semester: 'Fall 2026',
                    onRegisterTap: () {
                      setState(() => _currentIndex = 1); // Switch to Courses tab
                    },
                  ),
                  const SizedBox(height: 4),

                  // Credit Hours Card
                  CreditProgressCard(
                    registeredCredits: totalCredits,
                    minCredits: _dataService.minCreditHours,
                    maxCredits: _dataService.maxCreditHours,
                    semester: 'Fall 2026',
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.1,
                    children: [
                      _buildQuickAction(
                        icon: Icons.app_registration,
                        label: 'Register Courses',
                        isDark: isDark,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _buildQuickAction(
                        icon: Icons.library_books_outlined,
                        label: 'My Courses',
                        isDark: isDark,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisteredCoursesScreen()),
                          );
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.calendar_month_outlined,
                        label: 'Timetable',
                        isDark: isDark,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _buildQuickAction(
                        icon: Icons.school_outlined,
                        label: 'Academic Record',
                        isDark: isDark,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Today's Timetable Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Classes (Monday)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 2),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : Colors.black,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('View Timetable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (todayEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'No classes scheduled for today.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    )
                  else
                    ...todayEntries.map((e) => TimetableCard(entry: e)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? const Color(0xFF262626) : const Color(0xFFE5E5E5),
        ),
      ),
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
