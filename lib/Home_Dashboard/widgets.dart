import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

const Color brandRed = Color(0xFFC61C36);
const Color brandBlue = Color(0xFF2196F3);
const Color brandPurple = Color(0xFF8E44AD);

// ── Category Card ────────────────────────────────────────────────────────────
class CategoryCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final String subtext;
  final Color iconColor;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.subtext = "",
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(iconPath, width: 20, height: 20),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                subtext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder Card ────────────────────────────────────────────────────────────
class ReminderCard extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String dueInfo;
  final String? detailInfo;
  final Color? detailColor;
  final Color? sectionColor;
  final VoidCallback onTap;

  const ReminderCard({
    super.key,
    required this.month,
    required this.day,
    required this.title,
    required this.dueInfo,
    this.detailInfo,
    this.detailColor,
    this.sectionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateBoxBgColor =
        sectionColor?.withValues(alpha: 0.1) ?? const Color(0xFFF8E8EA);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: dateBoxBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      day,
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
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dueInfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: detailColor ?? const Color(0xFF888888),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (detailInfo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        detailInfo!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment Card ─────────────────────────────────────────────────────────────
class PaymentCard extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String amount;
  final String status;
  final bool isPaid;
  final Color? sectionColor;

  const PaymentCard({
    super.key,
    required this.month,
    required this.day,
    required this.title,
    required this.amount,
    required this.status,
    required this.isPaid,
    this.sectionColor,
  });

  @override
  Widget build(BuildContext context) {
    final manualColor = sectionColor ?? brandRed;
    // Colors based on the screenshot (Light blue for paid, Light red for manual)
    final statusColor = isPaid ? const Color(0xFF2196F3) : manualColor;
    final statusBgColor = isPaid
        ? const Color(0xFFE3F2FD)
        : manualColor.withValues(alpha: 0.1);

    // The date box uses the same light blue for 'paid automatically' but light red for manual in the design
    final dateBoxBgColor = isPaid
        ? const Color(0xFFE3F2FD)
        : manualColor.withValues(alpha: 0.1);
    final dateTextColor = isPaid
        ? const Color(0xFF546E7A)
        : manualColor.withValues(alpha: 0.8);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: TextStyle(
                    fontSize: 12,
                    color: dateTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontSize: 14,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF555555),
                      ),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid ? Icons.sync : Icons.priority_high,
                        color: statusColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
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

// ── Add Item Bottom Sheet ────────────────────────────────────────────────────
class AddItemBottomSheet extends StatelessWidget {
  const AddItemBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Add New Item',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a Category and add something\nyou want to keep organized.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.25,
            children: [
              _CategoryOption(
                iconPath: 'assets/images/icon/loan.png',
                title: 'Loans',
                iconColor: brandRed,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/my-loans');
                },
              ),
              _CategoryOption(
                iconPath: 'assets/images/icon/housing.png',
                title: 'Housing / Living Costs',
                iconColor: brandPurple,
                onTap: () {
                  Navigator.pop(context);
                  context.go('/housing-costs');
                },
              ),
              _CategoryOption(
                iconPath: 'assets/images/icon/insurance.png',
                title: 'Insurance',
                iconColor: brandBlue,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/my-insurances');
                },
              ),
              _CategoryOption(
                iconPath: 'assets/images/icon/doccument.png',
                title: 'Documents',
                iconColor: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/vault');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String iconPath;
  final String title;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.iconPath,
    required this.title,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Image.asset(iconPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Realistic Calendar Widget (TableCalendar) ───────────────────────────────
class CalendarWidget extends StatefulWidget {
  final Set<DateTime> paidDays;
  final Set<DateTime> manualDays;
  final DateTime? initialFocusedDay;
  final String calendarId;
  final Color? sectionColor;

  const CalendarWidget({
    super.key,
    this.paidDays = const {},
    this.manualDays = const {},
    this.initialFocusedDay,
    required this.calendarId,
    this.sectionColor,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  String get _focusedStorageKey => '${widget.calendarId}_focused_day';
  String get _selectedStorageKey => '${widget.calendarId}_selected_day';

  Color get _manualColor => widget.sectionColor ?? brandRed;

  @override
  void initState() {
    super.initState();
    final initialFocused = _normalizedDay(
      widget.initialFocusedDay ?? DateTime.now(),
    );
    final storedFocused =
        PageStorage.maybeOf(
              context,
            )?.readState(context, identifier: _focusedStorageKey)
            as DateTime?;
    final storedSelected =
        PageStorage.maybeOf(
              context,
            )?.readState(context, identifier: _selectedStorageKey)
            as DateTime?;

    _focusedDay = _normalizedDay(storedFocused ?? initialFocused);
    _selectedDay = storedSelected != null
        ? _normalizedDay(storedSelected)
        : _focusedDay;
  }

  DateTime _normalizedDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  void _persistCalendarState() {
    final storage = PageStorage.maybeOf(context);
    storage?.writeState(context, _focusedDay, identifier: _focusedStorageKey);
    storage?.writeState(context, _selectedDay, identifier: _selectedStorageKey);
  }

  void _updateFocusedDay(DateTime focusedDay, {DateTime? selectedDay}) {
    setState(() {
      _focusedDay = _normalizedDay(focusedDay);
      if (selectedDay != null) {
        _selectedDay = _normalizedDay(selectedDay);
      }
    });
    _persistCalendarState();
  }

  bool _hasManualMarker(DateTime date) =>
      widget.manualDays.contains(_normalizedDay(date));

  bool _hasPaidMarker(DateTime date) =>
      widget.paidDays.contains(_normalizedDay(date));

  Widget _buildDayCell(
    DateTime date, {
    required bool isSelected,
    required bool isToday,
  }) {
    final hasManualMarker = _hasManualMarker(date);
    final hasPaidMarker = _hasPaidMarker(date);
    final markerColor = hasManualMarker
        ? _manualColor
        : hasPaidMarker
        ? const Color(0xFF8FD3F4)
        : null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFB3E5FC)
            : isToday
            ? _manualColor.withValues(alpha: 0.2)
            : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              fontWeight: isSelected || isToday
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: isToday && !isSelected
                  ? _manualColor
                  : const Color(0xFF111111),
            ),
          ),
          if (markerColor != null)
            Positioned(
              bottom: 6,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.day,
      helpText: 'Select Month',
    );
    if (picked != null) {
      _updateFocusedDay(DateTime(picked.year, picked.month, 1));
    }
  }

  void _showYearPicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            selectedDate: _focusedDay,
            onChanged: (DateTime dateTime) {
              Navigator.pop(context);
              _updateFocusedDay(DateTime(dateTime.year, _focusedDay.month, 1));
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF888888)),
                onPressed: () {
                  _updateFocusedDay(
                    DateTime(_focusedDay.year, _focusedDay.month - 1, 1),
                  );
                },
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _showMonthPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            months[_focusedDay.month - 1],
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showYearPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${_focusedDay.year}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF888888)),
                onPressed: () {
                  _updateFocusedDay(
                    DateTime(_focusedDay.year, _focusedDay.month + 1, 1),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              _updateFocusedDay(focusedDay, selectedDay: selectedDay);
            },
            onPageChanged: (focusedDay) => _updateFocusedDay(focusedDay),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerVisible: false,
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: _manualColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFB3E5FC),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Color(0xFF111111),
                fontWeight: FontWeight.w700,
              ),
              todayTextStyle: TextStyle(
                color: _manualColor,
                fontWeight: FontWeight.w700,
              ),
              defaultTextStyle: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14,
              ),
              outsideDaysVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) =>
                  _buildDayCell(date, isSelected: false, isToday: false),
              todayBuilder: (context, date, _) =>
                  _buildDayCell(date, isSelected: false, isToday: true),
              selectedBuilder: (context, date, _) =>
                  _buildDayCell(date, isSelected: true, isToday: false),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CalendarLegend(
                color: const Color(0xFFB3E5FC),
                label: 'Paid automatically',
              ),
              const SizedBox(width: 16),
              _CalendarLegend(
                color: _manualColor,
                label: 'Manual action required',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _CalendarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
        ),
      ],
    );
  }
}

// ── Notification Toggle ──────────────────────────────────────────────────────
class NotificationToggle extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const NotificationToggle({
    super.key,
    this.initialValue = true,
    this.onChanged,
  });

  @override
  State<NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<NotificationToggle> {
  late bool _isOn;

  @override
  void initState() {
    super.initState();
    _isOn = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant NotificationToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _isOn = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/icon/notification.png',
              width: 22,
              height: 22,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notification',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Global alerts for your peace of mind',
                  style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Switch(
            value: _isOn,
            onChanged: (v) {
              setState(() => _isOn = v);
              widget.onChanged?.call(v);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: brandRed,
          ),
        ],
      ),
    );
  }
}

// ── Custom Bottom Nav Bar ────────────────────────────────────────────────────
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(26),
          topRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            imageAsset: 'assets/images/icon/home_bottom.png',
            activeImageAsset: 'assets/images/icon/active_home_bottom.png',
            label: 'Home',
            isSelected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.add_circle_outline,
            activeIcon: Icons.add_circle,
            label: 'Add',
            isSelected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            imageAsset: 'assets/images/icon/vault_bottom_nevigation.png',
            activeImageAsset:
                'assets/images/icon/active_vault_bottom_nevigation.png',
            label: 'Vault',
            isSelected: currentIndex == 2,
            onTap: () => onTap(2),
          ),
          _NavItem(
            imageAsset: 'assets/images/icon/profile_icon.png',
            activeImageAsset: 'assets/images/icon/active_profile_icon.png',
            label: 'Profile',
            isSelected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData? icon;
  final IconData? activeIcon;

  // Optional image assets
  final String? imageAsset;
  final String? activeImageAsset;

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    this.icon,
    this.activeIcon,
    this.imageAsset,
    this.activeImageAsset,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool useImage = imageAsset != null || activeImageAsset != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          useImage
              ? Image.asset(
                  isSelected
                      ? (activeImageAsset ?? imageAsset!)
                      : (imageAsset ?? activeImageAsset!),
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  color: isSelected ? brandRed : const Color(0xFFAAAAAA),
                )
              : Icon(
                  isSelected ? activeIcon : icon,
                  size: 24,
                  color: isSelected ? brandRed : const Color(0xFFAAAAAA),
                ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? brandRed : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}
