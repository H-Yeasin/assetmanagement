import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/housing_cost_model.dart';
import 'services/housing_api_service.dart';
import 'housing_widgets.dart';
import 'housing_additional_details_screen.dart';
import 'edit_housing_cost_screen.dart';
import '../Loan_Screen/loan_widgets.dart';
import '../Loan_Screen/models/document_model.dart';
import 'housing_add_documents_screen.dart';

class HousingCostDetailScreen extends StatefulWidget {
  final HousingCost cost;

  const HousingCostDetailScreen({super.key, required this.cost});

  @override
  State<HousingCostDetailScreen> createState() => _HousingCostDetailScreenState();
}

class _HousingCostDetailScreenState extends State<HousingCostDetailScreen> {
  final HousingApiService _apiService = HousingApiService();
  late HousingCost _cost;

  bool _reminderEnabled = true;
  String _reminderTiming = 'Same day';

  final List<String> _reminderTimings = [
    'Same day',
    '1 day before',
    '3 days before',
    '1 week before',
  ];

  @override
  void initState() {
    super.initState();
    _cost = widget.cost;
    _refreshCost();
  }

  Future<void> _refreshCost() async {
    if (_cost.id == null) return;
    try {
      final updated = await _apiService.getHousingCost(_cost.id!);
      if (mounted) setState(() => _cost = updated);
    } catch (_) {}
  }

  void _showPaymentModal() {
    showDialog(
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
                child: HousingPaymentModal(
                  cost: _cost,
                  onPaymentConfirmed: _refreshCost,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderModal() {
    showDialog(
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
                child: HousingReminderModal(cost: _cost),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAutoPay(bool value) async {
    try {
      final updated = await _apiService.updateHousingCost(_cost.id!, {'autoPay': value});
      setState(() => _cost = updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String get _categoryLabel {
    final catInfo = HousingCost.displayCategories.firstWhere(
      (c) => c['id'] == _cost.category,
      orElse: () => {'label': _cost.category},
    );
    return catInfo['label'] ?? _cost.category;
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, true),
                    child: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF111111)),
                  ),
                  Expanded(
                    child: Text(
                      _categoryLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditHousingCostScreen(cost: _cost)),
                      );
                      if (result == true) _refreshCost();
                    },
                    child: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC61C36)),
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
                    const SizedBox(height: 16),

                    // ── Summary Card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE7E9).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Monthly Payment:',
                            style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            NumberFormat('#,##0.00').format(_cost.amount),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Pay / Remind ──
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/setup_payment.png',
                            label: 'Pay',
                            onTap: _showPaymentModal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            iconPath: 'assets/images/icon/remind.png',
                            label: 'Remind',
                            onTap: _showReminderModal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Additional Details ──
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HousingAdditionalDetailsScreen(cost: _cost),
                          ),
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
                              width: 18,
                              height: 18,
                              errorBuilder: (c, e, s) => const Icon(Icons.apps, color: Color(0xFFC61C36), size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Additional Details',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC61C36)),
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (_) => HousingAddDocumentsScreen(
                                  cost: _cost,
                                  initialDocuments: _cost.documents.map((doc) {
                                    if (doc is Map<String, dynamic>) {
                                      return {
                                        'id': doc['_id'] ?? doc['id'] ?? '',
                                        'name': doc['displayName'] ?? doc['name'] ?? 'Existing Document',
                                        'type': (doc['mimeType']?.toString().contains('pdf') == true) || doc['type'] == 'pdf' ? 'pdf' : 'image',
                                        'date': doc['createdAt'] != null ? DateTime.tryParse(doc['createdAt']) ?? DateTime.now() : (doc['date'] is DateTime ? doc['date'] : DateTime.now()),
                                        'path': doc['path'],
                                      };
                                    }
                                    if (doc is DocumentFile) {
                                      return {
                                        'id': doc.id,
                                        'name': doc.displayName,
                                        'type': doc.mimeType.contains('pdf') ? 'pdf' : 'image',
                                        'date': doc.createdAt ?? DateTime.now(),
                                        'path': doc.path,
                                      };
                                    }
                                    return {
                                      'id': doc is String ? doc : doc.toString(),
                                      'name': 'Existing Document',
                                      'type': 'pdf',
                                      'date': DateTime.now(),
                                    };
                                  }).toList(),
                                )
                              )
                            );
                            if (result != null && result is List<Map<String, dynamic>>) {
                              final docIds = result.map((d) => d['id'] as String).toList();
                              
                              try {
                                await _apiService.updateHousingCost(_cost.id!, {'documents': docIds});
                                await _refreshCost();
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error updating documents: $e')),
                                  );
                                }
                              }
                            }
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.add, color: Color(0xFFC61C36), size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Add Documents',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFC61C36)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Document list
                    if (_cost.documents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'No documents attached',
                          style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
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
                                color: HousingCost.iconBgColorForCategory(_cost.category),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                HousingCost.iconForCategory(_cost.category),
                                width: 20, height: 20,
                                errorBuilder: (c, e, s) => const Icon(Icons.folder, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_cost.documents.length} Documents',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111111)),
                                  ),
                                  Text(
                                    '${_cost.name}_attachments',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // ── Auto-payment Toggle ──
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
                            value: _cost.autoPay,
                            onChanged: _toggleAutoPay,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFFC61C36),
                            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Reminders ──
                    const Text(
                      'Reminders',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
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

                    const SizedBox(height: 20),

                    // ── Notes ──
                    const Text(
                      'Notes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
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
                        _cost.notes?.isNotEmpty == true 
                            ? _cost.notes! 
                            : 'No notes added yet.',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF555555), height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 32),
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
            Image.asset(iconPath, width: 32, height: 32,
                errorBuilder: (c, e, s) => const Icon(Icons.image, size: 32)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111111))),
          ],
        ),
      ),
    );
  }
}
