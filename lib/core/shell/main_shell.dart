import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/communities')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/messages')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/communities');
        break;
      case 2:
        context.go('/events');
        break;
      case 3:
        context.go('/messages');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 768;

    if (isWide) {
      // Desktop/tablet: side navigation rail
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.surface,
              selectedIndex: idx,
              onDestinationSelected: (i) => _onTap(context, i),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: AppColors.questBlue),
              selectedLabelTextStyle: const TextStyle(color: AppColors.questBlue, fontWeight: FontWeight.w600),
              unselectedIconTheme: const IconThemeData(color: AppColors.textMuted),
              unselectedLabelTextStyle: const TextStyle(color: AppColors.textMuted),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.questBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: AppColors.questBlue.withValues(alpha: 0.4), blurRadius: 12)],
                      ),
                      child: const Center(
                        child: Icon(Icons.bolt, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Quest❗', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Communities')),
                NavigationRailDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: Text('Events')),
                NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('Messages')),
                NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom navigation bar
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => _onTap(context, i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Communities'),
            BottomNavigationBarItem(icon: Icon(Icons.event_outlined), activeIcon: Icon(Icons.event), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
