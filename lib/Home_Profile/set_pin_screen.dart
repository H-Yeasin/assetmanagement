import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/security_service.dart';

/// Two-step PIN setup screen:
/// Step 1 – Enter a 4-digit PIN
/// Step 2 – Confirm the PIN
/// On match: encrypts and stores PIN securely, then navigates to success.
class SetPinScreen extends StatefulWidget {
  const SetPinScreen({super.key});

  @override
  State<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends State<SetPinScreen> {
  static const int _pinLength = 4;

  // Step 1 values
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;
  bool _isMismatch = false;
  bool _isSaving = false;

  String get _currentPin => _isConfirmStep ? _confirmPin : _pin;

  void _onKeyTap(String val) {
    setState(() {
      _isMismatch = false;
      if (_isConfirmStep) {
        if (_confirmPin.length < _pinLength) _confirmPin += val;
      } else {
        if (_pin.length < _pinLength) _pin += val;
      }
    });
  }

  void _onDelete() {
    setState(() {
      _isMismatch = false;
      if (_isConfirmStep) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _onContinue() async {
    if (!_isConfirmStep) {
      // Step 1 → Step 2
      if (_pin.length < _pinLength) {
        _showSnack('Please enter a $_pinLength-digit PIN');
        return;
      }
      setState(() => _isConfirmStep = true);
    } else {
      // Step 2 → Verify match
      if (_confirmPin.length < _pinLength) {
        _showSnack('Please re-enter your PIN to confirm');
        return;
      }
      if (_pin != _confirmPin) {
        setState(() {
          _isMismatch = true;
          _confirmPin = '';
        });
        _showSnack('PINs do not match. Please try again.');
        return;
      }

      // Match! Save PIN
      setState(() => _isSaving = true);
      await SecurityService.setPin(_pin);
      if (!mounted) return;
      setState(() => _isSaving = false);
      context.pushReplacement('/pin-locked');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: brandRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // Back arrow (only on confirm step)
            if (_isConfirmStep)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF111111),
                      size: 22,
                    ),
                    onPressed: () => setState(() {
                      _isConfirmStep = false;
                      _confirmPin = '';
                      _isMismatch = false;
                    }),
                  ),
                ),
              ),

            // Title
            Text(
              _isConfirmStep ? 'Confirm PIN' : 'Set Your PIN',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _isConfirmStep
                    ? 'Enter your PIN again to confirm'
                    : 'This PIN will be required to access your Vault.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF777777),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // PIN entry circles (dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _currentPin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _isMismatch
                        ? Colors.red
                        : filled
                        ? brandRed
                        : const Color(0xFFDDDDDD),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            if (_isMismatch)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'PINs do not match',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
            const SizedBox(height: 28),

            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    disabledBackgroundColor: brandRed.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isConfirmStep ? 'Confirm PIN' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

// ── Light Gray Round Keypad Button ─────────────────────────────────────────────
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

// ── Delete Button ──────────────────────────────────────────────────────────────
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
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 26, color: Colors.black),
        ),
      ),
    );
  }
}

// ── Empty spacer ───────────────────────────────────────────────────────────────
class _KeypadEmpty extends StatelessWidget {
  const _KeypadEmpty();
  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 80, height: 50);
  }
}
