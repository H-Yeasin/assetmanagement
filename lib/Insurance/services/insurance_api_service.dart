import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/insurance_model.dart';
import '../../Loan_Screen/models/document_model.dart';
import '../../services/storage_service.dart';

class InsuranceApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  Future<Map<String, String>> getHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<InsurancePolicy>> fetchInsurances({String? category}) async {
    String query = '';
    if (category != null) query = '?category=$category';

    final response = await http.get(
      Uri.parse('$baseUrl/insurance$query'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => InsurancePolicy.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load insurances: ${response.body}');
    }
  }

  Future<InsurancePolicy> getInsurance(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/insurance/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return InsurancePolicy.fromJson(data['data']);
    } else {
      throw Exception('Failed to load insurance: ${response.body}');
    }
  }

  Future<InsurancePolicy> createInsurance(InsurancePolicy policy) async {
    final response = await http.post(
      Uri.parse('$baseUrl/insurance'),
      headers: await getHeaders(),
      body: json.encode(policy.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return InsurancePolicy.fromJson(data['data']);
    } else {
      throw Exception('Failed to create insurance: ${response.body}');
    }
  }

  Future<InsurancePolicy> updateInsurance(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/insurance/$id'),
      headers: await getHeaders(),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return InsurancePolicy.fromJson(data['data']);
    } else {
      throw Exception('Failed to update insurance: ${response.body}');
    }
  }

  Future<void> deleteInsurance(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/insurance/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete insurance: ${response.body}');
    }
  }

  Future<List<InsurancePolicy>> fetchUpcomingRenewals({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}';
    if (query.isNotEmpty) query = '?$query';

    final response = await http.get(
      Uri.parse('$baseUrl/insurance/upcoming$query'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => InsurancePolicy.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load upcoming renewals: ${response.body}');
    }
  }

  // Document Management
  Future<void> deleteDocument(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/documents/files/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete document: ${response.body}');
    }
  }

  Future<void> renameDocument(String id, String newName) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/documents/files/$id'),
      headers: await getHeaders(),
      body: json.encode({'displayName': newName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename document: ${response.body}');
    }
  }

  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'insurance',
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
        contentType: MediaType.parse(mimeType),
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

  // Reminder Management
  Future<void> createReminder({
    required String itemId,
    required String itemType,
    required String title,
    required DateTime remindAt,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: await getHeaders(),
      body: json.encode({
        'itemId': itemId,
        'itemType': itemType,
        'title': title,
        'remindAt': remindAt.toIso8601String(),
        'note': note,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create reminder: ${response.body}');
    }
  }

  Future<List<dynamic>> fetchUpcomingReminders({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}&';
    if (query.isNotEmpty) query = '?${query.substring(0, query.length - 1)}';

    final response = await http.get(
      Uri.parse('$baseUrl/reminders/upcoming$query'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load upcoming reminders: ${response.body}');
    }
  }
}
