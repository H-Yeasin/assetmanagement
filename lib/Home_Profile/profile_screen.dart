import 'package:flutter/material.dart';
import '../Home_Dashboard/widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 32),
              
              // User Info
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F8F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: brandRed, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'John Doe',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'john.doe@example.com',
                        style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Settings List
              _ProfileSection(title: 'Account Settings', items: [
                _ProfileItem(icon: Icons.person_outline, label: 'Edit Profile'),
                _ProfileItem(icon: Icons.lock_outline, label: 'Change Password'),
                _ProfileItem(icon: Icons.notifications_none, label: 'Notifications'),
              ]),
              
              const SizedBox(height: 32),
              
              _ProfileSection(title: 'More', items: [
                _ProfileItem(icon: Icons.help_outline, label: 'Help & Support'),
                _ProfileItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
                _ProfileItem(icon: Icons.logout, label: 'Logout', color: brandRed),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _ProfileSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF888888)),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ProfileItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF111111)).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? const Color(0xFF111111), size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w500, 
              color: color ?? const Color(0xFF111111),
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xFFBBBBBB)),
        ],
      ),
    );
  }
}
