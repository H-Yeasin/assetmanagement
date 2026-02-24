import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';

class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  String _pin = '';
  static const int _pinLength = 4;

  void _onKeyTap(String val) {
    if (_pin.length < _pinLength) {
      setState(() => _pin += val);
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Title
            const Text(
              'Set Your PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "You'll use this PIN if biometric access\nisn't available.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF777777),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // PIN entry boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 54,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBEBEB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    filled ? _pin[i] : '-',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF777777),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Custom Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 16),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 16),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const _KeypadEmpty(),
                      _KeypadButton(label: '0', onTap: () => _onKeyTap('0')),
                      _KeypadDelete(onTap: _onDelete),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Continue Button (Pinned at bottom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_pin.length == _pinLength) {
                      context.pushReplacement('/pin-locked');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a 4-digit PIN'),
                          backgroundColor: brandRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> labels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels
          .map((l) => _KeypadButton(label: l, onTap: () => _onKeyTap(l)))
          .toList(),
    );
  }
}

// ── Light Gray Square Keypad Button ───────────────────────────────────────────
class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _KeypadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}

// ── Delete Button with backspace-like icon shape ──────────────────────────────
class _KeypadDelete extends StatelessWidget {
  final VoidCallback onTap;
  const _KeypadDelete({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 50,
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF111111),
              fontFamily: 'MaterialIcons',
            ),
            child: const Icon(Icons.backspace, size: 28, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

// ── Empty spacer for keypad ───────────────────────────────────────────────────
class _KeypadEmpty extends StatelessWidget {
  const _KeypadEmpty();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 80, height: 50);
  }
}
