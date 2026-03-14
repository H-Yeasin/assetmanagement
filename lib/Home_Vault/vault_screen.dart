import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';

class VaultScreen extends StatefulWidget {
  final String? initialCategory;
  const VaultScreen({super.key, this.initialCategory});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<Map<String, _VaultModuleStats>> _statsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchVaultStats();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push('/vault-category', extra: widget.initialCategory);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<Map<String, _VaultModuleStats>> _fetchVaultStats() async {
    try {
      final results = await Future.wait([
        LoanService().fetchDocumentsByModule('loans'),
        LoanService().fetchDocumentsByModule('housing'),
        LoanService().fetchDocumentsByModule('insurance'),
        LoanService().fetchDocumentsByModule('documents'),
      ]);

      return {
        'loans': _VaultModuleStats.fromDocuments(results[0]),
        'housing': _VaultModuleStats.fromDocuments(results[1]),
        'insurance': _VaultModuleStats.fromDocuments(results[2]),
        'documents': _VaultModuleStats.fromDocuments(results[3]),
      };
    } catch (e) {
      return {
        'loans': const _VaultModuleStats.empty(),
        'housing': const _VaultModuleStats.empty(),
        'insurance': const _VaultModuleStats.empty(),
        'documents': const _VaultModuleStats.empty(),
      };
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = _fetchVaultStats();
    });
  }

  Future<void> _openCategory(String title) async {
    await context.push('/vault-category', extra: title);
    if (mounted) {
      await _refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildVaultContent(context);
  }

  Widget _buildVaultContent(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
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
                    onTap: () => context.go('/home'),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'FFP Vault',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20), // balance the back arrow
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search Bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFFBBBBBB),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                setState(() => _searchQuery = value.trim());
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search vault categories',
                                hintStyle: TextStyle(
                                  color: Color(0xFFBBBBBB),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: const Icon(
                                Icons.close,
                                color: Color(0xFFBBBBBB),
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Category Grid (2x2) ──
                    FutureBuilder<Map<String, _VaultModuleStats>>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        final stats =
                            snapshot.data ??
                            {
                              'loans': const _VaultModuleStats.empty(),
                              'housing': const _VaultModuleStats.empty(),
                              'insurance': const _VaultModuleStats.empty(),
                              'documents': const _VaultModuleStats.empty(),
                            };
                        final categories = [
                          _VaultCategoryConfig(
                            iconPath: 'assets/images/icon/loan.png',
                            title: 'Loans',
                            subtitle: stats['loans']!.label,
                            iconColor: brandRed,
                          ),
                          _VaultCategoryConfig(
                            iconPath: 'assets/images/icon/housing.png',
                            title: 'Housing / Living Costs',
                            subtitle: stats['housing']!.label,
                            iconColor: const Color(0xFF9C27B0),
                          ),
                          _VaultCategoryConfig(
                            iconPath: 'assets/images/icon/insurance.png',
                            title: 'Insurance',
                            subtitle: stats['insurance']!.label,
                            iconColor: const Color(0xFF2196F3),
                          ),
                          _VaultCategoryConfig(
                            iconPath: 'assets/images/icon/doccument.png',
                            title: 'Documents',
                            subtitle: stats['documents']!.label,
                            iconColor: const Color(0xFFFF9800),
                          ),
                        ];
                        final filteredCategories = categories
                            .where(
                              (category) =>
                                  _searchQuery.isEmpty ||
                                  category.title.toLowerCase().contains(
                                    _searchQuery.toLowerCase(),
                                  ),
                            )
                            .toList();

                        if (filteredCategories.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No vault categories matched your search.',
                              style: TextStyle(color: Color(0xFF888888)),
                            ),
                          );
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.3,
                          children: filteredCategories
                              .map(
                                (category) => _VaultCategoryCard(
                                  iconPath: category.iconPath,
                                  title: category.title,
                                  subtitle: category.subtitle,
                                  iconColor: category.iconColor,
                                  onTap: () => _openCategory(category.title),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // ── "Your Vault is Protected" Section ──
                    CustomPaint(
                      painter: _DashedBorderPainter(
                        color: brandRed.withValues(alpha: 0.35),
                        borderRadius: 16,
                        dashWidth: 8,
                        dashSpace: 5,
                        strokeWidth: 1.5,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/protected.png',
                              width: 52,
                              height: 52,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your Vault is Protected',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Primary Action ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _openCategory('Documents'),
                  child: const Text(
                    'Browse Documents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

class _VaultCategoryConfig {
  final String iconPath;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _VaultCategoryConfig({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.iconColor,
  });
}

class _VaultModuleStats {
  final int fileCount;
  final int folderCount;

  const _VaultModuleStats({required this.fileCount, required this.folderCount});

  const _VaultModuleStats.empty() : fileCount = 0, folderCount = 0;

  factory _VaultModuleStats.fromDocuments(List<dynamic> documents) {
    int files = 0;
    int folders = 0;
    for (final document in documents) {
      final mimeType = document.mimeType?.toString() ?? '';
      if (mimeType == 'application/vnd.anick-giroux.folder') {
        folders++;
      } else {
        files++;
      }
    }
    return _VaultModuleStats(fileCount: files, folderCount: folders);
  }

  String get label {
    final fileLabel = '$fileCount ${fileCount == 1 ? 'file' : 'files'}';
    final folderLabel =
        '$folderCount ${folderCount == 1 ? 'folder' : 'folders'}';
    return '$fileLabel • $folderLabel';
  }
}

// ── Vault Category Card ─────────────────────────────────────────────────────
class _VaultCategoryCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _VaultCategoryCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(iconPath, width: 22, height: 22),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ────────────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = Path();

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (draw) {
          dashPath.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
