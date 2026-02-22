import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Documents',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a Category and your important documents\nwill always be accessible.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF888888),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.search, color: Color(0xFFBBBBBB)),
                    SizedBox(width: 12),
                    Text(
                      'Search for documents...',
                      style: TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Category Options (2x2)
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: [
                  _VaultEntry(icon: Icons.account_balance_wallet_outlined, title: 'Loans', iconColor: brandRed),
                  _VaultEntry(icon: Icons.home_outlined, title: 'Housing / Living Costs', iconColor: Colors.purple),
                  _VaultEntry(icon: Icons.shield_outlined, title: 'Insurance', iconColor: Colors.blue),
                  _VaultEntry(icon: Icons.description_outlined, title: 'Documents', iconColor: Colors.orange),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;

  const _VaultEntry({
    required this.icon,
    required this.title,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
