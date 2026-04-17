import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import 'models/insurance_model.dart';
import '../services/insurance_service.dart';
import '../services/notification_service.dart';
import '../Loan_Screen/loan_widgets.dart';
import 'dart:ui';

class AddInsuranceScreen extends StatefulWidget {
  const AddInsuranceScreen({super.key});

  @override
  State<AddInsuranceScreen> createState() => _AddInsuranceScreenState();
}

class _AddInsuranceScreenState extends State<AddInsuranceScreen> {
  final InsuranceService _apiService = InsuranceService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _renewalDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _manufacturerController = TextEditingController();
  final TextEditingController _policyNumberController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _timeLeftController = TextEditingController();
  final TextEditingController _paymentsCompletedController =
      TextEditingController();
  final TextEditingController _totalPaymentsController =
      TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  String _selectedCategory = 'Personal';
  String _paymentType = 'Monthly';
  String _coverageType = 'Comprehensive';
  String? _personalInsuranceType;
  bool _isSaving = false;
  bool _showAdditionalDetails = false;
  List<String> _documentIds = [];

  final List<String> _categories = [
    'Personal',
    'Pet',
    'Home',
    'Appliance',
    'Auto',
    'Other',
  ];
  final List<String> _paymentTypes = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> _personalTypes = [
    'Disability',
    'Travel',
    'Group',
    'Critical Illness',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _providerController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _renewalDateController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    _petNameController.dispose();
    _manufacturerController.dispose();
    _policyNumberController.dispose();
    _vehicleModelController.dispose();
    _timeLeftController.dispose();
    _paymentsCompletedController.dispose();
    _totalPaymentsController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  DateTime? _parseDateText(String value) {
    if (value.trim().isEmpty) return null;
    for (final pattern in ['MM/dd/yy', 'MM/dd/yyyy']) {
      try {
        return DateFormat(pattern).parseStrict(value);
      } catch (_) {}
    }
    return null;
  }

  String _text(TextEditingController controller) => controller.text.trim();

  double _parsedAmount() {
    return double.tryParse(
          _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0.0;
  }

  List<String> get _frequencyOptions => _selectedCategory == 'Appliance'
      ? const ['One-time']
      : _paymentTypes;

  String get _normalizedPaymentType =>
      _selectedCategory == 'Appliance' ? 'One-time' : _paymentType;

  String get _nameLabel => 'Name';

  String get _nameHint {
    switch (_selectedCategory) {
      case 'Personal':
        return 'Life insurance';
      case 'Pet':
        return 'Pet insurance name';
      case 'Home':
        return 'Home insurance name';
      case 'Appliance':
        return 'Warranty name';
      case 'Auto':
        return 'Auto insurance name';
      case 'Other':
        return 'Other insurance name';
      default:
        return 'Insurance name';
    }
  }

  String get _amountLabel =>
      _selectedCategory == 'Appliance' ? 'One-time Payment' : 'Payment';

  String get _amountHint =>
      _selectedCategory == 'Appliance' ? '\$0.00' : '\$100';

  String get _frequencyLabel => 'Schedule';

  String get _dateLabel => 'Payment Date';

  String get _notesHint {
    switch (_selectedCategory) {
      case 'Pet':
        return 'Add any notes about your pet insurance.';
      case 'Auto':
        return 'Add any notes about this auto insurance.';
      case 'Appliance':
        return 'Add any notes about this warranty.';
      default:
        return 'Add any notes about this insurance.';
    }
  }

  String _paymentDayDescription(DateTime? date) {
    if (date == null) return '';

    if (_selectedCategory == 'Appliance') {
      return DateFormat('MMM dd, yyyy').format(date);
    }

    switch (_normalizedPaymentType) {
      case 'Monthly':
        return 'Every ${date.day}${_daySuffix(date.day)} of the month';
      case 'Quarterly':
        return 'Quarterly on ${DateFormat('MMM dd').format(date)}';
      case 'Yearly':
        return 'Yearly on ${DateFormat('MMM dd').format(date)}';
      case 'One-time':
        return DateFormat('MMM dd, yyyy').format(date);
      default:
        return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String? _validateRequiredFields() {
    if (_text(_nameController).isEmpty) {
      return 'Please enter the name';
    }
    // Amount and Date are now optional
    return null;
  }

  Future<void> _savePolicy() async {
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final amount = _parsedAmount();
      final paymentDate = _parseDateText(_dateController.text);
      final renewalDate =
          _parseDateText(_renewalDateController.text) ?? paymentDate;
      final startDate = _parseDateText(_startDateController.text);
      final endDate = _parseDateText(_endDateController.text);

      String policyName = _text(_nameController);

      final policy = InsurancePolicy(
        userId: '', // Set by backend
        name: policyName,
        category: _selectedCategory.toLowerCase(),
        premium: amount,
        paymentFrequency: _normalizedPaymentType,
        provider: _text(_providerController),
        renewalDate: renewalDate,
        coverageNotes: _text(_notesController),
        petName: _selectedCategory == 'Pet' ? _text(_petNameController) : null,
        propertyAddress: _selectedCategory == 'Home'
            ? _text(_addressController)
            : null,
        applianceName: _selectedCategory == 'Appliance'
            ? _text(_nameController)
            : null,
        manufacturer: _selectedCategory == 'Appliance'
            ? _text(_manufacturerController)
            : null,
        policyNumber: _text(_policyNumberController),
        documents: _documentIds,
        vehicleModel: _selectedCategory == 'Auto'
            ? _text(_vehicleModelController)
            : null,
        timeLeft: _selectedCategory == 'Auto' ? _text(_timeLeftController) : null,
        paymentsCompleted: _selectedCategory == 'Auto'
            ? int.tryParse(_text(_paymentsCompletedController))
            : null,
        totalPayments: _selectedCategory == 'Auto'
            ? int.tryParse(_text(_totalPaymentsController))
            : null,
        paymentDay: _paymentDayDescription(paymentDate),
        personalInsuranceType: _selectedCategory == 'Personal' ? _personalInsuranceType : null,
        status: 'active',
      );

      final createdPolicy = await _apiService.createInsurance(policy);

      if (renewalDate != null && createdPolicy.id != null) {
        final reminder = await _apiService.createReminder(
          itemId: createdPolicy.id!,
          itemType: 'insurance',
          title: 'Insurance Renewal: ${createdPolicy.name}',
          remindAt: renewalDate,
          note: 'Automatic renewal reminder for your insurance policy.',
        );

        await NotificationService.scheduleReminder(
          id: NotificationService.getNotificationId(reminder['id']),
          title: reminder['title'] ?? 'Insurance Reminder',
          body: reminder['note'] ?? 'Upcoming insurance renewal.',
          scheduledDate: renewalDate,
        );
      }

      if (mounted) context.pop(true);
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

  String get _appBarTitle {
    switch (_selectedCategory) {
      case 'Pet':
        return 'Add Pet Insurance';
      case 'Home':
        return 'Add Home Insurance';
      case 'Appliance':
        return 'Add Warranty';
      case 'Auto':
        return 'Add Auto Insurance';
      default:
        return _selectedCategory == 'Other'
            ? 'Add Other Insurance'
            : 'Add New Policy';
    }
  }

  String get _appBarRightAction {
    return 'Cancel';
  }

  Widget _buildCategorySelectorOrHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = cat;
                  _paymentType = cat == 'Appliance' ? 'One-time' : 'Monthly';
                  _showAdditionalDetails = false;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? brandRed : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? brandRed : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (cat != 'Other') ...[
                        Image.asset(
                          InsurancePolicy.categoryIcon(cat),
                          width: 16,
                          height: 16,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555555),
                          errorBuilder: (c, e, s) => Icon(
                            Icons.shield,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF555555),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555555),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFB),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: brandRed, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _appBarTitle,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_appBarRightAction == 'Save') {
                if (!_isSaving) _savePolicy();
              } else {
                context.pop();
              }
            },
            child: _isSaving && _appBarRightAction == 'Save'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: brandRed,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _appBarRightAction,
                    style: const TextStyle(
                      color: brandRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategorySelectorOrHeader(),
            ..._buildDynamicFields(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePolicy,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    return [
      const Text(
        'Required',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      const SizedBox(height: 16),
      _buildLabel(_nameLabel),
      _buildTextField(_nameController, _nameHint),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(_amountLabel),
                _buildTextField(_amountController, _amountHint),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(_frequencyLabel),
                _buildDropdownField(
                  _frequencyOptions,
                  _normalizedPaymentType,
                  _selectedCategory == 'Appliance' ? 'One-time' : 'Monthly',
                  (v) => setState(() => _paymentType = v!),
                  isRed: true,
                ),
              ],
            ),
          ),
        ],
      ),
      _buildLabel(_dateLabel),
      _buildDateField(_dateController, 'mm/dd/yy'),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: () =>
            setState(() => _showAdditionalDetails = !_showAdditionalDetails),
        child: Row(
          children: [
            const Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '(Optional)',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              _showAdditionalDetails
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF111111),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_showAdditionalDetails) ..._buildAdditionalDetailsFields(),
    ];
  }

  List<Widget> _buildAdditionalDetailsFields() {
    final widgets = <Widget>[];

    switch (_selectedCategory) {
      case 'Personal':
        widgets.addAll([
          _buildLabel('Provider'),
          _buildTextField(_providerController, 'Provider name'),
          _buildLabel('Renewal Date'),
          _buildDateField(_renewalDateController, 'mm/dd/yy'),
          _buildLabel('Insurance Type'),
          _buildDropdownField(
            _personalTypes,
            _personalInsuranceType,
            'Select type',
            (v) => setState(() => _personalInsuranceType = v),
          ),
        ]);
        break;
      case 'Pet':
        widgets.addAll([
          _buildLabel('Pet Name'),
          _buildTextField(_petNameController, 'Insured pet name'),
        ]);
        break;
      case 'Home':
        widgets.addAll([
          _buildLabel('Address'),
          _buildTextField(_addressController, 'Property address'),
          _buildLabel('Provider'),
          _buildTextField(_providerController, 'Provider name'),
          _buildLabel('Policy Number'),
          _buildTextField(_policyNumberController, 'Policy number'),
        ]);
        break;
      case 'Appliance':
        widgets.addAll([
          _buildLabel('Manufacturer'),
          _buildTextField(_manufacturerController, 'Manufacturer'),
          _buildLabel('Store / Provider'),
          _buildTextField(_providerController, 'Store or provider'),
        ]);
        break;
      case 'Auto':
        widgets.addAll([
          _buildLabel('Vehicle Model'),
          _buildTextField(_vehicleModelController, 'Vehicle model'),
          _buildLabel('Renewal Date'),
          _buildDateField(_renewalDateController, 'mm/dd/yy'),
          _buildLabel('Time Left'),
          _buildTextField(_timeLeftController, 'How many years'),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Payments Completed'),
                    _buildTextField(
                      _paymentsCompletedController,
                      'Completed payments',
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
                    _buildTextField(_totalPaymentsController, 'Total payments'),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Start Date'),
                    _buildDateField(_startDateController, 'mm/dd/yy'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('End Date'),
                    _buildDateField(_endDateController, 'mm/dd/yy'),
                  ],
                ),
              ),
            ],
          ),
          _buildLabel('Coverage Type'),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEBEB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _coverageType = 'Comprehensive'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _coverageType == 'Comprehensive'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Comprehensive',
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: 13,
                            fontWeight: _coverageType == 'Comprehensive'
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _coverageType = 'Third-party'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _coverageType == 'Third-party'
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Third-party',
                          style: TextStyle(
                            color: const Color(0xFF555555),
                            fontSize: 13,
                            fontWeight: _coverageType == 'Third-party'
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildLabel('Provider'),
          _buildTextField(_providerController, 'Provider name'),
          _buildLabel('Policy Number'),
          _buildTextField(_policyNumberController, 'Policy number'),
        ]);
        break;
      case 'Other':
        widgets.addAll([
          _buildLabel('Provider'),
          _buildTextField(_providerController, 'Provider name'),
        ]);
      default:
        break;
    }

    widgets.addAll([
      _buildLabel('Notes'),
      _buildTextField(_notesController, _notesHint, maxLines: 4),
      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ]);

    return widgets;
  }

  Widget _buildDropdownField(
    List<String> items,
    String? currentValue,
    String hint,
    ValueChanged<String?> onChanged, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            hint: Text(
              hint,
              style: TextStyle(
                color: isRed ? brandRed : const Color(0xFF888888),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: isRed ? brandRed : const Color(0xFF111111),
            ),
            style: TextStyle(
              color: isRed ? brandRed : const Color(0xFF111111),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            items: items
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildAddDocumentsButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton(
        onPressed: () async {
          final result = await context.push(
            '/insurance-add-documents',
            extra: {'initialDocuments': null},
          );
          if (result != null && result is List<Map<String, dynamic>>) {
            setState(() {
              _documentIds = result.map((d) => d['id'] as String).toList();
            });
          }
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: brandRed, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: Text(
          _documentIds.isEmpty
              ? '+Add Documents'
              : '+${_documentIds.length} Documents Added',
          style: const TextStyle(
            color: brandRed,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111111),
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFBBBBBB),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEBEBEB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: brandRed, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
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
                      child: CustomCalendarModal(
                        initialDate:
                            _parseDateText(controller.text) ?? DateTime.now(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          if (result != null) {
            setState(() {
              controller.text = DateFormat('MM/dd/yy').format(result);
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFBBBBBB),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: brandRed),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
