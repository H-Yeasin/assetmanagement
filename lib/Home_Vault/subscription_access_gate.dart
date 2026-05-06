import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../services/subscription_service.dart';

class SubscriptionAccessGate extends StatefulWidget {
  final Widget child;

  const SubscriptionAccessGate({super.key, required this.child});

  @override
  State<SubscriptionAccessGate> createState() => _SubscriptionAccessGateState();
}

class _SubscriptionAccessGateState extends State<SubscriptionAccessGate> {
  bool _redirected = false;
  final SubscriptionService _subscriptionService = SubscriptionService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionState>(
      stream: _subscriptionService.streamSubscription(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show transparent container while waiting — no spinner flash
          return const Scaffold(backgroundColor: Colors.white);
        }

        final subscription = snapshot.data ?? SubscriptionState.inactive;
        if (subscription.isActive || AppConfig.bypassVaultSubscription) {
          return widget.child;
        }

        if (!_redirected) {
          _redirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/subscription-plan');
            }
          });
        }

        return const Scaffold(backgroundColor: Colors.white);
      },
    );
  }
}
