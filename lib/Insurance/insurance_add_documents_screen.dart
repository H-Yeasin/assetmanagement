import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/shared_add_documents_screen.dart';
import 'models/insurance_model.dart';

class InsuranceAddDocumentsScreen extends StatelessWidget {
  final InsurancePolicy? policy;
  final List<Map<String, dynamic>>? initialDocuments;

  const InsuranceAddDocumentsScreen({
    super.key,
    this.policy,
    this.initialDocuments,
  });

  @override
  Widget build(BuildContext context) {
    Widget? reminderCard;
    if (policy != null) {
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
                    policy?.renewalDate != null
                        ? DateFormat(
                            'MMMM dd, yyyy',
                          ).format(policy!.renewalDate!)
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
                    ).format(policy?.premium ?? 0),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                if (policy?.isAutoPay ?? false)
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
      module: 'insurance',
      itemId: policy?.id,
      initialDocuments: initialDocuments,
      reminderCard: reminderCard,
      notes: policy?.coverageNotes,
    );
  }
}
