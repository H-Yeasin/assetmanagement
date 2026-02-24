import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Home_Dashboard/widgets.dart';
import 'models/insurance_model.dart';

class InsuranceListItem extends StatelessWidget {
  final String iconPath;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final String frequency;
  final bool isAutoPay;
  final VoidCallback onTap;

  const InsuranceListItem({
    super.key,
    required this.iconPath,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.frequency,
    required this.isAutoPay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final frequencyColor = frequency.toLowerCase().contains('yearly') ? const Color(0xFFFFA726) : const Color(0xFFBA68C8);
    final frequencyBgColor = frequency.toLowerCase().contains('yearly') ? const Color(0xFFFFF7E6) : frequencyColor.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                iconPath,
                errorBuilder: (c, e, s) => Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.security, size: 24, color: Colors.white70),
                ),
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
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        amount,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: frequencyBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync, color: frequencyColor, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              frequency,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: frequencyColor,
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

class UpcomingActionItem extends StatelessWidget {
  final String month;
  final String day;
  final String title;
  final String status;
  final String amount;
  final bool isAutoPay;

  const UpcomingActionItem({
    super.key,
    required this.month,
    required this.day,
    required this.title,
    required this.status,
    required this.amount,
    required this.isAutoPay,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAutoPay ? const Color(0xFF2196F3) : brandRed;
    final statusBgColor = statusColor.withValues(alpha: 0.1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(month, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                Text(day, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          status, 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
        ],
      ),
    );
  }
}

// ── Insurance Payment Modal ──────────────────────────────────────────────────

class InsurancePaymentModal extends StatefulWidget {
  final InsurancePolicy policy;
  final VoidCallback? onPaymentConfirmed;

  const InsurancePaymentModal({super.key, required this.policy, this.onPaymentConfirmed});

  @override
  State<InsurancePaymentModal> createState() => _InsurancePaymentModalState();
}

class _InsurancePaymentModalState extends State<InsurancePaymentModal> {
  bool _isProcessing = false;
  String _selectedMonth = 'January';
  final TextEditingController _amountController = TextEditingController();

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _amountController.text = NumberFormat('#,##0.00').format(widget.policy.premium);
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
      // Logic for recording payment would go here (e.g., adding to a payments list)
      // For now, we follow the pattern of refreshing the UI
      await Future.delayed(const Duration(seconds: 1)); 

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
                  NumberFormat.simpleCurrency().format(widget.policy.premium),
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
