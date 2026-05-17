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

class VaultCategoryScreen extends StatefulWidget {
  final String categoryName;

  const VaultCategoryScreen({super.key, required this.categoryName});

  @override
  State<VaultCategoryScreen> createState() => _VaultCategoryScreenState();
}

class _VaultCategoryScreenState extends State<VaultCategoryScreen> {
  late Future<List<DocumentFile>> _documentsFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _fetchCategoryDocuments();
  }

  Future<void> _reloadDocuments() async {
    setState(() {
      _documentsFuture = _fetchCategoryDocuments();
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
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCategoryActions,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
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
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: 'assets/images/upload.png',
                            label: 'Upload File',
                            onTap: _isUploading ? () {} : _showUploadOptions,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            icon: 'assets/images/createsubfolder.png',
                            label: 'Create Folder',
                            onTap: () async {
                              await context.push(
                                '/vault-create-subfolder',
                                extra: widget.categoryName,
                              );
                              if (mounted) await _reloadDocuments();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
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
                              'Failed to load files: ${snapshot.error}',
                              style: const TextStyle(color: brandRed),
                            ),
                          );
                        }

                        final allDocs = snapshot.data ?? [];
                        final folders = allDocs
                            .where(
                              (d) =>
                                  d.mimeType ==
                                  'application/vnd.anick-giroux.folder',
                            )
                            .toList();
                        final recentFiles = allDocs
                            .where(
                              (d) =>
                                  d.mimeType !=
                                      'application/vnd.anick-giroux.folder' &&
                                  (d.folderId == null || d.folderId!.isEmpty),
                            )
                            .toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sub Folders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (folders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Text(
                                  'No subfolders created yet.',
                                  style: TextStyle(color: Color(0xFF888888)),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: folders.length,
                                itemBuilder: (context, index) {
                                  final folder = folders[index];
                                  final itemCount = allDocs
                                      .where((d) => d.folderId == folder.id)
                                      .length;
                                  return _SubfolderRow(
                                    name: folder.displayName,
                                    itemCount: '$itemCount items',
                                    onTap: () async {
                                      await context.push(
                                        '/vault-subfolder',
                                        extra: {
                                          'folderName': folder.displayName,
                                          'folderId': folder.id,
                                          'categoryName': widget.categoryName,
                                        },
                                      );
                                      if (mounted) {
                                        await _reloadDocuments();
                                      }
                                    },
                                    onMenuTap: () =>
                                        _showFolderMenu(folder, allDocs),
                                  );
                                },
                              ),
                            const SizedBox(height: 32),
                            const Text(
                              'Recent Files',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (recentFiles.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'No files found in this category.',
                                    style: TextStyle(color: Color(0xFF888888)),
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentFiles.length,
                                itemBuilder: (context, index) {
                                  final doc = recentFiles[index];
                                  final isPdf =
                                      doc.mimeType == 'application/pdf' ||
                                      doc.filename.endsWith('.pdf');
                                  return _RecentFileRow(
                                    fileName: doc.displayName,
                                    fileInfo:
                                        '${(doc.size / 1024).toStringAsFixed(1)} KB',
                                    fileType: isPdf ? 'pdf' : 'image',
                                    onTap: () => _previewDocument(doc),
                                    onMenuTap: () => _showFileMenu(doc),
                                  );
                                },
                              ),
                          ],
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

  void _showFolderMenu(DocumentFile folder, List<DocumentFile> allDocs) {
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
                final result = await context.push<String>(
                  '/vault-edit-folder',
                  extra: {
                    'folderName': folder.displayName,
                    'folderId': folder.id,
                    'categoryName': widget.categoryName,
                  },
                );
                if (result != null && mounted) {
                  await _reloadDocuments();
                  _showMessage('Folder renamed successfully.');
                }
              },
            ),
            _MenuOption(
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              color: brandRed,
              onTap: () async {
                Navigator.pop(sheetContext);
                await _deleteFolder(folder, allDocs);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
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

  Future<void> _deleteFolder(
    DocumentFile folder,
    List<DocumentFile> allDocs,
  ) async {
    final confirm = await _confirm(
      title: 'Delete Folder',
      message:
          'This will delete the folder and all files inside it. This action cannot be undone.',
    );
    if (confirm != true) return;

    final service = LoanService();
    final children = allDocs.where((doc) => doc.folderId == folder.id).toList();

    try {
      for (final child in children) {
        await service.deleteDocument(child.id);
      }
      await service.deleteDocument(folder.id);
      await _reloadDocuments();
      _showMessage('Folder deleted successfully.');
    } catch (e) {
      _showMessage('Failed to delete folder: $e', isError: true);
    }
  }

  Future<void> _deleteFile(DocumentFile doc) async {
    final confirm = await _confirm(
      title: 'Delete File',
      message: 'Are you sure you want to delete this file?',
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
      _showMessage('Downloaded successfully.');
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<List<DocumentFile>> _fetchCategoryDocuments() async {
    return LoanService().fetchDocumentsByModule(_currentModule);
  }

  String get _currentModule {
    String module = 'loans';
    if (widget.categoryName.contains('Housing')) module = 'housing';
    if (widget.categoryName.contains('Insurance')) module = 'insurance';
    if (widget.categoryName.contains('Document')) module = 'documents';
    return module;
  }

  Future<void> _previewDocument(DocumentFile doc) async {
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
      _showMessage('Could not open the document: $e', isError: true);
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

  void _showCategoryActions() {
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
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  _showUploadOptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('Create Folder'),
                onTap: () async {
                  Navigator.pop(context);
                  await context.push(
                    '/vault-create-subfolder',
                    extra: widget.categoryName,
                  );
                  if (mounted) await _reloadDocuments();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadOptions() {
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
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFile();
                },
              ),
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

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() => _isUploading = true);
      final file = File(result.files.single.path!);

      await LoanService().uploadDocument(file, module: _currentModule);

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      final file = File(pickedFile.path);

      await LoanService().uploadDocument(file, module: _currentModule);

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

class _SubfolderRow extends StatelessWidget {
  final String name;
  final String itemCount;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _SubfolderRow({
    required this.name,
    required this.itemCount,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: brandRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.folder_rounded, color: brandRed, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemCount,
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

class _RecentFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _RecentFileRow({
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
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
  final Color color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF111111),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: icon is IconData
          ? Icon(icon as IconData, color: color)
          : Image.asset(icon as String, width: 22, height: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color,
        ),
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
                ? Icon(
                    icon as IconData,
                    color: const Color(0xFFE5002C),
                    size: 28,
                  )
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
