import 'package:flutter/material.dart';
import 'models/loan_model.dart';
import 'package:intl/intl.dart';

class LoanAdditionalDetailsScreen extends StatelessWidget {
  final Loan loan;

  const LoanAdditionalDetailsScreen({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    final bool isMortgage = loan.category == 'mortgage';

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
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Additional Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  const SizedBox(width: 28),
                ],
              ),
            ),

            // ── Grid ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/housing.png',
                            iconBgColor: const Color(0xFFFFEBEE),
                            label: isMortgage ? 'Property' : 'Loan Name',
                            value: loan.name,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/lending_bank.png',
                            iconBgColor: const Color(0xFFE3F2FD),
                            label: 'Lending Bank',
                            value: loan.lender ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/amortization.png',
                            iconBgColor: const Color(0xFFFFF8E1),
                            label: 'Amortization',
                            value: loan.amortizationPeriod ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/renewal_date.png',
                            iconBgColor: const Color(0xFFF3E5F5),
                            label: isMortgage ? 'Renewal Date' : 'End Date',
                            value: loan.endDate != null
                                ? DateFormat(
                                    'MMM dd, yyyy',
                                  ).format(loan.endDate!)
                                : 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/address.png',
                            iconBgColor: const Color(0xFFE8F5E9),
                            label: 'Address',
                            value: loan.propertyAddress ?? 'N/A',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailCard(
                            iconPath:
                                'assets/images/icon/housing.png', // Fallback
                            iconBgColor: const Color(0xFFE0F2F1),
                            label: 'Apartment',
                            value: loan.apartmentName ?? 'N/A',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            iconPath:
                                'assets/images/icon/additional_detail.png',
                            iconBgColor: const Color(0xFFEEEEEE),
                            label: 'Interest Rate',
                            value: '${loan.interestRate}%',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDetailCard(
                            iconPath: 'assets/images/icon/total_payment.png',
                            iconBgColor: const Color(0xFFF1F8E9),
                            label: 'Total Amount',
                            value: NumberFormat.simpleCurrency().format(
                              loan.totalAmount,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildDetailCard({
    required String iconPath,
    required Color iconBgColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconPath,
              width: 20,
              height: 20,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.info_outline, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111111),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
