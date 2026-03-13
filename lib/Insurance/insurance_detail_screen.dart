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

  double _monthlyEquivalent() {
    final freq = _policy.paymentFrequency?.toLowerCase() ?? '';
    if (freq.contains('annually') || freq.contains('yearly')) {
      return _policy.premium / 12;
    }
    if (freq.contains('quarterly')) {
      return _policy.premium / 3;
    }
    return _policy.premium;
  }

  double _annualEquivalent() {
    final freq = _policy.paymentFrequency?.toLowerCase() ?? '';
    if (freq.contains('monthly')) {
      return _policy.premium * 12;
    }
    if (freq.contains('quarterly')) {
      return _policy.premium * 4;
    }
    return _policy.premium;
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
    if (_policy.id == null || baseDate == null) return;

    if (!_reminderEnabled) {
      final existing = await _apiService.createReminder(
        itemId: _policy.id!,
        itemType: 'insurance',
        title: 'Insurance Renewal: ${_policy.name}',
        remindAt: baseDate,
        note: 'Automatic renewal reminder for your insurance policy.',
      );
      await _apiService.updateReminderNotificationEnabled(
        existing['id'].toString(),
        false,
      );
      await NotificationService.cancelReminder(
        NotificationService.getNotificationId(existing['id'].toString()),
      );
      return;
    }

    DateTime scheduledDate = baseDate;
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

    final reminder = await _apiService.createReminder(
      itemId: _policy.id!,
      itemType: 'insurance',
      title: 'Insurance Renewal: ${_policy.name}',
      remindAt: scheduledDate,
      note: 'Automatic renewal reminder for your insurance policy.',
    );

    await _apiService.updateReminderNotificationEnabled(
      reminder['id'].toString(),
      true,
    );
    await NotificationService.scheduleReminder(
      id: NotificationService.getNotificationId(reminder['id'].toString()),
      title: reminder['title'] ?? 'Insurance Reminder',
      body: reminder['note'] ?? 'Upcoming insurance renewal.',
      scheduledDate: scheduledDate,
    );
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
    final String categoryDisp =
        _policy.category[0].toUpperCase() + _policy.category.substring(1);

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
                    color: brandRed,
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

            // Annual Payment Card
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
                  const Text(
                    'Annual Payment',
                    style: TextStyle(
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
                    'Monthly equivalent: \$${NumberFormat('#,##0.00').format(_monthlyEquivalent())}',
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
                        color: brandRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Additional Details',
                      style: TextStyle(
                        color: brandRed,
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
                      border: Border.all(color: brandRed),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: brandRed, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Documents',
                          style: TextStyle(
                            color: brandRed,
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
            Container(
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
                          '${_policy.documents.length} Documents',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF111111),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _policy.documents.isNotEmpty
                              ? (_policy.documents.first is String
                                    ? _policy.documents.first
                                    : (_policy.documents.first
                                              as Map)['displayName'] ??
                                          'document')
                              : 'No documents',
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
                    activeTrackColor: brandRed,
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
                  const Icon(Icons.payment, color: brandRed, size: 40),
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
