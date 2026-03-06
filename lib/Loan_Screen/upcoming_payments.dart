import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';

class UpcomingPaymentsScreen extends StatefulWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  State<UpcomingPaymentsScreen> createState() => _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState extends State<UpcomingPaymentsScreen> {
  final LoanService _loanService = LoanService();

  @override
  void initState() {
    super.initState();
  }

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
          'Upcoming Payments',
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
            const SizedBox(height: 10),
            // Interactive Calendar
            const CalendarWidget(),

            const SizedBox(height: 32),

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

            StreamBuilder<List<dynamic>>(
              stream: _loanService.streamUpcomingPayments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: brandRed));
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: brandRed));
                }
                
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No upcoming payments found.', style: TextStyle(color: Colors.grey)),
                  );
                }

                return Column(
                  children: groups.map<Widget>((group) {
                    final date = DateTime.parse(group['date']);
                    final items = group['items'] as List;
                    return Column(
                      children: items.map<Widget>((item) {
                        return PaymentCard(
                          month: DateFormat('MMM').format(date),
                          day: DateFormat('dd').format(date),
                          title: item['name'],
                          amount: NumberFormat.simpleCurrency().format(item['monthlyPayment']),
                          status: item['autoPay'] ? 'Paid Automatically' : 'Manual Payment Required',
                          isPaid: item['autoPay'],
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
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

            const SizedBox(height: 48),

            // Notification Toggle Section
            const NotificationToggle(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
