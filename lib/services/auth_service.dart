import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ── Change this to your backend IP when testing on a real device ──────────
  // Emulator: 127.0.0.1  |  iOS Simulator: localhost  |  Real device: <your LAN IP>
  static const String _baseUrl = 'http://127.0.0.1:5000/api/v1/auth';
  static const String _userUrl = 'http://127.0.0.1:5000/api/v1/user';

  // ── Register ───────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      }),
    );
    return _decode(res);
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  // ── Verify Email OTP (registration) ───────────────────────────────────────
  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _decode(res);
  }

  // ── Forgot Password – sends OTP email ─────────────────────────────────────
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/forget'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    return _decode(res);
  }

  // ── Reset Password (after OTP verified for forgot password flow) ───────────
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp, 'password': newPassword}),
    );
    return _decode(res);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> logout({required String token}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decode(res);
  }

  // ── Two-Factor Auth (Login verification) ──────────────────────────────────
  /// Called during login when 2FA is required.
  /// Sends the 6-digit OTP to complete login and receive tokens.
  static Future<Map<String, dynamic>> verifyTwoFactorLogin({
    required String email,
    required String otp,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/two-factor/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    return _decode(res);
  }

  // ── Two-Factor Auth (Setup from profile) ──────────────────────────────────

  /// Fetches current 2FA status (enabled, registered email).
  static Future<Map<String, dynamic>> getTwoFactorStatus({
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse('$_userUrl/two-factor'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return _decode(res);
  }

  /// Sends OTP to [email] to start the 2FA enable process.
  static Future<Map<String, dynamic>> requestTwoFactorEnable({
    required String email,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_userUrl/two-factor/enable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'email': email}),
    );
    return _decode(res);
  }

  /// Verifies OTP and enables 2FA on the account.
  static Future<Map<String, dynamic>> verifyTwoFactorEnable({
    required String otp,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_userUrl/two-factor/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'otp': otp}),
    );
    return _decode(res);
  }

  /// Disables 2FA after confirming the user's [password].
  static Future<Map<String, dynamic>> disableTwoFactor({
    required String password,
    required String token,
  }) async {
    final res = await http.post(
      Uri.parse('$_userUrl/two-factor/disable'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'password': password}),
    );
    return _decode(res);
  }

  // ── Decode helper ──────────────────────────────────────────────────────────
  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'statusCode': res.statusCode,
      'success': body['success'] ?? false,
      'message': body['message'] ?? '',
      'data': body['data'],
    };
  }
}
