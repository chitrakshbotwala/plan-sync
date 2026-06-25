import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:plan_sync/widgets/tutorials/app_target_focus.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AppTourService {
  late AppPreferencesRepository _appPreferences;

  late GlobalKey _schedulePreferencesButtonKey;
  GlobalKey get schedulePreferencesButtonKey => _schedulePreferencesButtonKey;

  late GlobalKey _sectionBarKey;
  GlobalKey get sectionBarKey => _sectionBarKey;

  late GlobalKey _doneButtonKey;
  GlobalKey get doneButtonKey => _doneButtonKey;

  void onInit(BuildContext context) {
    _appPreferences = Provider.of<AppPreferencesRepository>(
      context,
      listen: false,
    );

    _schedulePreferencesButtonKey = GlobalKey();
    _sectionBarKey = GlobalKey();
    _doneButtonKey = GlobalKey();
  }

  Future<void> startAppTour(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    if (await tourAlreadyCompleted()) {
      return;
    } else if (!context.mounted) {
      return;
    }

    List<TargetFocus> targets = getTutorialTargets(context);

    TutorialCoachMark tutorial = TutorialCoachMark(
      targets: targets,
      colorShadow: colorScheme.onSurface,
      textSkip: "SKIP",
      textStyleSkip: TextStyle(color: colorScheme.surface),
      paddingFocus: 0,
      focusAnimationDuration: const Duration(milliseconds: 500),
      unFocusAnimationDuration: const Duration(milliseconds: 500),
      pulseAnimationDuration: const Duration(milliseconds: 750),
      showSkipInLastTarget: true,
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      initialFocus: 0,
      useSafeArea: true,
      onFinish: onTourComplete,
      onSkip: () {
        onTourComplete();
        return true;
      },
      onClickTargetWithTapPosition: onClickHandler,
    );

    if (!context.mounted) {
      return;
    }

    tutorial.show(context: context, rootOverlay: true);
  }

  Future<void> onClickHandler(
    TargetFocus target,
    TapDownDetails tapDownDetails,
  ) async {
    if (target.identify == schedulePreferencesButtonKey.hashCode) {
      Logger.i('key match with schedule button');

      await Future.delayed(const Duration(milliseconds: 250));
      PopupsWrapper.changeSectionPreference(
        context: schedulePreferencesButtonKey.currentContext!,
      );
    }

    if (target.identify == sectionBarKey.hashCode) {
      if (doneButtonKey.currentContext == null) {
        Logger.w('Done Button GK context is null.');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 250));
      await Scrollable.ensureVisible(
        doneButtonKey.currentContext!,
        alignment: 1,
        duration: const Duration(milliseconds: 250),
      );
    }

    return;
  }

  Future<bool> tourAlreadyCompleted() async {
    return _appPreferences.getTutorialStatus() ?? false;
  }

  List<TargetFocus> getTutorialTargets(BuildContext context) {
    List<TargetFocus> targets = [];
    final colorScheme = Theme.of(context).colorScheme;

    targets.add(
      AppTargetFocus.schedulePreferencesButton(
        colorScheme: colorScheme,
        buttonKey: schedulePreferencesButtonKey,
      ),
    );
    targets.add(
      AppTargetFocus.sectionBarButton(
        colorScheme: colorScheme,
        buttonKey: sectionBarKey,
      ),
    );
    targets.add(
      AppTargetFocus.doneButton(
        colorScheme: colorScheme,
        buttonKey: doneButtonKey,
      ),
    );
    return targets;
  }

  Future<void> onTourComplete() async {
    final res = await _appPreferences.saveTutorialStatus(true);
    if (res != true) {
      final err = {
        'origin': 'AppTourService.onTourComplete',
        'message': 'error saving to shared preferences'
      };
      return Future.error(err);
    }
    return;
  }
}
