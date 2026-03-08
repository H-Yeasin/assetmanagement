import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import '../Loan_Screen/models/document_model.dart';
import 'package:url_launcher/url_launcher.dart';

class VaultSubfolderScreen extends StatelessWidget {
  final String folderName;

  const VaultSubfolderScreen({super.key, required this.folderName});

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
                        folderName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        context.push('/vault-edit-folder', extra: folderName),
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

                    // ── Add New Files Section ──
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
                            onTap: () {
                              // Placeholder — file picker later
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.camera_alt_outlined,
                            label: 'Take photo',
                            onTap: () {
                              // Placeholder — camera later
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Uploaded Documents Section ──
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
                      future: _fetchFolderDocuments(),
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
                            final isPdf = doc.mimeType == 'application/pdf' || doc.displayName.endsWith('.pdf');
                            return _UploadedFileRow(
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
              onTap: () => context.pop(),
            ),
            _MenuOption(
              icon: 'assets/images/black_download.png',
              label: 'Download',
              onTap: () => context.pop(),
            ),
            _MenuOption(
              icon: 'assets/images/black_share.png',
              label: 'Share/Send',
              onTap: () => context.pop(),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
  Future<List<DocumentFile>> _fetchFolderDocuments() async {
    // For now, mapping folders to modules or just showing all 'loans' for demo
    // In a full implementation, we'd filter by folderId
    return LoanService().fetchDocumentsByModule('loans');
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
}

// ── Action Card (Upload / Take Photo) ────────────────────────────────────────
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

// ── Uploaded File Row ────────────────────────────────────────────────────────
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

// ── Menu Option (reusable) ───────────────────────────────────────────────────
class _MenuOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
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
