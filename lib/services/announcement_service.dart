import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';
import '../models/student.dart';

class AnnouncementService {
  static final AnnouncementService instance = AnnouncementService._internal();
  AnnouncementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _announcementsRef =>
      _firestore.collection('announcements');

  /// Stream all active announcements (excluding expired)
  Stream<List<UniversityAnnouncement>> streamAnnouncements({
    String category = 'All',
    Student? student,
    String searchQuery = '',
  }) {
    return _announcementsRef
        .orderBy('publishedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      return snapshot.docs
          .map((doc) => UniversityAnnouncement.fromMap(doc.data(), doc.id))
          .where((ann) {
            // Filter expired
            if (ann.expiresAt != null && now.isAfter(ann.expiresAt!)) {
              return false;
            }

            // Filter category
            if (category != 'All' && ann.category.toLowerCase() != category.toLowerCase()) {
              return false;
            }

            // Search query
            if (searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              final matchesTitle = ann.title.toLowerCase().contains(q);
              final matchesBody = ann.body.toLowerCase().contains(q);
              final matchesCat = ann.category.toLowerCase().contains(q);
              if (!matchesTitle && !matchesBody && !matchesCat) return false;
            }

            // Relevance to student:
            // Campus match
            if (student != null) {
              final campusMatch = ann.campus == 'All' ||
                  ann.campus.toLowerCase().contains(student.campus.toLowerCase()) ||
                  student.campus.toLowerCase().contains(ann.campus.toLowerCase());
              if (!campusMatch) return false;

              // Program match
              final programMatch = ann.program == 'All' ||
                  ann.program.toLowerCase() == student.program.toLowerCase();
              if (!programMatch && ann.program != 'All') return false;
            }

            return true;
          })
          .toList();
    });
  }

  /// Get the top latest announcements for Home dashboard (e.g. 3-4 announcements)
  Stream<List<UniversityAnnouncement>> streamLatestAnnouncements({int limit = 4, Student? student}) {
    return streamAnnouncements(student: student).map((list) {
      return list.take(limit).toList();
    });
  }

  /// Get a single announcement by ID
  Future<UniversityAnnouncement?> getAnnouncementById(String id) async {
    final doc = await _announcementsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UniversityAnnouncement.fromMap(doc.data()!, doc.id);
  }
}
