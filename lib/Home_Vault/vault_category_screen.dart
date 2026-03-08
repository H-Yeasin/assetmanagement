import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import '../Loan_Screen/models/document_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class VaultCategoryScreen extends StatelessWidget {
  final String categoryName;

  const VaultCategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
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
                        categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  // ── FAB "+" ──
                  GestureDetector(
                    onTap: () {
                      // Placeholder — open file picker later
                    },
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

                    // ── Create Subfolder Button ──
                    GestureDetector(
                      onTap: () => context.push(
                        '/vault-create-subfolder',
                        extra: categoryName,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: brandRed.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/createsubfolder.png',
                              width: 24,
                              height: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Create Subfolder',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: brandRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Sub Folders Section ──
                    const Text(
                      'Sub Folders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dummy subfolders
                    _SubfolderRow(
                      name: 'Notary',
                      itemCount: '4 items',
                      onTap: () =>
                          context.push('/vault-subfolder', extra: 'Notary'),
                      onMenuTap: () => _showFolderMenu(context, 'Notary'),
                    ),
                    _SubfolderRow(
                      name: 'Bank',
                      itemCount: '10 items',
                      onTap: () =>
                          context.push('/vault-subfolder', extra: 'Bank'),
                      onMenuTap: () => _showFolderMenu(context, 'Bank'),
                    ),
                    _SubfolderRow(
                      name: 'Taxes',
                      itemCount: '8 items',
                      onTap: () =>
                          context.push('/vault-subfolder', extra: 'Taxes'),
                      onMenuTap: () => _showFolderMenu(context, 'Taxes'),
                    ),

                    const SizedBox(height: 32),

                    // ── Recent Files Section ──
                    const Text(
                      'Recent Files',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 16),

                    FutureBuilder<List<DocumentFile>>(
                      future: _fetchCategoryDocuments(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: brandRed));
                        }
                        final docs = snapshot.data ?? [];
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No documents found in this category.',
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
                            final isPdf = doc.mimeType == 'application/pdf' || doc.filename.endsWith('.pdf');
                            return _RecentFileRow(
                              fileName: doc.displayName,
                              fileInfo: '${doc.size != null ? (doc.size! / 1024).toStringAsFixed(1) : "0"} KB',
                              fileType: isPdf ? 'pdf' : 'image',
                              onTap: () => _previewDocument(context, doc),
                              onMenuTap: () => _showFileMenu(context, doc.displayName),
                            );
                          },
                        );
                      }
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

  void _showFolderMenu(BuildContext context, String folderName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              onTap: () => Navigator.pop(context),
            ),
            _MenuOption(
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              color: brandRed,
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  void _showFileMenu(BuildContext context, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
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
              icon: 'assets/images/black_delete.png',
              label: 'Delete',
              onTap: () => Navigator.pop(context),
            ),
            _MenuOption(
              icon: 'assets/images/black_download.png',
              label: 'Download',
              onTap: () => Navigator.pop(context),
            ),
            _MenuOption(
              icon: 'assets/images/black_share.png',
              label: 'Share/Send',
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
  Future<List<DocumentFile>> _fetchCategoryDocuments() async {
    String module = 'loans';
    if (categoryName.contains('Housing')) module = 'housing';
    if (categoryName.contains('Insurance')) module = 'insurance';
    if (categoryName.contains('Documents')) module = 'loans'; // default or shared

    return LoanService().fetchDocumentsByModule(module);
  }

  void _previewDocument(BuildContext context, DocumentFile doc) {
    final isPdf = doc.mimeType == 'application/pdf' || doc.filename.endsWith('.pdf');
    if (isPdf) {
      _launchURL(doc.path);
    } else {
      _showImagePreview(context, doc);
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  void _showImagePreview(BuildContext context, DocumentFile doc) {
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
                ),
              ),
            ),
            PositionBag(
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
}

class PositionBag extends StatelessWidget {
  final double? top;
  final double? right;
  final Widget child;
  const PositionBag({super.key, this.top, this.right, required this.child});
  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, right: right, child: child);
  }
}

// ── Subfolder Row ────────────────────────────────────────────────────────────
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
              // Folder icon
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

// ── Recent File Row ──────────────────────────────────────────────────────────
class _RecentFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType; // 'pdf', 'image', etc.
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
              // File type icon
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ── Menu Option ──────────────────────────────────────────────────────────────
class _MenuOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF111111);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            icon is IconData
                ? Icon(icon as IconData, color: c, size: 22)
                : Image.asset(
                    icon as String,
                    width: 22,
                    height: 22,
                    color: color == brandRed ? brandRed : null,
                  ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
