import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ────────────────────────────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: const Color(0xFF999999),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Name ──────────────────────────────────────────────────
              const Text(
                'Anick Giroux',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 4),

              // ── Email in red ──────────────────────────────────────────
              const Text(
                'anick.giroux@email.com',
                style: TextStyle(
                  fontSize: 13,
                  color: brandRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // ── General Settings Section ──────────────────────────────
              _SectionLabel(label: 'General Settings'),
              const SizedBox(height: 10),
              _MenuCard(
                children: [
                  _MenuItem(
                    iconPath: 'assets/images/icon/setting_icon.png',
                    title: 'Account Settings',
                    subtitle: 'Manage your personal information',
                    onTap: () => context.push('/edit-profile'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Security & Privacy Section ────────────────────────────
              _SectionLabel(label: 'Security & Privacy'),
              const SizedBox(height: 10),
              _MenuCard(
                children: [
                  _MenuItem(
                    iconPath: 'assets/images/icon/lock_icon.png',
                    title: 'Change Password',
                    subtitle: 'Keep your account secure',
                    onTap: () => context.push('/change-password'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _MenuCard(
                children: [
                  _MenuItem(
                    iconPath: 'assets/images/icon/security_icon.png',
                    title: 'Setup security',
                    subtitle: 'Control your data and visibility',
                    onTap: () => context.push('/data-security'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _MenuCard(
                children: [
                  _MenuItem(
                    iconPath: 'assets/images/icon/subs_icon.png',
                    title: 'Subscription Plan',
                    subtitle: 'Manage your plan, data & visibility',
                    onTap: () => context.push('/subscription-plan'),
                  ),
                ],
              ),
              const SizedBox(height: 70),
              // ── Logout Card ───────────────────────────────────────────
              _MenuCard(
                children: [
                  _LogoutItem(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Log Out',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          content: const Text(
                            'Are you sure you want to log out?',
                            style: TextStyle(color: Color(0xFF555555)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                context.go('/');
                              },
                              child: const Text(
                                'Log Out',
                                style: TextStyle(color: brandRed),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}

// ── White Card Container ──────────────────────────────────────────────────────
class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

// ── General Menu Item ─────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFCECEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset(iconPath, width: 22, height: 22),
              ),
            ),
            const SizedBox(width: 14),
            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
          ],
        ),
      ),
    );
  }
}

// ── Logout Item ───────────────────────────────────────────────────────────────
class _LogoutItem extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFCECEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/icon/logout_cion.png',
                  width: 22,
                  height: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              'Log Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: brandRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
