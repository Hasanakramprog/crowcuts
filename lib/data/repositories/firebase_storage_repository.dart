import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Repository for Firebase Storage operations.
class FirebaseStorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a barber avatar and return the download URL.
  /// Path: barbers/{barberId}/avatar.jpg
  Future<String> uploadBarberAvatar({
    required String barberId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('barbers')
          .child(barberId)
          .child('avatar.jpg');

      final snapshot = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Use the snapshot ref directly — more reliable than ref.getDownloadURL()
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Append a timestamp to the URL to bust Flutter's Image.network cache
      // This ensures the new image is immediately shown in the UI
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      if (downloadUrl.contains('?')) {
        return '$downloadUrl&v=$cacheBuster';
      } else {
        return '$downloadUrl?v=$cacheBuster';
      }
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found' || e.code == 'unauthorized') {
        throw Exception(
          'Firebase Storage is not enabled for this project. '
          'Please enable it in the Firebase Console under Storage.',
        );
      }
      rethrow;
    }
  }

  /// Delete a barber avatar from storage.
  Future<void> deleteBarberAvatar(String barberId) async {
    try {
      await _storage
          .ref()
          .child('barbers')
          .child(barberId)
          .child('avatar.jpg')
          .delete();
    } catch (_) {
      // Ignore if file doesn't exist
    }
  }
}

final firebaseStorageRepositoryProvider =
    Provider<FirebaseStorageRepository>((ref) {
  return FirebaseStorageRepository();
});
