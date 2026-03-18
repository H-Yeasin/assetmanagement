import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Loan_Screen/models/document_model.dart';
import 'notification_service.dart';

class VaultDownloadResult {
  final String savedPath;

  const VaultDownloadResult({
    required this.savedPath,
  });
}

class VaultFileService {
  static int _notificationId(DocumentFile doc) =>
      (doc.id.hashCode ^ doc.filename.hashCode) & 0x7fffffff;

  static Future<File> _downloadToFile(
    DocumentFile doc,
    Directory directory,
  ) async {
    final response = await http.get(Uri.parse(doc.path));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Download failed with status ${response.statusCode}');
    }

    final file = File('${directory.path}/${doc.filename}');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  static Future<VaultDownloadResult> downloadDocument(DocumentFile doc) async {
    final notificationId = _notificationId(doc);
    await NotificationService.showInstantNotification(
      id: notificationId,
      title: 'Downloading',
      body: '${doc.displayName} is downloading.',
    );

    final docsDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${docsDir.path}/vault_downloads');
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    final file = await _downloadToFile(doc, vaultDir);
    await NotificationService.showInstantNotification(
      id: notificationId,
      title: 'Download Complete',
      body: '${doc.displayName} was downloaded successfully.',
    );
    return VaultDownloadResult(savedPath: file.path);
  }

  static Future<void> shareDocument(DocumentFile doc) async {
    final tempDir = await getTemporaryDirectory();
    final file = await _downloadToFile(doc, tempDir);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: doc.mimeType, name: doc.displayName)],
      subject: doc.displayName,
      text: doc.displayName,
    );
  }
}
