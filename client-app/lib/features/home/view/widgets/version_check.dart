import 'package:flutter/material.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/core/util/external_links.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:provider/provider.dart';

class VersionCheckWidget extends StatelessWidget {
  const VersionCheckWidget({super.key});

  Future<void> _openStore(BuildContext context) async {
    try {
      await ExternalLinks.store();
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.error(
        'Failed to open store',
        'Could not open the app store. Please try again.',
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = Provider.of<ThemeService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 8,
        right: 16,
        left: 16,
      ),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: appTheme.isDarkMode
              ? BorderSide.none
              : BorderSide(
                  color: colorScheme.onSurfaceVariant,
                ),
        ),
        color: appTheme.isDarkMode
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ListTile(
            title: Text(
              "Update Available",
              style: TextStyle(
                  color: appTheme.isDarkMode
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant),
            ),
            subtitle: Text(
              "A new version of Plan Sync is available "
              "with bug fixes and performance improvements. Tap to download and install.",
              style: TextStyle(
                  color: appTheme.isDarkMode
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant),
            ),
            contentPadding: const EdgeInsets.all(0),
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: AssetImage(
                'assets/favicon.png',
              ),
            ),
          ),
          FilledButton(
            style: ButtonStyle(
                elevation: const WidgetStatePropertyAll(0.0),
                backgroundColor: WidgetStatePropertyAll(colorScheme.secondary),
                foregroundColor:
                    WidgetStatePropertyAll(colorScheme.onSecondary),
                shape: const WidgetStatePropertyAll(StadiumBorder())),
            onPressed: () => _openStore(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_rounded),
                SizedBox(width: 8),
                Text('Download')
              ],
            ),
          ),
        ],
      ),
    );
  }
}
