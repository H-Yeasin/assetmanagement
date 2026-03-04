import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/loan_model.dart';
import '../models/document_model.dart';
import '../../services/storage_service.dart';

class LoanApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  Future<Map<String, String>> getHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Loan>> fetchLoans({String? status}) async {
    final queryParams = status != null ? '?status=$status' : '';
    final url = '$baseUrl/loans$queryParams';
    print('GET REQUEST: $url');
    print('HEADERS: await _getHeaders()');
    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> loanList = data['data'];
      return loanList.map((json) => Loan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load loans: ${response.body}');
    }
  }

  Future<Loan> getLoan(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/loans/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Loan.fromJson(data['data']);
    } else {
      throw Exception('Failed to load loan: ${response.body}');
    }
  }

  Future<Loan> createLoan(Loan loan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/loans'),
      headers: await _getHeaders(),
      body: json.encode(loan.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Loan.fromJson(data['data']);
    } else {
      throw Exception('Failed to create loan: ${response.body}');
    }
  }

  Future<Loan> updateLoan(String id, Map<String, dynamic> updates) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/loans/$id'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Loan.fromJson(data['data']);
    } else {
      throw Exception('Failed to update loan: ${response.body}');
    }
  }

  Future<void> deleteLoan(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/loans/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete loan: ${response.body}');
    }
  }

  Future<void> deleteDocument(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/documents/files/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  Future<void> renameDocument(String id, String newName) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/documents/files/$id'),
      headers: await _getHeaders(),
      body: json.encode({'displayName': newName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename document: ${response.body}');
    }
  }

  Future<Loan> markCompleted(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/loans/$id/complete'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return Loan.fromJson(data['data']);
    } else {
      throw Exception('Failed to complete loan: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchUpcomingPayments({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}';
    if (query.isNotEmpty) query = '?$query';

    final response = await http.get(
      Uri.parse('$baseUrl/loans/upcoming$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data']; // Returns grouped by date
    } else {
      throw Exception('Failed to load upcoming payments: ${response.body}');
    }
  }

  // Document Upload
  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'loans',
    String? folderId,
    String? relatedType,
    String? relatedId,
    String? displayName,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/documents/upload'),
    );
    final token = await StorageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['module'] = module;
    if (folderId != null) request.fields['folderId'] = folderId;
    if (relatedType != null) request.fields['relatedType'] = relatedType;
    if (relatedId != null) request.fields['relatedId'] = relatedId;
    if (displayName != null) request.fields['displayName'] = displayName;

    final extension = file.path.split('.').last.toLowerCase();
    String mimeType = 'application/octet-stream';
    if (extension == 'pdf') {
      mimeType = 'application/pdf';
    } else if (extension == 'png')
      mimeType = 'image/png';
    else if (extension == 'jpg' || extension == 'jpeg')
      mimeType = 'image/jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: http.MediaType.parse(mimeType),
      ),
    );

    var response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(resBody);
      return DocumentFile.fromJson(data['data']);
    } else {
      throw Exception('Failed to upload document: $resBody');
    }
  }

  // ── Past Activities ──────────────────────────────────────────────────────

  Future<List<dynamic>> fetchPastActivities({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}';
    if (query.isNotEmpty) query = '?$query';

    final response = await http.get(
      Uri.parse('$baseUrl/loans/past$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data']; // Returns grouped by date
    } else {
      throw Exception('Failed to load past activities: ${response.body}');
    }
  }

  // ── Reminders ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createReminder({
    required String itemType,
    required String itemId,
    required DateTime remindAt,
    String? title,
    String? note,
  }) async {
    final body = {
      'itemType': itemType,
      'itemId': itemId,
      'remindAt': remindAt.toIso8601String(),
      if (title != null) 'title': title,
      if (note != null) 'note': note,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: await _getHeaders(),
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to create reminder: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchUpcomingReminders({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}';
    if (query.isNotEmpty) query = '?$query';

    final response = await http.get(
      Uri.parse('$baseUrl/reminders/upcoming$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load reminders: ${response.body}');
    }
  }

  Future<void> markReminderDone(String id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/reminders/$id/done'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark reminder done: ${response.body}');
    }
  }
}
