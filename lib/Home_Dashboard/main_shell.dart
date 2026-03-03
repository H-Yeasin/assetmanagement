import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _calculateSelectedIndex(BuildContext context) {
    // Determine the current index based on the route location
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/vault')) return 2;
    if (location.startsWith('/profile') || location.startsWith('/edit-profile'))
      return 3;
    // For '/my-loans' or others not directly on the nav bar, we can highlight home or leave it
    if (location.startsWith('/my-loans')) return 0; // Visual fallback
    return 0; // Default
  }

  void _onTabTapped(int index, BuildContext context) {
    if (index == 1) {
      _showAddItemSheet();
    } else {
      switch (index) {
        case 0:
          context.go('/home');
          break;
        case 2:
          context.go('/vault');
          break;
        case 3:
          context.go('/profile');
          break;
      }
    }
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddItemBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onTabTapped(index, context),
      ),
    );
  }
}
