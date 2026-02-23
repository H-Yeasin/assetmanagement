import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/housing_cost_model.dart';
import '../Home_Dashboard/widgets.dart';

class HousingAdditionalDetailsScreen extends StatelessWidget {
  final HousingCost cost;

  const HousingAdditionalDetailsScreen({super.key, required this.cost});

  @override
  Widget build(BuildContext context) {
    final categoryLabel = HousingCost.displayCategories.firstWhere(
      (c) => c['id'] == cost.category,
      orElse: () => {'label': cost.category},
    )['label']!;

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
                  const Expanded(
                    child: Text(
                      'Additional Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Category Subtitle ──
                    Text(
                      categoryLabel,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                    ),
                    const SizedBox(height: 20),

                    // ── Detail Grid ──
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: cost.category == 'housing'
                          ? [
                              _DetailCard(
                                iconPath: 'assets/images/icon/farm_vila.png',
                                iconColor: _colorForCategory(cost.category),
                                title: categoryLabel,
                                value: cost.name,
                              ),
                              _DetailCard(
                                iconPath: 'assets/images/icon/Property_Taxes.png',
                                iconColor: const Color(0xFF888888), // greyish
                                title: 'Property Taxes',
                                value: '\$ ${NumberFormat('#,##0.00').format(cost.amount * 0.12)}',
                              ),
                              _DetailCard(
                                iconPath: 'assets/images/icon/condo.png',
                                iconColor: const Color(0xFF2196F3), // blue
                                title: 'Condo/HOA',
                                value: '\$ ${NumberFormat('#,##0.00').format(cost.amount * 0.11)}',
                              ),
                              _DetailCard(
                                iconPath: 'assets/images/icon/installment.png',
                                iconColor: const Color(0xFF4CAF50), // green
                                title: 'Monthly Cost',
                                value: '\$ ${NumberFormat('#,##0.00').format(cost.amount)}',
                              ),
                            ]
                          : [
                              _DetailCard(
                                iconPath: HousingCost.iconForCategory(cost.category),
                                iconColor: _colorForCategory(cost.category),
                                title: categoryLabel,
                                value: cost.name,
                              ),
                              _DetailCard(
                                iconPath: 'assets/images/icon/installment.png',
                                iconColor: const Color(0xFF2196F3), // blue
                                title: 'Installment',
                                value: '\$${NumberFormat('#,##0.00').format(cost.amount)} (Monthly)',
                              ),
                              _DetailCard(
                                iconPath: 'assets/images/icon/due_date.png',
                                iconColor: const Color(0xFF9C27B0), // purple
                                title: 'Due Date',
                                value: cost.dueDate != null ? DateFormat('d MMMM').format(cost.dueDate!) : 'Not set',
                              ),
                            ],
                    ),

                    const SizedBox(height: 20),

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
                            child: Row(
                              children: [
                                const Text('Same day', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF888888)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC61C36),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: CircleAvatar(radius: 10, backgroundColor: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForCategory(String category) {
    switch (category) {
      case 'housing': return const Color(0xFF2196F3);
      case 'utilities': return const Color(0xFFFFC107);
      case 'internet': return const Color(0xFF4CAF50);
      case 'transportation': return const Color(0xFF3F51B5);
      case 'insurance': return const Color(0xFFFF9800);
      case 'maintenance': return const Color(0xFF9C27B0);
      default: return brandRed;
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final String title;
  final String value;

  const _DetailCard({
    required this.iconPath,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            iconPath,
            width: 32,
            height: 32,
            errorBuilder: (context, error, stackTrace) => Icon(Icons.info_outline, size: 32, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
