import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';

class MainNavigation extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigation({super.key, required this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const CalendarScreen(),
      const ChatScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
        ),
      ),
      bottomNavigationBar: Center(
        heightFactor: 1.0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outline, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabSelected,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: isDark ? AppTheme.surfaceDarkElevated : AppTheme.primaryLight,
              elevation: 0,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box, color: theme.colorScheme.primary),
                  label: 'Tugas',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                  label: 'Jadwal',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.support_agent_outlined),
                  selectedIcon: Icon(Icons.support_agent, color: theme.colorScheme.primary),
                  label: 'Assistant',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
