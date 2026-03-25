import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/housing_cost_model.dart';
import '../services/housing_service.dart';
import '../services/notification_service.dart';
import 'housing_widgets.dart';
import 'housing_additional_details_screen.dart';
import 'edit_housing_cost_screen.dart';

import 'housing_add_documents_screen.dart';

class HousingCostDetailScreen extends StatefulWidget {
  final HousingCost cost;

  const HousingCostDetailScreen({super.key, required this.cost});

  @override
  State<HousingCostDetailScreen> createState() =>
      _HousingCostDetailScreenState();
}

class _HousingCostDetailScreenState extends State<HousingCostDetailScreen> {
  final HousingService _apiService = HousingService();
  late HousingCost _cost;

  bool _reminderEnabled = true;
  String _reminderTiming = 'Same day';
  DateTime? _baseReminderDate;

  final List<String> _reminderTimings = [
    'Same day',
    '1 day before',
    '3 days before',
    '1 week before',
  ];

  @override
  void initState() {
    super.initState();
    _cost = widget.cost;
    _refreshCost();
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
              .where('itemId', isEqualTo: _cost.id)
              .where('itemType', isEqualTo: 'housing')
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
    final baseDate = _baseReminderDate ?? _cost.dueDate;
    if (_cost.id == null || baseDate == null) return;

    if (!_reminderEnabled) {
      final existing = await _apiService.createReminder(
        itemId: _cost.id!,
        itemType: 'housing',
        title: 'Payment Reminder: ${_cost.name}',
        remindAt: baseDate,
        note: 'Reminder for ${_cost.category} payment.',
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
    switch (_reminderTiming) {
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
      itemId: _cost.id!,
      itemType: 'housing',
      title: 'Payment Reminder: ${_cost.name}',
      remindAt: scheduledDate,
      note: 'Reminder for ${_cost.category} payment.',
    );

    await _apiService.updateReminderNotificationEnabled(
      reminder['id'].toString(),
      true,
    );
    await NotificationService.scheduleReminder(
      id: NotificationService.getNotificationId(reminder['id'].toString()),
      title: reminder['title'] ?? 'Housing Payment Reminder',
      body: reminder['note'] ?? 'Reminder for housing payment.',
      scheduledDate: scheduledDate,
    );
  }

  Future<void> _refreshCost() async {
    if (_cost.id == null) return;
    try {
      final updated = await _apiService.getHousingCost(_cost.id!);
      if (mounted) setState(() => _cost = updated);
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
                child: HousingPaymentModal(
                  cost: _cost,
                  onPaymentConfirmed: _refreshCost,
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
                child: HousingReminderModal(cost: _cost),
              ),
            ),
          ),
        ],
      ),
    ).then((_) => _fetchReminder());
  }

  Future<void> _toggleAutoPay(bool value) async {
    try {
      final updated = await _apiService.updateHousingCost(_cost.id!, {
        'autoPay': value,
      });
      if (mounted) setState(() => _cost = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String get _categoryLabel {
    final catInfo = HousingCost.displayCategories.firstWhere(
      (c) => c['id'] == _cost.category,
      orElse: () => {'label': _cost.category},
    );
    return catInfo['label'] ?? _cost.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F5),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _categoryLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditHousingCostScreen(cost: _cost),
                        ),
                      );
                      if (result == true) _refreshCost();
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC61C36),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // ── Summary Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE7E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Monthly Payment:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat('#,##0.00').format(_cost.amount),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pay / Remind ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/setup_payment.png',
                            label: 'Pay',
                            onTap: _showPaymentModal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/remind.png',
                            label: 'Remind',
                            onTap: _showReminderModal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Additional Details ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                HousingAdditionalDetailsScreen(cost: _cost),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/icon/additional_detail.png',
                              width: 18,
                              height: 18,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.apps,
                                color: Color(0xFFC61C36),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Additional Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFC61C36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Documents ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Documents',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HousingAddDocumentsScreen(
                                  cost: _cost,
                                  initialDocuments: null,
                                ),
                              ),
                            );
                            if (result != null &&
                                result is List<Map<String, dynamic>>) {
                              await _refreshCost();
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add,
                                color: Color(0xFFC61C36),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Add Documents',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFC61C36),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Document list
                    StreamBuilder<int>(
                      stream: _apiService.streamDocumentsCountForRelated(
                        _cost.id ?? '',
                      ),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: HousingCost.iconBgColorForCategory(
                                    _cost.category,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  HousingCost.iconForCategory(_cost.category),
                                  width: 20,
                                  height: 20,
                                  errorBuilder: (c, e, s) =>
                                      const Icon(Icons.folder, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$count ${count == 1 ? 'Document' : 'Documents'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF111111),
                                      ),
                                    ),
                                    Text(
                                      _cost.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ── Auto-payment Toggle ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE7E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.repeat,
                              color: Color(0xFFC61C36),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Auto-payment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Text(
                                  'Pay automatic every month',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _cost.autoPay,
                            onChanged: _toggleAutoPay,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFFC61C36),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Reminders ──
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE7E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/icon/remind.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.notifications,
                                size: 20,
                                color: Color(0xFFC61C36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Reminders',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                Text(
                                  _reminderTiming == 'Same day'
                                      ? 'On the due date'
                                      : '$_reminderTiming date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFEEEEEE),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _reminderTiming,
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
                                    setState(() => _reminderTiming = val!);
                                    _rescheduleNotification();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _reminderEnabled,
                            onChanged: (v) {
                              setState(() => _reminderEnabled = v);
                              _rescheduleNotification();
                            },
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFFC61C36),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Notes ──
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _cost.notes?.isNotEmpty == true
                            ? _cost.notes!
                            : 'No notes added yet.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF555555),
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.iconPath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Image.asset(
              iconPath,
              width: 32,
              height: 32,
              errorBuilder: (c, e, s) => const Icon(Icons.image, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
