import 'package:flutter/material.dart';
import '../Authentication/welcome_screen.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color brandRed = Color(0xFFC61C36);

  final List<Map<String, dynamic>> _pages = [
    {
      'image': 'assets/images/onbording1.png',
      'title': 'See Your\n',
      'highlight': 'Finance',
      'suffix': ' Clearly',
      'desc':
          'All your rent, loans, and insurance organized in one simple, secure place.',
    },
    {
      'image': 'assets/images/onbording2.png',
      'title': 'Store What Matters\n',
      'highlight': 'Safely',
      'suffix': '',
      'desc':
          'Your important documents protected, organized, and always within reach in your Vault.',
    },
    {
      'image': 'assets/images/onbording3.png',
      'title': 'Never Miss What\n',
      'highlight': 'Matters',
      'suffix': '',
      'desc':
          'Gentle reminders for payments, renewals, and deadlines without the mental load.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (v) => setState(() => _currentPage = v),
            itemBuilder: (context, i) {
              return Column(
                children: [
                  Expanded(
                    flex: 11,
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.asset(_pages[i]['image'], fit: BoxFit.cover),
                    ),
                  ),
                  Expanded(
                    flex: 9,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: _pages[i]['title'],
                                  style: const TextStyle(
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                TextSpan(
                                  text: _pages[i]['highlight'],
                                  style: const TextStyle(color: brandRed),
                                ),
                                TextSpan(
                                  text: _pages[i]['suffix'],
                                  style: const TextStyle(
                                    color: Color(0xFF111111),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pages[i]['desc'],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF888888),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          Positioned(
            left: 28,
            bottom: MediaQuery.of(context).padding.bottom + 110,
            child: Row(
              children: List.generate(3, (index) {
                bool isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 8),
                  width: isActive ? 10 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? brandRed : const Color(0xFFE0E0E0),
                  ),
                );
              }),
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 28,
            right: 28,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentPage == 2 ? _buildGetStarted() : _buildNavRow(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow() {
    return Row(
      key: const ValueKey(1),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () async {
            await StorageService.setOnboardingSeen();
            if (mounted) {
              _pageController.animateToPage(
                2,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          child: const Text(
            'Skip',
            style: TextStyle(
              color: brandRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: brandRed,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x33C61C36),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGetStarted() {
    return SizedBox(
      key: const ValueKey(2),
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          await StorageService.setOnboardingSeen();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
