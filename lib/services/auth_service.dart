import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Map Firebase Auth exception codes to clean, human-readable student friendly messages
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'invalid-email':
        return 'Please enter a valid university email address (e.g. name@student.comsats.edu.pk).';
      case 'user-disabled':
        return 'This student account has been deactivated. Please contact the registrar office.';
      case 'email-already-in-use':
        return 'An account with this university email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many unsuccessful attempts. Access is temporarily restricted. Please try again shortly.';
      case 'network-request-failed':
        return 'Network error encountered. Please check your internet connection.';
      default:
        return e.message ?? 'An unexpected authentication error occurred. Please try again.';
    }
  }

  /// Sign In with Email & Password
  Future<Student> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      final student = await loadStudentProfile(uid);
      _currentStudent = student;
      return student;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw 'Sign in failed: ${e.toString()}';
    }
  }

  /// Register / Create New Student Account
  Future<Student> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required String registrationNumber,
    required String phone,
    required String program,
    required String campus,
    required int semester,
    String batch = 'FA23',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      final newStudent = Student(
        id: uid,
        name: fullName.trim(),
        registrationNumber: registrationNumber.trim().toUpperCase(),
        email: email.trim().toLowerCase(),
        phoneNumber: phone.trim(),
        program: program,
        campus: campus,
        batch: batch,
        semester: semester,
        cgpa: 3.45,
        completedCreditHours: (semester - 1) * 16,
        academicStanding: 'Good Standing',
      );

      await _firestore.collection('students').doc(uid).set(newStudent.toMap());
      _currentStudent = newStudent;
      return newStudent;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  /// Load Student Profile from Firestore
  Future<Student> loadStudentProfile(String uid) async {
    final docSnapshot = await _firestore.collection('students').doc(uid).get();

    if (docSnapshot.exists && docSnapshot.data() != null) {
      final student = Student.fromMap(docSnapshot.data()!, uid);
      _currentStudent = student;
      return student;
    } else {
      // If profile doesn't exist yet, seed a default COMSATS student profile
      final defaultStudent = Student(
        id: uid,
        name: _auth.currentUser?.displayName ?? 'COMSATS Student',
        registrationNumber: 'FA22-BCS-042',
        email: _auth.currentUser?.email ?? 'student@comsats.edu.pk',
        phoneNumber: '+92 300 1234567',
        program: 'BS Computer Science',
        campus: 'Islamabad Campus',
        batch: 'FA22',
        semester: 4,
        cgpa: 3.48,
        completedCreditHours: 54,
        academicStanding: 'Good Standing',
      );

      await _firestore.collection('students').doc(uid).set(defaultStudent.toMap());
      _currentStudent = defaultStudent;
      return defaultStudent;
    }
  }

  /// Update Student Profile
  Future<void> updateStudentProfile(Student updatedStudent) async {
    await _firestore.collection('students').doc(updatedStudent.id).update(updatedStudent.toMap());
    _currentStudent = updatedStudent;
  }

  /// Send Password Reset Email
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      throw 'Failed to send password reset: ${e.toString()}';
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _currentStudent = null;
  }
}
