import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream user's evidence records
  Stream<List<Map<String, dynamic>>> strEvidence(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('evidence')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Stream user's scan logs
  Stream<List<Map<String, dynamic>>> strScanLogs(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('scan_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  // Update Notification Preferences
  Future<void> updatePreferences(String uid, bool emailPushEnabled) async {
    await _db.collection('users').doc(uid).set({
      'alertsEnabled': emailPushEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Update Profile Photo URL
  Future<void> updateProfilePhoto(String uid, String photoUrl) async {
    await _db.collection('users').doc(uid).set({
      'profilePhotoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Delete a single evidence record by its Firestore document ID
  Future<void> deleteEvidence(String uid, String docId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('evidence')
        .doc(docId)
        .delete();
  }

  // Delete Profile Photo URL
  Future<void> deleteProfilePhoto(String uid) async {
    await _db
        .collection('users')
        .doc(uid)
        .update({
          'profilePhotoUrl': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        })
        .catchError((_) {}); // Ignore error if document doesn't exist
  }

  // Clear ALL evidence and scan logs (flush stale mock data before real scan)
  Future<void> clearAllEvidence(String uid) async {
    final evidenceDocs = await _db
        .collection('users')
        .doc(uid)
        .collection('evidence')
        .get();
    for (final doc in evidenceDocs.docs) {
      await doc.reference.delete();
    }
    final logDocs = await _db
        .collection('users')
        .doc(uid)
        .collection('scan_logs')
        .get();
    for (final doc in logDocs.docs) {
      await doc.reference.delete();
    }
  }
}
