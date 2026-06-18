import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:plan_sync/widgets/buttons/schedule_preferences_button.dart';
import 'package:plan_sync/widgets/date_widget.dart';
import 'package:plan_sync/widgets/hud/top_notice_hud.dart';
import 'package:provider/provider.dart';
import '../widgets/time_table.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().onReady(context);
    });
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
                  Text(
                    "Time Sheet",
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const TimeTableWidget()
                ],
              ),
              const SizedBox(height: 60)
            ],
          ),
        ));
  }
}
