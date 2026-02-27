import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController(text: 'Anick Giroux');
  final _emailController =
      TextEditingController(text: 'anick.giroux@email.com');
  // ← starts OFF; toggling ON navigates to two-factor email screen
  bool _twoFactor = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              size: 18, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ────────────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEEEEE),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                ),
                                child: ClipOval(
                                  child: Icon(Icons.person,
                                      size: 56,
                                      color: const Color(0xFF999999)),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: brandRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCECEE),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Change Photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: brandRed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Full Name ─────────────────────────────────────────
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(controller: _nameController),
                    const SizedBox(height: 20),

                    // ── Email ─────────────────────────────────────────────
                    const Text(
                      'Email Address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InputField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 28),

                    // ── Security & Privacy label ──────────────────────────
                    const Text(
                      'Security & Privacy',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Update Password
                    _SecurityCard(
                      iconPath:
                          'assets/images/icon/lock_icon.png',
                      title: 'Update Password',
                      subtitle: 'Last updated 3 months ago',
                      onTap: () => context.push('/change-password'),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFFBBBBBB)),
                    ),
                    const SizedBox(height: 10),

                    // Delete Account
                    _SecurityCard(
                      iconPath:
                          'assets/images/icon/delete_icon.png',
                      title: 'Delete Your Account',
                      subtitle:
                          'You can delete your all information',
                      onTap: () =>
                          context.push('/delete-account'),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFFBBBBBB)),
                    ),
                    const SizedBox(height: 10),

                    // FAQ
                    _SecurityCard(
                      iconPath: 'assets/images/icon/faq_icon.png',
                      title: 'FAQ',
                      subtitle: 'Your Questions Answered',
                      onTap: () => context.push('/faq'),
                      trailing: const Icon(Icons.chevron_right,
                          size: 20, color: Color(0xFFBBBBBB)),
                    ),
                    const SizedBox(height: 10),

                    // Two-Factor Authentication
                    _SecurityCard(
                      iconPath:
                          'assets/images/icon/tow_factor_icon.png',
                      title: 'Two-Factor Authentication',
                      subtitle: 'Recommended for extra safety',
                      onTap: () {
                        if (!_twoFactor) {
                          // Navigate to two-factor email screen when turning ON
                          GoRouter.of(context).push('/two-factor-email');
                        }
                      },
                      trailing: Switch(
                        value: _twoFactor,
                        onChanged: (val) {
                          setState(() => _twoFactor = val);
                          if (val) {
                            // Navigate to two-factor email screen when toggled ON
                            GoRouter.of(context).push('/two-factor-email');
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: brandRed,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor:
                            const Color(0xFFCCCCCC),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ── Save Changes button (pinned at bottom) ────────────────────
            Container(
              color: const Color(0xFFF8F6F6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile saved successfully!'),
                        backgroundColor: brandRed,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
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

// ── Text Input Field ──────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _InputField({required this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style:
          const TextStyle(fontSize: 15, color: Color(0xFF111111)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: brandRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
      ),
    );
  }
}

// ── Security Card Row ─────────────────────────────────────────────────────────
class _SecurityCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  const _SecurityCard({
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                child:
                    Image.asset(iconPath, width: 22, height: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
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
            trailing,
          ],
        ),
      ),
    );
  }
}