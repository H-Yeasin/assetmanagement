import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/loan_service.dart';
import '../shared/payment_timeline_helpers.dart';
import 'package:intl/intl.dart';

class UpcomingActionsScreen extends StatefulWidget {
  const UpcomingActionsScreen({super.key});

  @override
  State<UpcomingActionsScreen> createState() => _UpcomingActionsScreenState();
}

class _UpcomingActionsScreenState extends State<UpcomingActionsScreen> {
  final LoanService _loanService = LoanService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFBFBFB,
      ), // Match design's off-white background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111111),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upcoming Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {},
        //     child: const Text(
        //       'Edit',
        //       style: TextStyle(color: brandRed, fontWeight: FontWeight.w600),
        //     ),
        //   ),
        //   const SizedBox(width: 8),
        // ],
        centerTitle: true,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _loanService.streamUpcomingPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandRed),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final upcomingGroups = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Upcoming Actions',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Text(
                    //   'See All',
                    //   style: TextStyle(
                    //     fontSize: 13,
                    //     color: Color(0xFF111111),
                    //     fontWeight: FontWeight.w700,
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(height: 16),
                const TimelineInfoNote(label: upcomingActionsInfoNoteLabel),
                const SizedBox(height: 24),
                if (upcomingGroups.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        'No upcoming actions',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...upcomingGroups.map((group) {
                    final date = DateTime.parse(group['date']);
                    final items = group['items'] as List;
                    return Column(
                      children: items.map((item) {
                        return PaymentCard(
                          month: DateFormat('MMM').format(date),
                          day: DateFormat('dd').format(date),
                          title: item['name'],
                          amount:
                              '\$${NumberFormat('#,##0.00').format(item['paymentAmount'] ?? item['monthlyPayment'] ?? 0)}',
                          status: item['autoPay']
                              ? 'Paid automatically'
                              : 'Manual payment required',
                          isPaid: item['autoPay'],
                        );
                      }).toList(),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
