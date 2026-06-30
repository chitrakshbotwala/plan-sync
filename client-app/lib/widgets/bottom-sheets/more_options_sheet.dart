import 'package:flutter/material.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:provider/provider.dart';

/// "More" tab sheet: quick links to Settings and the Holiday List, plus a
/// quick theme toggle in the header.
class MoreOptionsSheet extends StatelessWidget {
  const MoreOptionsSheet({
    super.key,
    required this.onSettings,
    required this.onHolidayList,
  });

  final VoidCallback onSettings;
  final VoidCallback onHolidayList;

  @override
  Widget build(BuildContext context) {
    // Watch ThemeService so the sheet rebuilds with the live theme on toggle —
    // the modal route freezes the ancestor theme, so we re-apply it here.
    final appTheme = context.watch<ThemeService>();
    final themeData =
        appTheme.isDarkMode ? ThemeService.darkTheme : ThemeService.lightTheme;
    final colorScheme = themeData.colorScheme;

    return Theme(
      data: themeData,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: _content(context, colorScheme),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'More',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const _ThemeToggle(),
            ],
          ),
          const SizedBox(height: 16),
          _MoreOptionTile(
            icon: Icons.celebration_outlined,
            title: 'Holiday List',
            subtitle: 'Holidays & academic breaks',
            onTap: onHolidayList,
          ),
          const SizedBox(height: 8),
          _MoreOptionTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Profile, theme, account',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.watch<ThemeService>();
    final isDark = appTheme.isDarkMode;

    return Material(
      color: colorScheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: appTheme.toggleTheme,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                isDark ? 'Light mode' : 'Dark mode',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreOptionTile extends StatelessWidget {
  const _MoreOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
