import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:plan_sync/features/home/view/widgets/schedule_preferences_button.dart';
import 'package:plan_sync/features/home/view/widgets/date_widget.dart';
import 'package:plan_sync/features/home/view/widgets/hud/top_notice_hud.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:provider/provider.dart';
import 'package:plan_sync/features/schedule/view/widgets/time_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VersionViewModel _versionVm;

  @override
  void initState() {
    super.initState();
    _versionVm = context.read<VersionViewModel>();
    _versionVm.addListener(_onVersionUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<HomeViewModel>();
      vm.startAppTour(context);
      if (vm.shouldInitializeNotifications) {
        _initNotifications();
      }
      if (_versionVm.updateFailed) _showUpdateFailedPopup();
    });
  }

  @override
  void dispose() {
    _versionVm.removeListener(_onVersionUpdate);
    super.dispose();
  }

  void _onVersionUpdate() {
    if (_versionVm.updateFailed && mounted) {
      _showUpdateFailedPopup();
    }
  }

  void _showUpdateFailedPopup() {
    _versionVm.clearUpdateFailed();
    PopupsWrapper.showInAppUpateFailedPopup(context: context);
  }

  Future<void> _initNotifications() async {
    if (!mounted) return;
    final vm = context.read<HomeViewModel>();
    final shouldPrompt = await vm.shouldShowNotificationDialog();
    if (shouldPrompt && mounted) {
      final granted = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Notifications will be sent for class alerts. Would you like to enable notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (granted == true) {
        await vm.onNotificationGranted();
      } else {
        await vm.onNotificationDenied();
      }
    }
    await vm.initNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final schedulePrefsKey =
        context.read<HomeViewModel>().schedulePreferencesButtonKey;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor:
              colorScheme.surfaceContainerHighest.withOpacity(0.98),
          elevation: 0.0,
          toolbarHeight: 80,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          )),
          title: Text(
            "Plan Sync",
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          actions: [
            SchedulePreferenceButton(key: schedulePrefsKey),
            const SizedBox(width: 16),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TopNoticeHud(),
                  const DateWidget(),
                  const SizedBox(height: 16),
                  const TimeTableWidget()
                ],
              ),
              const SizedBox(height: 60)
            ],
          ),
        ));
  }
}

