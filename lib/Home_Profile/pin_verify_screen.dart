import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/security_service.dart';

/// PIN entry screen that guards access to the Vault.
/// Shows up when PIN is set and the user tries to open the Vault.
/// After 3 wrong attempts, locks out for 30 seconds.
class PinVerifyScreen extends StatefulWidget {
  final bool fromVault;
  const PinVerifyScreen({super.key, this.fromVault = true});

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  static const int _pinLength = 4;
  static const int _maxAttempts = 3;
  static const int _lockoutSeconds = 30;

  String _pin = '';
  int _attempts = 0;
  bool _isLocked = false;
  int _lockoutRemaining = 0;
  bool _isError = false;

  void _startLockout() {
    setState(() {
      _isLocked = true;
      _lockoutRemaining = _lockoutSeconds;
      _pin = '';
    });
    _tickLockout();
  }

  void _tickLockout() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _lockoutRemaining--);
      if (_lockoutRemaining > 0) {
        _tickLockout();
      } else {
        setState(() {
          _isLocked = false;
          _attempts = 0;
          _isError = false;
        });
      }
    });
  }

  void _onKeyTap(String val) {
    if (_isLocked) return;
    setState(() {
      _isError = false;
      if (_pin.length < _pinLength) _pin += val;
    });
  }

  void _onDelete() {
    if (_isLocked) return;
    setState(() {
      _isError = false;
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _onVerify() async {
    if (_pin.length < _pinLength || _isLocked) return;

    final correct = await SecurityService.verifyPin(_pin);

    if (!mounted) return;

    if (correct) {
      // Unlock: navigate back with success flag
      context.pop(true);
    } else {
      _attempts++;
      setState(() {
        _isError = true;
        _pin = '';
      });

      if (_attempts >= _maxAttempts) {
        _startLockout();
        _showSnack(
          'Too many wrong attempts. Locked for $_lockoutSeconds seconds.',
        );
      } else {
        _showSnack(
          'Incorrect PIN. ${_maxAttempts - _attempts} attempt${_maxAttempts - _attempts == 1 ? '' : 's'} remaining.',
        );
      }
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
            const SizedBox(height: 60),

            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: brandRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(Icons.lock_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              'Enter Your PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Status message
            _isLocked
                ? Text(
                    'Too many attempts. Try again in $_lockoutRemaining seconds.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : const Text(
                    'Enter your 4-digit PIN to unlock Vault',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF777777)),
                  ),
            const SizedBox(height: 40),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (i) {
                final filled = i < _pin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _isError
                        ? Colors.red
                        : _isLocked
                        ? const Color(0xFFBBBBBB)
                        : filled
                        ? brandRed
                        : const Color(0xFFDDDDDD),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            const Spacer(),

            // Keypad
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
                      const SizedBox(width: 80, height: 50),
                      _KeyButton(
                        label: '0',
                        onTap: () => _onKeyTap('0'),
                        disabled: _isLocked,
                      ),
                      GestureDetector(
                        onTap: _onDelete,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 80,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.backspace_outlined,
                              size: 26,
                              color: _isLocked
                                  ? const Color(0xFFBBBBBB)
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Verify button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isLocked || _pin.length < _pinLength)
                      ? null
                      : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandRed,
                    disabledBackgroundColor: brandRed.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Unlock Vault',
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
          .map(
            (l) => _KeyButton(
              label: l,
              onTap: () => _onKeyTap(l),
              disabled: _isLocked,
            ),
          )
          .toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool disabled;
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 80,
        height: 50,
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFEEEEEE) : const Color(0xFFEBEBEB),
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: disabled ? const Color(0xFFBBBBBB) : const Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}
