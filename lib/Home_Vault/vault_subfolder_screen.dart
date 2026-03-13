import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/models/document_model.dart';
import '../services/loan_service.dart';
import '../services/vault_file_service.dart';

class VaultSubfolderScreen extends StatefulWidget {
  final String folderName;
  final String folderId;
  final String categoryName;

  const VaultSubfolderScreen({
    super.key,
    required this.folderName,
    required this.folderId,
    required this.categoryName,
  });

  @override
  State<VaultSubfolderScreen> createState() => _VaultSubfolderScreenState();
}

class _VaultSubfolderScreenState extends State<VaultSubfolderScreen> {
  bool _isUploading = false;
  late Future<List<DocumentFile>> _documentsFuture;
  late String _folderName;

  @override
  void initState() {
    super.initState();
    _folderName = widget.folderName;
    _documentsFuture = _fetchFolderDocuments();
  }

  Future<void> _reloadDocuments() async {
    setState(() {
      _documentsFuture = _fetchFolderDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _folderName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final updatedName = await context.push<String>(
                        '/vault-edit-folder',
                        extra: {
                          'folderName': _folderName,
                          'folderId': widget.folderId,
                          'categoryName': widget.categoryName,
                        },
                      );
                      if (updatedName != null && mounted) {
                        setState(() => _folderName = updatedName);
                        await _reloadDocuments();
                      }
                    },
                    child: Image.asset(
                      'assets/images/create.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Add New Files',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: 'assets/images/upload.png',
                            label: 'Upload',
                            onTap: _isUploading ? () {} : _uploadFile,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.camera_alt_outlined,
                            label: 'Take photo',
                            onTap: _isUploading
                                ? () {}
                                : _showImageSourcePicker,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (_isUploading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: brandRed),
                              SizedBox(height: 12),
                              Text(
                                'Uploading...',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Text(
                      'Uploaded Documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<List<DocumentFile>>(
                      future: _documentsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: brandRed),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load folder files: ${snapshot.error}',
                              style: const TextStyle(color: brandRed),
                            ),
                          );
                        }

                        final allDocs = snapshot.data ?? [];
                        final docs = allDocs
                            .where((d) => d.folderId == widget.folderId)
                            .toList();

                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No documents found in this folder.',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final isPdf =
                                doc.mimeType == 'application/pdf' ||
                                doc.displayName.endsWith('.pdf');
                            return _UploadedFileRow(
                              fileName: doc.displayName,
                              fileInfo:
                                  '${(doc.size / 1024).toStringAsFixed(1)} KB',
                              fileType: isPdf ? 'pdf' : 'image',
                              onTap: () => _previewDocument(doc),
                              onMenuTap: () => _showFileMenu(doc),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileMenu(DocumentFile doc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _MenuOption(
              icon: Icons.edit_outlined,
              label: 'Rename',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _renameFile(doc);
              },
            ),
            _MenuOption(
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteFile(doc);
              },
            ),
            _MenuOption(
              icon: 'assets/images/black_download.png',
              label: 'Download',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _downloadDocument(doc);
              },
            ),
            _MenuOption(
              icon: 'assets/images/black_share.png',
              label: 'Share/Send',
              onTap: () async {
                Navigator.pop(sheetContext);
                await _shareDocument(doc);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  String get _currentModule {
    String mod = 'loans';
    if (widget.categoryName.contains('Housing')) mod = 'housing';
    if (widget.categoryName.contains('Insurance')) mod = 'insurance';
    if (widget.categoryName.contains('Document')) mod = 'documents';
    return mod;
  }

  Future<List<DocumentFile>> _fetchFolderDocuments() async {
    return LoanService().fetchDocumentsByModule(_currentModule);
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);
      final file = File(result.files.single.path!);

      await LoanService().uploadDocument(
        file,
        module: _currentModule,
        folderId: widget.folderId,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);
      await _reloadDocuments();
      _showMessage('File uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showMessage('Error uploading file: $e', isError: true);
    }
  }

  Future<void> _showImageSourcePicker() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final file = File(pickedFile.path);

      await LoanService().uploadDocument(
        file,
        module: _currentModule,
        folderId: widget.folderId,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);
      await _reloadDocuments();
      _showMessage('Image uploaded successfully.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showMessage('Error uploading image: $e', isError: true);
    }
  }

  Future<void> _deleteFile(DocumentFile doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: const Text('Are you sure you want to delete this file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await LoanService().deleteDocument(doc.id);
      await _reloadDocuments();
      _showMessage('File deleted successfully.');
    } catch (e) {
      _showMessage('Failed to delete file: $e', isError: true);
    }
  }

  Future<void> _renameFile(DocumentFile doc) async {
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
      await _reloadDocuments();
      _showMessage('File renamed successfully.');
    } catch (e) {
      _showMessage('Failed to rename file: $e', isError: true);
    }
  }

  Future<void> _downloadDocument(DocumentFile doc) async {
    try {
      final result = await VaultFileService.downloadDocument(doc);
      _showMessage(
        result.savedToGallery
            ? 'Downloaded successfully. Saved to gallery.'
            : 'Downloaded successfully.',
      );
    } catch (e) {
      _showMessage('Failed to download file: $e', isError: true);
    }
  }

  Future<void> _shareDocument(DocumentFile doc) async {
    try {
      await VaultFileService.shareDocument(doc);
    } catch (e) {
      _showMessage('Failed to share file: $e', isError: true);
    }
  }

  void _previewDocument(DocumentFile doc) {
    final isPdf =
        doc.mimeType == 'application/pdf' || doc.filename.endsWith('.pdf');
    if (isPdf) {
      _launchURL(doc.path);
    } else {
      _showImagePreview(doc);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      _showMessage('Opening document...');
    } else {
      _showMessage('Could not open the document.', isError: true);
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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? brandRed : null,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          children: [
            icon is IconData
                ? Icon(icon as IconData, color: brandRed, size: 28)
                : Image.asset(icon as String, width: 28, height: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadedFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _UploadedFileRow({
    required this.fileName,
    required this.fileInfo,
    required this.fileType,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: fileType == 'pdf'
                      ? const Color(0xFFFFF0F2)
                      : const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: fileType == 'pdf'
                    ? Image.asset(
                        'assets/images/pdficon.png',
                        width: 22,
                        height: 22,
                      )
                    : const Icon(
                        Icons.image_rounded,
                        color: Color(0xFF2196F3),
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileInfo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onMenuTap,
                child: const Icon(
                  Icons.more_vert,
                  color: Color(0xFF888888),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: icon is IconData
          ? Icon(icon as IconData, color: const Color(0xFF111111))
          : Image.asset(icon as String, width: 22, height: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF111111),
        ),
      ),
    );
  }
}
