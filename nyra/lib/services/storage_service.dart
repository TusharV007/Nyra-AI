import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload an identity photo to Firebase Storage and return the download URL
  Future<String?> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('users')
          .child(uid)
          .child('profile_photo.jpg');
      final uploadTask = await ref
          .putFile(imageFile)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception(
                'Upload timed out. Is Firebase Storage enabled in your Firebase Console?',
              );
            },
          );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
