import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/storage_service.dart';
import '../services/user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    final currentPass = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirmPass = _confirmController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }
    if (newPass != confirmPass) {
      _showSnackBar('New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await StorageService.getAccessToken();
      if (token == null) {
        _showSnackBar('Session expired. Please log in again.');
        return;
      }

      final result = await UserService.changePassword(
        token: token,
        currentPassword: currentPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnackBar('Password changed successfully!', isSuccess: true);
        Navigator.pop(context);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : brandRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          'Change password',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Current password'),
              _PasswordInputField(controller: _currentController),
              const SizedBox(height: 24),

              _buildLabel('New password'),
              _PasswordInputField(controller: _newController),
              const SizedBox(height: 24),

              _buildLabel('Confirm password'),
              _PasswordInputField(controller: _confirmController),
              const SizedBox(height: 12),

              // Forgot your password?
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    context.push('/forgot-password');
                  },
                  child: const Text(
                    'Forgot your password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: brandRed,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF666666),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PasswordInputField extends StatelessWidget {
  final TextEditingController controller;

  const _PasswordInputField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          hintText: '••••••',
          hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
        ),
      ),
    );
  }
}
