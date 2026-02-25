import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';

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
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF111111)),
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
                    onTap: () => context.push('/vault-edit-folder', extra: folderName),
                    child: Image.asset('assets/images/create.png', width: 22, height: 22),
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

                    // Dummy uploaded files
                    _UploadedFileRow(
                      fileName: 'Property_Deed.pdf',
                      fileInfo: '2.4 MB',
                      fileType: 'pdf',
                      onMenuTap: () => _showFileMenu(context, 'Property_Deed.pdf'),
                    ),
                    _UploadedFileRow(
                      fileName: 'ID_Front.jpg',
                      fileInfo: 'Jan 08 2024 • 2.4 MB',
                      fileType: 'image',
                      onMenuTap: () => _showFileMenu(context, 'ID_Front.jpg'),
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
  final VoidCallback onMenuTap;

  const _UploadedFileRow({
    required this.fileName,
    required this.fileInfo,
    required this.fileType,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
                  ? Image.asset('assets/images/pdficon.png', width: 22, height: 22)
                  : const Icon(Icons.image_rounded, color: Color(0xFF2196F3), size: 22),
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
              child: const Icon(Icons.more_vert, color: Color(0xFF888888), size: 22),
            ),
          ],
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
                : Image.asset(icon as String, width: 22, height: 22, color: color == brandRed ? brandRed : null),
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
