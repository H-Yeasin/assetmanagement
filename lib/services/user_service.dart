import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class UserService {
  // Use localhost for iOS simulator/macOS
  static const String _baseUrl = 'http://127.0.0.1:5000/api/v1/user';

  // ── Update Profile (Name & Avatar) ─────────────────────────────────────────
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String fullName,
    File? imageFile,
  }) async {
    final uri = Uri.parse('$_baseUrl/profile');
    final request = http.MultipartRequest('PUT', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['fullName'] = fullName;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final decoded = jsonDecode(responseData) as Map<String, dynamic>;

    return {
      'statusCode': response.statusCode,
      'success': decoded['success'] ?? false,
      'message': decoded['message'] ?? '',
      'data': decoded['data'],
    };
  }

  // ── Change Password ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'statusCode': res.statusCode,
      'success': body['success'] ?? false,
      'message': body['message'] ?? '',
    };
  }
}
