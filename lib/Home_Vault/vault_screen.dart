import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/security_service.dart';
import '../services/biometric_service.dart';
import '../services/loan_service.dart';

class VaultScreen extends StatefulWidget {
  final String? initialCategory;
  const VaultScreen({super.key, this.initialCategory});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  bool _unlocked = false;
  bool _isChecking = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSecurity());
  }

  Future<void> _checkSecurity() async {
    final biometricEnabled = await SecurityService.isBiometricEnabled();
    final pinEnabled = await SecurityService.isPinSet();

    if (!mounted) return;

    if (!biometricEnabled && !pinEnabled) {
      // No security set – open vault directly
      setState(() {
        _unlocked = true;
        _isChecking = false;
      });
      if (widget.initialCategory != null) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            context.push('/vault-category', extra: widget.initialCategory);
          }
        });
      }
      return;
    }

    if (biometricEnabled) {
      // Try biometric first
      final reason = await BiometricService.unavailableReason();
      if (reason == null) {
        final success = await BiometricService.authenticate(
          reason: 'Authenticate to open your FFP Vault',
        );
        if (!mounted) return;
        if (success) {
          setState(() {
            _unlocked = true;
            _isChecking = false;
          });
          if (widget.initialCategory != null) {
            Future.delayed(Duration.zero, () {
              if (mounted) {
                context.push('/vault-category', extra: widget.initialCategory);
              }
            });
          }
          return;
        }
        // Biometric failed/cancelled – fall through to PIN if set
      }
    }

    if (pinEnabled) {
      // Show PIN screen
      if (!mounted) return;
      setState(() => _isChecking = false);
      final result = await context.push<bool>('/pin-verify');
      if (mounted) {
        if (result == true) {
          setState(() => _unlocked = true);
          if (widget.initialCategory != null) {
            Future.delayed(Duration.zero, () {
              if (mounted) {
                context.push('/vault-category', extra: widget.initialCategory);
              }
            });
          }
        } else {
          // Navigated back without unlocking
          context.go('/home');
        }
      }
      return;
    }

    // No fallback available (biometric failed and no PIN) – back out
    if (!mounted) return;
    setState(() => _isChecking = false);
    if (mounted) context.go('/home');
  }

  Future<Map<String, String>> _fetchVaultStats() async {
    try {
      final results = await Future.wait([
        LoanService().fetchDocumentsByModule('loans'),
        LoanService().fetchDocumentsByModule('housing'),
        LoanService().fetchDocumentsByModule('insurance'),
        LoanService().fetchDocumentsByModule('documents'),
      ]);

      return {
        'loans': results[0].length.toString(),
        'housing': results[1].length.toString(),
        'insurance': results[2].length.toString(),
        'documents': results[3].length.toString(),
      };
    } catch (e) {
      return {'loans': '0', 'housing': '0', 'insurance': '0', 'documents': '0'};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: brandRed)),
      );
    }

    if (!_unlocked) {
      // Will be redirected to pin-verify – show blank
      return const Scaffold(backgroundColor: Colors.white);
    }

    return _buildVaultContent(context);
  }

  Widget _buildVaultContent(BuildContext context) {
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
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Color(0xFFBBBBBB),
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Search documents',
                            style: TextStyle(
                              color: Color(0xFFBBBBBB),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Category Grid (2x2) ──
                    FutureBuilder<Map<String, String>>(
                      future: _fetchVaultStats(),
                      builder: (context, snapshot) {
                        final stats =
                            snapshot.data ??
                            {
                              'loans': '...',
                              'housing': '...',
                              'insurance': '...',
                              'documents': '...',
                            };
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.3,
                          children: [
                            _VaultCategoryCard(
                              iconPath: 'assets/images/icon/loan.png',
                              title: 'Loans',
                              subtitle: '${stats['loans']} records',
                              iconColor: brandRed,
                              onTap: () => context.push(
                                '/vault-category',
                                extra: 'Loans',
                              ),
                            ),
                            _VaultCategoryCard(
                              iconPath: 'assets/images/icon/housing.png',
                              title: 'Housing / Living Costs',
                              subtitle: '${stats['housing']} records',
                              iconColor: const Color(0xFF9C27B0),
                              onTap: () => context.push(
                                '/vault-category',
                                extra: 'Housing / Living Costs',
                              ),
                            ),
                            _VaultCategoryCard(
                              iconPath: 'assets/images/icon/insurance.png',
                              title: 'Insurance',
                              subtitle: '${stats['insurance']} records',
                              iconColor: const Color(0xFF2196F3),
                              onTap: () => context.push(
                                '/vault-category',
                                extra: 'Insurance',
                              ),
                            ),
                            _VaultCategoryCard(
                              iconPath: 'assets/images/icon/doccument.png',
                              title: 'Documents',
                              subtitle: '${stats['documents']} saved',
                              iconColor: const Color(0xFFFF9800),
                              onTap: () => context.push(
                                '/vault-category',
                                extra: 'Documents',
                              ),
                            ),
                          ],
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

            // ── "Save Documents" Button ──
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
                  onPressed: _isSaving
                      ? null
                      : () async {
                          setState(() => _isSaving = true);
                          try {
                            final stats = await _fetchVaultStats();
                            int totalDocs = 0;
                            for (var val in stats.values) {
                              totalDocs += int.tryParse(val) ?? 0;
                            }

                            if (!mounted) return;

                            if (totalDocs > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Documents are saved successfully',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(
                                    0xFF4CAF50,
                                  ), // Green
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).size.height -
                                        220,
                                    left: 20,
                                    right: 20,
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'No documents found to save.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color(
                                    0xFFFFA000,
                                  ), // Amber
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.only(
                                    bottom:
                                        MediaQuery.of(context).size.height -
                                        220,
                                    left: 20,
                                    right: 20,
                                  ),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Documents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
