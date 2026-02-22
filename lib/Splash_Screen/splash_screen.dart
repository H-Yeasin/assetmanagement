import 'package:flutter/material.dart';
import 'dart:ui';
import '../Onbording_Screen/onbordin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _logoGrowController;
  late AnimationController _bounceController;
  late AnimationController _textController;

  late Animation<double> _circleAnimation;
  late Animation<double> _logoRadiusAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _textWidthAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textBlurAnimation;


  static const Color brandRed = Color(0xFFC61C36);
  static const double _logoInitialRadius = 6.0;
  static const double _logoFinalRadius = 40.0;


  @override
  void initState() {
    super.initState();

    // Red circle expand
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // Logo grows after red fills screen
    _logoGrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _logoRadiusAnimation = Tween<double>(
      begin: _logoInitialRadius,
      end: _logoFinalRadius,
    ).animate(
      CurvedAnimation(parent: _logoGrowController, curve: Curves.easeOut),
    );

    // Micro-bounce
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.09), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.09, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Text reveal + row shift to keep centered
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _textWidthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );
    _textBlurAnimation = Tween<double>(begin: 9.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );


    _runSequence();
  }

  Future<void> _runSequence() async {
    // 1. Expand red circle
    _circleController.forward();
    await Future.delayed(const Duration(milliseconds: 1100));

    // 2. Grow logo
    _logoGrowController.forward();
    await Future.delayed(const Duration(milliseconds: 650));

    // 3. Micro-bounce
    await _bounceController.forward();
    await Future.delayed(const Duration(milliseconds: 80));

    // 4. Reveal text + shift row to stay centered
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1000));

    // 5. Navigate to Onboarding Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  void dispose() {
    _circleController.dispose();
    _logoGrowController.dispose();
    _bounceController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxRadius = size.longestSide * 1.3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _circleController,
          _logoGrowController,
          _bounceController,
          _textController,
        ]),
        builder: (context, _) {
          final circleRadius = _circleAnimation.value * maxRadius;

          final logoRadius = (_logoGrowController.isAnimating ||
                  _logoGrowController.isCompleted)
              ? _logoRadiusAnimation.value * _bounceAnimation.value
              : _logoInitialRadius * _bounceAnimation.value;

          return Stack(
            children: [
              // ── White base ──────────────────────────────────────────
              Positioned.fill(child: Container(color: Colors.white)),

              // ── Expanding red circle ─────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _CirclePainter(
                    radius: circleRadius,
                    color: brandRed,
                  ),
                ),
              ),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    CircleAvatar(
                      radius: logoRadius,
                      backgroundColor: Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(logoRadius * 0.15),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Text — clips open from left → right
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _textWidthAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 14.0),
                          child: Opacity(
                            opacity: _textFadeAnimation.value,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: _textBlurAnimation.value,
                                sigmaY: 0.0,
                              ),
                              child: const Text(
                                'FFP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 58,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 3,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Expanding circle painter ─────────────────────────────────────────────────
class _CirclePainter extends CustomPainter {
  final double radius;
  final Color color;

  const _CirclePainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.radius != radius || old.color != color;
}