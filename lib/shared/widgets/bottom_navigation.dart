import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/theme_provider.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;

  const BottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.cardBackground.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: themeProvider.borderColor, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_outlined,
                      label: 'Ana Sayfa',
                      isActive: currentIndex == 0,
                      onTap: () => context.go('/'),
                      themeProvider: themeProvider,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.child_care_outlined,
                      label: 'Bebeklerim',
                      isActive: currentIndex == 1,
                      onTap: () => context.go('/babies'),
                      themeProvider: themeProvider,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'Grafikler',
                      isActive: currentIndex == 2,
                      onTap: () => context.go('/charts'),
                      themeProvider: themeProvider,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.photo_camera_outlined,
                      label: 'Anılar',
                      isActive: currentIndex == 3,
                      onTap: () => context.go('/memories'),
                      themeProvider: themeProvider,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.settings_outlined,
                      label: 'Ayarlar',
                      isActive: currentIndex == 4,
                      onTap: () => context.go('/settings'),
                      themeProvider: themeProvider,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final ThemeProvider themeProvider;

  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? themeProvider.primaryColor
                  : themeProvider.mutedForegroundColor,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? themeProvider.primaryColor
                    : themeProvider.mutedForegroundColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
