import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/housing_service.dart';
import '../services/insurance_service.dart';
import '../services/loan_service.dart';

class ReminderPresentation {
  final String itemName;
  final String sectionLabel;
  final Color sectionColor;
  final String amountLabel;
  final String statusLabel;
  final bool isAuto;

  const ReminderPresentation({
    required this.itemName,
    required this.sectionLabel,
    required this.sectionColor,
    required this.amountLabel,
    required this.statusLabel,
    required this.isAuto,
  });
}

class ReminderPresentationResolver {
  final LoanService loanService;
  final HousingService housingService;
  final InsuranceService insuranceService;

  const ReminderPresentationResolver({
    required this.loanService,
    required this.housingService,
    required this.insuranceService,
  });

  Future<ReminderPresentation> resolve(String? itemType, String? itemId) async {
    if (itemType == null || itemId == null || itemId.isEmpty) {
      return const ReminderPresentation(
        itemName: 'Reminder',
        sectionLabel: 'Unknown',
        sectionColor: Color(0xFF888888),
        amountLabel: '',
        statusLabel: 'Manual payment required',
        isAuto: false,
      );
    }

    try {
      switch (itemType) {
        case 'loan':
          final loan = await loanService.getLoan(itemId);
          return ReminderPresentation(
            itemName: loan.name,
            sectionLabel: 'Loans',
            sectionColor: const Color(0xFFC61C36),
            amountLabel: NumberFormat.simpleCurrency(
              decimalDigits: 2,
            ).format(loan.monthlyPayment),
            statusLabel: loan.autoPay
                ? 'Paid automatically'
                : 'Manual payment required',
            isAuto: loan.autoPay,
          );
        case 'housing':
          final cost = await housingService.getHousingCost(itemId);
          return ReminderPresentation(
            itemName: cost.name,
            sectionLabel: 'Housing/Living Costs',
            sectionColor: const Color(0xFF8E44AD),
            amountLabel: NumberFormat.simpleCurrency(
              decimalDigits: 2,
            ).format(cost.amount),
            statusLabel: cost.autoPay
                ? 'Paid automatically'
                : 'Manual payment required',
            isAuto: cost.autoPay,
          );
        case 'insurance':
          final policy = await insuranceService.getInsurance(itemId);
          final isAuto = policy.autoPayEnabledForStatus;
          return ReminderPresentation(
            itemName: policy.name,
            sectionLabel: 'Insurance',
            sectionColor: const Color(0xFF2196F3),
            amountLabel: NumberFormat.simpleCurrency(
              decimalDigits: 2,
            ).format(policy.premium),
            statusLabel: isAuto
                ? 'Paid automatically'
                : 'Manual payment required',
            isAuto: isAuto,
          );
        default:
          return const ReminderPresentation(
            itemName: 'Reminder',
            sectionLabel: 'Unknown',
            sectionColor: Color(0xFF888888),
            amountLabel: '',
            statusLabel: 'Manual payment required',
            isAuto: false,
          );
      }
    } catch (_) {
      return const ReminderPresentation(
        itemName: 'Reminder',
        sectionLabel: 'Unknown',
        sectionColor: Color(0xFF888888),
        amountLabel: '',
        statusLabel: 'Manual payment required',
        isAuto: false,
      );
    }
  }
}
