import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../services/revenuecat_service.dart';
import 'models/subscription_confirmation.dart';

/// A thin wrapper that presents RevenueCat's native paywall via
/// `purchases_ui_flutter`.
///
/// Used when `AppConfig.useRevenueCatPaywall` is `true`.
///
/// ### How it works
/// 1. Loads the current offering from RevenueCat.
/// 2. Presents the native RevenueCat paywall UI.
/// 3. Handles the result: purchased, restored, cancelled, or error.
///
/// ### Configuring the Paywall
/// Design your paywall in the RevenueCat dashboard under **Paywalls**.
/// The paywall is associated with an offering — make sure your offering
/// has a paywall configured.
///
/// See: https://www.revenuecat.com/docs/tools/paywalls
class RCPaywallScreen extends StatefulWidget {
  const RCPaywallScreen({super.key});

  @override
  State<RCPaywallScreen> createState() => _RCPaywallScreenState();
}

class _RCPaywallScreenState extends State<RCPaywallScreen> {
  bool _isPresenting = false;

  @override
  void initState() {
    super.initState();
    // Use microtask so the build is committed before we present the paywall.
    Future.microtask(_presentPaywall);
  }

  Future<void> _presentPaywall() async {
    if (_isPresenting) return;
    _isPresenting = true;

    try {
      // Pre-fetch the current offering so the paywall has data to show.
      // Pass an offering identifier if you have multiple paywalls/offerings.
      final offering = await RevenueCatService().getCurrentOffering();

      if (!mounted) return;

      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
      );

      if (!mounted) return;

      switch (result) {
        case PaywallResult.purchased:
        case PaywallResult.restored:
          // The SDK listener in main.dart auto-syncs to Firestore on purchase,
          // but we explicitly refresh customer info here to make sure the
          // latest state is available before navigating.
          await RevenueCatService().getCustomerInfo();
          if (!mounted) return;
          context.go(
            '/payment-success',
            extra: const PaymentStatusArgs(
              isSuccess: true,
              title: 'Subscription Active',
              message:
                  'Welcome to the FFP Vault.\n\nYour subscription is now active '
                  'and you can start organizing your finances with clarity and '
                  'confidence.',
              buttonLabel: 'Open the Vault',
            ),
          );
          break;

        case PaywallResult.cancelled:
        case PaywallResult.notPresented:
          // User dismissed the paywall — go back to the subscription plan screen.
          if (mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/subscription-plan');
            }
          }
          break;

        case PaywallResult.error:
          if (!mounted) return;
          context.go(
            '/payment-failed',
            extra: const PaymentStatusArgs(
              isSuccess: false,
              title: 'Something Went Wrong',
              message:
                  'We could not complete your purchase. Please try again.',
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      context.go(
        '/payment-failed',
        extra: const PaymentStatusArgs(
          isSuccess: false,
          title: 'Payment Failed',
          message: 'We could not complete your purchase. Please try again.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFC61C36)),
      ),
    );
  }
}
