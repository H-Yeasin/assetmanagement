import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _showAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddItemBottomSheet(),
    );
  }

  void _navigateToPayments(BuildContext context) {
    context.push('/upcoming-payments');
  }

  void _showFeedback(BuildContext context, String category) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $category...'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: brandRed,
      ),
    );
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
                  CategoryCard(
                    iconPath: 'assets/images/icon/loan.png',
                    title: 'Loans',
                    subtitle: '2 active',
                    iconColor: brandRed,
                    onTap: () {
                      context.go('/my-loans');
                    },
                  ),
                  CategoryCard(
                    iconPath: 'assets/images/icon/housing.png',
                    title: 'Housing / Living Costs',
                    subtitle: 'up to date',
                    iconColor: Colors.purple,
                    onTap: () {
                      context.go('/housing-costs');
                    },
                  ),
                  CategoryCard(
                    iconPath: 'assets/images/icon/insurance.png',
                    title: 'Insurance',
                    subtitle: '3 policies',
                    iconColor: Colors.blue,
                    onTap: () => context.push('/my-insurances'),
                  ),
                  CategoryCard(
                    iconPath: 'assets/images/icon/doccument.png',
                    title: 'Documents',
                    subtitle: '12 stored',
                    iconColor: Colors.orange,
                    onTap: () => context.push('/add-documents'),
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
              const SizedBox(height: 20),
              ReminderCard(
                month: 'Jan',
                day: '01',
                title: 'Apartment Rent Due',
                dueInfo: 'Due in 3 days',
                onTap: () => context.push('/upcoming-reminders'),
              ),
              ReminderCard(
                month: 'Feb',
                day: '20',
                title: 'Car Insurance Renewal',
                dueInfo: 'February 20, 2025',
                onTap: () => context.push('/upcoming-reminders'),
              ),

              const SizedBox(height: 32),

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
