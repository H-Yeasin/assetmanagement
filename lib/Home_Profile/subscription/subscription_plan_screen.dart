import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/subscription_service.dart';
import 'models/subscription_state.dart';
import 'widgets/feature_item.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  final bool openedFromVaultGate;

  const SubscriptionPlanScreen({super.key, this.openedFromVaultGate = false});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isCancelling = false;

  void _handleBackNavigation() {
    if (widget.openedFromVaultGate) {
      context.go('/home');
      return;
    }

    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _cancelSubscription() async {
    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text(
          'You will be redirected to your App Store / Google Play subscription '
          'settings where you can cancel or manage your plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      final opened = await _subscriptionService.cancelSubscription();
      if (!mounted) return;
      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open subscription settings. Please manage your '
              'subscription directly through the App Store or Google Play.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _formatPeriodEnd(DateTime? date) {
    if (date == null) return 'Billing updates after activation';
    return 'Active until ${DateFormat('MMM d, yyyy').format(date)}';
  }

  String _formatTrialEnd(DateTime? date) {
    if (date == null) return 'Trial expires soon';
    final days = date.difference(DateTime.now()).inDays;
    if (days > 0) return 'Trial expires in $days days';
    if (days == 0) return 'Trial expires today';
    return 'Trial expired';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionState>(
      stream: _subscriptionService.streamSubscription(),
      builder: (context, snapshot) {
        final subscription = snapshot.data ?? SubscriptionState.inactive;
        final isSubscribed = subscription.isSubscribed;
        final isFreeTrialActive = subscription.isFreeTrialActive;
        final hasAccess = subscription.isActive;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBackNavigation();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          if (hasAccess)
                            GestureDetector(
                              onTap: _handleBackNavigation,
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                                size: 24,
                              ),
                            )
                          else
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: _handleBackNavigation,
                                  child: const Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    subscription.status == 'trialing' && !isFreeTrialActive 
                                        ? 'Your trial has\nexpired'
                                        : 'Subscribe to\nthe Vault',
                                    style: const TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),
                          if (hasAccess)
                            Text(
                              isSubscribed 
                                ? 'Manage your\nmonthly plan'
                                : '14 days free trial\nactive',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            isSubscribed
                                ? 'Your subscription is active. You can keep it, or cancel anytime before your next billing date.'
                                : isFreeTrialActive
                                    ? 'You have full access to the Vault during your trial. Subscribe now to maintain access after it ends.'
                                    : 'Organize your payments. Secure your documents.\nStay in control without the mental load.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: const [
                                FeatureItem(text: 'Centralized Payment Tracking.'),
                                SizedBox(height: 16),
                                FeatureItem(text: 'Smart Reminders'),
                                SizedBox(height: 16),
                                FeatureItem(text: 'Secure Document Vault'),
                                SizedBox(height: 16),
                                FeatureItem(text: 'Clear Timelines'),
                                SizedBox(height: 16),
                                FeatureItem(text: 'Mobile First Access'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isSubscribed 
                                                ? 'Subscription'
                                                : '14 days free trial',
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isSubscribed
                                                ? subscription.cancelAtPeriodEnd
                                                      ? 'Cancellation scheduled'
                                                      : 'Subscription active'
                                                : isFreeTrialActive
                                                    ? 'Currently active'
                                                    : 'Trial expired',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  subscription.cancelAtPeriodEnd || (!isSubscribed && !isFreeTrialActive)
                                                  ? const Color(0xFFFF9800)
                                                  : const Color(0xFFC61C36),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCE8EB),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/images/shield_icon.png',
                                          width: 32,
                                          height: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Divider(
                                  color: Color(0xFFEEEEEE),
                                  height: 1,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: isSubscribed
                                                      ? '\$6.99'
                                                      : 'Then \$6.99',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const TextSpan(
                                                  text: ' / month',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                    color: Color(0xFF888888),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isSubscribed
                                                ? _formatPeriodEnd(subscription.currentPeriodEnd)
                                                : isFreeTrialActive 
                                                    ? _formatTrialEnd(subscription.trialEndDate)
                                                    : 'Starts immediately',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSubscribed)
                                      GestureDetector(
                                        onTap:
                                            subscription.cancelAtPeriodEnd ||
                                                _isCancelling
                                            ? null
                                            : _cancelSubscription,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 7,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFDDDDDD),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            subscription.cancelAtPeriodEnd
                                                ? 'CANCELLED'
                                                : 'CANCEL ANYTIME',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  subscription.cancelAtPeriodEnd
                                                  ? const Color(0xFFFF9800)
                                                  : const Color(0xFF555555),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    color: const Color(0xFFF5F5F5),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isSubscribed
                                ? subscription.cancelAtPeriodEnd ||
                                          _isCancelling
                                      ? null
                                      : _cancelSubscription
                                : () {
                                    context.push('/choose-payment');
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC61C36),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isCancelling
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    isSubscribed
                                        ? subscription.cancelAtPeriodEnd
                                              ? 'Cancellation Scheduled'
                                              : 'Cancel Subscription'
                                        : 'Subscribe Now',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        if (hasAccess) ...[
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () => context.go('/home'),
                            child: const Text(
                              'Back to Profile',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFC61C36),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          isSubscribed
                              ? 'If you cancel, access remains available until the current billing period ends.'
                              : 'Recurring billing. No commitment. By continuing.\nYou agree to our Terms of Service and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF999999),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

