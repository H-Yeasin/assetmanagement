import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';

class LoanCategoryScreen extends StatelessWidget {
  const LoanCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Loan Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _CategoryItem(
            iconPath: 'assets/images/icon/home_morgarate.png',
            label: 'Home Mortgage',
            bgColor: const Color(0xFFE3F2FD),
            onTap: () => Navigator.pop(context, 'Home Mortgage'),
          ),
          _CategoryItem(
            iconPath: 'assets/images/icon/car_loan.png',
            label: 'Car Loan',
            bgColor: const Color(0xFFFFF8E1),
            onTap: () => Navigator.pop(context, 'Car Loan'),
          ),
          _CategoryItem(
            iconPath: 'assets/images/icon/business_loan.png',
            label: 'Business Loan',
            bgColor: const Color(0xFFE8F5E9),
            onTap: () => Navigator.pop(context, 'Business Loan'),
          ),
          _CategoryItem(
            iconPath: 'assets/images/icon/personal_loan.png',
            label: 'Personal Loan',
            bgColor: const Color(0xFFE8F5E9),
            onTap: () => Navigator.pop(context, 'Personal Loan'),
          ),
          _CategoryItem(
            iconPath: 'assets/images/icon/student_loan.png',
            label: 'Students Loan',
            bgColor: const Color(0xFFF3E5F5),
            onTap: () => Navigator.pop(context, 'Students Loan'),
          ),
          _CategoryItem(
            iconPath: 'assets/images/icon/custom_loan.png',
            label: 'Custom Loan',
            bgColor: const Color(0xFFFFEBEE),
            onTap: () => Navigator.pop(context, 'Custom Loan'),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color bgColor;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.iconPath,
    required this.label,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Image.asset(iconPath, width: 20, height: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF111111)),
            ),
          ],
        ),
      ),
    );
  }
}
