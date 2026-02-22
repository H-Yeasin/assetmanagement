import 'package:flutter/material.dart';
import 'shared_widgets.dart';
import 'forgot_password.dart';

class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onKeyTap(String value) {
    for (int i = 0; i < 6; i++) {
      if (_controllers[i].text.isEmpty) {
        setState(() {
          _controllers[i].text = value;
        });
        if (i < 5) {
          FocusScope.of(context).requestFocus(_focusNodes[i + 1]);
        }
        break;
      }
    }
  }

  void _onBackspace() {
    for (int i = 5; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        setState(() {
          _controllers[i].text = '';
        });
        if (i > 0) {
          FocusScope.of(context).requestFocus(_focusNodes[i - 1]);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const AppLogo(),
                  const SizedBox(height: 28),
                  const Text(
                    'Enter Verification Code',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "We've sent a 6-digit code to your email.",
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 48),
                  
                  // OTP Boxes (6 digits)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) {
                      return Container(
                        width: 48,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _controllers[index].text.isNotEmpty
                                ? brandRed
                                : const Color(0xFFC61C36),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _controllers[index].text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111111),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 32),
                  const Text(
                    'Resend code in 45s',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 40),
                  AppPrimaryButton(
                    label: 'Verify',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPassword()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Custom Keypad (Red background style)
          Container(
            padding: EdgeInsets.fromLTRB(
              20, 
              24, 
              20, 
              MediaQuery.of(context).padding.bottom + 20
            ),
            decoration: const BoxDecoration(
              color: brandRed,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                _buildKeyRow(['1', '2', '3']),
                const SizedBox(height: 12),
                _buildKeyRow(['4', '5', '6']),
                const SizedBox(height: 12),
                _buildKeyRow(['7', '8', '9']),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKey('0'), // Centered 0
                    _buildBackspaceKey(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTap: () => _onKeyTap(value),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: GestureDetector(
          onTap: _onBackspace,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.close_rounded, color: Colors.red, size: 24),
          ),
        ),
      ),
    );
  }
}
