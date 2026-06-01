import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Home_Dashboard/widgets.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';
import '../services/security_service.dart';
import '../services/auth_service.dart';
import '../services/vault_session_manager.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  File? _imageFile;
  String? _existingAvatarUrl;
  bool _isLoading = false;
  // ← starts OFF; toggling ON navigates to two-factor email screen
  bool _twoFactor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await UserService.syncProfileWithFirestore();
    final name = await StorageService.getUserName() ?? '';
    final email = await StorageService.getUserEmail() ?? '';
    final avatar = await StorageService.getUserAvatar();
    final is2fa = await SecurityService.is2faEnabled();
    if (mounted) {
      setState(() {
        _nameController.text = name;
        _emailController.text = email;
        _existingAvatarUrl = (avatar != null && avatar.trim().isNotEmpty)
            ? avatar
            : null;
        _twoFactor = is2fa;
      });
    }
  }

  Future<void> _pickImage() async {
    VaultSessionManager.instance.expectExternalActivity();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, // Profile picture doesn't need to be wider than 512px
      maxHeight: 512,
      imageQuality: 80, // 80% JPEG quality — sharp enough, but tiny file size
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final res = await UserService.updateProfile(
        token: token,
        fullName: _nameController.text.trim(),
        imageFile: _imageFile,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // Update local storage name & avatar
        final userAvatar = res['data']?['avatarUrl'] as String?;
        final message =
            res['message'] as String? ?? 'Profile saved successfully!';
        final imageUploadFailed =
            (res['data']?['imageUploadFailed'] as bool?) ?? false;
        await StorageService.saveSession(
          accessToken: token,
          refreshToken: await StorageService.getRefreshToken() ?? '',
          userId: await StorageService.getUserId() ?? '',
          email: _emailController.text,
          name: _nameController.text.trim(),
          avatar: userAvatar,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: imageUploadFailed ? Colors.orange : brandRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disableTwoFactor() async {
    final passwordCtrl = TextEditingController();
    bool isDisabling = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Disable Two-Factor',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please enter your password to disable 2FA.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF555555)),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: const Color(0xFFF9F9F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3003F),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                if (!isDisabling)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                  ),
                ElevatedButton(
                  onPressed: isDisabling
                      ? null
                      : () async {
                          final pass = passwordCtrl.text.trim();
                          if (pass.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter your current password.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isDisabling = true);
                          final token = await StorageService.getAccessToken();
                          if (token == null) {
                            if (ctx.mounted) Navigator.pop(ctx, false);
                            return;
                          }

                          try {
                            final res = await AuthService.disableTwoFactor(
                              password: pass,
                              token: token,
                            );
                            if (res['success'] == true) {
                              if (ctx.mounted) Navigator.pop(ctx, true);
                            } else {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      res['message'] ?? 'Failed to disable 2FA',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setDialogState(() => isDisabling = false);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              setDialogState(() => isDisabling = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE3003F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isDisabling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Disable'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await SecurityService.set2faEnabled(false);
      if (mounted) {
        setState(() => _twoFactor = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled.'),
            backgroundColor: Color(0xFF333333),
          ),
        );
      }
    }
  }

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
          icon: const Icon(
            Icons.arrow_back,
            size: 18,
            color: Color(0xFF111111),
          ),
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
                  horizontal: 20,
                  vertical: 24,
                ),
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
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: ClipOval(
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : (_existingAvatarUrl != null
                                            ? Image.network(
                                                _existingAvatarUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 56,
                                                      color: Color(0xFF999999),
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person,
                                                size: 56,
                                                color: Color(0xFF999999),
                                              )),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: brandRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
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
                    TextField(
                      controller: _emailController,
                      readOnly: true, // Make email non-editable
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF888888),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF0F0F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
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
                      iconPath: 'assets/images/icon/lock_icon.png',
                      title: 'Update Password',
                      subtitle: 'Last updated 3 months ago',
                      onTap: () => context.push('/change-password'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Delete Account
                    _SecurityCard(
                      iconPath: 'assets/images/icon/delete_icon.png',
                      title: 'Delete Your Account',
                      subtitle: 'You can delete your all information',
                      onTap: () => context.push('/delete-account'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // FAQ
                    _SecurityCard(
                      iconPath: 'assets/images/icon/faq_icon.png',
                      title: 'FAQ',
                      subtitle: 'Your Questions Answered',
                      onTap: () => context.push('/faq'),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: Color(0xFFBBBBBB),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Two-Factor Authentication
                    _SecurityCard(
                      iconPath: 'assets/images/icon/tow_factor_icon.png',
                      title: 'Two-Factor Authentication',
                      subtitle: 'Recommended for extra safety',
                      onTap: () async {
                        if (!_twoFactor) {
                          // Navigate to two-factor email screen when turning ON
                          await GoRouter.of(context).push('/two-factor-email');
                          _loadData();
                        } else {
                          // Disable 2FA
                          await _disableTwoFactor();
                        }
                      },
                      trailing: Switch(
                        value: _twoFactor,
                        onChanged: (val) async {
                          if (val) {
                            // Navigate to two-factor email screen when toggled ON
                            await GoRouter.of(
                              context,
                            ).push('/two-factor-email');
                            _loadData();
                          } else {
                            // Prompt to disable 2FA
                            await _disableTwoFactor();
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: brandRed,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCCCCCC),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
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

// ── Text Input Field ──────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;

  const _InputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Image.asset(iconPath, width: 22, height: 22),
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
