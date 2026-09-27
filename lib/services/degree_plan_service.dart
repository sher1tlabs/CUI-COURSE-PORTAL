import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/degree_plan.dart';

class DegreePlanService {
  static final DegreePlanService instance = DegreePlanService._internal();
  DegreePlanService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _plansRef => _firestore.collection('degree_plans');

  /// Fetch degree plan for a specific program
  Future<DegreePlan?> getDegreePlanForProgram(String programName) async {
    // Try exact or prefix match
    final query = await _plansRef.get();
    for (final doc in query.docs) {
      final pName = doc.data()['program'] as String? ?? '';
      if (pName.toLowerCase() == programName.toLowerCase() ||
          programName.toLowerCase().contains(pName.toLowerCase()) ||
          pName.toLowerCase().contains(programName.toLowerCase())) {
        return DegreePlan.fromMap(doc.data(), doc.id);
      }
    }

    // Default fallback BS Computer Science degree plan
    return _defaultComputerSciencePlan();
  }

  DegreePlan _defaultComputerSciencePlan() {
    return const DegreePlan(
      id: 'bs-cs-plan',
      program: 'BS Computer Science',
      campus: 'All',
      totalCreditHours: 133,
      semesters: [
        SemesterPlan(
          semester: 1,
          courses: ['CSC101', 'MTH101', 'HUM100', 'PHY120', 'ISL101'],
        ),
        SemesterPlan(
          semester: 2,
          courses: ['CSC103', 'MTH105', 'PHY121', 'HUM103', 'CSC112'],
        ),
        SemesterPlan(
          semester: 3,
          courses: ['CSC211', 'MTH231', 'EEE241', 'HUM102', 'CSC291'],
        ),
        SemesterPlan(
          semester: 4,
          courses: ['CSC241', 'CPE241', 'CSC339', 'MTH262'],
          electives: ['CSC483'],
        ),
        SemesterPlan(
          semester: 5,
          courses: ['CSC322', 'CSC312', 'MTH375'],
          electives: ['CSC483', 'CSC471'],
        ),
      ],
      generalElectives: ['CSC483', 'CSC471', 'CSC412', 'SWE302'],
    );
  }
}
