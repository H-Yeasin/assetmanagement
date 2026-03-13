import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../services/loan_service.dart';
import 'widgets.dart';

class PastActivitiesScreen extends StatefulWidget {
  const PastActivitiesScreen({super.key});

  @override
  State<PastActivitiesScreen> createState() => _PastActivitiesScreenState();
}

class _PastActivitiesScreenState extends State<PastActivitiesScreen> {
  final LoanService _loanService = LoanService();

  bool _isPaidActivity(Map<String, dynamic> item) {
    final note = item['note']?.toString().toLowerCase() ?? '';
    final title = item['title']?.toString().toLowerCase() ?? '';
    return note.contains('paid') ||
        note.contains('auto') ||
        title.contains('paid');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
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
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: brandRed),
                  );
                }
                return StreamBuilder<List<dynamic>>(
                  stream: _loanService.streamPastActivities(),
                  builder: (context, activitySnapshot) {
                    if (activitySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: brandRed),
                      );
                    }
                    if (activitySnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${activitySnapshot.error}'),
                      );
                    }

                    final activities = activitySnapshot.data ?? [];
                    if (activities.isEmpty) {
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        final doneAt = item['doneAt'];
                        final remindAt = item['remindAt'];
                        final date = doneAt != null
                            ? doneAt.toDate() as DateTime
                            : remindAt != null
                            ? remindAt.toDate() as DateTime
                            : DateTime.now();
                        final isPaid = _isPaidActivity(item);

                        return _PastActivityCard(
                          month: DateFormat('MMM').format(date),
                          day: DateFormat('dd').format(date),
                          title: item['title']?.toString() ?? 'Reminder',
                          subtitle:
                              item['note']?.toString() ??
                              'Completed activity',
                          isPaid: isPaid,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'All data will be deleted within 14 days.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8F8F8F),
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

class _PastActivityCard extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String subtitle;
  final bool isPaid;

  const _PastActivityCard({
    required this.month,
    required this.day,
    required this.title,
    required this.subtitle,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPaid ? const Color(0xFF2196F3) : brandRed;
    final statusBgColor = isPaid
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFFFEBEE);
    final dateBoxBgColor = isPaid
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFF7E7EB);
    final dateTextColor = isPaid
        ? const Color(0xFF6B7F8F)
        : const Color(0xFF8D6E63);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dateBoxBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 11,
                    color: dateTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111111),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                if (isPaid)
                  Text(
                    'Paid',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8F8F8F),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.priority_high,
                          size: 12,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Manual payment required',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
