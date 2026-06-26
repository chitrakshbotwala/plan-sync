import 'package:plan_sync/core/services/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('ScaffoldWithNavBar'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = Provider.of<ThemeService>(context, listen: false);
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: SalomonBottomBar(
          curve: Curves.easeInOutExpo,
          duration: Durations.medium2,
          selectedColorOpacity: 0.08,
          itemShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: appTheme.isDarkMode
              ? colorScheme.surface
              : const Color(0xffafddb9),
          selectedItemColor: appTheme.isDarkMode
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
          unselectedItemColor: appTheme.isDarkMode
              ? colorScheme.onSurface
              : colorScheme.onSurfaceVariant.withValues(alpha: 0.64),
          items: <SalomonBottomBarItem>[
            SalomonBottomBarItem(
              icon: const Icon(Icons.access_time_outlined),
              title: const Text('Today'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.bar_chart),
              title: const Text('Attendance'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.location_on_outlined),
              title: const Text('Campus'),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.more_horiz),
              title: const Text('More'),
            ),
          ],
          currentIndex: navigationShell.currentIndex,
          onTap: (int index) => _onTap(context, index),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
