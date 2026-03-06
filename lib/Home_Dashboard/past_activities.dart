import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart';
import '../services/loan_service.dart';

class PastActivitiesScreen extends StatefulWidget {
  const PastActivitiesScreen({super.key});

  @override
  State<PastActivitiesScreen> createState() => _PastActivitiesScreenState();
}

class _PastActivitiesScreenState extends State<PastActivitiesScreen> {
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
          'View Past Activities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<dynamic>>(
              stream: _loanService.streamPastActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: brandRed));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final groups = snapshot.data ?? [];
                if (groups.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text(
                        'No past activities found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  children: groups.expand<Widget>((group) {
                    final date = DateTime.parse(group['date']);
                    final items = group['items'] as List;
                    return items.map((item) {
                      return PaymentCard(
                        month: DateFormat('MMM').format(date),
                        day: DateFormat('dd').format(date),
                        title: item['name'],
                        amount: NumberFormat.simpleCurrency().format(item['monthlyPayment']),
                        status: 'Paid',
                        isPaid: true,
                      );
                    }).toList();
                  }).toList(),
                );
              },
            ),
          ),

          // Data Deletion Notice
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'All data will be deleted within 14 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFBBBBBB),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
