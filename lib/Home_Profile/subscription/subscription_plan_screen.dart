import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../services/subscription_service.dart';

class SubscriptionPlanScreen extends StatefulWidget {
  const SubscriptionPlanScreen({super.key});

  @override
  State<SubscriptionPlanScreen> createState() => _SubscriptionPlanScreenState();
}

class _SubscriptionPlanScreenState extends State<SubscriptionPlanScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isCancelling = false;

  Future<void> _cancelSubscription() async {
    if (_isCancelling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Your subscription will stay active until the end of the current billing period, then it will cancel automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep Plan'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancel Plan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCancelling = true);
    try {
      await _subscriptionService.cancelSubscription();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cancellation scheduled. Your plan remains active until period end.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to cancel subscription: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _formatPeriodEnd(DateTime? date) {
    if (date == null) return 'Billing updates after activation';
    return 'Active until ${DateFormat('MMM d, yyyy').format(date)}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SubscriptionState>(
      stream: _subscriptionService.streamSubscription(),
      builder: (context, snapshot) {
        final subscription = snapshot.data ?? SubscriptionState.inactive;
        final isActive = subscription.isActive;

        return Scaffold(
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
                        if (isActive)
                          GestureDetector(
                            onTap: () {
                              if (GoRouter.of(context).canPop()) {
                                GoRouter.of(context).pop();
                              } else {
                                context.go('/home');
                              }
                            },
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
                                onTap: () {
                                  if (GoRouter.of(context).canPop()) {
                                    GoRouter.of(context).pop();
                                  } else {
                                    context.go('/home');
                                  }
                                },
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
                              const Expanded(
                                child: Text(
                                  'Start your 14 days\nfree trial',
                                  style: TextStyle(
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
                        if (isActive)
                          Text(
                            'Manage your\nmonthly plan',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          isActive
                              ? 'Your subscription is active. You can keep it, or cancel anytime before your next billing date.'
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
                              _FeatureItem(
                                text: 'Centralized Payment Tracking.',
                              ),
                              SizedBox(height: 16),
                              _FeatureItem(text: 'Smart Reminders'),
                              SizedBox(height: 16),
                              _FeatureItem(text: 'Secure Document Vault'),
                              SizedBox(height: 16),
                              _FeatureItem(text: 'Clear Timelines'),
                              SizedBox(height: 16),
                              _FeatureItem(text: 'Mobile First Access'),
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
                                        const Text(
                                          '14 days free trial',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isActive
                                              ? subscription.cancelAtPeriodEnd
                                                    ? 'Cancellation scheduled'
                                                    : 'Subscription active'
                                              : 'First 2 weeks on us',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                subscription.cancelAtPeriodEnd
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
                                                text: isActive
                                                    ? '\$6.99'
                                                    : 'Then \$6.99',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              TextSpan(
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
                                          isActive
                                              ? _formatPeriodEnd(
                                                  subscription.currentPeriodEnd,
                                                )
                                              : 'Starts after trial ends',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    GestureDetector(
                                      onTap: subscription.cancelAtPeriodEnd || _isCancelling
                                          ? null
                                          : _cancelSubscription,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
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
                                            color: subscription.cancelAtPeriodEnd
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
                          onPressed: isActive
                              ? subscription.cancelAtPeriodEnd || _isCancelling
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
                                  isActive
                                      ? subscription.cancelAtPeriodEnd
                                            ? 'Cancellation Scheduled'
                                            : 'Cancel Subscription'
                                      : 'Start Free Trial',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => context.go('/home'),
                        child: Text(
                          isActive ? 'Back to Profile' : 'Continue later',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFC61C36),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isActive
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
        );
      },
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFFC61C36),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}
