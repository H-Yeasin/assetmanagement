import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ffp_vault/services/notification_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ── Register (Email/Password) ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) {
        return _formatError("Passwords do not match");
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.reload();
        await _safeUpsertUserDoc(user, fallbackName: fullName);
        return _authSuccess(
          user,
          message: 'Registration successful',
          userName: fullName,
        );
      }
      return _formatError("Registration failed");
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "An error occurred during registration");
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await _safeUpsertUserDoc(user);
        final twoFactorResult = await requestTwoFactorLogin(email: email);
        final twoFactorRequired =
            (twoFactorResult['data']?['twoFactorRequired'] == true);
        if (twoFactorRequired) {
          return {
            'statusCode': 403,
            'success': false,
            'message':
                twoFactorResult['message'] ??
                'Two-factor authentication required',
            'data': {
              'twoFactorRequired': true,
              'email': twoFactorResult['data']?['email'] ?? email,
            },
          };
        }
        return _authSuccess(
          user,
          message: 'Login successful',
          userName: await _safeResolveDisplayName(user),
        );
      }
      return _formatError("Login failed");
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "Invalid email or password");
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return _formatError('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return _formatError('Google sign-in failed.');

      await _safeUpsertUserDoc(user);
      return _authSuccess(
        user,
        message: 'Google login successful',
        userName: await _safeResolveDisplayName(user),
      );
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Apple Sign-In ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> loginWithApple() async {
    try {
      if (!(defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
        return _formatError('Apple sign-in is only available on iOS/macOS.');
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);
      final user = userCredential.user;
      if (user == null) return _formatError('Apple sign-in failed.');

      if ((user.displayName ?? '').trim().isEmpty) {
        final fullName = [
          appleCredential.givenName,
          appleCredential.familyName,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' ');
        if (fullName.isNotEmpty) {
          await user.updateDisplayName(fullName);
        }
      }

      await _safeUpsertUserDoc(user);
      return _authSuccess(
        user,
        message: 'Apple login successful',
        userName: await _safeResolveDisplayName(user),
      );
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? 'Apple sign-in failed.');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final callable = _functions.httpsCallable('requestPasswordResetOtp');
      await callable.call({'email': email.trim()});
      return {
        'statusCode': 200,
        'success': true,
        'message': 'OTP sent to your email',
      };
    } on FirebaseFunctionsException catch (e) {
      return _formatError((e.message ?? 'Error sending OTP'), 400);
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "Error sending OTP");
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> logout({String? token}) async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      return {
        'statusCode': 200,
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  // ── Two-Factor Auth (Placeholder for complex migration) ──────────────────
  static Future<Map<String, dynamic>> getTwoFactorStatus({
    required String token,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return _formatError("User not logged in", 401);

    final doc = await _db.collection('users').doc(user.uid).get();
    return {
      'statusCode': 200,
      'success': true,
      'data': {
        'isTwoFactorEnabled': doc.data()?['twoFactorEnabled'] ?? false,
        'email': doc.data()?['twoFactorEmail'] ?? user.email,
      },
    };
  }

  static Future<Map<String, dynamic>> requestTwoFactorEnable({
    required String email,
    required String token,
  }) async {
    try {
      final callable = _functions.httpsCallable('requestTwoFactorEnable');
      final response = await callable.call({'email': email.trim()});
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      return {
        'statusCode': 200,
        'success': true,
        'message': data['message'] ?? 'Verification code sent',
        'data': {'email': data['email'] ?? email.trim()},
      };
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? 'Failed to send verification code');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> verifyTwoFactorEnable({
    required String otp,
    required String token,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      final callable = _functions.httpsCallable('verifyTwoFactorEnable');
      final response = await callable.call({'otp': otp.trim()});
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};

      return {
        'statusCode': 200,
        'success': true,
        'message': data['message'] ?? 'Two-factor authentication enabled',
        'data': {'enabled': true, 'email': data['email'] ?? user.email ?? ''},
      };
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? 'Invalid verification code');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> requestTwoFactorLogin({
    required String email,
  }) async {
    try {
      final callable = _functions.httpsCallable('requestTwoFactorLogin');
      final response = await callable.call({'email': email.trim()});
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};
      return {
        'statusCode': 200,
        'success': true,
        'message': data['message'] ?? 'Verification flow ready',
        'data': {
          'twoFactorRequired': data['twoFactorRequired'] == true,
          'email': data['email'] ?? email.trim(),
        },
      };
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? 'Failed to start 2FA login');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> verifyTwoFactorLogin({
    required String email,
    required String otp,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      final callable = _functions.httpsCallable('verifyTwoFactorLogin');
      await callable.call({'otp': otp.trim()});

      return _authSuccess(
        user,
        message: '2FA verification successful',
        userName: await _safeResolveDisplayName(user),
      );
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? 'Invalid verification code');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> disableTwoFactor({
    required String token,
    String? password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return _formatError("User not logged in", 401);

      final isPasswordProvider = user.providerData.any(
        (p) => p.providerId == 'password',
      );

      if (isPasswordProvider) {
        if (user.email == null) {
          return _formatError('Current account email is missing');
        }
        if (password == null || password.trim().isEmpty) {
          return _formatError('Current password is required to disable 2FA');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password.trim(),
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        return _formatError(
          '2FA disable requires re-authentication with password. This account is signed in with social login.',
        );
      }

      await _db.collection('users').doc(user.uid).set({
        'twoFactorEnabled': false,
        'twoFactorEmail': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'statusCode': 200,
        'success': true,
        'message': 'Two-factor authentication disabled',
      };
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    return _formatError(
      'Email OTP verification is not enabled. Use email verification link or phone OTP.',
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    String? email,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    try {
      if (confirmPassword != null && newPassword != confirmPassword) {
        return _formatError("Passwords do not match");
      }
      if (email == null || email.trim().isEmpty) {
        return _formatError('Email is required');
      }
      final callable = _functions.httpsCallable('resetPasswordWithOtp');
      await callable.call({
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      });
      return {
        'statusCode': 200,
        'success': true,
        'message': 'Password reset successful',
      };
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? "Error resetting password");
    } on FirebaseAuthException catch (e) {
      return _formatError(e.message ?? "Error resetting password");
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<Map<String, dynamic>> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPasswordResetOtp');
      await callable.call({'email': email.trim(), 'otp': otp.trim()});
      return {'statusCode': 200, 'success': true, 'message': 'OTP verified'};
    } on FirebaseFunctionsException catch (e) {
      return _formatError(e.message ?? 'Invalid OTP');
    } catch (e) {
      return _formatError(e.toString());
    }
  }

  static Future<void> _upsertUserDoc(User user, {String? fallbackName}) async {
    final userRef = _db.collection('users').doc(user.uid);
    final existing = await userRef.get();
    await userRef.set({
      'fullName': user.displayName ?? fallbackName ?? '',
      'email': user.email ?? '',
      'phone': user.phoneNumber ?? '',
      'avatarUrl': user.photoURL ?? '',
      if (!existing.exists) 'twoFactorEnabled': false,
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _safeUpsertUserDoc(
    User user, {
    String? fallbackName,
  }) async {
    try {
      await _upsertUserDoc(user, fallbackName: fallbackName);
    } catch (_) {
      // Firestore unavailability should not block successful authentication.
    }
  }

  static Future<String> _resolveDisplayName(User user) async {
    final displayName = user.displayName?.trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final doc = await _db.collection('users').doc(user.uid).get();
    return (doc.data()?['fullName'] as String?)?.trim().isNotEmpty == true
        ? (doc.data()?['fullName'] as String)
        : 'User';
  }

  static Future<String> _safeResolveDisplayName(User user) async {
    try {
      return await _resolveDisplayName(user);
    } catch (_) {
      final fallback = user.displayName?.trim() ?? '';
      return fallback.isNotEmpty ? fallback : 'User';
    }
  }

  static Future<Map<String, dynamic>> _authSuccess(
    User user, {
    required String message,
    required String userName,
  }) async {
    // Try to init/update FCM token now that user has logged in
    try {
      await NotificationService.initFCM();
    } catch (_) {}

    // Fetch the latest metadata from Firestore to ensure local storage starts with correct data
    String finalName = userName;
    String? finalAvatar = user.photoURL;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        finalName = data?['fullName'] as String? ?? userName;
        finalAvatar = data?['avatarUrl'] as String? ?? user.photoURL;
      }
    } catch (_) {}

    final idToken = await user.getIdToken();
    return {
      'statusCode': 200,
      'success': true,
      'message': message,
      'data': {
        'accessToken': idToken,
        'refreshToken': user.refreshToken ?? '',
        '_id': user.uid,
        'user': {
          '_id': user.uid,
          'email': user.email ?? '',
          'phone': user.phoneNumber ?? '',
          'fullName': finalName,
          'avatar': {'url': finalAvatar ?? ''},
        },
      },
    };
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
