import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/housing_cost_model.dart';
import '../../Loan_Screen/models/document_model.dart';
import '../../services/storage_service.dart';

class HousingApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<HousingCost>> fetchHousingCosts({String? category}) async {
    String query = '';
    if (category != null) query = '?category=$category';

    final response = await http.get(
      Uri.parse('$baseUrl/housing$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => HousingCost.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load housing costs: ${response.body}');
    }
  }

  Future<HousingCost> getHousingCost(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/housing/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return HousingCost.fromJson(data['data']);
    } else {
      throw Exception('Failed to load housing cost: ${response.body}');
    }
  }

  Future<HousingCost> createHousingCost(HousingCost cost) async {
    final response = await http.post(
      Uri.parse('$baseUrl/housing'),
      headers: await _getHeaders(),
      body: json.encode(cost.toJson()),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = json.decode(response.body);
      return HousingCost.fromJson(data['data']);
    } else {
      throw Exception('Failed to create housing cost: ${response.body}');
    }
  }

  Future<HousingCost> updateHousingCost(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/housing/$id'),
      headers: await _getHeaders(),
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return HousingCost.fromJson(data['data']);
    } else {
      throw Exception('Failed to update housing cost: ${response.body}');
    }
  }

  Future<void> deleteHousingCost(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/housing/$id'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete housing cost: ${response.body}');
    }
  }

  Future<List<HousingCost>> fetchUpcomingHousingCosts({
    DateTime? from,
    DateTime? to,
  }) async {
    String query = '';
    if (from != null) query += 'from=${from.toIso8601String()}&';
    if (to != null) query += 'to=${to.toIso8601String()}';
    if (query.isNotEmpty) query = '?$query';

    final response = await http.get(
      Uri.parse('$baseUrl/housing/upcoming$query'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => HousingCost.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load upcoming housing costs: ${response.body}',
      );
    }
  }

  // Document Management
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

  Future<DocumentFile> uploadDocument(
    File file, {
    String module = 'housing',
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
    } else if (extension == 'png') {
      mimeType = 'image/png';
    } else if (extension == 'jpg' || extension == 'jpeg') {
      mimeType = 'image/jpeg';
    }

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

  Future<void> createReminder({
    required String itemId,
    required String itemType,
    required String title,
    required DateTime remindAt,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: await _getHeaders(),
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
}
