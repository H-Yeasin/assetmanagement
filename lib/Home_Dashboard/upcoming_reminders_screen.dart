import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';

class UpcomingRemindersScreen extends StatelessWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upcoming Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment List Section
            const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 20),

            // Dummy Reminders
            ReminderCard(
              month: 'Jan',
              day: '01',
              title: 'Apartment Rent Due',
              dueInfo: 'Due in 3 days',
              onTap: () {},
            ),
            ReminderCard(
              month: 'Feb',
              day: '20',
              title: 'Car Insurance Renewal',
              dueInfo: 'February 20, 2025',
              onTap: () {},
            ),
            ReminderCard(
              month: 'Mar',
              day: '15',
              title: 'Health Insurance Premium',
              dueInfo: 'March 15, 2025',
              onTap: () {},
            ),
            ReminderCard(
              month: 'Apr',
              day: '10',
              title: 'Property Tax Installment',
              dueInfo: 'April 10, 2025',
              onTap: () {},
            ),

            const SizedBox(height: 24),

            // View Past Activity Button
            Center(
              child: GestureDetector(
                onTap: () {
                  context.push('/past-activities');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.history, size: 18, color: brandRed),
                    SizedBox(width: 8),
                    Text(
                      'View Past Activity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: brandRed,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
