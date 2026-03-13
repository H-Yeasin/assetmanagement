import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';
import 'add_documents_screen.dart';
import 'models/loan_model.dart';
import '../services/loan_service.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  String _selectedCategory = 'personal';
  bool _autoPayment = true;
  String _selectedAmortization = '';
  final LoanService _loanService = LoanService();
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _monthlyPaymentController =
      TextEditingController();
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _lenderController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Specific fields
  final TextEditingController _remainingBalanceController =
      TextEditingController();
  final TextEditingController _propertyAddressController =
      TextEditingController();
  final TextEditingController _apartmentNameController =
      TextEditingController();
  final TextEditingController _totalPaymentsController =
      TextEditingController();
  final TextEditingController _completedPaymentsController =
      TextEditingController();
  final TextEditingController _annualPaymentController =
      TextEditingController();
  final TextEditingController _timeLeftController = TextEditingController();

  List<Map<String, dynamic>> _uploadedDocuments = [];

  final List<Map<String, String>> _categories = [
    {
      'id': 'mortgage',
      'label': 'Home Mortgage',
      'icon': 'assets/images/icon/home_morgarate.png',
    },
    {
      'id': 'car',
      'label': 'Car Loan',
      'icon': 'assets/images/icon/car_loan.png',
    },
    {
      'id': 'business',
      'label': 'Business Loan',
      'icon': 'assets/images/icon/custom_loan.png',
    },
    {
      'id': 'student',
      'label': 'Students Loan',
      'icon': 'assets/images/icon/student_loan.png',
    },
    {
      'id': 'personal',
      'label': 'Personal Loan',
      'icon': 'assets/images/icon/personal_loan.png',
    },
    {
      'id': 'other',
      'label': 'Custom Loan',
      'icon': 'assets/images/icon/custom_loan.png',
    },
  ];

  DateTime? _parseDateText(String value) {
    if (value.trim().isEmpty) return null;
    for (final pattern in ['MM/dd/yy', 'MM/dd/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(value);
      } catch (_) {}
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _monthlyPaymentController.dispose();
    _paymentDateController.dispose();
    _totalAmountController.dispose();
    _interestRateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _lenderController.dispose();
    _notesController.dispose();
    _remainingBalanceController.dispose();
    _propertyAddressController.dispose();
    _apartmentNameController.dispose();
    _totalPaymentsController.dispose();
    _completedPaymentsController.dispose();
    _annualPaymentController.dispose();
    _timeLeftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMortgage = _selectedCategory == 'mortgage';
    final bool isCarLoan = _selectedCategory == 'car';

    return Scaffold(
      backgroundColor: (isMortgage || isCarLoan)
          ? const Color(0xFFFDF5F5)
          : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      isMortgage
                          ? 'Add New Agreement'
                          : (isCarLoan ? 'Add Car Loan' : 'Add Loan'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            if (isMortgage || isCarLoan) ...[
              // ── Tab Indicator ──
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    Text(
                      isMortgage ? 'Mortgage' : 'Car Loan',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 2,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: brandRed,
                    ),
                  ],
                ),
              ),
            ],

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: isMortgage
                    ? _buildMortgageLayout()
                    : (isCarLoan
                          ? _buildCarLoanLayout()
                          : _buildDefaultLayout()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Required',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 16),

        // Loan Name
        _buildLabel('Loan Name'),
        _buildInputField(
          controller: _nameController,
          hint: 'e.g., Tesla Model 3',
        ),

        const SizedBox(height: 20),

        _buildLabel('Loan Category'),
        _buildCategoryPicker(),

        const SizedBox(height: 24),

        // Monthly Payment + Payment Date
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Monthly Payment'),
                  _buildInputField(
                    controller: _monthlyPaymentController,
                    hint: '\$500',
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Payment Date'),
                  _buildInputField(
                    controller: _paymentDateController,
                    hint: 'mm/dd/yyyy',
                    isDate: true,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Auto-payment toggle
        _buildAutoPayToggle(),

        const SizedBox(height: 32),
        const Text(
          'Additional Details (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 20),

        // Total Amount
        _buildLabel('Total Amount'),
        _buildInputField(
          controller: _totalAmountController,
          hint: '\$15,000.00',
          isNumber: true,
        ),

        const SizedBox(height: 20),

        // Interest Rate + Remaining Balance
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Interest Rate (%)'),
                  _buildInputField(
                    controller: _interestRateController,
                    hint: '4.5',
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Remaining Balance'),
                  _buildInputField(
                    controller: _remainingBalanceController,
                    hint: '\$ 0.00',
                    isNumber: true,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Start Date + End Date
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Start Date'),
                  _buildInputField(
                    controller: _startDateController,
                    hint: 'mm/dd/yy',
                    isDate: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('End Date'),
                  _buildInputField(
                    controller: _endDateController,
                    hint: 'mm/dd/yy',
                    isDate: true,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        _buildAddDocumentsButton(),
        const SizedBox(height: 20),

        _buildLabel('Notes'),
        _buildInputField(
          controller: _notesController,
          hint: 'Optional notes...',
          maxLines: 3,
        ),

        const SizedBox(height: 28),
        _buildSaveButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCarLoanLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildLabel('Loan Category'),
        _buildCategoryPicker(),
        const SizedBox(height: 24),

        _buildLabel('Monthly Payment'),
        _buildInputField(
          controller: _monthlyPaymentController,
          hint: '\$260',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        _buildLabel('Time Left (months)'),
        _buildInputField(
          controller: _timeLeftController,
          hint: '18',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        _buildLabel('Payment completed'),
        _buildInputField(
          controller: _completedPaymentsController,
          hint: '12',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        _buildLabel('Total payments'),
        _buildInputField(
          controller: _totalPaymentsController,
          hint: '60',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Start Date'),
                  _buildInputField(
                    controller: _startDateController,
                    hint: '12 April 2025',
                    isDate: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('End Date'),
                  _buildInputField(
                    controller: _endDateController,
                    hint: '12 Oct 2026',
                    isDate: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Original Loan'),
                  _buildInputField(
                    controller: _totalAmountController,
                    hint: '15,00,000',
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Remaining Loan'),
                  _buildInputField(
                    controller: _remainingBalanceController,
                    hint: '15,00,000',
                    isNumber: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildLabel('Vehicle'),
        _buildInputField(controller: _nameController, hint: 'Toyota Corolla'),
        const SizedBox(height: 20),

        _buildLabel('Installment'),
        _buildInputField(
          controller: _monthlyPaymentController,
          hint: '\$260.00',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        _buildLabel('Interest rate'),
        _buildInputField(
          controller: _interestRateController,
          hint: '4.5%',
          isNumber: true,
        ),
        const SizedBox(height: 24),

        _buildAddDocumentsButton(),
        const SizedBox(height: 20),

        _buildRemindersSection(),
        const SizedBox(height: 32),

        _buildSaveButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMortgageLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildLabel('Loan Category'),
        _buildCategoryPicker(),
        const SizedBox(height: 24),

        _buildLabel('Property Name'),
        _buildInputField(controller: _nameController, hint: 'Name'),
        const SizedBox(height: 20),

        _buildLabel('Property Address'),
        _buildInputField(
          controller: _propertyAddressController,
          hint: 'Property Address',
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Mortgage Start Date'),
                  _buildInputField(
                    controller: _startDateController,
                    hint: 'mm/dd/yy',
                    isDate: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Renewal Date'),
                  _buildInputField(
                    controller: _endDateController,
                    hint: 'mm/dd/yy',
                    isDate: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildLabel('Annual Payments'),
        _buildInputField(
          controller: _annualPaymentController,
          hint: '\$2,400',
          isNumber: true,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Completed Payments'),
                  _buildInputField(
                    controller: _completedPaymentsController,
                    hint: '24',
                    isNumber: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Total Payments'),
                  _buildInputField(
                    controller: _totalPaymentsController,
                    hint: '60',
                    isNumber: true,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Apartment name'),
                  _buildInputField(
                    controller: _apartmentNameController,
                    hint: 'mm/dd/yy',
                  ), // Mockup has date-like hint? Wait, let's check image.
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Lending Bank'),
                  _buildInputField(
                    controller: _lenderController,
                    hint: 'mm/dd/yy',
                  ), // Mockup has date-like hint... odd but I'll stick to it.
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildLabel('Amortization Period'),
        _buildAmortizationPicker(), // This should match mockup style
        const SizedBox(height: 24),

        _buildAddDocumentsButton(isMortgage: true),
        const SizedBox(height: 24),

        const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 16),
        _buildRemindersSection(),

        const SizedBox(height: 28),
        _buildSaveButton(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAddDocumentsButton({bool isMortgage = false}) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddDocumentsScreen(initialDocuments: _uploadedDocuments),
          ),
        );
        if (result != null && result is List<Map<String, dynamic>>) {
          setState(() {
            _uploadedDocuments = result;
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isMortgage ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _uploadedDocuments.isEmpty ? brandRed : Colors.green,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: _uploadedDocuments.isEmpty ? brandRed : Colors.green,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              _uploadedDocuments.isEmpty
                  ? 'Add Documents'
                  : '${_uploadedDocuments.length} Documents Added',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _uploadedDocuments.isEmpty ? brandRed : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveLoan,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _selectedCategory == 'mortgage'
                    ? 'Save & Add Loan'
                    : 'Save & Add Loan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF1F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync, color: brandRed, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Auto-payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pay automatic every month',
                      style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _autoPayment,
                onChanged: (val) => setState(() => _autoPayment = val),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLabel('Payment Date'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Every 15th of the month',
                  style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: Color(0xFF888888),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPicker() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onChanged: (val) => setState(() => _selectedCategory = val!),
          items: _categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'],
              child: Row(
                children: [
                  Image.asset(cat['icon']!, width: 24, height: 24),
                  const SizedBox(width: 12),
                  Text(cat['label']!, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAutoPayToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sync_rounded, color: brandRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Auto-payment',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Pay automatically every month',
                  style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoPayment,
            onChanged: (v) => setState(() => _autoPayment = v),
            activeTrackColor: brandRed,
          ),
        ],
      ),
    );
  }

  Future<void> _saveLoan() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter loan name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final bool isMortgage = _selectedCategory == 'mortgage';

      double monthly;
      if (isMortgage) {
        final annualStr = _annualPaymentController.text.replaceAll(
          RegExp(r'[^\d.]'),
          '',
        );
        final annual = double.tryParse(annualStr) ?? 0.0;
        monthly = annual / 12;
      } else {
        final monthlyStr = _monthlyPaymentController.text.replaceAll(
          RegExp(r'[^\d.]'),
          '',
        );
        monthly = double.tryParse(monthlyStr) ?? 0.0;
      }

      final totalStr = _totalAmountController.text.replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      final totalAmount = double.tryParse(totalStr) ?? 0.0;

      final remainingStr = _remainingBalanceController.text.replaceAll(
        RegExp(r'[^\d.]'),
        '',
      );
      final remainingValue = double.tryParse(remainingStr) ?? 0.0;

      final pDate = _parseDateText(_paymentDateController.text) ?? DateTime.now();

      final loan = Loan(
        userId: '', // Let backend handle or provide via auth provider
        name: _nameController.text,
        category: _selectedCategory == 'business' ? 'other' : _selectedCategory,
        monthlyPayment: monthly,
        paymentDate: pDate,
        autoPay: _autoPayment,
        totalAmount: totalAmount,
        interestRate: double.tryParse(_interestRateController.text) ?? 0.0,
        startDate: _parseDateText(_startDateController.text),
        endDate: _parseDateText(_endDateController.text),
        remainingBalance: isMortgage ? 0.0 : remainingValue,
        notes: _notesController.text,
        documents: _uploadedDocuments.map((d) => d['id'] as String).toList(),
        propertyAddress: isMortgage ? _propertyAddressController.text : null,
        apartmentName: isMortgage ? _apartmentNameController.text : null,
        lender: _lenderController.text,
        amortizationPeriod: isMortgage ? _selectedAmortization : null,
        totalPayments: isMortgage
            ? (int.tryParse(_totalPaymentsController.text) ?? 0)
            : (int.tryParse(_totalPaymentsController.text) ?? 0),
        completedPayments: isMortgage
            ? (int.tryParse(_completedPaymentsController.text) ?? 0)
            : (int.tryParse(_completedPaymentsController.text) ?? 0),
      );

      final createdLoan = await _loanService.createLoan(loan);

      if (createdLoan.id != null) {
        final reminder = await _loanService.createReminder(
          itemType: 'loan',
          itemId: createdLoan.id!,
          remindAt: pDate,
          title: 'Loan Payment Reminder: ${createdLoan.name}',
          note: 'Reminder for your loan upcoming payment.',
        );

        await NotificationService.scheduleReminder(
          id: NotificationService.getNotificationId(reminder['id']),
          title: reminder['title'] ?? 'Loan Reminder',
          body: reminder['note'] ?? 'Upcoming loan payment.',
          scheduledDate: pDate,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Loan added successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: brandRed,
              onPrimary: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yy').format(picked);
      });
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF444444),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
    bool isDate = false,
  }) {
    return GestureDetector(
      onTap: isDate ? () => _selectDate(context, controller) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: TextField(
          controller: controller,
          enabled: !isDate,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            suffixIcon: isDate
                ? const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Color(0xFF888888),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildAmortizationPicker() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...['5y', '10y', '15y', '20y', '25y', 'Custom'].map(
                  (opt) => ListTile(
                    title: Text(opt),
                    onTap: () {
                      setState(() => _selectedAmortization = opt);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedAmortization.isEmpty
                  ? 'Select how many years'
                  : _selectedAmortization,
              style: TextStyle(
                fontSize: 15,
                color: _selectedAmortization.isEmpty
                    ? const Color(0xFFAAAAAA)
                    : Colors.black,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }
}
