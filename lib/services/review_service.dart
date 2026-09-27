import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_review.dart';

class ReviewService {
  static final ReviewService instance = ReviewService._internal();
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _reviewsRef => _firestore.collection('course_reviews');
  CollectionReference<Map<String, dynamic>> get _reportsRef => _firestore.collection('review_reports');
  CollectionReference<Map<String, dynamic>> get _registrationsRef => _firestore.collection('registrations');
  CollectionReference<Map<String, dynamic>> get _academicRecordsRef => _firestore.collection('academic_records');

  /// Stream published reviews for a specific course (anonymized for students)
  Stream<List<CourseReview>> streamCourseReviews(String courseCode) {
    return _reviewsRef
        .where('courseCode', isEqualTo: courseCode)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CourseReview.fromMap(doc.data(), doc.id)).toList();
    });
  }

  /// Get published reviews for a specific course
  Future<List<CourseReview>> getCourseReviews(String courseCode) async {
    final snapshot = await _reviewsRef
        .where('courseCode', isEqualTo: courseCode)
        .where('status', isEqualTo: 'published')
        .get();

    return snapshot.docs.map((doc) => CourseReview.fromMap(doc.data(), doc.id)).toList();
  }

  /// Get aggregated metrics for a course
  Future<Map<String, dynamic>> getCourseAggregates(String courseCode) async {
    final reviews = await getCourseReviews(courseCode);
    if (reviews.isEmpty) {
      return {
        'count': 0,
        'avgDifficulty': 0.0,
        'avgWorkload': 0.0,
        'avgTeaching': 0.0,
      };
    }

    final totalDiff = reviews.fold<int>(0, (sum, r) => sum + r.difficulty);
    final totalWorkload = reviews.fold<int>(0, (sum, r) => sum + r.workload);
    final totalTeaching = reviews.fold<int>(0, (sum, r) => sum + r.teachingRating);

    return {
      'count': reviews.length,
      'avgDifficulty': totalDiff / reviews.length,
      'avgWorkload': totalWorkload / reviews.length,
      'avgTeaching': totalTeaching / reviews.length,
    };
  }

  /// Check whether the student is eligible to review the course:
  /// 1. Must be/have been registered in the course
  /// 2. Must not have already reviewed this course for the semester
  Future<Map<String, dynamic>> checkReviewEligibility({
    required String studentId,
    required String courseCode,
    String semesterId = 'Spring 2026',
  }) async {
    if (studentId.isEmpty) {
      return {'eligible': false, 'reason': 'Please sign in to submit feedback.'};
    }

    // 1. Check existing reviews from this student for this course
    final existingReviews = await _reviewsRef
        .where('studentId', isEqualTo: studentId)
        .where('courseCode', isEqualTo: courseCode)
        .get();

    if (existingReviews.docs.isNotEmpty) {
      return {
        'eligible': false,
        'reason': 'You have already submitted feedback for $courseCode.',
      };
    }

    // 2. Check if student has/had registration in this course
    final regQuery = await _registrationsRef
        .where('studentId', isEqualTo: studentId)
        .where('courseCode', isEqualTo: courseCode)
        .get();

    if (regQuery.docs.isNotEmpty) {
      final regDoc = regQuery.docs.first.data();
      return {
        'eligible': true,
        'instructorId': regDoc['instructorId'] ?? '',
        'instructorName': regDoc['instructorName'] ?? '',
        'sectionCode': regDoc['sectionCode'] ?? '',
      };
    }

    // 3. Alternatively check academic records (completed course history)
    final academicQuery = await _academicRecordsRef
        .where('studentId', isEqualTo: studentId)
        .get();

    for (final doc in academicQuery.docs) {
      final courses = doc.data()['courses'] as List? ?? [];
      for (final c in courses) {
        if (c is Map && c['courseCode'] == courseCode) {
          return {
            'eligible': true,
            'instructorId': '',
            'instructorName': 'Faculty Member',
            'sectionCode': '',
          };
        }
      }
    }

    // For demo/new accounts who haven't completed or registered yet:
    return {
      'eligible': false,
      'reason': 'Feedback is available only to students currently registered in or who have completed $courseCode.',
    };
  }

  /// Submit a review (enforces authenticated UID, anonymous display flag, published status, and one-review-per-course constraint using Firestore transactions)
  Future<void> submitReview({
    required String courseCode,
    required String courseName,
    required String instructorId,
    required String instructorName,
    required String semesterId,
    required int difficulty,
    required int workload,
    required int teachingRating,
    int organizationRating = 4,
    int communicationRating = 4,
    int supportRating = 4,
    String comment = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated.';

    final eligibility = await checkReviewEligibility(studentId: user.uid, courseCode: courseCode, semesterId: semesterId);
    if (eligibility['eligible'] != true) {
      throw eligibility['reason'] ?? 'You are not eligible to submit feedback for this course.';
    }

    // Deterministic document ID to enforce one-review-per-student-per-course-per-semester
    final cleanSemester = semesterId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final cleanCode = courseCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();
    final reviewDocId = '${user.uid}_${cleanCode}_$cleanSemester';
    final docRef = _reviewsRef.doc(reviewDocId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        throw 'You have already submitted feedback for $courseCode in $semesterId.';
      }

      final review = CourseReview(
        id: reviewDocId,
        studentId: user.uid,
        courseCode: courseCode,
        courseName: courseName,
        instructorId: instructorId,
        instructorName: instructorName,
        semesterId: semesterId,
        difficulty: difficulty,
        workload: workload,
        teachingRating: teachingRating,
        organizationRating: organizationRating,
        communicationRating: communicationRating,
        supportRating: supportRating,
        comment: comment.trim(),
        anonymous: true,
        status: 'published',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      transaction.set(docRef, review.toMap());
    });
  }

  /// Report a review for moderation
  Future<void> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    final reportDoc = _reportsRef.doc();

    await reportDoc.set({
      'reviewId': reviewId,
      'reportedBy': user?.uid ?? 'anonymous_student',
      'reason': reason,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'pending',
    });

    // Mark review as flagged
    await _reviewsRef.doc(reviewId).update({'status': 'flagged'});
  }
}
