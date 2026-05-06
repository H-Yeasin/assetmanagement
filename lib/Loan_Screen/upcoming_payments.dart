import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../Home_Dashboard/widgets.dart';
import '../Housing_Living_cost/models/housing_cost_model.dart';
import '../Insurance/models/insurance_model.dart';
import '../services/housing_service.dart';
import '../services/insurance_service.dart';
import '../services/loan_service.dart';

class UpcomingPaymentsScreen extends StatefulWidget {
  const UpcomingPaymentsScreen({super.key});

  @override
  State<UpcomingPaymentsScreen> createState() => _UpcomingPaymentsScreenState();
}

class _UpcomingPaymentsScreenState extends State<UpcomingPaymentsScreen> {
  final LoanService _loanService = LoanService();
  final HousingService _housingService = HousingService();
  final InsuranceService _insuranceService = InsuranceService();

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isFutureOrToday(DateTime date) {
    return !_normalizeDay(date).isBefore(_normalizeDay(DateTime.now()));
  }

  List<_PaymentListItem> _combineItems(
    List<dynamic> loanGroups,
    List<HousingCost> housingCosts,
    List<InsurancePolicy> policies,
  ) {
    final items = <_PaymentListItem>[];

    for (final group in loanGroups) {
      final date = DateTime.tryParse(group['date']?.toString() ?? '');
      if (date == null) continue;
      final groupItems = (group['items'] as List?) ?? const [];
      for (final item in groupItems) {
        final amount =
            ((item['paymentAmount'] ?? item['monthlyPayment'] ?? 0) as num)
                .toDouble();

        items.add(
          _PaymentListItem(
            date: date,
            title: item['name']?.toString() ?? 'Payment',
            amount: amount,
            isPaid: item['autoPay'] == true,
          ),
        );
      }
    }

    for (final cost in housingCosts) {
      if (cost.dueDate == null) continue;
      items.add(
        _PaymentListItem(
          date: cost.dueDate!,
          title: cost.name,
          amount: cost.amount,
          isPaid: cost.autoPay,
        ),
      );
    }

    for (final policy in policies) {
      if (policy.isOneTime || !policy.isActive) {
        continue;
      }
      final dates = InsuranceService.generateOccurrences(policy);
      for (final date in dates) {
        items.add(
          _PaymentListItem(
            date: date,
            title: policy.name,
            amount: policy.premium,
            isPaid: policy.autoPayEnabledForStatus,
          ),
        );
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    return items.where((item) => _isFutureOrToday(item.date)).toList();
  }

  Set<DateTime> _manualDaysFromItems(List<_PaymentListItem> items) {
    final days = <DateTime>{};
    for (final item in items) {
      if (!item.isPaid) {
        days.add(_normalizeDay(item.date));
      }
    }
    return days;
  }

  Set<DateTime> _paidDaysFromItems(List<_PaymentListItem> items) {
    final days = <DateTime>{};
    for (final item in items) {
      if (item.isPaid) {
        days.add(_normalizeDay(item.date));
      }
    }
    return days;
  }

  _PaymentListItem? _nextUpcomingItem(List<_PaymentListItem> items) {
    if (items.isEmpty) return null;
    return items.first;
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
      body: StreamBuilder<List<dynamic>>(
        stream: _loanService.streamUpcomingPayments(),
        builder: (context, loanSnapshot) {
          if (loanSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandRed),
            );
          }
          if (loanSnapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${loanSnapshot.error}',
                style: const TextStyle(color: brandRed),
              ),
            );
          }

          return StreamBuilder<List<HousingCost>>(
            stream: _housingService.streamHousingCosts(),
            builder: (context, housingSnapshot) {
              if (housingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: brandRed),
                );
              }
              if (housingSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${housingSnapshot.error}',
                    style: const TextStyle(color: brandRed),
                  ),
                );
              }

              return StreamBuilder<List<InsurancePolicy>>(
                stream: _insuranceService.streamInsurances(status: 'active'),
                builder: (context, insuranceSnapshot) {
                  if (insuranceSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: brandRed),
                    );
                  }
                  if (insuranceSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${insuranceSnapshot.error}',
                        style: const TextStyle(color: brandRed),
                      ),
                    );
                  }

                  final items = _combineItems(
                    loanSnapshot.data ?? [],
                    housingSnapshot.data ?? [],
                    insuranceSnapshot.data ?? [],
                  );
                  final manualDays = _manualDaysFromItems(items);
                  final paidDays = _paidDaysFromItems(items);
                  final nextUpcoming = _nextUpcomingItem(items);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        CalendarWidget(
                          calendarId: 'upcoming_payments_calendar',
                          manualDays: manualDays,
                          paidDays: paidDays,
                        ),
                        if (nextUpcoming != null) ...[
                          const SizedBox(height: 18),
                          _PrimaryUpcomingCard(item: nextUpcoming),
                        ],
                        const SizedBox(height: 32),
                        const Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No upcoming payments found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          Column(
                            children: items.map<Widget>((item) {
                              return PaymentCard(
                                month: DateFormat('MMM').format(item.date),
                                day: DateFormat('dd').format(item.date),
                                title: item.title,
                                amount:
                                    '\$${NumberFormat('#,##0.00').format(item.amount)}',
                                status: item.isPaid
                                    ? 'Paid Automatically'
                                    : 'Manual Payment Required',
                                isPaid: item.isPaid,
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 24),
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
                        const NotificationToggle(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PaymentListItem {
  final DateTime date;
  final String title;
  final double amount;
  final bool isPaid;

  const _PaymentListItem({
    required this.date,
    required this.title,
    required this.amount,
    required this.isPaid,
  });
}

class _PrimaryUpcomingCard extends StatelessWidget {
  final _PaymentListItem item;

  const _PrimaryUpcomingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final dateBoxBgColor = item.isPaid
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFFFEBEE);
    final dateTextColor = item.isPaid
        ? const Color(0xFF546E7A)
        : const Color(0xFF8D6E63);
    final difference = item.date.difference(DateTime.now()).inDays;
    final dueText = difference <= 0
        ? 'Due today'
        : 'Due in $difference day${difference == 1 ? '' : 's'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dateBoxBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(item.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: dateTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateFormat('dd').format(item.date),
                  style: TextStyle(
                    fontSize: 16,
                    color: dateTextColor,
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
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dueText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8F8F8F),
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
