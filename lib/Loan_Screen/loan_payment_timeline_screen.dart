import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../Home_Dashboard/widgets.dart';
import '../shared/payment_timeline_helpers.dart';
import '../services/loan_service.dart';
import 'models/loan_model.dart';
import 'utils/loan_calculations.dart';

class LoanPaymentTimelineScreen extends StatefulWidget {
  final Loan? loan;

  const LoanPaymentTimelineScreen({super.key, this.loan});

  @override
  State<LoanPaymentTimelineScreen> createState() =>
      _LoanPaymentTimelineScreenState();
}

class _LoanPaymentTimelineScreenState extends State<LoanPaymentTimelineScreen> {
  final LoanService _loanService = LoanService();
  StreamSubscription<List<Loan>>? _subscription;
  List<Loan> _loans = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab = 0;

  final List<String> _tabs = const ['All', 'Past', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      _loans = [widget.loan!];
      _isLoading = false;
      _refreshSingleLoan();
    } else {
      _subscription = _loanService
          .streamLoans(status: 'active')
          .listen(
            (loans) {
              if (!mounted) return;
              setState(() {
                _loans = loans;
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

  Future<void> _refreshSingleLoan() async {
    final id = widget.loan?.id;
    if (id == null) return;
    try {
      final loan = await _loanService.getLoan(id);
      if (!mounted) return;
      setState(() => _loans = [loan]);
    } catch (_) {
      // Keep the passed-in loan available if refresh is unavailable.
    }
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<_TimelineItem> _items({int? tab}) {
    final selectedTab = tab ?? _selectedTab;
    final items = <_TimelineItem>[];
    final today = _normalizeDay(DateTime.now());

    for (final loan in _loans) {
      final start = loan.startDate ?? loan.paymentDate ?? today;
      final end =
          loan.endDate ??
          DateTime(
            today.year,
            today.month + rollingTimelineFutureMonths,
            today.day,
          );
      final dates = LoanCalculations.paymentOccurrences(
        loan,
        from: start,
        to: end,
        includePast: true,
      );
      for (final date in dates) {
        final day = _normalizeDay(date);
        items.add(
          _TimelineItem(loan: loan, date: day, isPast: day.isBefore(today)),
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

  Set<DateTime> _manualDays(List<_TimelineItem> items) {
    return items
        .where((item) => !item.loan.autoPay)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  Set<DateTime> _paidDays(List<_TimelineItem> items) {
    return items
        .where((item) => item.loan.autoPay)
        .map((item) => _normalizeDay(item.date))
        .toSet();
  }

  String _statusLabel(_TimelineItem item) {
    if (item.loan.autoPay) {
      return item.isPast ? 'Paid automatically' : 'Scheduled auto-payment';
    }
    return item.isPast ? 'Past scheduled payment' : 'Manual payment required';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.loan == null ? 'Payment Timeline' : widget.loan!.name;

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
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      CalendarWidget(
                        calendarId: widget.loan == null
                            ? 'loan_payment_timeline'
                            : 'loan_payment_timeline_${widget.loan!.id ?? widget.loan!.name}',
                        paidDays: _paidDays(calendarItems),
                        manualDays: _manualDays(calendarItems),
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
                            title: item.loan.name,
                            amount: NumberFormat.simpleCurrency(
                              decimalDigits: 2,
                            ).format(LoanCalculations.paymentAmount(item.loan)),
                            status: _statusLabel(item),
                            isPaid: item.loan.autoPay,
                            sectionColor: brandRed,
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _TimelineItem {
  final Loan loan;
  final DateTime date;
  final bool isPast;

  const _TimelineItem({
    required this.loan,
    required this.date,
    required this.isPast,
  });
}
