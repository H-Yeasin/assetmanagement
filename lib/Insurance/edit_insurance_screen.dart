import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../Home_Dashboard/widgets.dart';
import 'models/insurance_model.dart';
import 'services/insurance_api_service.dart';

class EditInsuranceScreen extends StatefulWidget {
  final InsurancePolicy policy;
  const EditInsuranceScreen({super.key, required this.policy});

  @override
  State<EditInsuranceScreen> createState() => _EditInsuranceScreenState();
}

class _EditInsuranceScreenState extends State<EditInsuranceScreen> {
  final InsuranceApiService _apiService = InsuranceApiService();
  late TextEditingController _nameController;
  late TextEditingController _providerController;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _notesController;
  
  late TextEditingController _addressController;
  late TextEditingController _petNameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _policyNumberController;
  late TextEditingController _vehicleModelController;
  late TextEditingController _timeLeftController;
  late TextEditingController _paymentsCompletedController;
  late TextEditingController _totalPaymentsController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  late String _paymentType;
  late String _coverageType;
  String? _personalInsuranceType;
  bool _isSaving = false;
  bool _isAutoPay = true;
  String _paymentDay = 'Every 15th of the month';

  final List<String> _paymentTypes = ['Monthly', 'Quarterly', 'Yearly'];
  final List<String> _personalTypes = ['Disability', 'Travel', 'Group', 'Critical Illness'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.policy.name);
    _providerController = TextEditingController(text: widget.policy.provider);
    _amountController = TextEditingController(text: widget.policy.premium.toString());
    _dateController = TextEditingController(
      text: widget.policy.renewalDate != null ? DateFormat('MM/dd/yyyy').format(widget.policy.renewalDate!) : ''
    );
    _notesController = TextEditingController(text: widget.policy.coverageNotes);
    
    _addressController = TextEditingController(text: widget.policy.propertyAddress);
    _petNameController = TextEditingController(text: widget.policy.petName);
    _manufacturerController = TextEditingController(text: widget.policy.manufacturer);
    _policyNumberController = TextEditingController(text: widget.policy.policyNumber);
    _vehicleModelController = TextEditingController(text: widget.policy.vehicleModel);
    _timeLeftController = TextEditingController(text: widget.policy.timeLeft);
    _paymentsCompletedController = TextEditingController(text: widget.policy.paymentsCompleted?.toString() ?? '');
    _totalPaymentsController = TextEditingController(text: widget.policy.totalPayments?.toString() ?? '');
    _startDateController = TextEditingController(
      text: widget.policy.startDate != null ? DateFormat('MM/dd/yyyy').format(widget.policy.startDate!) : ''
    );
    _endDateController = TextEditingController(
      text: widget.policy.endDate != null ? DateFormat('MM/dd/yyyy').format(widget.policy.endDate!) : ''
    );
    
    _isAutoPay = widget.policy.isAutoPay ?? true;
    _paymentDay = widget.policy.paymentDay ?? 'Every 15th of the month';
    _coverageType = widget.policy.coverageType ?? 'Comprehensive';
    _personalInsuranceType = widget.policy.personalInsuranceType; // Assuming this field exists in model

    final freq = widget.policy.paymentFrequency?.toLowerCase();
    if (freq == 'monthly') {
      _paymentType = 'Monthly';
    } else if (freq == 'quarterly') {
      _paymentType = 'Quarterly';
    } else if (freq == 'annually' || freq == 'yearly') {
      _paymentType = 'Yearly';
    } else {
      _paymentType = 'Monthly';
    }
  }

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

  Future<void> _updatePolicy() async {
    setState(() => _isSaving = true);
    try {
      final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      DateTime? renewalDate;
      if (_dateController.text.isNotEmpty) {
        try { renewalDate = DateFormat('MM/dd/yyyy').parse(_dateController.text); } catch (_) {}
      }
      DateTime? startDate;
      if (_startDateController.text.isNotEmpty) {
        try { startDate = DateFormat('MM/dd/yyyy').parse(_startDateController.text); } catch (_) {}
      }
      DateTime? endDate;
      if (_endDateController.text.isNotEmpty) {
        try { endDate = DateFormat('MM/dd/yyyy').parse(_endDateController.text); } catch (_) {}
      }

      final tempPolicy = InsurancePolicy(
        userId: widget.policy.userId,
        name: widget.policy.category == 'pet' ? _petNameController.text : _nameController.text,
        category: widget.policy.category,
        premium: amount,
        paymentFrequency: _paymentType,
        provider: _providerController.text,
        renewalDate: renewalDate,
        coverageNotes: _notesController.text,
        petName: _petNameController.text,
        propertyAddress: _addressController.text,
        applianceName: widget.policy.category == 'appliance' ? _nameController.text : null,
        manufacturer: _manufacturerController.text,
        policyNumber: _policyNumberController.text,
        vehicleModel: _vehicleModelController.text,
        timeLeft: _timeLeftController.text,
        paymentsCompleted: int.tryParse(_paymentsCompletedController.text),
        totalPayments: int.tryParse(_totalPaymentsController.text),
        startDate: startDate,
        endDate: endDate,
        coverageType: _coverageType,
        isAutoPay: _isAutoPay,
        paymentDay: _paymentDay,
        personalInsuranceType: _personalInsuranceType,
        documents: widget.policy.documents,
      );

      final packedUpdates = tempPolicy.toJson();
      await _apiService.updateInsurance(widget.policy.id!, packedUpdates);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String categoryDisp = widget.policy.category[0].toUpperCase() + widget.policy.category.substring(1);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF111111), size: 24), 
          onPressed: () => context.pop(),
        ),
        title: Text('Edit $categoryDisp Insurance', 
          style: const TextStyle(color: Color(0xFF111111), fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              if (!_isSaving) _updatePolicy();
            },
            child: _isSaving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: brandRed, strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: brandRed, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.policy.category == 'auto') ..._buildAutoEditFields()
            else if (widget.policy.category == 'personal') ..._buildPersonalEditFields()
            else if (widget.policy.category == 'pet') ..._buildPetEditFields()
            else if (widget.policy.category == 'home') ..._buildHomeEditFields()
            else if (widget.policy.category == 'appliance') ..._buildWarrantyEditFields()
            else ..._buildDefaultEditFields(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _updatePolicy,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandRed,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isSaving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save and Continue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAutoEditFields() {
    return [
      _buildLabel('Payment'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(_paymentTypes, _paymentType, 'Yearly', (v) => setState(() => _paymentType = v!), isRed: true)),
        ],
      ),

      _buildLabel('Time Left (months)'),
      _buildTextField(_timeLeftController, '36'),

      _buildLabel('Payment completed'),
      _buildTextField(_paymentsCompletedController, '24'),

      _buildLabel('Total payments'),
      _buildTextField(_totalPaymentsController, '60'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Start Date'),
                _buildDateField(_startDateController, '12 Jan 2024'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('End Date'),
                _buildDateField(_endDateController, 'End Dec 2024'),
              ],
            ),
          ),
        ],
      ),

      _buildLabel('Vehicle Name'),
      _buildTextField(_nameController, 'Tesla Model S'),

      _buildLabel('Lending Company'),
      _buildTextField(_providerController, 'City Bank'),

      _buildAddDocumentsButton(),

      const SizedBox(height: 24),
      const Text('Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
      const SizedBox(height: 16),
      
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEBEBEB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.repeat, color: brandRed, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Auto-payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                      const SizedBox(height: 2),
                      const Text('Pay automatic every month', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isAutoPay, 
                    onChanged: (v) => setState(() => _isAutoPay = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: brandRed,
                    trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Payment Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Implement day picker or similar if needed, staying with existing day for now
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_paymentDay, style: const TextStyle(color: Color(0xFF555555), fontSize: 13, fontWeight: FontWeight.w500)),
                    const Icon(Icons.calendar_today_outlined, color: Color(0xFF555555), size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildPersonalEditFields() {
    return [
      _buildLabel('Select Insurance Type'),
      _buildDropdownField(_personalTypes, _personalInsuranceType, 'Select type', (v) => setState(() => _personalInsuranceType = v)),

      _buildLabel('Policy Name'),
      _buildTextField(_nameController, 'Policy Name'),

      _buildLabel('Premium'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(_paymentTypes, _paymentType, 'Yearly', (v) => setState(() => _paymentType = v!), isRed: true)),
        ],
      ),

      _buildLabel('Insurance Provider'),
      _buildTextField(_providerController, 'Provider Name'),

      _buildLabel('Renewal Date'),
      _buildDateField(_dateController, 'mm/dd/yy'),

      _buildLabel('Coverage Notes'),
      _buildTextField(_notesController, 'Any additional notes...', maxLines: 4),

      _buildAddDocumentsButton(),
      _buildRemindersSection(),
    ];
  }

  List<Widget> _buildPetEditFields() {
    return [
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
                _buildDateField(_startDateController, 'mm/dd/yyyy'),
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

      _buildLabel('Payment'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(_paymentTypes, _paymentType, 'Monthly', (v) => setState(() => _paymentType = v!), isRed: true)),
        ],
      ),

      _buildLabel('Coverage Notes'),
      _buildTextField(_notesController, 'Notes...', maxLines: 4),

      _buildAddDocumentsButton(),
      _buildRemindersSection(),
    ];
  }

  List<Widget> _buildHomeEditFields() {
    return [
      _buildLabel('Property Name'),
      _buildTextField(_nameController, 'Property Name'),

      _buildLabel('Property Address'),
      _buildTextField(_addressController, 'Address'),

      _buildLabel('Provider'),
      _buildTextField(_providerController, 'Insurance Co.'),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Policy Number'),
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

      _buildLabel('Payment'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(_paymentTypes, _paymentType, 'Monthly', (v) => setState(() => _paymentType = v!), isRed: true)),
        ],
      ),

      _buildLabel('Coverage Notes'),
      _buildTextField(_notesController, 'Notes...', maxLines: 4),

      _buildAddDocumentsButton(),
      _buildRemindersSection(),
    ];
  }

  List<Widget> _buildWarrantyEditFields() {
    return [
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

      _buildAddDocumentsButton(),
      _buildRemindersSection(),
    ];
  }

  Widget _buildRemindersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.repeat, color: brandRed, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Auto-payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                        const SizedBox(height: 2),
                        const Text('Pay automatic every month', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: _isAutoPay,
                      onChanged: (v) => setState(() => _isAutoPay = v),
                      activeThumbColor: Colors.white,
                      activeTrackColor: brandRed,
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Payment Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F1F1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_paymentDay, style: const TextStyle(color: Color(0xFF555555), fontSize: 13, fontWeight: FontWeight.w500)),
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF555555), size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDefaultEditFields() {
    return [
      _buildLabel(widget.policy.category == 'pet' ? 'Pet Name' : 'Name'),
      _buildTextField(_nameController, 'Name'),

      _buildLabel('Payment'),
      Row(
        children: [
          Expanded(child: _buildTextField(_amountController, 'Amount')),
          const SizedBox(width: 16),
          Expanded(child: _buildDropdownField(_paymentTypes, _paymentType, 'Yearly', (v) => setState(() => _paymentType = v!), isRed: true)),
        ],
      ),

      _buildLabel('Renewal Date'),
      _buildDateField(_dateController, 'mm/dd/yy'),

      const SizedBox(height: 24),
      const Text('Additional Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
      const SizedBox(height: 16),

      if (widget.policy.category == 'home') ...[
        _buildLabel('Property Address'),
        _buildTextField(_addressController, 'Address'),
      ],
      
      _buildLabel('Provider'),
      _buildTextField(_providerController, 'Provider name'),

      _buildLabel('Policy Number'),
      _buildTextField(_policyNumberController, 'Policy Number'),

      _buildLabel('Coverage Notes'),
      _buildTextField(_notesController, 'Notes...', maxLines: 4),

      _buildAddDocumentsButton(),
    ];
  }

  Widget _buildDropdownField(List<String> items, String? currentValue, String hint, ValueChanged<String?> onChanged, {bool isRed = false}) {
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
            hint: Text(hint, style: TextStyle(color: isRed ? brandRed : const Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w400)),
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: isRed ? brandRed : const Color(0xFF111111)),
            style: TextStyle(color: isRed ? brandRed : const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.w500),
            items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildAddDocumentsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: () {}, // Implement document management
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: brandRed, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        child: const Text('+Add Documents', style: TextStyle(color: brandRed, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13, fontWeight: FontWeight.w400),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          DateTime initialDate = DateTime.now();
          if (controller.text.isNotEmpty) {
            try { initialDate = DateFormat('MM/dd/yyyy').parse(controller.text); } catch (_) {}
          }
           final DateTime? result = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(primary: brandRed),
                ),
                child: child!,
              );
            },
          );

          if (result != null) {
            setState(() {
              controller.text = DateFormat('MM/dd/yyyy').format(result);
            });
          }
        },
        child: AbsorbPointer(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, color: Color(0xFF111111), fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13, fontWeight: FontWeight.w400),
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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}
