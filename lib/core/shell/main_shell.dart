import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/create')) return 2;
    if (location.startsWith('/connect')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/explore');
        break;
      case 2:
        context.go('/create');
        break;
      case 3:
        context.go('/connect');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _selectedIndex(context);
    final isWide = MediaQuery.of(context).size.width >= 768;
    
    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;
    final unreadCount = chatState?.threads.fold<int>(0, (sum, t) => sum + t.unreadCount) ?? 0;

    if (isWide) {
      // Desktop/tablet: side navigation rail
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: context.colors.surface,
              selectedIndex: idx,
              onDestinationSelected: (i) => _onTap(context, i),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: context.colors.questBlue),
              selectedLabelTextStyle: TextStyle(
                color: context.colors.questBlue,
                fontWeight: FontWeight.w600,
              ),
              unselectedIconTheme: IconThemeData(
                color: context.colors.textMuted,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: context.colors.textMuted,
              ),
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.colors.questBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.questBlue.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.bolt, color: Colors.white, size: 22),
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Quest',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),

                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Explore'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.add_circle_outline),
                  selectedIcon: Icon(Icons.add_circle),
                  label: Text('Create'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people_alt_outlined),
                  selectedIcon: Icon(Icons.people_alt),
                  label: Text('Connect'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('You'),
                ),
              ],
            ),
            VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Mobile: bottom navigation bar
    return Scaffold(
      backgroundColor: context.colors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: context.colors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) => _onTap(context, i),
          backgroundColor: context.colors.background,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: context.colors.questBlue,
          unselectedItemColor: context.colors.textMuted,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 32),
              activeIcon: Icon(Icons.add_circle, size: 32),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: _buildConnectIcon(context, unreadCount, false),
              activeIcon: _buildConnectIcon(context, unreadCount, true),
              label: 'Connect',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectIcon(BuildContext context, int unreadCount, bool isActive) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(isActive ? Icons.people_alt : Icons.people_alt_outlined),
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
