import 'package:flutter/material.dart';
import 'shared_widgets.dart';
import 'sign_in.dart';
import 'login.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Hero Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/loginpage_image.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Welcome to '),
                        TextSpan(
                          text: 'FFP',
                          style: TextStyle(color: brandRed),
                        ),
                        TextSpan(text: ' Vault'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF888888),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Clarify, control, and peace of mind.\n',
                        ),
                        const TextSpan(text: 'All in '),
                        TextSpan(
                          text: 'One Place.',
                          style: TextStyle(
                            color: brandRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Buttons
                  AppPrimaryButton(
                    label: 'Sign up',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignIn()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  AppSecondaryButton(
                    label: 'Log In',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
