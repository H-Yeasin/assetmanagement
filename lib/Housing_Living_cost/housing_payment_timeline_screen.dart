import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../Home_Dashboard/widgets.dart';
import '../shared/payment_timeline_helpers.dart';
import '../services/housing_service.dart';
import 'models/housing_cost_model.dart';

class HousingPaymentTimelineScreen extends StatefulWidget {
  final HousingCost? cost;

  const HousingPaymentTimelineScreen({super.key, this.cost});

  @override
  State<HousingPaymentTimelineScreen> createState() =>
      _HousingPaymentTimelineScreenState();
}

class _HousingPaymentTimelineScreenState
    extends State<HousingPaymentTimelineScreen> {
  final HousingService _housingService = HousingService();
  StreamSubscription<List<HousingCost>>? _subscription;
  List<HousingCost> _costs = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  final List<String> _tabs = const ['All', 'Past', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    if (widget.cost != null) {
      _costs = [widget.cost!];
      _isLoading = false;
      _refreshSingleCost();
    } else {
      _subscription = _housingService.streamHousingCosts().listen(
        (costs) {
          if (!mounted) return;
          setState(() {
            _costs = costs.where((cost) => cost.dueDate != null).toList();
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

  Future<void> _refreshSingleCost() async {
    final id = widget.cost?.id;
    if (id == null) return;
    try {
      final cost = await _housingService.getHousingCost(id);
      if (!mounted) return;
      setState(() => _costs = [cost]);
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

  List<DateTime> _occurrencesFor(HousingCost cost) {
    final baseDate = cost.dueDate;
    if (baseDate == null) return const [];

    final today = _normalizeDay(DateTime.now());
    final start = _normalizeDay(baseDate);
    final futureCutoff = _addMonths(today, rollingTimelineFutureMonths);
    final dates = <DateTime>[];
    var current = start;
    var guard = 0;
    while (!current.isAfter(futureCutoff) && guard < 240) {
      dates.add(current);
      current = _addMonths(current, 1);
      guard++;
    }
    return dates;
  }

  List<_HousingTimelineItem> _items({int? tab}) {
    final selectedTab = tab ?? _selectedTab;
    final today = _normalizeDay(DateTime.now());
    final items = <_HousingTimelineItem>[];

    for (final cost in _costs) {
      for (final date in _occurrencesFor(cost)) {
        final day = _normalizeDay(date);
        items.add(
          _HousingTimelineItem(
            cost: cost,
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

  Set<DateTime> _manualDays(List<_HousingTimelineItem> items) {
    return items
        .where((item) => !item.cost.autoPay)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  Set<DateTime> _paidDays(List<_HousingTimelineItem> items) {
    return items
        .where((item) => item.cost.autoPay)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  String _statusLabel(_HousingTimelineItem item) {
    if (item.cost.autoPay) {
      return item.isPast ? 'Paid automatically' : 'Scheduled auto-payment';
    }
    return item.isPast ? 'Past scheduled payment' : 'Manual payment required';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.cost == null ? 'Payment Timeline' : widget.cost!.name;

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
          ? const Center(child: CircularProgressIndicator(color: brandRed))
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
                final hasOpenEndedItems = _costs.any((cost) => cost.dueDate != null);
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      CalendarWidget(
                        calendarId: widget.cost == null
                            ? 'housing_payment_timeline'
                            : 'housing_payment_timeline_${widget.cost!.id ?? widget.cost!.name}',
                        paidDays: _paidDays(calendarItems),
                        manualDays: _manualDays(calendarItems),
                      ),
                      if (hasOpenEndedItems) ...[
                        const SizedBox(height: 16),
                        const TimelineInfoNote(),
                      ],
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
                                    color: selected ? brandRed : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? brandRed
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
                        'Scheduled Payments',
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
                              'No scheduled payments found.',
                              style: TextStyle(color: Color(0xFF888888)),
                            ),
                          ),
                        )
                      else
                        ...items.map(
                          (item) => PaymentCard(
                            month: DateFormat('MMM').format(item.date),
                            day: DateFormat('dd').format(item.date),
                            title: item.cost.name,
                            amount: NumberFormat.simpleCurrency(
                              decimalDigits: 2,
                            ).format(item.cost.amount),
                            status: _statusLabel(item),
                            isPaid: item.cost.autoPay,
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

class _HousingTimelineItem {
  final HousingCost cost;
  final DateTime date;
  final bool isPast;

  const _HousingTimelineItem({
    required this.cost,
    required this.date,
    required this.isPast,
  });
}
