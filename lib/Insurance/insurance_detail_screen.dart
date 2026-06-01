import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import '../services/insurance_service.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/insurance_model.dart';
import 'insurance_widgets.dart';

class InsuranceDetailScreen extends StatefulWidget {
  final InsurancePolicy policy;

  const InsuranceDetailScreen({super.key, required this.policy});

  @override
  State<InsuranceDetailScreen> createState() => _InsuranceDetailScreenState();
}

class _InsuranceDetailScreenState extends State<InsuranceDetailScreen> {
  final InsuranceService _apiService = InsuranceService();
  late InsurancePolicy _policy;
  bool _reminderEnabled = true;
  String _selectedReminder = 'Same day';
  DateTime? _baseReminderDate;
  final List<String> _reminderTimings = [
    'Same day',
    '1 day before',
    '3 days before',
    '1 week before',
  ];

  FirebaseFirestore get _firestore => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'ffpvault',
  );

  double _monthlyEquivalent() {
    return _policy.monthlyEquivalent;
  }

  double _annualEquivalent() {
    return _policy.annualEquivalent;
  }

  String _paymentSummaryTitle() {
    if (_policy.isOneTime) {
      return _policy.isWarranty ? 'One-time Warranty Cost' : 'One-time Payment';
    }
    return 'Annual Payment';
  }

  String _paymentSummarySubtitle() {
    if (_policy.isOneTime) {
      return 'Excluded from monthly payment totals';
    }
    return 'Monthly equivalent: \$${NumberFormat('#,##0.00').format(_monthlyEquivalent())}';
  }

  DateTime? _nextScheduleDate() {
    final dates = InsuranceService.generateOccurrences(_policy);
    return dates.isEmpty ? null : dates.first;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String _scheduleLabel() {
    if (_policy.isOneTime) return 'One-time';
    final frequency = _policy.paymentFrequency;
    if (frequency == null || frequency.trim().isEmpty) return 'Monthly';
    return frequency;
  }

  String _categoryDisplay() {
    if (_policy.isWarranty) return 'Warranty';
    return _policy.category[0].toUpperCase() + _policy.category.substring(1);
  }

  @override
  void initState() {
    super.initState();
    _policy = widget.policy;
    _refreshPolicy();
    _fetchReminder();
  }

  Future<void> _fetchReminder() async {
    try {
      final snapshot =
          await FirebaseFirestore.instanceFor(
                app: Firebase.app(),
                databaseId: 'ffpvault',
              )
              .collection('reminders')
              .where('itemId', isEqualTo: _policy.id)
              .where('itemType', isEqualTo: 'insurance')
              .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _baseReminderDate = (data['remindAt'] as Timestamp).toDate();
        });
      }
    } catch (e) {
      debugPrint('Error fetching reminder: $e');
    }
  }

  Future<void> _rescheduleNotification() async {
    final baseDate = _baseReminderDate ?? _policy.renewalDate;
    if (_policy.id == null) return;
    if (_policy.id == null) return;

    if (!_reminderEnabled) {
      final snapshot = await _firestore
          .collection('reminders')
          .where('itemId', isEqualTo: _policy.id)
          .where('itemType', isEqualTo: 'insurance')
          .where('isDone', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await _apiService.updateReminderNotificationEnabled(doc.id, false);
        await NotificationService.cancelReminder(
          NotificationService.getNotificationId(doc.id),
        );
      }
      return;
    }

    await _apiService.ensureRecurringReminders(_policy);

    DateTime scheduledDate = baseDate ?? DateTime.now();
    if (baseDate != null) {
      switch (_selectedReminder) {
        case '1 day before':
          scheduledDate = baseDate.subtract(const Duration(days: 1));
          break;
        case '3 days before':
          scheduledDate = baseDate.subtract(const Duration(days: 3));
          break;
        case '1 week before':
          scheduledDate = baseDate.subtract(const Duration(days: 7));
          break;
        default:
          break;
      }
    }

    final pendingSnapshot = await _firestore
        .collection('reminders')
        .where('itemId', isEqualTo: _policy.id)
        .where('itemType', isEqualTo: 'insurance')
        .where('isDone', isEqualTo: false)
        .orderBy('remindAt')
        .limit(1)
        .get();

    if (pendingSnapshot.docs.isNotEmpty) {
      final firstReminder = pendingSnapshot.docs.first;
      await _apiService.updateReminderNotificationEnabled(
        firstReminder.id,
        true,
      );
      await NotificationService.scheduleReminder(
        id: NotificationService.getNotificationId(firstReminder.id),
        title: 'Insurance Reminder',
        body: 'Upcoming insurance renewal.',
        scheduledDate: scheduledDate,
      );
    }
  }

  Future<void> _refreshPolicy() async {
    if (_policy.id == null) return;
    try {
      final updated = await _apiService.getInsurance(_policy.id!);
      if (mounted) setState(() => _policy = updated);
    } catch (_) {}
  }

  void _showPaymentModal() {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 343,
                child: InsurancePaymentModal(
                  policy: _policy,
                  onPaymentConfirmed: _refreshPolicy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderModal() {
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(color: Colors.transparent),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 343,
                child: InsuranceReminderModal(policy: _policy),
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _fetchReminder());
  }

  @override
  Widget build(BuildContext context) {
    final String categoryDisp = _categoryDisplay();
    final nextScheduleDate = _nextScheduleDate();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(
            Icons.arrow_back,
            color: Color(0xFF111111),
            size: 24,
          ),
        ),
        title: Text(
          '$categoryDisp Insurance',
          style: const TextStyle(
            color: Color(0xFF111111),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await context.push(
                '/edit-insurance',
                extra: _policy,
              );
              if (result == true) _refreshPolicy();
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: brandBlue,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Payment Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _paymentSummaryTitle(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${NumberFormat('#,##0.00').format(_annualEquivalent())}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _paymentSummarySubtitle(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ScheduleRow(label: 'Schedule', value: _scheduleLabel()),
                  _ScheduleRow(
                    label: _policy.isOneTime ? 'Paid on' : 'Next Payment',
                    value: _formatDate(nextScheduleDate),
                  ),
                  _ScheduleRow(
                    label: 'Start Date',
                    value: _formatDate(_policy.startDate),
                  ),
                  _ScheduleRow(
                    label: _policy.isOneTime ? 'End Date' : 'Renewal Date',
                    value: _formatDate(_policy.renewalDate ?? _policy.endDate),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            if (_policy.isOneTime)
              _ActionBox(
                label: 'Remind',
                iconPath: 'assets/images/insurance/remind.png',
                onTap: _showReminderModal,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _ActionBox(
                      label: 'Pay',
                      iconPath: 'assets/images/insurance/pay.png',
                      onTap: _showPaymentModal,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionBox(
                      label: 'Remind',
                      iconPath: 'assets/images/insurance/remind.png',
                      onTap: _showReminderModal,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            // Additional Details Button
            GestureDetector(
              onTap: () =>
                  context.push('/insurance-additional-details', extra: _policy),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF0F0F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/insurance/additionaldetailicon.png',
                      width: 18,
                      height: 18,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.grid_view_rounded,
                        color: brandBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        color: brandBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    '/insurance-add-documents',
                    extra: {'policy': _policy},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: brandBlue),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: brandBlue, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Documents',
                          style: TextStyle(
                            color: brandBlue,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<int>(
              stream: _apiService.streamDocumentsCountForRelated(
                _policy.id ?? '',
              ),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/insurance/doccument.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$count ${count == 1 ? 'Document' : 'Documents'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF111111),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _policy.name,
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              'Reminders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/insurance/reminder.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Reminders',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF111111),
                          ),
                        ),
                        Text(
                          _selectedReminder == 'Same day'
                              ? 'On the due date'
                              : '$_selectedReminder date',
                          style: const TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReminder,
                          isDense: true,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Color(0xFF888888),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF555555),
                          ),
                          items: _reminderTimings
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            setState(() => _selectedReminder = val!);
                            _rescheduleNotification();
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch(
                    value: _reminderEnabled,
                    onChanged: (v) {
                      setState(() => _reminderEnabled = v);
                      _rescheduleNotification();
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: brandBlue,
                    trackOutlineColor: WidgetStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Text(
                _policy.coverageNotes ?? 'No notes available.',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String label;
  final String value;

  const _ScheduleRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF111111),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBox extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;

  const _ActionBox({
    required this.label,
    required this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: 48,
              height: 48,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.payment, color: brandBlue, size: 40),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
