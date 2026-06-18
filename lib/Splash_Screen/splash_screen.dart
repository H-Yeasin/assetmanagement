import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../Onbording_Screen/onbordin_screen.dart';
import '../Authentication/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // Safety fallback: if lottie doesn't trigger onLoaded/complete,
    // we still navigate after 5 seconds to avoid white screen lock.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) _navigateAfterSplash();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSplash() async {
    if (_didNavigate) return;
    _didNavigate = true;

    try {
      final seenOnboarding = await StorageService.hasSeenOnboarding();
      if (!mounted) return;

      if (!seenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }

      final firebaseUser = FirebaseAuth.instance.currentUser;
      final pendingRegistrationEmail =
          await StorageService.getPendingRegistrationEmail();
      final pendingTwoFactor = await StorageService.hasPendingTwoFactorLogin();
      if (!mounted) return;

      if (pendingRegistrationEmail != null &&
          pendingRegistrationEmail.isNotEmpty) {
        if (firebaseUser != null) {
          context.go(
            '/verify-otp',
            extra: {
              'email': pendingRegistrationEmail,
              'flow': 'register',
              'initialResendSeconds': 0,
            },
          );
          return;
        }

        await StorageService.clearPendingRegistration();
        if (!mounted) return;
      }

      if (pendingTwoFactor) {
        if (firebaseUser != null) {
          final email = await StorageService.getPendingTwoFactorEmail() ?? '';
          final rememberMe =
              await StorageService.getPendingTwoFactorPersistLogin();
          if (!mounted) return;
          context.go(
            '/two-factor-otp',
            extra: {'email': email, 'flow': 'login', 'rememberMe': rememberMe},
          );
          return;
        }

        await StorageService.clearPendingTwoFactorLogin();
        if (!mounted) return;
      }

      final loggedIn = await StorageService.isLoggedIn();
      if (!mounted) return;

      if (loggedIn) {
        final keepLoggedIn = await StorageService.isSessionPersistent();
        if (!mounted) return;
        if (!keepLoggedIn) {
          await AuthService.logout();
          await StorageService.clearSession();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
          return;
        }

        if (firebaseUser == null) {
          await StorageService.clearSession();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          );
          return;
        }

        context.go('/home');
      } else {
        if (firebaseUser != null) {
          await AuthService.logout();
          await StorageService.clearSession();
          if (!mounted) return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      debugPrint("Navigation error: $e");
      if (!mounted) return;
      // Fallback to onboarding if something breaks
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFFC61C36),
              ),
            ),
            Lottie.asset(
              'assets/images/lottie_Animation/Logo_animation_Lottie_fixed.json',
              controller: _lottieController,
              width: MediaQuery.of(context).size.width * 1.4,
              height: MediaQuery.of(context).size.width * 1.4,
              fit: BoxFit.contain,
              delegates: const LottieDelegates(),
              onLoaded: (composition) {
                _lottieController
                  ..duration = composition.duration
                  ..forward().whenComplete(() {
                    if (mounted) _navigateAfterSplash();
                  });
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _navigateAfterSplash();
                });
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
