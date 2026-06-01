import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/models/document_model.dart';
import '../services/loan_service.dart';
import '../services/vault_file_service.dart';
import '../services/vault_session_manager.dart';
import 'vault_category_dialogs.dart';

/// Mixin that provides document CRUD operations and file upload logic
/// for VaultCategoryScreen.
///
/// Depends on [VaultCategoryDialogsMixin] for `confirm`, `showMessage`,
/// and `reloadDocuments`.
mixin VaultCategoryActionsMixin<T extends StatefulWidget> on State<T>,
    VaultCategoryDialogsMixin<T> {
  // ── Abstract contracts the host state must satisfy ────────────────────────
  bool get isUploading;
  set isUploading(bool value);
  String get currentModule;

  // ── Delete folder + children ─────────────────────────────────────────────
  @override
  Future<void> deleteFolder(
    DocumentFile folder,
    List<DocumentFile> allDocs,
  ) async {
    final confirmed = await confirm(
      title: 'Delete Folder',
      message:
          'This will delete the folder and all files inside it. This action cannot be undone.',
    );
    if (confirmed != true) return;

    final service = LoanService();
    final children =
        allDocs.where((doc) => doc.folderId == folder.id).toList();

    try {
      for (final child in children) {
        await service.deleteDocument(child.id);
      }
      await service.deleteDocument(folder.id);
      await reloadDocuments();
      showMessage('Folder deleted successfully.');
    } catch (e) {
      showMessage('Failed to delete folder: $e', isError: true);
    }
  }

  // ── Delete single file ───────────────────────────────────────────────────
  @override
  Future<void> deleteFile(DocumentFile doc) async {
    final confirmed = await confirm(
      title: 'Delete File',
      message: 'Are you sure you want to delete this file?',
    );
    if (confirmed != true) return;

    try {
      await LoanService().deleteDocument(doc.id);
      await reloadDocuments();
      showMessage('File deleted successfully.');
    } catch (e) {
      showMessage('Failed to delete file: $e', isError: true);
    }
  }

  // ── Rename file ──────────────────────────────────────────────────────────
  @override
  Future<void> renameFile(DocumentFile doc) async {
    final controller = TextEditingController(text: doc.displayName);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save != true) return;

    final newName = controller.text.trim();
    if (newName.isEmpty || newName == doc.displayName) return;

    try {
      await LoanService().renameDocument(doc.id, newName);
      await reloadDocuments();
      showMessage('File renamed successfully.');
    } catch (e) {
      showMessage('Failed to rename file: $e', isError: true);
    }
  }

  // ── Download ─────────────────────────────────────────────────────────────
  @override
  Future<void> downloadDocument(DocumentFile doc) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo.png', width: 60, height: 60),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: brandRed),
              const SizedBox(height: 16),
              const Text(
                'Downloading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await VaultFileService.downloadDocument(doc);
      showMessage('Downloaded successfully.');
    } catch (e) {
      if (mounted) Navigator.pop(context);
      showMessage('Failed to download file: $e', isError: true);
    }
  }

  // ── Share ────────────────────────────────────────────────────────────────
  @override
  Future<void> shareDocument(DocumentFile doc) async {
    try {
      await VaultFileService.shareDocument(doc);
    } catch (e) {
      showMessage('Failed to share file: $e', isError: true);
    }
  }

  // ── Preview (PDF → external, image → in-app) ────────────────────────────
  Future<void> previewDocument(DocumentFile doc) async {
    try {
      final openUrl = await LoanService().getDocumentOpenUrl(doc);
      final resolvedDoc = DocumentFile(
        id: doc.id,
        userId: doc.userId,
        module: doc.module,
        originalName: doc.originalName,
        displayName: doc.displayName,
        filename: doc.filename,
        mimeType: doc.mimeType,
        size: doc.size,
        path: openUrl,
        relatedType: doc.relatedType,
        relatedId: doc.relatedId,
        createdAt: doc.createdAt,
        updatedAt: doc.updatedAt,
        folderId: doc.folderId,
      );
      final isPdf =
          resolvedDoc.mimeType == 'application/pdf' ||
          resolvedDoc.filename.endsWith('.pdf');
      if (isPdf) {
        await _launchURL(resolvedDoc.path);
      } else {
        _showImagePreview(resolvedDoc);
      }
    } catch (e) {
      showMessage('Could not open the document: $e', isError: true);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      showMessage('Opening document...');
    } else {
      showMessage('Could not open the document.', isError: true);
    }
  }

  void _showImagePreview(DocumentFile doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: InteractiveViewer(
                child: Image.network(
                  doc.path,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Text(
                      'Preview unavailable',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── File upload ──────────────────────────────────────────────────────────
  @override
  void uploadFile() async {
    try {
      VaultSessionManager.instance.expectExternalActivity();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => isUploading = true);
      final file = File(result.files.single.path!);

      await LoanService().uploadDocument(file, module: currentModule);

      if (!mounted) return;
      setState(() => isUploading = false);
      await reloadDocuments();
      showMessage('File uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploading = false);
      showMessage('Error uploading file: $e', isError: true);
    }
  }

  // ── Image pick (camera / gallery) ────────────────────────────────────────
  @override
  void pickImage(ImageSource source) async {
    try {
      VaultSessionManager.instance.expectExternalActivity();
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => isUploading = true);
      final file = File(pickedFile.path);

      await LoanService().uploadDocument(file, module: currentModule);

      if (!mounted) return;
      setState(() => isUploading = false);
      await reloadDocuments();
      showMessage('Image uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => isUploading = false);
      showMessage('Error uploading image: $e', isError: true);
    }
  }

  // ── Module resolver ──────────────────────────────────────────────────────
  String resolveModule(String categoryNameValue) {
    String module = 'loans';
    if (categoryNameValue.contains('Housing')) module = 'housing';
    if (categoryNameValue.contains('Insurance')) module = 'insurance';
    if (categoryNameValue.contains('Document')) module = 'documents';
    return module;
  }

  // ── Fetch helper ─────────────────────────────────────────────────────────
  Future<List<DocumentFile>> fetchCategoryDocuments() async {
    return LoanService().fetchDocumentsByModule(currentModule);
  }
}
