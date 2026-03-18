import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/shared_add_documents_screen.dart';
import 'models/housing_cost_model.dart';

class HousingAddDocumentsScreen extends StatelessWidget {
  final HousingCost? cost;
  final List<Map<String, dynamic>>? initialDocuments;

  const HousingAddDocumentsScreen({
    super.key,
    this.cost,
    this.initialDocuments,
  });

  @override
  Widget build(BuildContext context) {
    Widget? reminderCard;
    if (cost != null) {
      reminderCard = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFC61C36).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFFC61C36),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Reminders',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cost?.dueDate != null
                        ? DateFormat('MMMM dd, yyyy').format(cost!.dueDate!)
                        : 'N/A',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Text(
                    NumberFormat.simpleCurrency(
                      decimalDigits: 2,
                    ).format(cost?.amount ?? 0),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                if (cost?.autoPay ?? false)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Paid automatically',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return SharedAddDocumentsScreen(
      title: 'Add Documents',
      module: 'housing',
      itemId: cost?.id,
      initialDocuments: initialDocuments,
      reminderCard: reminderCard,
      notes: cost?.notes,
    );
  }
}
