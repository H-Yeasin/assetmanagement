import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:anick_giroux/services/storage_service.dart';
import 'dart:io';

class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  // Use default storage instance to inherit default rules correctly
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Sync Profile with Firestore ───────────────────────────────────────────
  static Future<void> syncProfileWithFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final name = data?['fullName'] as String? ?? user.displayName ?? 'User';
        final avatar = data?['avatarUrl'] as String? ?? user.photoURL;

        await StorageService.updateNameAndAvatar(
          name: name,
          avatar: avatar,
        );
      }
    } catch (_) {
      // Best-effort sync should not crash the app
    }
  }

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
      String? uploadWarning;

      // Upload image if provided
      if (imageFile != null) {
        try {
          // Force-refresh the ID token so Storage rules see a valid auth context
          await user.getIdTokenResult(true);

          final ref = _storage.ref().child('avatars/${user.uid}/profile.jpg');

          // Explicitly pass the token in customMetadata so rules can access it if native auth is dropped
          final metadata = SettableMetadata(contentType: 'image/jpeg');

          // Use putFile instead of putData matching document upload success
          await ref.putFile(imageFile, metadata);
          photoUrl = await ref.getDownloadURL();
        } on FirebaseException catch (e) {
          uploadWarning = e.code == 'unauthorized'
              ? 'Profile name updated, but image upload is not allowed by Firebase Storage rules.'
              : 'Profile name updated, but image upload failed: ${e.code} ${e.message}';
        }
      }

      // Update Firebase Auth Profile
      await user.updateDisplayName(fullName);
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      await _db.collection('users').doc(user.uid).set({
        'fullName': fullName,
        // ignore: use_null_aware_elements
        if (photoUrl != null) 'avatarUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {
        'statusCode': 200,
        'success': true,
        'message': uploadWarning ?? 'Profile updated successfully',
        'data': {
          'fullName': fullName,
          'avatarUrl': photoUrl ?? user.photoURL,
          'imageUploadFailed': uploadWarning != null,
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
      if (newPassword == currentPassword) {
        return _formatError("New password must be different");
      }

      final isPasswordProvider = user.providerData.any(
        (p) => p.providerId == 'password',
      );
      if (!isPasswordProvider || user.email == null) {
        return _formatError(
          "Password change is only available for email/password accounts",
        );
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

  // ── Delete Account ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteAccount({
    required String email,
    String? password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      if ((user.email ?? '').toLowerCase() != email.trim().toLowerCase()) {
        return _formatError("Email does not match current account");
      }

      final isPasswordProvider = user.providerData.any(
        (p) => p.providerId == 'password',
      );
      if (isPasswordProvider) {
        if (password == null || password.trim().isEmpty) {
          return _formatError("Password is required");
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password.trim(),
        );
        await user.reauthenticateWithCredential(credential);
      }

      final uid = user.uid;

      // Best-effort cleanup before deleting auth user.
      try {
        await _db.collection('users').doc(uid).delete();
      } catch (_) {}
      try {
        await _storage.ref().child('avatars/$uid/profile.jpg').delete();
      } catch (_) {}

      await user.delete();

      return {
        'statusCode': 200,
        'success': true,
        'message': 'Account deleted successfully',
      };
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "Failed to delete account");
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
