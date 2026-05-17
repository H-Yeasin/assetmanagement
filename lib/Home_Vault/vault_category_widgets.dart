import 'package:flutter/material.dart';

import '../Home_Dashboard/widgets.dart';

// ── Subfolder Row ────────────────────────────────────────────────────────────
class VaultSubfolderRow extends StatelessWidget {
  final String name;
  final String itemCount;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const VaultSubfolderRow({
    super.key,
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

// ── Recent File Row ──────────────────────────────────────────────────────────
class VaultRecentFileRow extends StatelessWidget {
  final String fileName;
  final String fileInfo;
  final String fileType;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const VaultRecentFileRow({
    super.key,
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

// ── Menu Option ──────────────────────────────────────────────────────────────
class VaultMenuOption extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const VaultMenuOption({
    super.key,
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

// ── Action Card ──────────────────────────────────────────────────────────────
class VaultActionCard extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const VaultActionCard({
    super.key,
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
