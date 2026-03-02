import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/loan_widgets.dart';
import 'models/housing_cost_model.dart';
import 'services/housing_api_service.dart';
import '../Loan_Screen/add_documents_screen.dart';

class AddHousingCostScreen extends StatefulWidget {
  const AddHousingCostScreen({super.key});

  @override
  State<AddHousingCostScreen> createState() => _AddHousingCostScreenState();
}

class _AddHousingCostScreenState extends State<AddHousingCostScreen> {
  final HousingApiService _apiService = HousingApiService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  
  String _selectedCategory = 'housing';
  bool _reminderEnabled = true;
  String _reminderTiming = 'Same day';
  bool _isSaving = false;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  final List<String> _reminderTimings = [
    'Same day',
    '1 day before',
    '3 days before',
    '1 week before',
  ];

  bool get _isHousingCategory => _selectedCategory == 'housing';

  String get _screenTitle => _isHousingCategory ? 'Housing/Living Costs' : 'Living Costs';

  String get _amountLabel => _isHousingCategory ? 'Monthly Housing Cost' : 'Amount';

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    DateTime initialDate = DateTime.now();
    if (controller.text.isNotEmpty) {
      try {
        initialDate = DateFormat('MM/dd/yy').parse(controller.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDialog<DateTime>(
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
                child: CustomCalendarModal(initialDate: initialDate),
              ),
            ),
          ),
        ],
      ),
    );

    if (picked != null) {
      setState(() {
        controller.text = DateFormat('MM/dd/yy').format(picked);
      });
    }
  }

  Future<void> _saveCost() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a cost name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      DateTime? dueDate;
      if (_dueDateController.text.isNotEmpty) {
        try {
          dueDate = DateFormat('MM/dd/yy').parse(_dueDateController.text);
        } catch (_) {}
      }

      final cost = HousingCost(
        userId: '',
        name: _nameController.text,
        category: _selectedCategory,
        amount: amount,
        dueDate: dueDate,
        autoPay: _reminderEnabled, // Using reminder toggle as autoPay hint if no specific toggle
        notes: _nameController.text, // Using name as notes for now or check if notes controller exists
        documents: _uploadedDocuments.map((d) => d['id']).toList(),
      );

      final createdCost = await _apiService.createHousingCost(cost);

      if (_reminderEnabled && createdCost.id != null && dueDate != null) {
        DateTime remindAt = dueDate;
        if (_reminderTiming == '1 day before') {
          remindAt = dueDate.subtract(const Duration(days: 1));
        } else if (_reminderTiming == '3 days before') {
          remindAt = dueDate.subtract(const Duration(days: 3));
        } else if (_reminderTiming == '1 week before') {
          remindAt = dueDate.subtract(const Duration(days: 7));
        }

        await _apiService.createReminder(
          itemId: createdCost.id!,
          itemType: 'housing',
          title: 'Payment Reminder: ${createdCost.name}',
          remindAt: remindAt,
          note: 'Automatic reminder for your housing cost.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Housing cost saved!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F5),
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
                    child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111111)),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _screenTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
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
                    const SizedBox(height: 8),

                    // ── Cost Name ──
                    _buildLabel('Cost Name'),
                    _buildInputField(
                      controller: _nameController,
                      hint: _isHousingCategory ? 'e.g. Rent, internet' : 'Gas Bill',
                    ),
                    const SizedBox(height: 20),

                    // ── Amount + Category Row ──
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel(_amountLabel),
                              _buildInputField(
                                controller: _amountController,
                                hint: _isHousingCategory ? '\$1,000' : '\$ 00.00',
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
                              _buildLabel('Category'),
                              _buildCategoryDropdown(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Due Date ──
                    _buildLabel('Due Date'),
                    _buildInputField(
                      controller: _dueDateController,
                      hint: 'mm/dd/yy',
                      isDate: true,
                    ),
                    const SizedBox(height: 24),

                    // ── Payment Reminders ──
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
                              color: const Color(0xFFFDE7E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/icon/remind.png',
                              width: 20, height: 20,
                              errorBuilder: (c, e, s) => const Icon(Icons.notifications, size: 20, color: Color(0xFFC61C36)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Payment Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
                                Text('4 days before date', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _reminderTiming,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF888888)),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                                items: _reminderTimings.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (val) => setState(() => _reminderTiming = val!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: _reminderEnabled,
                            onChanged: (v) => setState(() => _reminderEnabled = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFFC61C36),
                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // ── Documents Section ──
                  _buildAddDocumentsButton(),
                  const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Bottom Buttons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Add Another Entry (non-housing)
                  if (!_isHousingCategory) ...[
                    GestureDetector(
                      onTap: () async {
                        _saveCost();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color(0xFFC61C36), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Add Another Entry',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFC61C36)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Save & Continue
                  GestureDetector(
                    onTap: _isSaving ? null : _saveCost,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: brandRed,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Save & Continue',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
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
          style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            suffixIcon: isDate ? const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF888888)) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = HousingCost.displayCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBEBEB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF111111)),
          style: const TextStyle(fontSize: 15, color: Color(0xFF111111)),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['id'],
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: HousingCost.iconBgColorForCategory(cat['id']!),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      cat['icon']!,
                      width: 18, height: 18,
                      errorBuilder: (c, e, s) => const Icon(Icons.category, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cat['label']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
      ),
    );
  }

  Widget _buildAddDocumentsButton() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddDocumentsScreen(initialDocuments: _uploadedDocuments, module: 'housing'),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _uploadedDocuments.isEmpty ? brandRed : Colors.green),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: _uploadedDocuments.isEmpty ? brandRed : Colors.green, size: 20),
            const SizedBox(width: 4),
            Text(
              _uploadedDocuments.isEmpty ? 'Add Documents' : '${_uploadedDocuments.length} Documents Added',
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
}
