import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course.dart';
import '../models/section.dart';
import '../models/instructor.dart';
import '../models/registration.dart';
import '../models/academic_record.dart';
import '../models/system_settings.dart';
import '../models/student.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _coursesRef => _firestore.collection('courses');
  CollectionReference<Map<String, dynamic>> get _instructorsRef => _firestore.collection('instructors');
  CollectionReference<Map<String, dynamic>> get _registrationsRef => _firestore.collection('registrations');
  CollectionReference<Map<String, dynamic>> get _academicRecordsRef => _firestore.collection('academic_records');
  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      _firestore.collection('system_settings').doc('registration_period');

  // ================= COURSES ================= //

  Stream<List<Course>> streamCourses() {
    return _coursesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<List<Course>> getCourses() async {
    final snapshot = await _coursesRef.get();
    return snapshot.docs.map((doc) => Course.fromMap(doc.data(), doc.id)).toList();
  }

  // ================= SECTIONS ================= //

  Stream<List<Section>> streamSections(String courseId) {
    return _coursesRef.doc(courseId).collection('sections').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Section.fromMap(doc.data(), doc.id, courseId: courseId)).toList();
    });
  }

  Future<List<Section>> getSections(String courseId) async {
    final snapshot = await _coursesRef.doc(courseId).collection('sections').get();
    return snapshot.docs.map((doc) => Section.fromMap(doc.data(), doc.id, courseId: courseId)).toList();
  }

  // ================= INSTRUCTORS ================= //

  Future<List<Instructor>> getInstructors() async {
    final snapshot = await _instructorsRef.get();
    return snapshot.docs.map((doc) => Instructor.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Instructor?> getInstructorById(String id) async {
    final doc = await _instructorsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Instructor.fromMap(doc.data()!, doc.id);
  }

  // ================= REGISTRATIONS ================= //

  Stream<List<Registration>> streamStudentRegistrations(String studentId) {
    return _registrationsRef
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Registration.fromMap(doc.data(), doc.id))
          .where((reg) => reg.status != 'Dropped')
          .toList();
    });
  }

  Future<List<Registration>> getStudentRegistrations(String studentId) async {
    final snapshot = await _registrationsRef
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs
        .map((doc) => Registration.fromMap(doc.data(), doc.id))
        .where((reg) => reg.status != 'Dropped')
        .toList();
  }

  /// Register a course section for a student
  Future<void> registerCourse({
    required Student student,
    required Course course,
    required Section section,
    String semester = 'Spring 2026',
  }) async {
    // 1. Check if already registered
    final existingRegistrations = await getStudentRegistrations(student.id);
    final isAlreadyRegistered = existingRegistrations.any((r) => r.courseCode == course.code);
    if (isAlreadyRegistered) {
      throw 'You are already registered in ${course.code} - ${course.title}.';
    }

    // 2. Check credit hours limit
    final currentCredits = existingRegistrations.fold<int>(0, (sum, r) => sum + r.creditHours);
    if (currentCredits + course.creditHours > 18) {
      throw 'Credit limit exceeded! Maximum allowed is 18 credit hours (Current: $currentCredits + ${course.creditHours} = ${currentCredits + course.creditHours}).';
    }

    // 3. Check section capacity
    if (section.isFull) {
      throw 'Section ${section.sectionName} is completely full. Please choose another section.';
    }

    // 4. Check schedule conflict
    for (final reg in existingRegistrations) {
      final sharedDays = section.days.where((day) => reg.days.contains(day)).toList();
      if (sharedDays.isNotEmpty && reg.timeSlot == section.timeSlot) {
        throw 'Schedule conflict detected with ${reg.courseCode} on ${sharedDays.join(", ")} at ${section.timeSlot}.';
      }
    }

    // 5. Execute transaction: create registration & decrement available seat in section
    final newRegDocRef = _registrationsRef.doc();
    final sectionDocRef = _coursesRef.doc(course.id.isNotEmpty ? course.id : course.code).collection('sections').doc(section.id);

    final registration = Registration(
      id: newRegDocRef.id,
      studentId: student.id,
      courseId: course.id,
      courseCode: course.code,
      courseTitle: course.title,
      creditHours: course.creditHours,
      sectionId: section.id,
      sectionCode: section.sectionName,
      instructorName: section.instructor,
      days: section.days,
      timeSlot: section.timeSlot,
      room: section.room,
      semester: semester,
      status: 'Registered',
      registrationDate: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(newRegDocRef, registration.toMap());

      transaction.update(sectionDocRef, {
        'enrolledCount': FieldValue.increment(1),
        'availableSeats': FieldValue.increment(-1),
      });
    });
  }

  /// Drop a registered course
  Future<void> dropCourse({
    required String registrationId,
    required String courseId,
    required String sectionId,
  }) async {
    final regRef = _registrationsRef.doc(registrationId);
    final sectionRef = _coursesRef.doc(courseId).collection('sections').doc(sectionId);

    await _firestore.runTransaction((transaction) async {
      transaction.delete(regRef);

      transaction.update(sectionRef, {
        'enrolledCount': FieldValue.increment(-1),
        'availableSeats': FieldValue.increment(1),
      });
    });
  }

  // ================= SYSTEM SETTINGS ================= //

  Future<SystemSettings> getSystemSettings() async {
    final doc = await _settingsRef.get();
    if (!doc.exists || doc.data() == null) {
      return const SystemSettings();
    }
    return SystemSettings.fromMap(doc.data()!);
  }

  // ================= ACADEMIC RECORDS ================= //

  Future<List<AcademicRecord>> getStudentAcademicRecords(String studentId) async {
    final snapshot = await _academicRecordsRef
        .where('studentId', isEqualTo: studentId)
        .get();

    if (snapshot.docs.isEmpty) {
      // Return realistic COMSATS semester transcripts
      return [
        const AcademicRecord(
          id: 'sem-3',
          studentId: '',
          semester: 'Fall 2025',
          academicYear: '2025-2026',
          gpa: 3.65,
          cgpa: 3.48,
          creditHoursEarned: 17,
          creditHoursAttempted: 17,
          courses: [
            SemesterCourseGrade(
              courseCode: 'CSC211',
              courseTitle: 'Data Structures',
              creditHours: 4,
              grade: 'A',
              gradePoint: 4.0,
              marks: 88,
            ),
            SemesterCourseGrade(
              courseCode: 'MTH231',
              courseTitle: 'Linear Algebra',
              creditHours: 3,
              grade: 'B+',
              gradePoint: 3.33,
              marks: 79,
            ),
            SemesterCourseGrade(
              courseCode: 'EEE241',
              courseTitle: 'Digital Logic Design',
              creditHours: 4,
              grade: 'A-',
              gradePoint: 3.67,
              marks: 84,
            ),
            SemesterCourseGrade(
              courseCode: 'HUM100',
              courseTitle: 'English Comprehension',
              creditHours: 3,
              grade: 'A',
              gradePoint: 4.0,
              marks: 90,
            ),
            SemesterCourseGrade(
              courseCode: 'CSC291',
              courseTitle: 'Software Engineering Concepts',
              creditHours: 3,
              grade: 'B+',
              gradePoint: 3.33,
              marks: 78,
            ),
          ],
        ),
        const AcademicRecord(
          id: 'sem-2',
          studentId: '',
          semester: 'Spring 2025',
          academicYear: '2024-2025',
          gpa: 3.42,
          cgpa: 3.40,
          creditHoursEarned: 18,
          creditHoursAttempted: 18,
          courses: [
            SemesterCourseGrade(
              courseCode: 'CSC103',
              courseTitle: 'Object Oriented Programming',
              creditHours: 4,
              grade: 'B+',
              gradePoint: 3.33,
              marks: 77,
            ),
            SemesterCourseGrade(
              courseCode: 'MTH105',
              courseTitle: 'Multivariable Calculus',
              creditHours: 3,
              grade: 'A-',
              gradePoint: 3.67,
              marks: 83,
            ),
            SemesterCourseGrade(
              courseCode: 'PHY120',
              courseTitle: 'Applied Physics',
              creditHours: 4,
              grade: 'B',
              gradePoint: 3.0,
              marks: 74,
            ),
            SemesterCourseGrade(
              courseCode: 'HUM103',
              courseTitle: 'Islamic Studies',
              creditHours: 3,
              grade: 'A',
              gradePoint: 4.0,
              marks: 92,
            ),
            SemesterCourseGrade(
              courseCode: 'CSC112',
              courseTitle: 'Discrete Structures',
              creditHours: 4,
              grade: 'A-',
              gradePoint: 3.67,
              marks: 82,
            ),
          ],
        ),
      ];
    }

    return snapshot.docs.map((doc) => AcademicRecord.fromMap(doc.data(), doc.id)).toList();
  }

  // ================= SEED DATA UTILITY ================= //

  /// Seed initial COMSATS catalogue and system settings into Firestore if not present
  Future<void> initializePortalDataIfEmpty() async {
    try {
      final coursesSnapshot = await _coursesRef.limit(1).get();
      if (coursesSnapshot.docs.isNotEmpty) {
        return; // Already seeded!
      }

      // 1. Seed System Settings
      await _settingsRef.set(const SystemSettings().toMap());

      // 2. Seed Instructors
      final instructors = [
        const Instructor(
          id: 'inst-1',
          name: 'Dr. Tariq Mahmood',
          designation: 'Professor & Chair',
          department: 'Computer Science',
          coursesTaught: ['CSC241', 'CSC483'],
          office: 'Room 304, CS Block A',
          email: 'tariq.mahmood@comsats.edu.pk',
        ),
        const Instructor(
          id: 'inst-2',
          name: 'Dr. Ayesha Siddiqa',
          designation: 'Associate Professor',
          department: 'Computer Science',
          coursesTaught: ['CPE241', 'CSC322'],
          office: 'Room 210, CS Block B',
          email: 'ayesha.siddiqa@comsats.edu.pk',
        ),
        const Instructor(
          id: 'inst-3',
          name: 'Engr. Bilal Hashmi',
          designation: 'Assistant Professor',
          department: 'Software Engineering',
          coursesTaught: ['CSC339', 'CSC471'],
          office: 'Room 105, SE Block',
          email: 'bilal.hashmi@comsats.edu.pk',
        ),
        const Instructor(
          id: 'inst-4',
          name: 'Dr. Noman Bashir',
          designation: 'Associate Professor',
          department: 'Mathematics',
          coursesTaught: ['MTH262', 'MTH231'],
          office: 'Room 401, Basic Sciences',
          email: 'noman.bashir@comsats.edu.pk',
        ),
        const Instructor(
          id: 'inst-5',
          name: 'Ms. Fatima Zahra',
          designation: 'Lecturer',
          department: 'Humanities',
          coursesTaught: ['HUM102'],
          office: 'Room 112, Humanities Wing',
          email: 'fatima.zahra@comsats.edu.pk',
        ),
      ];

      for (final inst in instructors) {
        await _instructorsRef.doc(inst.id).set(inst.toMap());
      }

      // 3. Seed Courses with nested Sections
      final coursesData = [
        {
          'course': const Course(
            id: 'CSC241',
            code: 'CSC241',
            title: 'Object Oriented Programming',
            creditHours: 4,
            department: 'Computer Science',
            description: 'Advanced concepts of classes, inheritance, polymorphism, templates, memory management, and design patterns in C++ / Java.',
            prerequisites: ['CSC103'],
            courseType: 'Core',
            recommendedSemester: 4,
            isOffered: true,
            availableSeats: 48,
            totalSeats: 100,
          ),
          'sections': [
            const Section(
              id: 'sec-241-a',
              courseId: 'CSC241',
              courseCode: 'CSC241',
              sectionName: 'BCS-4A',
              instructor: 'Dr. Tariq Mahmood',
              instructorId: 'inst-1',
              days: ['Monday', 'Wednesday'],
              startTime: '08:30 AM',
              endTime: '10:00 AM',
              timeSlot: '08:30 AM - 10:00 AM',
              room: 'CS Block A - Lab 1',
              totalSeats: 50,
              availableSeats: 32,
              enrolledCount: 18,
            ),
            const Section(
              id: 'sec-241-b',
              courseId: 'CSC241',
              courseCode: 'CSC241',
              sectionName: 'BCS-4B',
              instructor: 'Dr. Tariq Mahmood',
              instructorId: 'inst-1',
              days: ['Tuesday', 'Thursday'],
              startTime: '10:00 AM',
              endTime: '11:30 AM',
              timeSlot: '10:00 AM - 11:30 AM',
              room: 'CS Block A - Lab 2',
              totalSeats: 50,
              availableSeats: 16,
              enrolledCount: 34,
            ),
          ],
        },
        {
          'course': const Course(
            id: 'CPE241',
            code: 'CPE241',
            title: 'Database Systems',
            creditHours: 4,
            department: 'Computer Science',
            description: 'Entity-relationship modeling, relational algebra, SQL DDL/DML, normalization, indexing, transaction processing, and ACID properties.',
            prerequisites: ['CSC211'],
            courseType: 'Core',
            recommendedSemester: 4,
            isOffered: true,
            availableSeats: 42,
            totalSeats: 90,
          ),
          'sections': [
            const Section(
              id: 'sec-cpe-a',
              courseId: 'CPE241',
              courseCode: 'CPE241',
              sectionName: 'BCS-4A',
              instructor: 'Dr. Ayesha Siddiqa',
              instructorId: 'inst-2',
              days: ['Monday', 'Wednesday'],
              startTime: '11:30 AM',
              endTime: '01:00 PM',
              timeSlot: '11:30 AM - 01:00 PM',
              room: 'CS Block B - Room 202',
              totalSeats: 45,
              availableSeats: 21,
              enrolledCount: 24,
            ),
            const Section(
              id: 'sec-cpe-b',
              courseId: 'CPE241',
              courseCode: 'CPE241',
              sectionName: 'BCS-4B',
              instructor: 'Dr. Ayesha Siddiqa',
              instructorId: 'inst-2',
              days: ['Tuesday', 'Thursday'],
              startTime: '01:30 PM',
              endTime: '03:00 PM',
              timeSlot: '01:30 PM - 03:00 PM',
              room: 'CS Block B - Lab 3',
              totalSeats: 45,
              availableSeats: 21,
              enrolledCount: 24,
            ),
          ],
        },
        {
          'course': const Course(
            id: 'CSC339',
            code: 'CSC339',
            title: 'Computer Networks',
            creditHours: 4,
            department: 'Computer Science',
            description: 'OSI and TCP/IP stack layers, socket programming, routing protocols, flow control, congestion mitigation, subnetting, and network security.',
            prerequisites: ['CSC211'],
            courseType: 'Core',
            recommendedSemester: 4,
            isOffered: true,
            availableSeats: 38,
            totalSeats: 80,
          ),
          'sections': [
            const Section(
              id: 'sec-net-a',
              courseId: 'CSC339',
              courseCode: 'CSC339',
              sectionName: 'BCS-4A',
              instructor: 'Engr. Bilal Hashmi',
              instructorId: 'inst-3',
              days: ['Tuesday', 'Thursday'],
              startTime: '08:30 AM',
              endTime: '10:00 AM',
              timeSlot: '08:30 AM - 10:00 AM',
              room: 'Telecom Block - Lab 4',
              totalSeats: 40,
              availableSeats: 19,
              enrolledCount: 21,
            ),
          ],
        },
        {
          'course': const Course(
            id: 'MTH262',
            code: 'MTH262',
            title: 'Statistics & Probability Theory',
            creditHours: 3,
            department: 'Mathematics',
            description: 'Discrete and continuous distributions, conditional probability, expectation, variance, hypothesis testing, linear regression, and ANOVA.',
            prerequisites: ['MTH105'],
            courseType: 'Core',
            recommendedSemester: 4,
            isOffered: true,
            availableSeats: 45,
            totalSeats: 60,
          ),
          'sections': [
            const Section(
              id: 'sec-mth-a',
              courseId: 'MTH262',
              courseCode: 'MTH262',
              sectionName: 'BCS-4A',
              instructor: 'Dr. Noman Bashir',
              instructorId: 'inst-4',
              days: ['Monday', 'Wednesday'],
              startTime: '01:30 PM',
              endTime: '03:00 PM',
              timeSlot: '01:30 PM - 03:00 PM',
              room: 'Basic Sciences - Room 108',
              totalSeats: 60,
              availableSeats: 45,
              enrolledCount: 15,
            ),
          ],
        },
        {
          'course': const Course(
            id: 'HUM102',
            code: 'HUM102',
            title: 'Technical & Report Writing',
            creditHours: 3,
            department: 'Humanities',
            description: 'Engineering documentation, research papers, project proposals, executive summaries, professional correspondence, and oral defense.',
            prerequisites: ['HUM100'],
            courseType: 'University Requirement',
            recommendedSemester: 4,
            isOffered: true,
            availableSeats: 52,
            totalSeats: 70,
          ),
          'sections': [
            const Section(
              id: 'sec-hum-a',
              courseId: 'HUM102',
              courseCode: 'HUM102',
              sectionName: 'BCS-4A',
              instructor: 'Ms. Fatima Zahra',
              instructorId: 'inst-5',
              days: ['Friday'],
              startTime: '09:00 AM',
              endTime: '12:00 PM',
              timeSlot: '09:00 AM - 12:00 PM',
              room: 'Seminar Hall 2',
              totalSeats: 70,
              availableSeats: 52,
              enrolledCount: 18,
            ),
          ],
        },
        {
          'course': const Course(
            id: 'CSC483',
            code: 'CSC483',
            title: 'Artificial Intelligence',
            creditHours: 3,
            department: 'Computer Science',
            description: 'Heuristic search algorithms, adversarial search, constraint satisfaction, propositional and first-order logic, Bayesian reasoning, and machine learning.',
            prerequisites: ['CSC211', 'MTH262'],
            courseType: 'Elective',
            recommendedSemester: 5,
            isOffered: true,
            availableSeats: 28,
            totalSeats: 50,
          ),
          'sections': [
            const Section(
              id: 'sec-ai-a',
              courseId: 'CSC483',
              courseCode: 'CSC483',
              sectionName: 'BCS-5A',
              instructor: 'Dr. Tariq Mahmood',
              instructorId: 'inst-1',
              days: ['Wednesday', 'Friday'],
              startTime: '02:00 PM',
              endTime: '03:30 PM',
              timeSlot: '02:00 PM - 03:30 PM',
              room: 'CS Block A - Hall 3',
              totalSeats: 50,
              availableSeats: 28,
              enrolledCount: 22,
            ),
          ],
        },
      ];

      for (final item in coursesData) {
        final Course course = item['course'] as Course;
        final sections = item['sections'] as List<Section>;

        await _coursesRef.doc(course.id).set(course.toMap());
        for (final sec in sections) {
          await _coursesRef.doc(course.id).collection('sections').doc(sec.id).set(sec.toMap());
        }
      }

      // 4. Seed University Announcements
      final announcementsRef = _firestore.collection('announcements');
      final announcements = [
        {
          'id': 'ann-1',
          'title': 'Spring 2026 Course Registration & Add/Drop Deadline',
          'body': 'Course registration for the Spring 2026 semester is now actively open through the portal. Students are advised to register before February 28, 2026, 11:59 PM. Late fee charges will apply thereafter.',
          'category': 'Registration',
          'priority': 'Urgent',
          'publishedAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'campus': 'All',
          'department': 'All',
          'program': 'All',
          'semester': 'All',
          'createdBy': 'Registrar Office CUI',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'ann-2',
          'title': 'Mid-Term Examination Datesheet Notification',
          'body': 'The tentative schedule for Spring 2026 mid-term examinations has been published. Individual datesheets by section will be visible under the Timetable and Academic tabs next week.',
          'category': 'Examination',
          'priority': 'Important',
          'publishedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(days: 45)).toIso8601String(),
          'campus': 'Islamabad',
          'department': 'Computer Science',
          'program': 'BS Computer Science',
          'semester': 'All',
          'createdBy': 'Controller of Examinations',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'ann-3',
          'title': 'HEC & COMSATS Need-Based Scholarships 2026',
          'body': 'Applications are invited from eligible students for the HEC Need-Based and COMSATS Endowment Fund scholarships. Submit attested supporting documentation to the Student Financial Aid Office (SFAO) by March 15, 2026.',
          'category': 'Scholarship',
          'priority': 'Normal',
          'publishedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
          'campus': 'All',
          'department': 'All',
          'program': 'All',
          'semester': 'All',
          'createdBy': 'Student Financial Aid Office',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'ann-4',
          'title': 'Guest Lecture: Modern Distributed Systems in Cloud Infrastructure',
          'body': 'The Department of Computer Science is hosting Dr. Farhan Zaidi (Cloud Systems Architect) for a seminar on Kubernetes and fault-tolerant microservices. Venue: CS Block Seminar Hall 1.',
          'category': 'Events',
          'priority': 'Normal',
          'publishedAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
          'expiresAt': DateTime.now().add(const Duration(days: 10)).toIso8601String(),
          'campus': 'Islamabad',
          'department': 'Computer Science',
          'program': 'All',
          'semester': 'All',
          'createdBy': 'CS Department Society',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      ];

      for (final ann in announcements) {
        await announcementsRef.doc(ann['id'] as String).set(ann);
      }

      // 5. Seed Degree Plans
      final degreePlansRef = _firestore.collection('degree_plans');
      await degreePlansRef.doc('bs-cs').set({
        'program': 'BS Computer Science',
        'campus': 'All',
        'totalCreditHours': 133,
        'semesters': [
          {
            'semester': 1,
            'courses': ['CSC101', 'MTH101', 'HUM100', 'PHY120', 'ISL101'],
          },
          {
            'semester': 2,
            'courses': ['CSC103', 'MTH105', 'PHY121', 'HUM103', 'CSC112'],
          },
          {
            'semester': 3,
            'courses': ['CSC211', 'MTH231', 'EEE241', 'HUM102', 'CSC291'],
          },
          {
            'semester': 4,
            'courses': ['CSC241', 'CPE241', 'CSC339', 'MTH262'],
            'electives': ['CSC483'],
          },
          {
            'semester': 5,
            'courses': ['CSC322', 'CSC312', 'MTH375'],
            'electives': ['CSC483', 'CSC471'],
          },
        ],
        'electives': ['CSC483', 'CSC471', 'CSC412', 'SWE302'],
      });

      // 6. Seed Student Feedback (Course Reviews)
      final reviewsRef = _firestore.collection('course_reviews');
      final reviews = [
        {
          'id': 'rev-241-1',
          'studentId': 'verified_student_1',
          'courseCode': 'CSC241',
          'courseName': 'Object Oriented Programming',
          'instructorId': 'inst-1',
          'instructorName': 'Dr. Tariq Mahmood',
          'semesterId': 'Fall 2025',
          'difficulty': 4,
          'workload': 4,
          'teachingRating': 5,
          'organizationRating': 5,
          'communicationRating': 4,
          'supportRating': 5,
          'comment': 'Lectures were very thorough. Make sure to complete all coding lab assignments independently as exams heavily emphasize OOP design patterns and pointers.',
          'anonymous': true,
          'status': 'published',
          'createdAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
        },
        {
          'id': 'rev-241-2',
          'studentId': 'verified_student_2',
          'courseCode': 'CSC241',
          'courseName': 'Object Oriented Programming',
          'instructorId': 'inst-1',
          'instructorName': 'Dr. Tariq Mahmood',
          'semesterId': 'Spring 2025',
          'difficulty': 4,
          'workload': 3,
          'teachingRating': 4,
          'organizationRating': 4,
          'communicationRating': 5,
          'supportRating': 4,
          'comment': 'Good balance of theory and practice. The semester project requires steady weekly milestones.',
          'anonymous': true,
          'status': 'published',
          'createdAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        },
        {
          'id': 'rev-cpe-1',
          'studentId': 'verified_student_3',
          'courseCode': 'CPE241',
          'courseName': 'Database Systems',
          'instructorId': 'inst-2',
          'instructorName': 'Dr. Ayesha Siddiqa',
          'semesterId': 'Fall 2025',
          'difficulty': 3,
          'workload': 4,
          'teachingRating': 5,
          'organizationRating': 5,
          'communicationRating': 5,
          'supportRating': 4,
          'comment': 'Excellent explanation of normalization and relational algebra. Lab tasks with PostgreSQL helped reinforce complex queries.',
          'anonymous': true,
          'status': 'published',
          'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
        },
      ];

      for (final rev in reviews) {
        await reviewsRef.doc(rev['id'] as String).set(rev);
      }
    } catch (e) {
      print('Seed initialization error: $e');
    }
  }
}
