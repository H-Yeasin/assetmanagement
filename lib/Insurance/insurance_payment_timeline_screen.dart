import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../Home_Dashboard/widgets.dart';
import '../shared/payment_timeline_helpers.dart';
import '../services/insurance_service.dart';
import 'insurance_widgets.dart';
import 'models/insurance_model.dart';

class InsurancePaymentTimelineScreen extends StatefulWidget {
  final InsurancePolicy? policy;

  const InsurancePaymentTimelineScreen({super.key, this.policy});

  @override
  State<InsurancePaymentTimelineScreen> createState() =>
      _InsurancePaymentTimelineScreenState();
}

class _InsurancePaymentTimelineScreenState
    extends State<InsurancePaymentTimelineScreen> {
  final InsuranceService _insuranceService = InsuranceService();
  StreamSubscription<List<InsurancePolicy>>? _subscription;
  List<InsurancePolicy> _policies = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  final List<String> _tabs = const ['All', 'Past', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    _insuranceService.ensureAllActiveInsuranceReminders();

    if (widget.policy != null) {
      _policies = [widget.policy!];
      _isLoading = false;
      _refreshSinglePolicy();
    } else {
      _subscription = _insuranceService.streamInsurances(status: 'active').listen(
        (policies) {
          if (!mounted) return;
          setState(() {
            _policies = policies;
            _isLoading = false;
            _error = null;
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshSinglePolicy() async {
    final id = widget.policy?.id;
    if (id == null) return;
    try {
      final policy = await _insuranceService.getInsurance(id);
      if (!mounted) return;
      setState(() => _policies = [policy]);
    } catch (_) {}
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _addMonths(DateTime date, int months) {
    final targetMonth = date.month + months;
    final targetYear = date.year + ((targetMonth - 1) ~/ 12);
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final lastDay = DateTime(targetYear, normalizedMonth + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(targetYear, normalizedMonth, day);
  }

  List<DateTime> _occurrencesFor(InsurancePolicy policy) {
    final today = _normalizeDay(DateTime.now());
    final futureCutoff = _addMonths(today, rollingTimelineFutureMonths);
    return InsuranceService.generateOccurrences(
      policy,
      from: DateTime(2020),
      to: futureCutoff,
    );
  }

  List<_InsuranceTimelineItem> _items({int? tab}) {
    final selectedTab = tab ?? _selectedTab;
    final today = _normalizeDay(DateTime.now());
    final items = <_InsuranceTimelineItem>[];

    for (final policy in _policies.where((policy) => policy.isActive)) {
      for (final date in _occurrencesFor(policy)) {
        final day = _normalizeDay(date);
        items.add(
          _InsuranceTimelineItem(
            policy: policy,
            date: day,
            isPast: day.isBefore(today),
          ),
        );
      }
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    if (selectedTab == 1) {
      return items.where((item) => item.isPast).toList().reversed.toList();
    }
    if (selectedTab == 2) {
      return items.where((item) => !item.isPast).toList();
    }
    return items;
  }

  Set<DateTime> _manualDays(List<_InsuranceTimelineItem> items) {
    return items
        .where((item) => !item.policy.autoPayEnabledForStatus)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  Set<DateTime> _paidDays(List<_InsuranceTimelineItem> items) {
    return items
        .where((item) => item.policy.autoPayEnabledForStatus)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  String _statusLabel(_InsuranceTimelineItem item) {
    if (item.policy.isOneTime) return item.policy.paymentStatusLabel;
    if (item.policy.autoPayEnabledForStatus) {
      return item.isPast ? 'Paid automatically' : 'Scheduled auto-payment';
    }
    return item.isPast ? 'Past scheduled payment' : 'Manual payment required';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.policy == null ? 'Payment Timeline' : widget.policy!.name;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandBlue))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: $_error', textAlign: TextAlign.center),
              ),
            )
          : Builder(
              builder: (context) {
                final items = _items();
                final calendarItems = _items(tab: 0);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      CalendarWidget(
                        calendarId: widget.policy == null
                            ? 'insurance_payment_timeline'
                            : 'insurance_payment_timeline_${widget.policy!.id ?? widget.policy!.name}',
                        paidDays: _paidDays(calendarItems),
                        manualDays: _manualDays(calendarItems),
                        sectionColor: brandBlue,
                      ),
                      const SizedBox(height: 16),
                      const TimelineInfoNote(),
                      const SizedBox(height: 24),
                      Row(
                        children: List.generate(_tabs.length, (index) {
                          final selected = _selectedTab == index;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index < _tabs.length - 1 ? 10 : 0,
                              ),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedTab = index),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected ? brandBlue : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? brandBlue
                                          : const Color(0xFFEDEDED),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _tabs[index],
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF555555),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Scheduled Insurance Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No scheduled insurance actions found.',
                              style: TextStyle(color: Color(0xFF888888)),
                            ),
                          ),
                        )
                      else
                        ...items.map(
                          (item) => UpcomingActionItem(
                            month: DateFormat('MMM').format(item.date),
                            day: DateFormat('dd').format(item.date),
                            title: item.policy.name,
                            status: _statusLabel(item),
                            amount: NumberFormat.simpleCurrency(
                              decimalDigits: 2,
                            ).format(item.policy.premium),
                            isAutoPay: item.policy.autoPayEnabledForStatus,
                            isWarrantyExpiry: item.policy.isOneTime,
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _InsuranceTimelineItem {
  final InsurancePolicy policy;
  final DateTime date;
  final bool isPast;

  const _InsuranceTimelineItem({
    required this.policy,
    required this.date,
    required this.isPast,
  });
}
