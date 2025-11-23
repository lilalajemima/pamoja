import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<NavigationItem> _navItems = [
    NavigationItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      route: '/main/home',
    ),
    NavigationItem(
      label: 'Explore',
      icon: Icons.search,
      activeIcon: Icons.search,
      route: '/main/explore',
    ),
    NavigationItem(
      label: 'Tracker',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      route: '/main/tracker',
    ),
    NavigationItem(
      label: 'Community',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      route: '/main/community',
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      route: '/main/profile',
    ),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      context.go(_navItems[index].route);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely determine selected index based on current route
    try {
      final location = GoRouterState.of(context).uri.toString();
      final foundIndex = _navItems.indexWhere(
        (item) => location.contains(item.route),
      );
      if (foundIndex != -1 && foundIndex != _selectedIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedIndex = foundIndex;
            });
          }
        });
      }
    } catch (e) {
      // Ignore routing errors
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: isDarkMode 
              ? const Color(0xFF757575) 
              : AppTheme.mediumGray,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
          ),
          items: _navItems.map((item) {
            final isSelected = _navItems.indexOf(item) == _selectedIndex;
            return BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}