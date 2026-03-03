import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
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

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSplash() async {
    // Check if user is already logged in
    final loggedIn = await StorageService.isLoggedIn();
    if (!mounted) return;

    if (loggedIn) {
      // Skip onboarding and auth — go straight to home via GoRouter
      context.go('/home');
    } else {
      // Check if onboarding has been shown before
      final seenOnboarding = await StorageService.hasSeenOnboarding();
      if (!mounted) return;

      if (seenOnboarding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Lottie.asset(
          'assets/images/lottie_Animation/Logo_animation_Lottie_fixed.json',
          controller: _lottieController,
          width: MediaQuery.of(context).size.width * 3.00,
          height: MediaQuery.of(context).size.width * 3.00,
          fit: BoxFit.contain,
          delegates: const LottieDelegates(),
          onLoaded: (composition) {
            _lottieController
              ..duration = composition.duration
              ..forward().whenComplete(() {
                if (mounted) _navigateAfterSplash();
              });
          },
        ),
      ),
    );
  }
}
