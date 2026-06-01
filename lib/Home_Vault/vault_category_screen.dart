import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/models/document_model.dart';
import 'vault_category_actions.dart';
import 'vault_category_dialogs.dart';
import 'vault_category_widgets.dart';

class VaultCategoryScreen extends StatefulWidget {
  final String categoryName;

  const VaultCategoryScreen({super.key, required this.categoryName});

  @override
  State<VaultCategoryScreen> createState() => _VaultCategoryScreenState();
}

class _VaultCategoryScreenState extends State<VaultCategoryScreen>
    with
        VaultCategoryDialogsMixin<VaultCategoryScreen>,
        VaultCategoryActionsMixin<VaultCategoryScreen> {
  late Future<List<DocumentFile>> _documentsFuture;
  bool _isUploading = false;

  // ── Mixin contract implementations ─────────────────────────────────────
  @override
  String get categoryName => widget.categoryName;

  @override
  bool get isUploading => _isUploading;

  @override
  set isUploading(bool value) => _isUploading = value;

  @override
  String get currentModule => resolveModule(widget.categoryName);

  @override
  void showUploadOptions() => showUploadOptionsSheet();

  @override
  Future<void> reloadDocuments() async {
    setState(() {
      _documentsFuture = fetchCategoryDocuments();
    });
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _documentsFuture = fetchCategoryDocuments();
  }

  // ── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildActionCards(),
                    const SizedBox(height: 28),
                    if (_isUploading) _buildUploadingIndicator(),
                    _buildDocumentList(),
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

  // ── Header row ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
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
            onTap: showCategoryActions,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: brandRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload / Create Folder cards ──────────────────────────────────────
  Widget _buildActionCards() {
    return Row(
      children: [
        Expanded(
          child: VaultActionCard(
            icon: 'assets/images/upload.png',
            label: 'Upload File',
            onTap: _isUploading ? () {} : showUploadOptions,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: VaultActionCard(
            icon: 'assets/images/createsubfolder.png',
            label: 'Create Folder',
            onTap: () async {
              await context.push(
                '/vault-create-subfolder',
                extra: widget.categoryName,
              );
              if (mounted) await reloadDocuments();
            },
          ),
        ),
      ],
    );
  }

  // ── Upload spinner ────────────────────────────────────────────────────
  Widget _buildUploadingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: brandRed),
            SizedBox(height: 12),
            Text('Uploading...', style: TextStyle(color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }

  // ── Documents FutureBuilder ───────────────────────────────────────────
  Widget _buildDocumentList() {
    return FutureBuilder<List<DocumentFile>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
            .where((d) => d.mimeType == 'application/vnd.anick-giroux.folder')
            .toList();
        final recentFiles = allDocs
            .where(
              (d) =>
                  d.mimeType != 'application/vnd.anick-giroux.folder' &&
                  (d.folderId == null || d.folderId!.isEmpty),
            )
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSubFoldersSection(folders, allDocs),
            const SizedBox(height: 32),
            _buildRecentFilesSection(recentFiles),
          ],
        );
      },
    );
  }

  // ── Sub Folders section ───────────────────────────────────────────────
  Widget _buildSubFoldersSection(
    List<DocumentFile> folders,
    List<DocumentFile> allDocs,
  ) {
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
              return VaultSubfolderRow(
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
                    await reloadDocuments();
                  }
                },
                onMenuTap: () => showFolderMenu(folder, allDocs),
              );
            },
          ),
      ],
    );
  }

  // ── Recent Files section ──────────────────────────────────────────────
  Widget _buildRecentFilesSection(List<DocumentFile> recentFiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              return VaultRecentFileRow(
                fileName: doc.displayName,
                fileInfo: '${(doc.size / 1024).toStringAsFixed(1)} KB',
                fileType: isPdf ? 'pdf' : 'image',
                onTap: () => previewDocument(doc),
                onMenuTap: () => showFileMenu(doc),
              );
            },
          ),
      ],
    );
  }
}
