import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../services/housing_service.dart';
import '../services/insurance_service.dart';
import '../services/loan_service.dart';
import '../Housing_Living_cost/models/housing_cost_model.dart';
import '../Insurance/models/insurance_model.dart';
import '../Loan_Screen/models/loan_model.dart';
import 'widgets.dart';

class HomeDashboardScreen extends StatelessWidget {
  HomeDashboardScreen({super.key});

  final LoanService _loanService = LoanService();
  final HousingService _housingService = HousingService();
  final InsuranceService _insuranceService = InsuranceService();

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          Colors.transparent, // We handle blur & darkening in the builder
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.black.withValues(alpha: 0.10), // Subtle darkening
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {}, // Prevent taps on the sheet from dismissing
                  child: const AddItemBottomSheet(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPayments(BuildContext context) {
    context.push('/upcoming-payments');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                        height: 1.2,
                      ),
                      children: [
                        TextSpan(text: 'Welcome to\n'),
                        TextSpan(
                          text: 'FFP',
                          style: TextStyle(
                            color: brandRed,
                            fontSize: 45,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(text: ' Vault'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _navigateToPayments(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/icon/notification.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Your financial life. Clear, organized,\nand under control.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // 2x2 Category Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  StreamBuilder<List<Loan>>(
                    stream: _loanService.streamLoans(status: 'active'),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? snapshot.data!.length
                          : 0;
                      final loadingText =
                          snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : '$count active';
                      return CategoryCard(
                        iconPath: 'assets/images/icon/loan.png',
                        title: 'Loans',
                        subtitle: loadingText,
                        iconColor: brandRed,
                        onTap: () {
                          context.go('/my-loans');
                        },
                      );
                    },
                  ),
                  StreamBuilder<List<HousingCost>>(
                    stream: _housingService.streamHousingCosts(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? snapshot.data!.length
                          : 0;
                      final loadingText =
                          snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : '$count added';
                      return CategoryCard(
                        iconPath: 'assets/images/icon/housing.png',
                        title: 'Housing / Living Costs',
                        subtitle: loadingText,
                        iconColor: Colors.purple,
                        onTap: () {
                          context.go('/housing-costs');
                        },
                      );
                    },
                  ),
                  StreamBuilder<List<InsurancePolicy>>(
                    stream: _insuranceService.streamInsurances(),
                    builder: (context, snapshot) {
                      final count = snapshot.hasData
                          ? snapshot.data!.length
                          : 0;
                      final loadingText =
                          snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : '$count policies';
                      return CategoryCard(
                        iconPath: 'assets/images/icon/insurance.png',
                        title: 'Insurance',
                        subtitle: loadingText,
                        iconColor: Colors.blue,
                        onTap: () => context.push('/my-insurances'),
                      );
                    },
                  ),
                  StreamBuilder<int>(
                    stream: _loanService.streamDocumentsCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      final loadingText =
                          snapshot.connectionState == ConnectionState.waiting
                          ? '...'
                          : '$count stored';
                      return CategoryCard(
                        iconPath: 'assets/images/icon/doccument.png',
                        title: 'Documents',
                        subtitle: loadingText,
                        iconColor: Colors.orange,
                        onTap: () => context.push('/vault'),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Upcoming Reminders Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming Reminders',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/upcoming-reminders'),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
              StreamBuilder<List<dynamic>>(
                stream: _loanService.streamUpcomingReminders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: brandRed),
                      ),
                    );
                  }

                  final reminders = snapshot.data ?? [];
                  if (reminders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No upcoming reminders',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: reminders.take(2).map((r) {
                      final remindAt =
                          (r['remindAt'] as dynamic).toDate() as DateTime;
                      final note = r['note'] ?? r['title'] ?? 'Reminder';
                      final title = r['title'] ?? 'Task';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ReminderCard(
                          month: DateFormat('MMM').format(remindAt),
                          day: DateFormat('dd').format(remindAt),
                          title: title,
                          dueInfo: note,
                          onTap: () => context.push('/upcoming-reminders'),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Add New Item Button
              GestureDetector(
                onTap: () => _showAddItemSheet(context),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: brandRed,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: brandRed.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Add New Item',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
