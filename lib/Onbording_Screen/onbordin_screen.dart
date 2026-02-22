import 'package:flutter/material.dart';
import '../Authentication/welcome_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color brandRed = Color(0xFFC61C36);

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      image: 'assets/images/onbording1.png',
      headlineParts: [
        _TextPart('See Your\n', false),
        _TextPart('Finance', true),
        _TextPart(' Clearly', false),
      ],
      description:
          'All your rent, loans, and insurance organized in one simple, secure place.',
    ),
    _OnboardingData(
      image: 'assets/images/onbording2.png',
      headlineParts: [
        _TextPart('Store What Matters.\n', false),
        _TextPart('Safely', true),
        _TextPart('.', false),
      ],
      description:
          'Your important documents protected, organized, and always within reach in your Vault.',
    ),
    _OnboardingData(
      image: 'assets/images/onbording3.png',
      headlineParts: [
        _TextPart('Never Miss What\n', false),
        _TextPart('Matters', true),
      ],
      description:
          'Gentle reminders for payments, renewals, and deadlines without the mental load.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() {
    // Navigate to Welcome Screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Page view
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return _OnboardingPage(data: _pages[index]);
            },
          ),

          // Bottom overlay: dots + buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomBar(
              currentPage: _currentPage,
              totalPages: _pages.length,
              onNext: _nextPage,
              onSkip: _skip,
              onGetStarted: _getStarted,
              brandRed: brandRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single onboarding page ───────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        // Top 60% — image
        SizedBox(
          height: size.height * 0.60,
          width: double.infinity,
          child: Image.asset(
            data.image,
            fit: BoxFit.cover,
          ),
        ),

        // Bottom 40% — content
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Headline with mixed color
                RichText(
                  text: TextSpan(
                    children: data.headlineParts.map((part) {
                      return TextSpan(
                        text: part.text,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: part.isRed
                              ? const Color(0xFFC61C36)
                              : const Color(0xFF111111),
                          height: 1.25,
                          letterSpacing: -0.3,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Text(
                  data.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF888888),
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom bar: dots + skip + next/get started ───────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onGetStarted;
  final Color brandRed;

  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onSkip,
    required this.onGetStarted,
    required this.brandRed,
  });

  bool get _isLastPage => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        28,
        16,
        28,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pagination dots — centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalPages, (index) {
              final isActive = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 20 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? brandRed : const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // Skip + Next OR Get Started
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLastPage
                ? _GetStartedButton(
                    key: const ValueKey('getstarted'),
                    onTap: onGetStarted,
                    brandRed: brandRed,
                  )
                : _NavRow(
                    key: const ValueKey('navrow'),
                    onSkip: onSkip,
                    onNext: onNext,
                    brandRed: brandRed,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Skip + circular Next ─────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final Color brandRed;

  const _NavRow({
    super.key,
    required this.onSkip,
    required this.onNext,
    required this.brandRed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Skip
        GestureDetector(
          onTap: onSkip,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Skip',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Circular Next button
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: brandRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: brandRed.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Full-width Get Started button ────────────────────────────────────────────
class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color brandRed;

  const _GetStartedButton({
    super.key,
    required this.onTap,
    required this.brandRed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: brandRed,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: brandRed.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Data models ──────────────────────────────────────────────────────────────
class _OnboardingData {
  final String image;
  final List<_TextPart> headlineParts;
  final String description;

  const _OnboardingData({
    required this.image,
    required this.headlineParts,
    required this.description,
  });
}

class _TextPart {
  final String text;
  final bool isRed;
  const _TextPart(this.text, this.isRed);
}