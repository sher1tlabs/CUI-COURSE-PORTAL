import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/section.dart';
import '../models/instructor.dart';
import '../models/timetable_entry.dart';
import '../models/registration.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class LocalDataService extends ChangeNotifier {
  static final LocalDataService _instance = LocalDataService._internal();
  factory LocalDataService() => _instance;
  LocalDataService._internal() {
    _initializeData();
    _connectFirebase();
  }

  void _connectFirebase() {
    try {
      // Sync with Firebase Auth state
      AuthService.instance.authStateChanges.listen((user) async {
        if (user != null) {
          try {
            final student = await AuthService.instance.loadStudentProfile(user.uid);
            _currentStudent = student;
            notifyListeners();

            // Stream user registrations from Firestore
            FirestoreService.instance.streamStudentRegistrations(user.uid).listen((remoteRegs) {
              if (remoteRegs.isNotEmpty) {
                _registrations = remoteRegs;
                notifyListeners();
              }
            });
          } catch (e) {
            debugPrint('LocalDataService auth listener notice: $e');
          }
        }
      });

      // Stream course catalogue from Firestore
      FirestoreService.instance.streamCourses().listen((remoteCourses) {
        if (remoteCourses.isNotEmpty) {
          _courses = remoteCourses;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Firebase connection notice: $e');
    }
  }

  // State
  late Student _currentStudent;
  bool _isRegistrationOpen = true;
  final DateTime _registrationDeadline = DateTime(2026, 9, 30, 23, 59);
  final int _minCreditHours = 12;
  final int _maxCreditHours = 18;

  List<Course> _courses = [];
  List<Section> _sections = [];
  List<Instructor> _instructors = [];
  List<Registration> _registrations = [];
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _completedCourses = [];
  List<Map<String, dynamic>> _semesterHistory = [];

  // Getters
  Student get currentStudent => _currentStudent;
  bool get isRegistrationOpen => _isRegistrationOpen;
  DateTime get registrationDeadline => _registrationDeadline;
  int get minCreditHours => _minCreditHours;
  int get maxCreditHours => _maxCreditHours;
  List<Course> get courses => List.unmodifiable(_courses);
  List<Section> get sections => List.unmodifiable(_sections);
  List<Instructor> get instructors => List.unmodifiable(_instructors);
  List<Registration> get registrations => List.unmodifiable(_registrations);
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  List<Map<String, dynamic>> get completedCourses => List.unmodifiable(_completedCourses);
  List<Map<String, dynamic>> get semesterHistory => List.unmodifiable(_semesterHistory);

  int get totalRegisteredCreditHours {
    int total = 0;
    for (var reg in _registrations) {
      if (reg.status == 'Registered') {
        final course = _courses.firstWhere(
          (c) => c.code == reg.courseCode,
          orElse: () => const Course(code: '', title: '', creditHours: 0, department: '', description: '', courseType: '', recommendedSemester: 1),
        );
        total += course.creditHours;
      }
    }
    return total;
  }

  int get availableCreditHours => _maxCreditHours - totalRegisteredCreditHours;

  void toggleRegistrationStatus() {
    _isRegistrationOpen = !_isRegistrationOpen;
    notifyListeners();
  }

  void updateProfile({String? name, String? phoneNumber}) {
    _currentStudent = _currentStudent.copyWith(
      name: name,
      phoneNumber: phoneNumber,
    );
    notifyListeners();
  }

  List<Section> getSectionsForCourse(String courseCode) {
    return _sections.where((s) => s.courseCode == courseCode).toList();
  }

  Course? getCourseByCode(String code) {
    try {
      return _courses.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  Section? getSectionById(String id) {
    try {
      return _sections.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Instructor? getInstructorById(String id) {
    try {
      return _instructors.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isCourseRegistered(String courseCode) {
    return _registrations.any((r) => r.courseCode == courseCode && r.status == 'Registered');
  }

  Registration? getRegistrationForCourse(String courseCode) {
    try {
      return _registrations.firstWhere((r) => r.courseCode == courseCode && r.status == 'Registered');
    } catch (_) {
      return null;
    }
  }

  // --- RULE ENGINE VALIDATION ---

  Map<String, dynamic> checkPrerequisites(Course course) {
    if (course.prerequisites.isEmpty) {
      return {'passed': true, 'message': 'No prerequisites required'};
    }

    final completedCodes = _completedCourses.map((c) => c['code'] as String).toSet();
    final missing = course.prerequisites.where((p) => !completedCodes.contains(p)).toList();

    if (missing.isEmpty) {
      return {'passed': true, 'message': 'Prerequisites completed'};
    } else {
      return {
        'passed': false,
        'message': 'Required: ${missing.join(", ")}',
        'missing': missing,
      };
    }
  }

  int _timeToMinutes(String timeStr) {
    final parts = timeStr.trim().split(' ');
    if (parts.length < 2) return 0;
    final hm = parts[0].split(':');
    int h = int.tryParse(hm[0]) ?? 0;
    int m = hm.length > 1 ? (int.tryParse(hm[1]) ?? 0) : 0;
    final meridian = parts[1].toUpperCase();

    if (meridian == 'PM' && h != 12) h += 12;
    if (meridian == 'AM' && h == 12) h = 0;
    return h * 60 + m;
  }

  Map<String, dynamic> checkScheduleConflict(Section targetSection, {String? ignoreCourseCode}) {
    final targetStart = _timeToMinutes(targetSection.startTime);
    final targetEnd = _timeToMinutes(targetSection.endTime);

    for (var reg in _registrations) {
      if (reg.status != 'Registered') continue;
      if (ignoreCourseCode != null && reg.courseCode == ignoreCourseCode) continue;

      final registeredSection = getSectionById(reg.sectionId);
      if (registeredSection == null) continue;

      // Check common days
      final commonDays = registeredSection.days.where((d) => targetSection.days.contains(d)).toList();
      if (commonDays.isEmpty) continue;

      final regStart = _timeToMinutes(registeredSection.startTime);
      final regEnd = _timeToMinutes(registeredSection.endTime);

      // Overlap formula: startA < endB && endA > startB
      if (targetStart < regEnd && targetEnd > regStart) {
        final conflictCourse = getCourseByCode(reg.courseCode);
        return {
          'hasConflict': true,
          'conflictCourseCode': reg.courseCode,
          'conflictCourseTitle': conflictCourse?.title ?? reg.courseCode,
          'conflictTime': '${registeredSection.startTime} - ${registeredSection.endTime}',
          'commonDays': commonDays.join(', '),
          'message': '${targetSection.courseCode} overlaps with ${reg.courseCode} on ${commonDays.join(', ')}.',
        };
      }
    }

    return {'hasConflict': false};
  }

  Map<String, dynamic> validateRegistration(Course course, Section section) {
    if (!_isRegistrationOpen) {
      return {'valid': false, 'error': 'Registration period is currently closed.'};
    }

    if (isCourseRegistered(course.code)) {
      return {'valid': false, 'error': 'You are already registered for this course.'};
    }

    final prereqCheck = checkPrerequisites(course);
    if (prereqCheck['passed'] != true) {
      return {
        'valid': false,
        'error': 'Prerequisite not completed.\n${prereqCheck['message']}'
      };
    }

    if (totalRegisteredCreditHours + course.creditHours > _maxCreditHours) {
      return {
        'valid': false,
        'error': 'Credit hour limit exceeded! Maximum allowed is $_maxCreditHours CH. Adding ${course.creditHours} CH would exceed the limit.'
      };
    }

    if (section.isFull) {
      return {'valid': false, 'error': 'Selected section ${section.sectionName} is full (0 seats available).'};
    }

    final conflictCheck = checkScheduleConflict(section);
    if (conflictCheck['hasConflict'] == true) {
      return {
        'valid': false,
        'error': conflictCheck['message'],
        'conflict': conflictCheck,
      };
    }

    return {'valid': true};
  }

  bool registerCourse(String courseCode, String sectionId) {
    final course = getCourseByCode(courseCode);
    final section = getSectionById(sectionId);
    if (course == null || section == null) return false;

    final validation = validateRegistration(course, section);
    if (validation['valid'] != true) return false;

    // Add registration
    final newReg = Registration(
      id: 'reg_${DateTime.now().millisecondsSinceEpoch}',
      studentId: _currentStudent.id,
      courseId: course.id.isNotEmpty ? course.id : course.code,
      courseCode: courseCode,
      courseTitle: course.title,
      creditHours: course.creditHours,
      sectionId: sectionId,
      sectionCode: section.sectionName,
      instructorName: section.instructor,
      days: section.days,
      timeSlot: section.timeSlot,
      room: section.room,
      semester: 'Spring 2026',
      registrationDate: DateTime.now(),
    );
    _registrations.add(newReg);

    // Decrement available seat in section
    final idx = _sections.indexWhere((s) => s.id == sectionId);
    if (idx != -1) {
      _sections[idx] = _sections[idx].copyWith(availableSeats: _sections[idx].availableSeats - 1);
    }

    notifyListeners();

    // Persist to Cloud Firestore
    FirestoreService.instance.registerCourse(
      student: _currentStudent,
      course: course,
      section: section,
      semester: 'Spring 2026',
    ).catchError((e) {
      debugPrint('Firestore registration sync notice: $e');
    });

    return true;
  }

  bool dropCourse(String courseCode) {
    final regIdx = _registrations.indexWhere((r) => r.courseCode == courseCode && r.status == 'Registered');
    if (regIdx == -1) return false;

    final reg = _registrations[regIdx];
    final sectionIdx = _sections.indexWhere((s) => s.id == reg.sectionId);
    if (sectionIdx != -1) {
      _sections[sectionIdx] = _sections[sectionIdx].copyWith(availableSeats: _sections[sectionIdx].availableSeats + 1);
    }

    _registrations.removeAt(regIdx);
    notifyListeners();

    // Persist drop to Cloud Firestore
    FirestoreService.instance.dropCourse(
      registrationId: reg.id,
      courseId: reg.courseId.isNotEmpty ? reg.courseId : reg.courseCode,
      sectionId: reg.sectionId,
    ).catchError((e) {
      debugPrint('Firestore drop sync notice: $e');
    });

    return true;
  }

  Map<String, dynamic> changeSection(String courseCode, String newSectionId) {
    final regIdx = _registrations.indexWhere((r) => r.courseCode == courseCode && r.status == 'Registered');
    if (regIdx == -1) return {'success': false, 'message': 'Course is not registered.'};

    final oldReg = _registrations[regIdx];
    if (oldReg.sectionId == newSectionId) return {'success': false, 'message': 'Already in this section.'};

    final newSection = getSectionById(newSectionId);
    if (newSection == null) return {'success': false, 'message': 'Section not found.'};

    if (newSection.isFull) return {'success': false, 'message': 'Section is full.'};

    final conflict = checkScheduleConflict(newSection, ignoreCourseCode: courseCode);
    if (conflict['hasConflict'] == true) {
      return {'success': false, 'message': 'Schedule conflict with ${conflict['conflictCourseCode']}.'};
    }

    // Free seat in old section
    final oldSectionIdx = _sections.indexWhere((s) => s.id == oldReg.sectionId);
    if (oldSectionIdx != -1) {
      _sections[oldSectionIdx] = _sections[oldSectionIdx].copyWith(availableSeats: _sections[oldSectionIdx].availableSeats + 1);
    }

    // Take seat in new section
    final newSectionIdx = _sections.indexWhere((s) => s.id == newSectionId);
    if (newSectionIdx != -1) {
      _sections[newSectionIdx] = _sections[newSectionIdx].copyWith(availableSeats: _sections[newSectionIdx].availableSeats - 1);
    }

    _registrations[regIdx] = Registration(
      id: oldReg.id,
      studentId: oldReg.studentId,
      courseCode: courseCode,
      sectionId: newSectionId,
      semester: oldReg.semester,
      registrationDate: DateTime.now(),
    );

    notifyListeners();
    return {'success': true, 'message': 'Section changed successfully.'};
  }

  List<TimetableEntry> getTimetableForDay(String day) {
    final List<TimetableEntry> entries = [];
    for (var reg in _registrations) {
      if (reg.status != 'Registered') continue;
      final course = getCourseByCode(reg.courseCode);
      final section = getSectionById(reg.sectionId);
      if (course == null || section == null) continue;

      if (section.days.contains(day)) {
        entries.add(TimetableEntry(
          id: '${reg.id}_$day',
          courseCode: course.code,
          courseTitle: course.title,
          sectionName: section.sectionName,
          instructor: section.instructor,
          day: day,
          startTime: section.startTime,
          endTime: section.endTime,
          room: section.room,
          creditHours: course.creditHours,
        ));
      }
    }

    // Sort by startTime
    entries.sort((a, b) => _timeToMinutes(a.startTime).compareTo(_timeToMinutes(b.startTime)));
    return entries;
  }

  void markNotificationAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      _notifications[idx]['isRead'] = true;
      notifyListeners();
    }
  }

  void markAllNotificationsAsRead() {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();
  }

  void _initializeData() {
    _currentStudent = const Student(
      id: 'std_042',
      name: 'Hassan Raza',
      registrationNumber: 'SP24-BCE-042',
      email: 'sp24-bce-042@isb.comsats.edu.pk',
      phoneNumber: '+92 312 8765432',
      program: 'BS Computer Engineering (BCE)',
      campus: 'Islamabad Campus',
      batch: 'Spring 2024',
      semester: 3,
      cgpa: 3.42,
      completedCreditHours: 64,
      academicStanding: 'Good Standing',
    );

    _completedCourses = [
      {'code': 'CSC101', 'title': 'Programming Fundamentals', 'grade': 'A', 'gpa': 4.0, 'creditHours': 4},
      {'code': 'MTH101', 'title': 'Calculus & Analytical Geometry', 'grade': 'A-', 'gpa': 3.7, 'creditHours': 3},
      {'code': 'HUM100', 'title': 'English Comprehension & Composition', 'grade': 'B+', 'gpa': 3.3, 'creditHours': 3},
      {'code': 'PHY120', 'title': 'Applied Physics for Engineers', 'grade': 'B', 'gpa': 3.0, 'creditHours': 4},
      {'code': 'EEE111', 'title': 'Electric Circuit Analysis', 'grade': 'A-', 'gpa': 3.7, 'creditHours': 4},
      {'code': 'MTH105', 'title': 'Multivariable Calculus', 'grade': 'B+', 'gpa': 3.3, 'creditHours': 3},
      {'code': 'CSC102', 'title': 'Discrete Structures', 'grade': 'A', 'gpa': 4.0, 'creditHours': 3},
      {'code': 'ISL101', 'title': 'Islamic Studies', 'grade': 'A', 'gpa': 4.0, 'creditHours': 2},
    ];

    _instructors = const [
      Instructor(
        id: 'inst_1',
        name: 'Dr. Ahmed Khan',
        designation: 'Associate Professor',
        department: 'Computer Science',
        coursesTaught: ['CSC241 Object Oriented Programming', 'CSC312 Design & Analysis of Algorithms'],
        office: 'CS Building, Room 304',
        email: 'ahmed.khan@comsats.edu.pk',
      ),
      Instructor(
        id: 'inst_2',
        name: 'Dr. Ali Raza',
        designation: 'Assistant Professor',
        department: 'Computer Engineering',
        coursesTaught: ['CPE241 Digital Logic Design', 'CPE321 Microprocessor Systems'],
        office: 'EE Building, Room 212',
        email: 'ali.raza@comsats.edu.pk',
      ),
      Instructor(
        id: 'inst_3',
        name: 'Dr. Fatima Zahra',
        designation: 'Professor & HOD',
        department: 'Computer Science',
        coursesTaught: ['CSC291 Software Engineering', 'CSC490 Final Year Project'],
        office: 'Faculty Block B, Room 101',
        email: 'fatima.zahra@comsats.edu.pk',
      ),
      Instructor(
        id: 'inst_4',
        name: 'Dr. Sarah Tariq',
        designation: 'Assistant Professor',
        department: 'Mathematics',
        coursesTaught: ['MTH242 Differential Equations', 'MTH101 Calculus'],
        office: 'Math Block, Room 115',
        email: 'sarah.tariq@comsats.edu.pk',
      ),
      Instructor(
        id: 'inst_5',
        name: 'Engr. Bilal Tariq',
        designation: 'Lecturer',
        department: 'Computer Engineering',
        coursesTaught: ['CPE241 Digital Logic Design Lab', 'CSC241 OOP Lab'],
        office: 'Hardware Lab 3',
        email: 'bilal.tariq@comsats.edu.pk',
      ),
    ];

    _courses = const [
      Course(
        code: 'CSC241',
        title: 'Object Oriented Programming',
        creditHours: 4,
        department: 'Computer Science',
        description: 'Advanced programming paradigms, object-oriented concepts: classes, inheritance, polymorphism, templates, exception handling, and GUI development.',
        prerequisites: ['CSC101'],
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 3,
      ),
      Course(
        code: 'CPE241',
        title: 'Digital Logic Design',
        creditHours: 4,
        department: 'Computer Engineering',
        description: 'Number systems, Boolean algebra, logic gates, combinational and sequential circuit design, Karnaugh maps, counters, registers, and HDL simulation.',
        prerequisites: ['EEE111'],
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 3,
      ),
      Course(
        code: 'CSC291',
        title: 'Software Engineering',
        creditHours: 3,
        department: 'Computer Science',
        description: 'Systematic approach to development, maintenance, and testing of complex software systems. Agile methodologies, UML modeling, requirements engineering, and CI/CD pipelines.',
        prerequisites: ['CSC101'],
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 3,
      ),
      Course(
        code: 'MTH242',
        title: 'Differential Equations',
        creditHours: 3,
        department: 'Mathematics',
        description: 'First order and second order ordinary differential equations, Laplace transforms, Fourier series, and applications in engineering systems.',
        prerequisites: ['MTH101'],
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 3,
      ),
      Course(
        code: 'CSC312',
        title: 'Algorithms Analysis & Design',
        creditHours: 3,
        department: 'Computer Science',
        description: 'Asymptotic notation, divide and conquer, dynamic programming, greedy algorithms, graph traversals, shortest paths, and NP-completeness.',
        prerequisites: ['CSC241'], // NOTE: Requires CSC241 (currently in progress, so testing prerequisite failure)
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 4,
      ),
      Course(
        code: 'HUM102',
        title: 'Report Writing Skills',
        creditHours: 3,
        department: 'Humanities',
        description: 'Techniques of formal technical writing, research reports, executive summaries, presentations, and professional ethics.',
        prerequisites: ['HUM100'],
        corequisites: [],
        courseType: 'University Requirement',
        recommendedSemester: 3,
      ),
      Course(
        code: 'CPE321',
        title: 'Microprocessor Systems',
        creditHours: 4,
        department: 'Computer Engineering',
        description: 'Architecture and assembly language programming of x86/ARM microprocessors, bus interfacing, interrupts, DMA, and memory hierarchies.',
        prerequisites: ['CPE241'], // Missing prerequisite
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 4,
      ),
      Course(
        code: 'MTH262',
        title: 'Statistics and Probability',
        creditHours: 3,
        department: 'Mathematics',
        description: 'Random variables, discrete and continuous probability distributions, regression, correlation, hypothesis testing, and statistical estimation.',
        prerequisites: ['MTH101'],
        corequisites: [],
        courseType: 'Core',
        recommendedSemester: 3,
      ),
      Course(
        code: 'CSC339',
        title: 'Data Communication & Networking',
        creditHours: 4,
        department: 'Computer Science',
        description: 'OSI and TCP/IP protocol architectures, packet routing, transport layer protocols, addressing, wireless standards, and network security.',
        prerequisites: ['CSC101'],
        corequisites: [],
        courseType: 'Elective',
        recommendedSemester: 4,
      ),
      Course(
        code: 'ENV100',
        title: 'Environmental Sciences',
        creditHours: 3,
        department: 'Humanities',
        description: 'Ecology, sustainable energy, pollution control, resource management, and environmental laws.',
        prerequisites: [],
        corequisites: [],
        courseType: 'University Requirement',
        recommendedSemester: 3,
      ),
    ];

    _sections = [
      // CSC241
      const Section(
        id: 'sec_csc241_a',
        courseCode: 'CSC241',
        sectionName: 'Section A',
        instructor: 'Dr. Ahmed Khan',
        instructorId: 'inst_1',
        days: ['Monday', 'Wednesday'],
        startTime: '09:00 AM',
        endTime: '10:30 AM',
        room: 'C-Block 204',
        totalSeats: 40,
        availableSeats: 8,
      ),
      const Section(
        id: 'sec_csc241_b',
        courseCode: 'CSC241',
        sectionName: 'Section B',
        instructor: 'Dr. Ahmed Khan',
        instructorId: 'inst_1',
        days: ['Tuesday', 'Thursday'],
        startTime: '01:00 PM',
        endTime: '02:30 PM',
        room: 'Lab 4',
        totalSeats: 40,
        availableSeats: 0, // Full section test
      ),
      const Section(
        id: 'sec_csc241_c',
        courseCode: 'CSC241',
        sectionName: 'Section C',
        instructor: 'Engr. Bilal Tariq',
        instructorId: 'inst_5',
        days: ['Tuesday', 'Thursday'],
        startTime: '10:30 AM',
        endTime: '12:00 PM',
        room: 'C-Block 201',
        totalSeats: 35,
        availableSeats: 14,
      ),

      // CPE241
      const Section(
        id: 'sec_cpe241_a',
        courseCode: 'CPE241',
        sectionName: 'Section A',
        instructor: 'Dr. Ali Raza',
        instructorId: 'inst_2',
        days: ['Monday', 'Wednesday'],
        startTime: '11:00 AM',
        endTime: '12:30 PM',
        room: 'Hardware Lab 3',
        totalSeats: 35,
        availableSeats: 6,
      ),
      const Section(
        id: 'sec_cpe241_b',
        courseCode: 'CPE241',
        sectionName: 'Section B',
        instructor: 'Engr. Bilal Tariq',
        instructorId: 'inst_5',
        days: ['Monday', 'Wednesday'],
        startTime: '09:30 AM',
        endTime: '11:00 AM', // Conflict with CSC241 Sec A
        room: 'EE-Block 102',
        totalSeats: 35,
        availableSeats: 12,
      ),

      // CSC291
      const Section(
        id: 'sec_csc291_a',
        courseCode: 'CSC291',
        sectionName: 'Section A',
        instructor: 'Dr. Fatima Zahra',
        instructorId: 'inst_3',
        days: ['Tuesday', 'Thursday'],
        startTime: '09:00 AM',
        endTime: '10:30 AM',
        room: 'C-Block 305',
        totalSeats: 45,
        availableSeats: 15,
      ),
      const Section(
        id: 'sec_csc291_b',
        courseCode: 'CSC291',
        sectionName: 'Section B',
        instructor: 'Dr. Fatima Zahra',
        instructorId: 'inst_3',
        days: ['Friday'],
        startTime: '09:00 AM',
        endTime: '12:00 PM',
        room: 'CS Seminar Hall',
        totalSeats: 45,
        availableSeats: 20,
      ),

      // MTH242
      const Section(
        id: 'sec_mth242_a',
        courseCode: 'MTH242',
        sectionName: 'Section A',
        instructor: 'Dr. Sarah Tariq',
        instructorId: 'inst_4',
        days: ['Monday', 'Wednesday'],
        startTime: '01:30 PM',
        endTime: '03:00 PM',
        room: 'Math Block 112',
        totalSeats: 50,
        availableSeats: 11,
      ),

      // HUM102
      const Section(
        id: 'sec_hum102_a',
        courseCode: 'HUM102',
        sectionName: 'Section A',
        instructor: 'Dr. Sarah Tariq',
        instructorId: 'inst_4',
        days: ['Tuesday', 'Thursday'],
        startTime: '03:00 PM',
        endTime: '04:30 PM',
        room: 'Hum Block 201',
        totalSeats: 40,
        availableSeats: 19,
      ),

      // MTH262
      const Section(
        id: 'sec_mth262_a',
        courseCode: 'MTH262',
        sectionName: 'Section A',
        instructor: 'Dr. Sarah Tariq',
        instructorId: 'inst_4',
        days: ['Friday'],
        startTime: '02:30 PM',
        endTime: '05:30 PM',
        room: 'Math Block 110',
        totalSeats: 45,
        availableSeats: 18,
      ),

      // CSC312
      const Section(
        id: 'sec_csc312_a',
        courseCode: 'CSC312',
        sectionName: 'Section A',
        instructor: 'Dr. Ahmed Khan',
        instructorId: 'inst_1',
        days: ['Monday', 'Wednesday'],
        startTime: '03:00 PM',
        endTime: '04:30 PM',
        room: 'C-Block 204',
        totalSeats: 40,
        availableSeats: 15,
      ),
    ];

    // Initial Registered Courses (total: 14 Credit Hours)
    _registrations = [
      Registration(
        id: 'reg_1',
        studentId: _currentStudent.id,
        courseCode: 'CSC241',
        sectionId: 'sec_csc241_a',
        semester: 'Fall 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Registration(
        id: 'reg_2',
        studentId: _currentStudent.id,
        courseCode: 'CPE241',
        sectionId: 'sec_cpe241_a',
        semester: 'Fall 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Registration(
        id: 'reg_3',
        studentId: _currentStudent.id,
        courseCode: 'CSC291',
        sectionId: 'sec_csc291_a',
        semester: 'Fall 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Registration(
        id: 'reg_4',
        studentId: _currentStudent.id,
        courseCode: 'MTH242',
        sectionId: 'sec_mth242_a',
        semester: 'Fall 2026',
        registrationDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    _notifications = [
      {
        'id': 'notif_1',
        'title': 'Course Registration is Open',
        'message': 'Your Fall 2026 course registration period has started.',
        'time': '2 hours ago',
        'isRead': false,
      },
      {
        'id': 'notif_2',
        'title': 'Registration Deadline',
        'message': 'Course registration closes on September 30, 2026. Please verify your schedule.',
        'time': '1 day ago',
        'isRead': false,
      },
      {
        'id': 'notif_3',
        'title': 'Section Availability',
        'message': 'A seat is available in CSC241 Section B.',
        'time': '2 days ago',
        'isRead': true,
      },
    ];

    _semesterHistory = [
      {
        'semester': 'Spring 2024',
        'gpa': 3.52,
        'creditHours': 16,
        'courses': [
          {'code': 'CSC101', 'title': 'Programming Fundamentals', 'ch': 4, 'grade': 'A'},
          {'code': 'MTH101', 'title': 'Calculus & Analytical Geometry', 'ch': 3, 'grade': 'A-'},
          {'code': 'HUM100', 'title': 'English Comprehension', 'ch': 3, 'grade': 'B+'},
          {'code': 'PHY120', 'title': 'Applied Physics for Engineers', 'ch': 4, 'grade': 'B'},
          {'code': 'ISL101', 'title': 'Islamic Studies', 'ch': 2, 'grade': 'A'},
        ]
      },
      {
        'semester': 'Fall 2024',
        'gpa': 3.32,
        'creditHours': 16,
        'courses': [
          {'code': 'EEE111', 'title': 'Electric Circuit Analysis', 'ch': 4, 'grade': 'A-'},
          {'code': 'MTH105', 'title': 'Multivariable Calculus', 'ch': 3, 'grade': 'B+'},
          {'code': 'CSC102', 'title': 'Discrete Structures', 'ch': 3, 'grade': 'A'},
          {'code': 'HUM102', 'title': 'Report Writing Skills', 'ch': 3, 'grade': 'B'},
          {'code': 'ENV100', 'title': 'Environmental Sciences', 'ch': 3, 'grade': 'B+'},
        ]
      },
      {
        'semester': 'Spring 2025',
        'gpa': 3.45,
        'creditHours': 17,
        'courses': [
          {'code': 'CSC211', 'title': 'Data Structures', 'ch': 4, 'grade': 'B+'},
          {'code': 'CPE201', 'title': 'Basic Electronics', 'ch': 4, 'grade': 'A-'},
          {'code': 'MTH241', 'title': 'Linear Algebra', 'ch': 3, 'grade': 'A'},
          {'code': 'HUM110', 'title': 'Pakistan Studies', 'ch': 3, 'grade': 'A'},
          {'code': 'CSC205', 'title': 'Computer Architecture', 'ch': 3, 'grade': 'B'},
        ]
      },
    ];
  }
}
