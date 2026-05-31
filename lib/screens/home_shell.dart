import 'package:flutter/material.dart';

import '../core/auth/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'roulette_screen.dart';
import 'mood_ai_screen.dart';
import 'geo_tag_screen.dart';
import 'profile_screen.dart';

/// Root scaffold that hosts the four primary destinations and the shared
/// bottom navigation bar, matching the SummerDrift design.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.authService});

  final AuthService? authService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.route, label: 'маршрут', color: AppColors.coral),
    _NavItem(icon: Icons.psychology, label: 'ai', color: AppColors.warm),
    _NavItem(icon: Icons.location_on, label: 'тайники', color: AppColors.mint),
    _NavItem(icon: Icons.person, label: 'профиль', color: AppColors.coral),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      const RouletteScreen(),
      const MoodAiScreen(),
      const GeoTagScreen(),
      ProfileScreen(authService: widget.authService),
    ];

    return Scaffold(
      // IndexedStack keeps each screen's state alive when switching tabs.
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _BottomNav(
        items: _navItems,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: Color(0x0F000000), width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? item.color : AppColors.navInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: AppTextStyles.body(
                size: 11,
                weight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
