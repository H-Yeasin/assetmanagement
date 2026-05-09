import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/loan_model.dart';
import 'utils/loan_calculations.dart';
import '../Home_Dashboard/widgets.dart';

class AdditionalDetailsScreen extends StatelessWidget {
  final Loan loan;

  const AdditionalDetailsScreen({super.key, required this.loan});

  double _estimatedRemainingBalance() {
    return LoanCalculations.estimatedRemainingBalance(loan);
  }

  String _interestText() {
    if (loan.interestRate == 0) return 'N/A';
    return '${NumberFormat('#,##0.##').format(loan.interestRate)}%';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMortgage = loan.category == 'mortgage';
    final bool isCarLoan = loan.category == 'car';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F5), // Light pinkish-grey background
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
                  const SizedBox(width: 24), // Balance the back arrow
                ],
              ),
            ),

            // ── Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: isMortgage
                    ? _buildMortgageDetails()
                    : (isCarLoan
                          ? _buildCarLoanDetails()
                          : _buildDefaultDetails()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarLoanDetails() {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _DetailCard(
              iconPath: 'assets/images/icon/car_loan.png',
              iconColor: const Color(0xFF2196F3), // Blue
              title: 'Vehicle',
              value: loan.name,
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/installment.png',
              iconColor: const Color(0xFF9C27B0), // Purple
              title: 'Payment Amount',
              value: NumberFormat.simpleCurrency().format(loan.monthlyPayment),
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/loan.png', // Or use icon/car_loan
              iconColor: brandRed,
              title: 'Original Loan',
              value: NumberFormat.simpleCurrency().format(loan.totalAmount),
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/remaining.png',
              iconColor: const Color(0xFF4CAF50), // Green
              title: 'Remaining Loan',
              value: NumberFormat.simpleCurrency().format(
                _estimatedRemainingBalance(),
              ),
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/installment.png',
              iconColor: const Color(0xFFFFC107), // Amber
              title: 'Payments',
              value: '${loan.completedPayments} / ${loan.totalPayments}',
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/intarest_rate.png',
              iconColor: const Color(0xFFE91E63), // Pink
              title: 'Interest Rate',
              value: _interestText(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMortgageDetails() {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _DetailCard(
              iconPath: 'assets/images/icon/housing.png',
              iconColor: const Color(0xFF9C27B0), // Purple
              title: 'Property',
              value: loan.apartmentName ?? 'N/A',
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/lending_bank.png',
              iconColor: const Color(0xFF2196F3), // Blue
              title: 'Lending Bank',
              value: loan.lender ?? 'N/A',
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/amortization.png',
              iconColor: const Color(0xFFFFC107), // Amber/Yellow
              title: 'Amortization',
              value: loan.amortizationPeriod ?? 'N/A',
            ),
            _DetailCard(
              iconPath: 'assets/images/icon/renewal_date.png',
              iconColor: const Color(0xFF673AB7), // Deep Purple
              title: 'Renewal Date',
              value: loan.endDate != null
                  ? DateFormat('MMM dd, yyyy').format(loan.endDate!)
                  : 'N/A',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FullWidthDetailCard(
          iconPath: 'assets/images/icon/address.png',
          iconColor: const Color(0xFF4CAF50), // Green
          title: 'Address',
          value: loan.propertyAddress ?? 'N/A',
        ),
      ],
    );
  }

  Widget _buildDefaultDetails() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _DetailCard(
          iconPath: 'assets/images/icon/intarest_rate.png',
          iconColor: Colors.purple,
          title: 'Interest Rate',
          value: _interestText(),
        ),
        _DetailCard(
          iconPath: 'assets/images/icon/installment.png',
          iconColor: Colors.blue,
          title: 'Payment Amount',
          value: NumberFormat.simpleCurrency().format(loan.monthlyPayment),
        ),
        _DetailCard(
          iconPath: 'assets/images/icon/loan.png',
          iconColor: brandRed,
          title: 'Total Amount',
          value: NumberFormat.simpleCurrency().format(loan.totalAmount),
        ),
        _DetailCard(
          iconPath: 'assets/images/icon/remaining.png',
          iconColor: Colors.green,
          title: 'Balance Left',
          value: NumberFormat.simpleCurrency().format(
            _estimatedRemainingBalance(),
          ),
        ),
      ],
    );
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
        crossAxisAlignment: CrossAxisAlignment.center, // Center icon with text
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconPath,
              width: 22,
              height: 22,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.info_outline, size: 22, color: iconColor),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888888),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
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

class _FullWidthDetailCard extends StatelessWidget {
  final String iconPath;
  final Color iconColor;
  final String title;
  final String value;

  const _FullWidthDetailCard({
    required this.iconPath,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              iconPath,
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.location_on_outlined, size: 24, color: iconColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
