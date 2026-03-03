import 'package:flutter/material.dart';
import 'loan_widgets.dart';
import 'add_documents_screen.dart';
import 'edit_loan_screen.dart';
import 'models/loan_model.dart';
import 'services/loan_api_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'models/document_model.dart';
import '../Home_Dashboard/widgets.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan _currentLoan;
  final LoanApiService _apiService = LoanApiService();
  String _selectedReminder = 'Same day';
  bool _isReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentLoan = widget.loan;
    _refreshLoan();
  }

  Future<void> _refreshLoan() async {
    try {
      final updatedLoan = await _apiService.getLoan(_currentLoan.id!);
      setState(() {
        _currentLoan = updatedLoan;
      });
    } catch (e) {
      print('Error refreshing loan: $e');
    }
  }

  Future<void> _deleteDocument(String docId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isRefreshing = true);
      try {
        await _apiService.deleteDocument(docId);
        await _refreshLoan();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Document deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _renameDocument(String docId, String currentName) async {
    final TextEditingController controller = TextEditingController(
      text: currentName,
    );
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      setState(() => _isRefreshing = true);
      try {
        await _apiService.renameDocument(docId, newName);
        await _refreshLoan();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Document renamed')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Rename failed: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    }
  }

  String _selectedReminder = 'Same day';
  bool _isReminderEnabled = true;

  String _getTimeLeft() {
    if (_currentLoan.endDate == null) return 'N/A';
    final now = DateTime.now();
    final difference = _currentLoan.endDate!.difference(now);
    if (difference.isNegative) return 'Completed';

    final years = (difference.inDays / 365).floor();
    final months = ((difference.inDays % 365) / 30).floor();

    if (years > 0) {
      return '$years ${years == 1 ? 'Year' : 'Years'}${months > 0 ? ' $months ${months == 1 ? 'Mo' : 'Mos'}' : ''}';
    } else {
      return '${difference.inDays} Day${difference.inDays > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFDF5F5,
      ), // Light pinkish-grey background from design
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _currentLoan.name,
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
                          builder: (_) => EditLoanScreen(loan: _currentLoan),
                        ),
                      );
                      if (result == true) {
                        _refreshLoan();
                      }
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        color: brandRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                    const SizedBox(height: 12),

                    // ── Progress Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Monthly Payment',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    NumberFormat.simpleCurrency(
                                      decimalDigits: 0,
                                    ).format(_currentLoan.monthlyPayment),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Time Left',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getTimeLeft(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111111),
                                    ), // Black instead of red based on the image
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment progress',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111111),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_currentLoan.completedPayments} of ${_currentLoan.totalPayments} payments completed',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111111),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _currentLoan.totalPayments > 0
                                  ? (_currentLoan.completedPayments /
                                        _currentLoan.totalPayments)
                                  : 0.0,
                              backgroundColor: const Color(0xFFE0E0E0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                brandRed,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Started ${_currentLoan.startDate != null ? DateFormat('MMMM y').format(_currentLoan.startDate!) : 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'End Date : ${_currentLoan.endDate != null ? DateFormat('MMMM y').format(_currentLoan.endDate!) : 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888888),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Action Buttons ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/setup_payment.png',
                            label: 'Pay',
                            onTap: () {
                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                barrierColor: Colors.black.withOpacity(
                                  0.3,
                                ), // #000000 30%
                                builder: (context) => Stack(
                                  children: [
                                    // Applying Background blur: 4
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 4,
                                          sigmaY: 4,
                                        ),
                                        child: Container(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 343, // Fixed (343px)
                                          child: SetupPaymentModal(
                                            loan: _currentLoan,
                                            onPaymentConfirmed: _refreshLoan,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/remind.png',
                            label: 'Remind',
                            onTap: () {
                              showDialog(
                                context: context,
                                useRootNavigator: true,
                                barrierColor: Colors.black.withOpacity(
                                  0.3,
                                ), // #000000 30%
                                builder: (context) => Stack(
                                  children: [
                                    // Applying Background blur: 4
                                    Positioned.fill(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 4,
                                          sigmaY: 4,
                                        ),
                                        child: Container(
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    const Center(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 343, // Fixed (343px)
                                          child: ReminderModal(
                                            loan: _currentLoan,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Additional Details Button ──
                    GestureDetector(
                      onTap: () {
                        // Navigate to additional details
                        context.push(
                          '/additional-details',
                          extra: _currentLoan,
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
                              width: 20,
                              height: 20,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.list_alt,
                                color: brandRed,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Additional Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: brandRed,
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDocumentsScreen(
                                  loan: _currentLoan,
                                  initialDocuments: _currentLoan.documents.map((
                                    doc,
                                  ) {
                                    if (doc is Map<String, dynamic>) {
                                      return {
                                        'id': doc['_id'] ?? doc['id'] ?? '',
                                        'name':
                                            doc['displayName'] ??
                                            doc['name'] ??
                                            'Existing Document',
                                        'type':
                                            (doc['mimeType']
                                                        ?.toString()
                                                        .contains('pdf') ==
                                                    true) ||
                                                doc['type'] == 'pdf'
                                            ? 'pdf'
                                            : 'image',
                                        'date': doc['createdAt'] != null
                                            ? DateTime.tryParse(
                                                    doc['createdAt'],
                                                  ) ??
                                                  DateTime.now()
                                            : (doc['date'] is DateTime
                                                  ? doc['date']
                                                  : DateTime.now()),
                                        'path': doc['path'],
                                      };
                                    }
                                    if (doc is DocumentFile) {
                                      return {
                                        'id': doc.id,
                                        'name': doc.displayName,
                                        'type': doc.mimeType.contains('pdf')
                                            ? 'pdf'
                                            : 'image',
                                        'date': doc.createdAt ?? DateTime.now(),
                                        'path': doc.path,
                                      };
                                    }
                                    return {
                                      'id': doc is String
                                          ? doc
                                          : doc.toString(),
                                      'name': 'Existing Document',
                                      'type': 'pdf',
                                      'date': DateTime.now(),
                                    };
                                  }).toList(),
                                ),
                              ),
                            );
                            if (result != null &&
                                result is List<Map<String, dynamic>>) {
                              final docIds = result
                                  .map((d) => d['id'] as String)
                                  .toList();
                              setState(() => _isRefreshing = true);
                              try {
                                await _apiService.updateLoan(_currentLoan.id!, {
                                  'documents': docIds,
                                });
                                await _refreshLoan();
                              } finally {
                                if (mounted)
                                  setState(() => _isRefreshing = false);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: brandRed),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '+ Add Documents',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: brandRed,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                              color: brandRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/icon/loan.png',
                              width: 24,
                              height: 24,
                              color: brandRed,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.description,
                                color: brandRed,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_currentLoan.documents.length} Documents',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentLoan.name,
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
                    ),

                    const SizedBox(height: 32),

                    // ── Reminders ──
                    const Text(
                      'Reminders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC61C36).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              'assets/images/icon/remind.png',
                              width: 22,
                              height: 22,
                              color: const Color(0xFFC61C36),
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.notifications_active,
                                color: Color(0xFFC61C36),
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Payment Reminders',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111111),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedReminder == 'Same day'
                                      ? 'On the due date'
                                      : '$_selectedReminder date',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF888888),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            height: 28,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReminder,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 14,
                                  color: Color(0xFF555555),
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF555555),
                                  fontWeight: FontWeight.w500,
                                ),
                                items:
                                    [
                                      'Same day',
                                      '1 day before',
                                      '3 days before',
                                      '1 week before',
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedReminder = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 50,
                            height: 30,
                            child: FittedBox(
                              fit: BoxFit.fill,
                              child: Switch(
                                value: _isReminderEnabled,
                                onChanged: (val) {
                                  setState(() {
                                    _isReminderEnabled = val;
                                  });
                                },
                                activeThumbColor: Colors.white,
                                activeTrackColor: const Color(0xFFC61C36),
                                inactiveTrackColor: const Color(0xFFE0E0E0),
                                trackOutlineColor: WidgetStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Notes ──
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 18,
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
                        _currentLoan.notes?.isNotEmpty == true
                            ? _currentLoan.notes!
                            : "Planning to pay off early if bonus comes through in June. Need to check if there's any prepayment penalty in the agreement.",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF888888),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
