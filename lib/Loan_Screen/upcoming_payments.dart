import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import 'services/loan_api_service.dart';
import 'package:intl/intl.dart';

class UpcomingPaymentsScreen extends StatefulWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  State<UpcomingPaymentsScreen> createState() => _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState extends State<UpcomingPaymentsScreen> {
  final LoanApiService _apiService = LoanApiService();
  List<dynamic> _upcomingGroups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpcoming();
  }

  Future<void> _loadUpcoming() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groups = await _apiService.fetchUpcomingPayments();
      setState(() {
        _upcomingGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

            // Dummy Payment Data aligned with Calendar Markers (Jan 2025)
            const PaymentCard(
              month: 'Jan',
              day: '11',
              title: 'Home Loan',
              amount: '\$2,460.00',
              status: 'Paid Automatically',
              isPaid: true,
            ),
            const PaymentCard(
              month: 'Jan',
              day: '17',
              title: 'Car Loan',
              amount: '\$2,230.00',
              status: 'Manual Payment Required',
              isPaid: false,
            ),
            const PaymentCard(
              month: 'Jan',
              day: '22',
              title: 'Student Loan',
              amount: '\$1,300.00',
              status: 'Paid Automatically',
              isPaid: true,
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
