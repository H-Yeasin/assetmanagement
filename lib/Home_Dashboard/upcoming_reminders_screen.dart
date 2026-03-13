import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../Home_Dashboard/widgets.dart';
import '../services/housing_service.dart';
import '../services/insurance_service.dart';
import '../services/loan_service.dart';
import '../services/notification_service.dart';

class UpcomingRemindersScreen extends StatefulWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  State<UpcomingRemindersScreen> createState() =>
      _UpcomingRemindersScreenState();
}

class _UpcomingRemindersScreenState extends State<UpcomingRemindersScreen> {
  final LoanService _loanService = LoanService();
  final HousingService _housingService = HousingService();
  final InsuranceService _insuranceService = InsuranceService();

  bool _globalNotificationsEnabled = true;
  bool _isUpdatingGlobalToggle = false;

  @override
  void initState() {
    super.initState();
    _loadGlobalNotificationPreference();
  }

  Future<void> _loadGlobalNotificationPreference() async {
    final enabled = await NotificationService.areReminderNotificationsEnabled();
    if (!mounted) return;
    setState(() => _globalNotificationsEnabled = enabled);
  }

  DateTime _normalizeDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<List<_ReminderViewModel>> _buildReminderViewModels(
    List<dynamic> reminders,
  ) async {
    return Future.wait(
      reminders.map((reminder) async {
        final remindAt = (reminder['remindAt'] as dynamic).toDate() as DateTime;
        final isAuto = await _resolveAutoStatus(
          reminder['itemType']?.toString(),
          reminder['itemId']?.toString(),
        );

        return _ReminderViewModel(
          id: reminder['id']?.toString() ?? '',
          title: reminder['title']?.toString() ?? 'Task',
          note: reminder['note']?.toString() ?? 'Reminder',
          remindAt: remindAt,
          itemType: reminder['itemType']?.toString() ?? '',
          itemId: reminder['itemId']?.toString() ?? '',
          notificationEnabled: reminder['notificationEnabled'] != false,
          isAuto: isAuto,
        );
      }),
    );
  }

  Future<bool> _resolveAutoStatus(String? itemType, String? itemId) async {
    if (itemType == null || itemId == null || itemId.isEmpty) return false;

    try {
      switch (itemType) {
        case 'loan':
          final loan = await _loanService.getLoan(itemId);
          return loan.autoPay;
        case 'housing':
          final cost = await _housingService.getHousingCost(itemId);
          return cost.autoPay;
        case 'insurance':
          final insurance = await _insuranceService.getInsurance(itemId);
          return insurance.isAutoPay ?? false;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _markAsDone(_ReminderViewModel reminder) async {
    try {
      await _loanService.markReminderDone(reminder.id);
      await NotificationService.cancelReminder(
        NotificationService.getNotificationId(reminder.id),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark reminder as done: $e')),
      );
    }
  }

  Future<void> _toggleReminder(
    _ReminderViewModel reminder,
    bool enabled,
  ) async {
    try {
      await _loanService.updateReminderNotificationEnabled(reminder.id, enabled);

      final notificationId = NotificationService.getNotificationId(reminder.id);
      if (!enabled || !_globalNotificationsEnabled) {
        await NotificationService.cancelReminder(notificationId);
      } else {
        await NotificationService.scheduleReminder(
          id: notificationId,
          title: reminder.title,
          body: reminder.note,
          scheduledDate: reminder.remindAt,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Reminder turned on successfully.'
                : 'Reminder turned off successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reminder: $e')),
      );
    }
  }

  Future<void> _toggleGlobalNotifications(bool enabled) async {
    setState(() => _isUpdatingGlobalToggle = true);
    try {
      await NotificationService.setReminderNotificationsEnabled(enabled);
      if (!mounted) return;
      setState(() => _globalNotificationsEnabled = enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabled
                ? 'Reminder notifications are on.'
                : 'Reminder notifications are off.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notifications: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingGlobalToggle = false);
      }
    }
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
          'Upcoming Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _loanService.streamUpcomingReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: brandRed),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: brandRed),
              ),
            );
          }

          final reminders = snapshot.data ?? [];
          return FutureBuilder<List<_ReminderViewModel>>(
            future: _buildReminderViewModels(reminders),
            builder: (context, reminderSnapshot) {
              if (reminderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: brandRed),
                );
              }
              if (reminderSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${reminderSnapshot.error}',
                    style: const TextStyle(color: brandRed),
                  ),
                );
              }

              final reminderItems = reminderSnapshot.data ?? [];
              final manualDays = reminderItems
                  .where((item) => !item.isAuto)
                  .map((item) => _normalizeDay(item.remindAt))
                  .toSet();
              final paidDays = reminderItems
                  .where((item) => item.isAuto)
                  .map((item) => _normalizeDay(item.remindAt))
                  .toSet();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    CalendarWidget(
                      calendarId: 'upcoming_reminders_calendar',
                      manualDays: manualDays,
                      paidDays: paidDays,
                      initialFocusedDay: reminderItems.isNotEmpty
                          ? reminderItems.first.remindAt
                          : DateTime.now(),
                    ),
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
                    if (reminderItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No upcoming reminders.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: reminderItems
                            .map(
                              (item) => _ReminderListTile(
                                reminder: item,
                                notificationsAllowed:
                                    _globalNotificationsEnabled,
                                onToggle: (enabled) =>
                                    _toggleReminder(item, enabled),
                                onMarkDone: () => _markAsDone(item),
                              ),
                            )
                            .toList(),
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
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        NotificationToggle(
                          initialValue: _globalNotificationsEnabled,
                          onChanged: _toggleGlobalNotifications,
                        ),
                        if (_isUpdatingGlobalToggle)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: brandRed,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReminderViewModel {
  final String id;
  final String title;
  final String note;
  final DateTime remindAt;
  final String itemType;
  final String itemId;
  final bool notificationEnabled;
  final bool isAuto;

  const _ReminderViewModel({
    required this.id,
    required this.title,
    required this.note,
    required this.remindAt,
    required this.itemType,
    required this.itemId,
    required this.notificationEnabled,
    required this.isAuto,
  });
}

class _ReminderListTile extends StatelessWidget {
  final _ReminderViewModel reminder;
  final bool notificationsAllowed;
  final ValueChanged<bool> onToggle;
  final VoidCallback onMarkDone;

  const _ReminderListTile({
    required this.reminder,
    required this.notificationsAllowed,
    required this.onToggle,
    required this.onMarkDone,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = notificationsAllowed && reminder.notificationEnabled;
    final statusColor = reminder.isAuto ? const Color(0xFF2196F3) : brandRed;
    final statusBackground = reminder.isAuto
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(reminder.remindAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateFormat('dd').format(reminder.remindAt),
                      style: const TextStyle(
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
                    Text(
                      reminder.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.note,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('MMM dd, yyyy • hh:mm a').format(
                        reminder.remindAt,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: notificationsAllowed ? onToggle : null,
                activeThumbColor: Colors.white,
                activeTrackColor: brandRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  reminder.isAuto
                      ? 'Paid Automatically'
                      : 'Manual Action Required',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onMarkDone,
                child: const Text('Mark Done'),
              ),
            ],
          ),
          if (!notificationsAllowed)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Global reminder notifications are turned off.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
