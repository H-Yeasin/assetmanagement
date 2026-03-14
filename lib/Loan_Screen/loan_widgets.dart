import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:ui';
import '../Home_Dashboard/widgets.dart';
import 'models/loan_model.dart';
import '../services/loan_service.dart';
import '../services/notification_service.dart';

// ── Loan Status Badge ───────────────────────────────────────────────────────

class LoanStatusBadge extends StatelessWidget {
  final String status;
  final bool isPaid;

  const LoanStatusBadge({
    super.key,
    required this.status,
    required this.isPaid,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPaid ? const Color(0xFF2196F3) : brandRed;
    final bgColor = isPaid ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPaid ? Icons.sync : Icons.priority_high,
            color: statusColor,
            size: 10,
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
    );
  }
}

// ── Loan List Item ──────────────────────────────────────────────────────────

class LoanListItem extends StatelessWidget {
  final String iconPath;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final bool isPaid;
  final VoidCallback onTap;

  const LoanListItem({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.isPaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine background color based on loan type/icon
    Color iconBgColor = const Color(0xFFFFF3E0); // Default orange
    if (iconPath.contains('home')) {
      iconBgColor = const Color(0xFFE3F2FD); // Blue for home
    } else if (iconPath.contains('personal')) {
      iconBgColor = const Color(0xFFE8F5E9); // Green for personal
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Image.asset(iconPath, width: 26, height: 26),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111111),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF888888),
                        ),
                      ),
                      LoanStatusBadge(status: status, isPaid: isPaid),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SetupPaymentModal extends StatefulWidget {
  final Loan loan;
  final VoidCallback? onPaymentConfirmed;

  const SetupPaymentModal({
    super.key,
    required this.loan,
    this.onPaymentConfirmed,
  });

  @override
  State<SetupPaymentModal> createState() => _SetupPaymentModalState();
}

class _SetupPaymentModalState extends State<SetupPaymentModal> {
  late bool _isAutoPayment;
  bool _isProcessing = false;
  final LoanService _loanService = LoanService();
  String _selectedMonth = 'January';
  final TextEditingController _amountController = TextEditingController();

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _isAutoPayment = widget.loan.autoPay;
    _amountController.text = widget.loan.monthlyPayment == 0
        ? ''
        : NumberFormat('#,##0.00').format(widget.loan.monthlyPayment);
    // Set current month as default
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    setState(() => _isProcessing = true);
    try {
      final completedP = widget.loan.completedPayments + 1;
      final existingRemaining = widget.loan.remainingBalance > 0
          ? widget.loan.remainingBalance
          : (widget.loan.totalAmount > 0
                ? widget.loan.totalAmount -
                      (widget.loan.completedPayments * widget.loan.monthlyPayment)
                : widget.loan.monthlyPayment);
      final remaining = existingRemaining - widget.loan.monthlyPayment;

      int totalP = widget.loan.totalPayments;
      if (totalP == 0 && widget.loan.monthlyPayment > 0 && widget.loan.totalAmount > 0) {
        totalP = (widget.loan.totalAmount / widget.loan.monthlyPayment).ceil();
      }

      final isCompleted = totalP > 0 && completedP >= totalP;
      
      final Map<String, dynamic> updates = {
        'completedPayments': completedP,
        'remainingBalance': remaining > 0 ? remaining : 0,
        'autoPay': _isAutoPayment,
      };
      
      if (totalP > 0) {
         updates['totalPayments'] = totalP;
      }

      if (isCompleted) {
        updates['status'] = 'completed';
        updates['completedAt'] = null; // We will use LoanService.markCompleted instead if needed, or directly update here. The api uses updateLoan. 
        // to use serverTimestamp we can't easily here without importing cloud_firestore, so let's import it or just use Timestamp.now()
      }
      
      await _loanService.updateLoan(widget.loan.id!, updates);
      
      if (isCompleted) {
         await _loanService.markCompleted(widget.loan.id!);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentConfirmed?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16), // Padding: 16px
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF), // Colors: #FFFFFF
        borderRadius: BorderRadius.all(Radius.circular(16)), // Radius: 16px
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Gap: 10px
            // ── Payment Amount Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE7E9), // Light pink background
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Payment Amount',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFC61C36),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormat.simpleCurrency().format(
                      widget.loan.monthlyPayment,
                    ),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Amount Input
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 15,
                  ),
                ),
                style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 10),

            // Month Dropdown
            const Text(
              'Month',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF111111),
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF888888),
                  ),
                  items: _months.map((String month) {
                    return DropdownMenuItem<String>(
                      value: month,
                      child: Text(month),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedMonth = val!),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Auto-payment
            Row(
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
                  value: _isAutoPayment,
                  onChanged: (v) => setState(() => _isAutoPayment = v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFFC61C36),
                  trackOutlineColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _recordPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE7E9),
                      foregroundColor: const Color(0xFFC61C36),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFC61C36),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reminder Modal ──────────────────────────────────────────────────────────

class ReminderModal extends StatefulWidget {
  final Loan loan;
  const ReminderModal({super.key, required this.loan});

  @override
  State<ReminderModal> createState() => _ReminderModalState();
}

class _ReminderModalState extends State<ReminderModal> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 14, minute: 0); // 2:00 PM
  bool _isSaving = false;
  final LoanService _apiService = LoanService();
  void _openCalendar() async {
    final DateTime? result = await showDialog<DateTime>(
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
                child: CustomCalendarModal(initialDate: _selectedDate),
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  void _openTimePicker() async {
    final TimeOfDay? result = await showTimePicker(
      context: context,
      useRootNavigator: true,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(
                0xFFC61C36,
              ), // Selected Hour/Minute text and Circle
              onPrimary: Colors.white,
              onSurface: Color(0xFF212121), // Unselected Hour/Minute text
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              helpTextStyle: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111111),
                fontWeight: FontWeight.w500,
              ),
              hourMinuteColor: const Color(
                0xFFEBEBEB,
              ), // Box background (#EBEBEB)
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFC61C36);
                }
                return const Color(0xFF212121);
              }),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFFDE7E9); // AM pink
                }
                return const Color(0xFFEDE9F2); // PM light purple
              }),
              dayPeriodTextColor: const Color(0xFF111111),
              dayPeriodBorderSide: const BorderSide(
                color: Color(0xFFAAAAAA),
                width: 1,
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hourMinuteShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              // ── Clock Dial Styling ──
              dialBackgroundColor: const Color(
                0xFFECECEC,
              ), // Dial background (#ECECEC)
              dialTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return const Color(0xFF212121);
              }),
              dialHandColor: const Color(
                0xFFC61C36,
              ), // Needle/Selector hand (#C61C36)
              entryModeIconColor: const Color(0xFFC61C36),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFC61C36),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedTime = result;
      });
    }
  }

  Future<void> _onSave() async {
    setState(() => _isSaving = true);
    try {
      final DateTime scheduledDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final result = await _apiService.createReminder(
        itemType: 'loan',
        itemId: widget.loan.id!,
        remindAt: scheduledDate,
        title: 'Loan Payment Reminder: ${widget.loan.name}',
        note: 'Reminder for your loan upcoming payment.',
      );

      // Schedule local notification
      await NotificationService.scheduleReminder(
        id: NotificationService.getNotificationId(result['id']),
        title: result['title'] ?? 'Loan Reminder',
        body: result['note'] ?? 'Upcoming loan payment.',
        scheduledDate: scheduledDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMMM dd').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16), // Padding: 16px
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(16)), // Radius: 16px
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pick Date & Time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Date Selection (Click triggers calendar) ──
            GestureDetector(
              onTap: _openCalendar,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF111111),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // ── Time Selection (Click triggers time picker) ──
            GestureDetector(
              onTap: _openTimePicker,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedTime.hourOfPeriod.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF111111),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(height: 1, color: const Color(0xFFEEEEEE)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF111111),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDE7E9),
                      foregroundColor: const Color(0xFFC61C36),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFC61C36),
                            ),
                          )
                        : const Text(
                            'Set Reminder',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Calendar Modal ───────────────────────────────────────────────────

class CustomCalendarModal extends StatefulWidget {
  final DateTime initialDate;
  const CustomCalendarModal({super.key, required this.initialDate});

  @override
  State<CustomCalendarModal> createState() => _CustomCalendarModalState();
}

class _CustomCalendarModalState extends State<CustomCalendarModal> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  final List<String> _months = [
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
  final List<int> _years = List.generate(20, (index) => 2015 + index);

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Custom Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF111111)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month - 1,
                    );
                  });
                },
              ),
              Row(
                children: [
                  // Month Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _focusedDay.month,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              _months[i],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _focusedDay = DateTime(_focusedDay.year, val!);
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Year Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _focusedDay.year,
                        items: _years
                            .map(
                              (y) => DropdownMenuItem(
                                value: y,
                                child: Text(
                                  '$y',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _focusedDay = DateTime(val!, _focusedDay.month);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFF111111)),
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime(
                      _focusedDay.year,
                      _focusedDay.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Table Calendar ──
          TableCalendar(
            firstDay: DateTime.utc(2015, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            currentDay: DateTime.now(),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              // Return the selected date
              Navigator.pop(context, selectedDay);
            },
            headerVisible: false,
            daysOfWeekHeight: 40,
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: const Color(0xFFC61C36),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFFC61C36).withValues(alpha: 0.1),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(8),
              ),
              defaultDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              weekendDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              outsideDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              holidayDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              markerDecoration: const BoxDecoration(shape: BoxShape.rectangle),
              todayTextStyle: const TextStyle(
                color: Color(0xFFC61C36),
                fontWeight: FontWeight.bold,
              ),
              outsideDaysVisible: true,
              outsideTextStyle: const TextStyle(color: Color(0xFFBBBBBB)),
              defaultTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              weekendTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
              weekendStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Time Picker Modal ────────────────────────────────────────────────

class CustomTimePickerModal extends StatelessWidget {
  const CustomTimePickerModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select Time',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox('07'),
              const Text(
                ' : ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              _buildTimeBox('00'),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: brandRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AM',
                      style: TextStyle(
                        color: brandRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'PM',
                    style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(12, (index) => _buildClockNumber(index + 1)),
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: brandRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: brandRed),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildClockNumber(int num) {
    return Transform.rotate(
      angle: (num * 30) * (3.14159 / 180),
      child: Container(
        height: 160,
        alignment: Alignment.topCenter,
        child: Transform.rotate(
          angle: -(num * 30) * (3.14159 / 180),
          child: Text(
            '$num',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
        ),
      ),
    );
  }
}
