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
  final TextEditingController _notesController = TextEditingController();

  // Extra specific fields
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

  Future<void> _savePolicy() async {
    // Validate based on category requirements from Figma
    if ((_selectedCategory == 'Pet' &&
            (_petNameController.text.isEmpty ||
                _nameController.text.isEmpty)) ||
        (_selectedCategory == 'Home' && _nameController.text.isEmpty) ||
        (_selectedCategory == 'Appliance' && _nameController.text.isEmpty) ||
        (_selectedCategory == 'Auto' && _nameController.text.isEmpty) ||
        (_selectedCategory == 'Personal' && _nameController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in the required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final amount =
          double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;
      final renewalDate = _parseDateText(_dateController.text);
      final startDate = _parseDateText(_startDateController.text);
      final endDate = _parseDateText(_endDateController.text);

      // Dynamically map fields based on category
      String policyName = _nameController.text;
      String? petName;
      String? applianceName;
      String? address;

      if (_selectedCategory == 'Pet') {
        petName = _petNameController.text;
      } else if (_selectedCategory == 'Appliance') {
        applianceName = _nameController.text;
        policyName =
            'Warranty'; // Default name if Appliance name takes over main name field
      } else if (_selectedCategory == 'Home') {
        address = _addressController.text;
        // The policy number field was used for policy name in home layout
        if (_policyNumberController.text.isNotEmpty) {
          policyName = _policyNumberController.text;
        }
      }

      final policy = InsurancePolicy(
        userId: '', // Set by backend
        name: policyName,
        category: _selectedCategory.toLowerCase(),
        premium: amount,
        paymentFrequency: _paymentType,
        provider: _providerController.text,
        renewalDate: renewalDate,
        coverageNotes: _notesController.text,
        petName: petName,
        propertyAddress: address,
        applianceName: applianceName,
        manufacturer: _selectedCategory == 'Appliance'
            ? _manufacturerController.text
            : null,
        policyNumber: _selectedCategory != 'Home'
            ? _policyNumberController.text
            : null,
        documents: _documentIds,
        vehicleModel: _selectedCategory == 'Auto'
            ? _vehicleModelController.text
            : null,
        timeLeft: _selectedCategory == 'Auto' ? _timeLeftController.text : null,
        paymentsCompleted: _selectedCategory == 'Auto'
            ? int.tryParse(_paymentsCompletedController.text)
            : null,
        totalPayments: _selectedCategory == 'Auto'
            ? int.tryParse(_totalPaymentsController.text)
            : null,
        startDate: startDate,
        endDate: endDate,
        coverageType: _selectedCategory == 'Auto' ? _coverageType : null,
        isAutoPay: true, // Defaulting for now
        paymentDay: 'Every 15th of the month', // Default for new policies
        personalInsuranceType: _personalInsuranceType,
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
        return 'Add New Policy'; // Personal / Other
    }
  }

  String get _appBarRightAction {
    return (_selectedCategory == 'Personal' ||
            _selectedCategory == 'Other' ||
            _selectedCategory == 'Auto')
        ? 'Cancel'
        : 'Save';
  }

  Widget _buildCategorySelectorOrHeader() {
    // If it's a specific category with a sub-layout, show the badge header
    if (_selectedCategory != 'Personal' && _selectedCategory != 'Other') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECTED CATEGORY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF555555),
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => setState(
                () => _selectedCategory = 'Personal',
              ), // Ability to go back to selection
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: brandRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedCategory != 'Other') ...[
                      Image.asset(
                        InsurancePolicy.categoryIcon(_selectedCategory),
                        width: 14,
                        height: 14,
                        color: Colors.white,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _selectedCategory,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: Show the selector list
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
                  _paymentType = 'Monthly'; // Reset defaults
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
    switch (_selectedCategory) {
      case 'Auto':
        return _buildAutoFields();
      case 'Personal':
        return _buildPersonalFields();
      case 'Pet':
        return _buildPetFields();
      case 'Home':
        return _buildHomeFields();
      case 'Appliance':
        return _buildWarrantyFields();
      case 'Other':
      default:
        // Default to Personal layout if generic/other
        return _buildPersonalFields();
    }
  }

  List<Widget> _buildAutoFields() {
    return [
      _buildLabel('Vehicle'),
      _buildTextField(_nameController, 'Name'),

      _buildLabel('Payment'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDropdownField(
              _paymentTypes,
              _paymentType,
              'Yearly',
              (v) => setState(() => _paymentType = v!),
              isRed: true,
            ),
          ),
        ],
      ),

      _buildLabel('Renewal Date'),
      _buildDateField(_dateController, 'mm/dd/yy'),

      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => setState(() => _showAdditionalDetails = !_showAdditionalDetails),
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
              _showAdditionalDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: const Color(0xFF111111),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (_showAdditionalDetails) ...[

      _buildLabel('Time Left'),
      _buildTextField(_timeLeftController, 'How Many Years'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Payment completed'),
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
                _buildLabel('Total payments'),
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

      _buildLabel('Vehicle Model'),
      _buildTextField(_vehicleModelController, 'Write Vehicle Model'),

      _buildLabel('Provider'),
      _buildTextField(_providerController, 'Provider name'),

      _buildLabel('Policy Number'),
      _buildTextField(_policyNumberController, 'e.g.,HMI-8888'),

      _buildLabel('Coverage Type'),
      Container(
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
                onTap: () => setState(() => _coverageType = 'Comprehensive'),
                child: Container(
                  decoration: BoxDecoration(
                    color: _coverageType == 'Comprehensive'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _coverageType == 'Comprehensive'
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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
                    boxShadow: _coverageType == 'Third-party'
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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
      const SizedBox(height: 24),
      ],

      _buildLabel('Coverage Notes'),
      _buildTextField(
        _notesController,
        'Planning to pay off early if bonus comes through in June. Need to check if there\'s any prepayment penalty in the agreement.',
        maxLines: 4,
      ),

      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ];
  }

  List<Widget> _buildPersonalFields() {
    return [
      _buildLabel('Select Insurance Type'),
      _buildDropdownField(
        _personalTypes,
        _personalInsuranceType,
        'Select type',
        (v) => setState(() => _personalInsuranceType = v),
      ),

      _buildLabel('Policy Name'),
      _buildTextField(_nameController, 'Auto Insurance'),

      _buildLabel('Premium'),
      _buildTextField(_amountController, '\$100'),

      _buildLabel('Insurance Provider'),
      _buildTextField(_providerController, 'Provider Name'),

      _buildLabel('Renewal Date'),
      _buildDateField(_dateController, 'mm/dd/yy'),

      _buildLabel('Coverage Notes'),
      _buildTextField(_notesController, 'Any additional notes...', maxLines: 4),

      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ];
  }

  List<Widget> _buildPetFields() {
    return [
      const Text(
        'Pet Details',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      const SizedBox(height: 24),

      _buildLabel('Pet Name'),
      _buildTextField(_petNameController, 'Insured Pet Name'),

      _buildLabel('Policy Name'),
      _buildTextField(_nameController, 'Name of Policy'),

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
                _buildLabel('Renewal Date'),
                _buildDateField(_dateController, 'mm/dd/yyyy'),
              ],
            ),
          ),
        ],
      ),

      _buildLabel('Provider'),
      _buildTextField(_providerController, 'Insurance Co.'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Payment'),
                _buildTextField(_amountController, '\$0.00'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Type'),
                _buildDropdownField(
                  _paymentTypes,
                  _paymentType,
                  'Monthly',
                  (v) => setState(() => _paymentType = v!),
                  isRed: true,
                ),
              ],
            ),
          ),
        ],
      ),

      _buildLabel('Coverage Notes'),
      _buildTextField(
        _notesController,
        'Planning to pay off early if bonus comes through in June. Need to check if there\'s any prepayment penalty in the agreement.',
        maxLines: 4,
      ),

      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ];
  }

  List<Widget> _buildHomeFields() {
    return [
      const Text(
        'Policy Details',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      const SizedBox(height: 24),

      _buildLabel('Property Name'),
      _buildTextField(_nameController, '124 Rain Avenue, Seattle, WA7896'),

      _buildLabel('Property Address'),
      _buildTextField(_addressController, '124 Rain Avenue, Seattle, WA7896'),

      _buildLabel('Provider'),
      _buildTextField(_providerController, 'Insurance Co.'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Policy name'),
                _buildTextField(_policyNumberController, 'HMI-8888'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Renewal Date'),
                _buildDateField(_dateController, 'mm/dd/yyyy'),
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
                _buildLabel('Payment'),
                _buildTextField(_amountController, '\$0.00'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Type'),
                _buildDropdownField(
                  _paymentTypes,
                  _paymentType,
                  'Monthly',
                  (v) => setState(() => _paymentType = v!),
                  isRed: true,
                ),
              ],
            ),
          ),
        ],
      ),

      _buildLabel('Coverage Notes'),
      _buildTextField(
        _notesController,
        'Planning to pay off early if bonus comes through in June. Need to check if there\'s any prepayment penalty in the agreement.',
        maxLines: 4,
      ),

      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ];
  }

  List<Widget> _buildWarrantyFields() {
    return [
      const Text(
        'Policy Details',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
      const SizedBox(height: 24),

      _buildLabel('Appliance Name'),
      _buildTextField(_nameController, 'Washing Machine'),

      _buildLabel('Manufacturer'),
      _buildTextField(_manufacturerController, 'Bosch'),

      _buildLabel('Store/Provider'),
      _buildTextField(_providerController, 'Best Buy'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Warranty End Date'),
                _buildDateField(_dateController, 'mm/dd/yyyy'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Original Price'),
                _buildTextField(_amountController, '\$ 0.00'),
              ],
            ),
          ),
        ],
      ),

      _buildLabel('Coverage Notes'),
      _buildTextField(
        _notesController,
        'Planning to pay off early if bonus comes through in June. Need to check if there\'s any prepayment penalty in the agreement.',
        maxLines: 4,
      ),

      const SizedBox(height: 8),
      _buildAddDocumentsButton(),
    ];
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
