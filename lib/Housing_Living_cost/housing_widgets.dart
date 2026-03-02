import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/loan_widgets.dart';
import 'models/housing_cost_model.dart';
import 'services/housing_api_service.dart';

// ── Housing Cost List Item ─────────────────────────────────────────────────

class HousingCostListItem extends StatelessWidget {
  final String iconPath;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final String status;
  final bool isPaid;
  final VoidCallback onTap;

  const HousingCostListItem({
    super.key,
    required this.iconPath,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.isPaid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isPaid ? const Color(0xFF2196F3) : brandRed;
    final statusBgColor = isPaid ? const Color(0xFFE3F2FD) : const Color(0xFFFFEBEE);

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
              child: Image.asset(iconPath, width: 26, height: 26,
                  errorBuilder: (c, e, s) => const Icon(Icons.home, size: 26)),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        amount,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
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
                            Flexible(
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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

// ── Housing Payment Modal ──────────────────────────────────────────────────

class HousingPaymentModal extends StatefulWidget {
  final HousingCost cost;
  final VoidCallback? onPaymentConfirmed;

  const HousingPaymentModal({super.key, required this.cost, this.onPaymentConfirmed});

  @override
  State<HousingPaymentModal> createState() => _HousingPaymentModalState();
}

class _HousingPaymentModalState extends State<HousingPaymentModal> {
  late bool _isAutoPayment;
  bool _isProcessing = false;
  final HousingApiService _apiService = HousingApiService();
  String _selectedMonth = 'January';
  final TextEditingController _amountController = TextEditingController();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _isAutoPayment = widget.cost.autoPay;
    _amountController.text = NumberFormat('#,##0.00').format(widget.cost.amount);
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
      await _apiService.updateHousingCost(widget.cost.id!, {
        'autoPay': _isAutoPayment,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onPaymentConfirmed?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment recorded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 24, color: Color(0xFF111111)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Payment Amount Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE7E9),
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
                  style: TextStyle(fontSize: 18, color: Color(0xFFC61C36), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.simpleCurrency().format(widget.cost.amount),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Amount Input
          const Text('Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
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
                prefixStyle: TextStyle(color: Color(0xFF888888), fontSize: 15),
              ),
              style: const TextStyle(fontSize: 15, color: Color(0xFF555555)),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(height: 10),

          // Month Dropdown
          const Text('Month', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111111))),
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
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF111111)),
                style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
                items: _months.map((String month) {
                  return DropdownMenuItem<String>(value: month, child: Text(month));
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
                child: const Icon(Icons.repeat, color: Color(0xFFC61C36), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Auto-payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                    Text('Pay automatic every month', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Switch(
                value: _isAutoPayment,
                onChanged: (v) => setState(() => _isAutoPayment = v),
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFC61C36),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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
                  child: const Text('Cancel', style: TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC61C36)))
                      : const Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Housing Reminder Modal ──────────────────────────────────────────────────

class HousingReminderModal extends StatefulWidget {
  final HousingCost cost;
  const HousingReminderModal({super.key, required this.cost});

  @override
  State<HousingReminderModal> createState() => _HousingReminderModalState();
}

class _HousingReminderModalState extends State<HousingReminderModal> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isSaving = false;
  final HousingApiService _apiService = HousingApiService();

  void _openCalendar() async {
    final DateTime? result = await showDialog<DateTime>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withOpacity(0.3),
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
      setState(() => _selectedDate = result);
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
            colorScheme: const ColorScheme.light(primary: Color(0xFFC61C36)),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _selectedTime = result);
    }
  }

  void _onSave() async {
    setState(() => _isSaving = true);
    try {
      final remindAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _apiService.createReminder(
        itemId: widget.cost.id!,
        itemType: 'housing',
        title: 'Payment Reminder: ${widget.cost.name}',
        remindAt: remindAt,
        note: 'Reminder for ${widget.cost.category} payment.',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder set successfully')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('MMMM dd, yyyy').format(_selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Set Reminder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 24, color: Color(0xFF111111)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _openCalendar,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pick Date', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formattedDate, style: const TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500)),
                    const Icon(Icons.calendar_today, color: Color(0xFFC61C36), size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFFEEEEEE)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onTap: _openTimePicker,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pick Time', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedTime.hourOfPeriod.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.access_time, color: Color(0xFFC61C36), size: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFFEEEEEE)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15, color: Color(0xFF111111), fontWeight: FontWeight.w500)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC61C36)))
                    : const Text('Set Reminder', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
