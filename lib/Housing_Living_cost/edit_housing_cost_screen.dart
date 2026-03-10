import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Home_Dashboard/widgets.dart';
import '../Loan_Screen/loan_widgets.dart';
import 'models/housing_cost_model.dart';
import '../services/housing_service.dart';
import '../Loan_Screen/add_documents_screen.dart';

class EditHousingCostScreen extends StatefulWidget {
  final HousingCost cost;

  const EditHousingCostScreen({super.key, required this.cost});

  @override
  State<EditHousingCostScreen> createState() => _EditHousingCostScreenState();
}

class _EditHousingCostScreenState extends State<EditHousingCostScreen> {
  final HousingService _apiService = HousingService();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _dueDateController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  late bool _autoPay;
  bool _isSaving = false;
  List<Map<String, dynamic>> _uploadedDocuments = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.cost.name);
    _amountController = TextEditingController(
      text: widget.cost.amount.toStringAsFixed(2),
    );
    _dueDateController = TextEditingController(
      text: widget.cost.dueDate != null
          ? DateFormat('MM/dd/yy').format(widget.cost.dueDate!)
          : '',
    );
    _notesController = TextEditingController(text: widget.cost.notes ?? '');
    _selectedCategory = widget.cost.category;
    _autoPay = widget.cost.autoPay;
    _uploadedDocuments = widget.cost.documents.map((doc) {
      if (doc is Map<String, dynamic>) return doc;
      return {
        'id': doc is String ? doc : (doc as dynamic).id,
        'name': 'Document',
        'type': 'pdf',
        'date': DateTime.now(),
      };
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dueDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime initialDate = widget.cost.dueDate ?? DateTime.now();
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

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a cost name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount =
          double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0;
      DateTime? dueDate;
      if (_dueDateController.text.isNotEmpty) {
        try {
          dueDate = DateFormat('MM/dd/yy').parse(_dueDateController.text);
        } catch (_) {}
      }

      final updates = <String, dynamic>{
        'name': _nameController.text,
        'category': _selectedCategory,
        'amount': amount,
        'autoPay': _autoPay,
        'notes': _notesController.text,
        'documents': _uploadedDocuments.map((d) => d['id']).toList(),
      };
      if (dueDate != null) {
        updates['dueDate'] = dueDate.toIso8601String();
      }

      await _apiService.updateHousingCost(widget.cost.id!, updates);

      if (_autoPay && dueDate != null) {
        // Use the due date for the auto-pay reminder
        // Currently setting reminder for the due date itself
        final pDate = dueDate;

        await _apiService.createReminder(
          itemId: widget.cost.id!,
          itemType: 'housing',
          title: 'Housing Payment Update: ${_nameController.text}',
          remindAt: pDate,
          note: 'Updated automatic reminder for your housing cost.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Housing cost updated!')));
        Navigator.pop(context, true);
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
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Edit Housing Cost',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
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
                    const SizedBox(height: 8),

                    // Cost Name
                    _buildLabel('Cost Name'),
                    _buildInputField(
                      controller: _nameController,
                      hint: 'Cost name',
                    ),
                    const SizedBox(height: 20),

                    // Amount + Category
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Amount'),
                              _buildInputField(
                                controller: _amountController,
                                hint: '\$0.00',
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

                    // Due Date
                    _buildLabel('Due Date'),
                    _buildInputField(
                      controller: _dueDateController,
                      hint: 'mm/dd/yy',
                      isDate: true,
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    _buildLabel('Notes'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEBEBEB)),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 4,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111111),
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          hintText: 'Add notes...',
                          hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Auto-pay toggle
                    Container(
                      padding: const EdgeInsets.all(16),
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
                            value: _autoPay,
                            onChanged: (v) => setState(() => _autoPay = v),
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFFC61C36),
                            trackOutlineColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildAddDocumentsButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Save Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveChanges,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: brandRed,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
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
                      width: 18,
                      height: 18,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.category, size: 18),
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
            builder: (_) => AddDocumentsScreen(
              initialDocuments: _uploadedDocuments,
              module: 'housing',
            ),
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
}
