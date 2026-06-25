import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/features/settings/viewmodel/settings_view_model.dart';
import 'package:plan_sync/core/util/constants.dart';
import 'package:plan_sync/core/util/external_links.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:plan_sync/features/settings/view/widgets/logout_button.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _copyUID(BuildContext context) async {
    final uid = context.read<SettingsViewModel>().uid;

    if (uid == null) {
      CustomSnackbar.error(
        'Error',
        'No UID found. Please Login again.',
        context,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: uid));
    if (!context.mounted) return;
    CustomSnackbar.info(
      'Copied',
      'Your UID has been copied into the clipboard.',
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    final userImage = CachedNetworkImageProvider(
      vm.photoUrl ?? DEFAULT_USER_IMAGE,
      cacheKey: vm.uid ?? 'DEFAULT_USER_IMAGE',
    );

    const chillGuyImage = CachedNetworkImageProvider(
      CHILL_GUY_IMAGE,
      cacheKey: 'CHILL_GUY_IMAGE',
    );

    return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          elevation: 0.0,
          toolbarHeight: 80,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          )),
          title: Text(
            "Account",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          actions: const [
            LogoutButton(),
            SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // TODO: maybe remove this pun?
                GestureDetector(
                  onLongPress: vm.togglePun,
                  child: CircleAvatar(
                    radius: 64,
                    foregroundImage:
                        vm.isPunActivated ? chillGuyImage : userImage,
                    backgroundImage: const AssetImage('assets/favicon.png'),
                    backgroundColor: colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  vm.displayName ?? "Plan Sync Wizard",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  vm.email ?? "connect@plansync.in",
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.72),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Plan Sync v${vm.clientVersion} | ',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                    Text(
                      'Copy UID',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.72),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _copyUID(context),
                      enableFeedback: true,
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: colorScheme.onSurface,
                        semanticLabel: 'Copy',
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    Icons.downloading_rounded,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Set Primary Sections",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () => PopupsWrapper.changeSectionPreference(
                    context: context,
                  ),
                ),
                Consumer<AttendanceViewModel>(
                  builder: (context, attendance, _) => ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enableFeedback: true,
                    leading: Icon(
                      Icons.fact_check_outlined,
                      color: colorScheme.onSurface,
                    ),
                    title: Text(
                      "KIIT Portal Login",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      attendance.hasCredentials
                          ? "Connected · ${attendance.registrationNumber}"
                          : "Connect to track attendance",
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: colorScheme.onSurface,
                    ),
                    onTap: () =>
                        BottomSheets.kiitCredentials(context: context),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    Icons.school_outlined,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Request Features/Changes",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () => PopupsWrapper.requestFeature(
                    context: context,
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    Icons.report,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Report an error",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () => PopupsWrapper.reportError(
                    autoFill: false,
                    context: context,
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(Icons.share, color: colorScheme.onSurface),
                  title: Text(
                    "Share This App",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () {
                    BottomSheets.shareAppBottomSheet(context: context);
                    vm.logShareSheetOpen();
                    vm.logShareViaExternalApps();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Divider(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.48),
                  ),
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    FontAwesomeIcons.fileLines,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Terms of Service",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_right_rounded,
                      color: colorScheme.onSurface),
                  onTap: () async {
                    try {
                      await ExternalLinks.termsAndConditions();
                    } catch (e) {
                      if (!context.mounted) return;
                      CustomSnackbar.error(
                        'Failed to open link',
                        'Could not open Terms of Service. Please try again.',
                        context,
                      );
                    }
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    Icons.security_rounded,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Privacy Policy",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.onSurface,
                  ),
                  onTap: () async {
                    try {
                      await ExternalLinks.privacyPolicy();
                    } catch (e) {
                      if (!context.mounted) return;
                      CustomSnackbar.error(
                        'Failed to open link',
                        'Could not open Privacy Policy. Please try again.',
                        context,
                      );
                    }
                  },
                ),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  enableFeedback: true,
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    "Delete your account",
                    style: TextStyle(
                      color: colorScheme.error,
                    ),
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_right_rounded,
                    color: colorScheme.error,
                  ),
                  onTap: () => PopupsWrapper.deleteAccount(
                    context: context,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ));
  }
}
