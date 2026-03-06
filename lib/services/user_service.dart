import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Update Profile (Name & Avatar) ─────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    String? token, // Token is no longer strictly required with Firebase Auth
    required String fullName,
    File? imageFile,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      String? photoUrl;

      // Upload image if provided
      if (imageFile != null) {
        final ref = _storage.ref().child('avatars/${user.uid}.jpg');
        await ref.putFile(imageFile);
        photoUrl = await ref.getDownloadURL();
      }

      // Update Firebase Auth Profile
      await user.updateDisplayName(fullName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      await _db.collection('users').doc(user.uid).update({
        'fullName': fullName,
        if (photoUrl != null) 'avatarUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'statusCode': 200,
        'success': true,
        'message': 'Profile updated successfully',
        'data': {
          'fullName': fullName,
          'avatarUrl': photoUrl ?? user.photoURL,
        },
      };
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Change Password ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword({
    String? token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      if (newPassword != confirmPassword) {
        return _formatError("New passwords do not match");
      }

      // Re-authenticate user before sensitive operation
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return {
        'statusCode': 200,
        'success': true,
        'message': 'Password changed successfully',
      };
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "Error updating password");
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Helper ───────────────────────────────────────────────────────────────
  static Map<String, dynamic> _formatError(String message, [int code = 400]) {
    return {
      'statusCode': code,
      'success': false,
      'message': message,
      'data': null,
    };
  }
}
