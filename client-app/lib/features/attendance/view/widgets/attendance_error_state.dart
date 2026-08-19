import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/animations/fade_slide_in.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';

/// Full-screen failure view. Instead of one flat "something failed" line it
/// gives each failure kind a tailored icon, headline and explanation, an
/// obvious retry, and a kind-specific secondary action — all animated in.
class AttendanceErrorState extends StatefulWidget {
  const AttendanceErrorState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  State<AttendanceErrorState> createState() => _AttendanceErrorStateState();
}

class _AttendanceErrorStateState extends State<AttendanceErrorState>
    with SingleTickerProviderStateMixin {
  // A single settling pop on the icon badge. Deliberately one-shot: a looping
  // pulse would nag the user and would never let the frame settle.
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kind = widget.viewModel.errorKind ?? ScrapeErrorKind.unknown;
    final cfg = _configFor(kind, colorScheme);
    final accent = cfg.accent;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeSlideIn(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.78, end: 1.0).animate(
                  CurvedAnimation(parent: _pop, curve: Curves.elasticOut),
                ),
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                  ),
                  child: Icon(cfg.icon, size: 52, color: accent),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(
                cfg.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Text(
                cfg.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 26),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              child: FilledButton.icon(
                onPressed: widget.viewModel.refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(cfg.retryLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            // "No attendance found" is usually the wrong year/session, not a
            // real failure — let the user re-pick the period without logging
            // out and back in.
            if (kind == ScrapeErrorKind.noData)
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: widget.viewModel.chooseAnotherPeriod,
                    icon: const Icon(Icons.event_repeat_outlined),
                    label: const Text('Change year & session'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: TextButton.icon(
                onPressed: () =>
                    PopupsWrapper.reportAttendanceIssue(context: context),
                icon: const Icon(Icons.mail_outline_rounded, size: 18),
                label: const Text('Report issue'),
                style: TextButton.styleFrom(
                  foregroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ErrorConfig _configFor(ScrapeErrorKind kind, ColorScheme cs) {
    switch (kind) {
      case ScrapeErrorKind.networkUnavailable:
        return _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          title: 'You\'re offline',
          body: 'We couldn\'t reach the internet. Reconnect to Wi-Fi or '
              'mobile data, then try again.',
          retryLabel: 'Retry',
          accent: cs.error,
        );
      case ScrapeErrorKind.timeout:
        return _ErrorConfig(
          icon: Icons.hourglass_empty_rounded,
          title: 'This took too long',
          body: 'The KIIT portal was slow to respond. It\'s usually a blip — '
              'give it another go.',
          retryLabel: 'Try again',
          accent: cs.tertiary,
        );
      case ScrapeErrorKind.portalUnavailable:
        return _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          title: 'Portal is down',
          body: 'The KIIT portal isn\'t responding right now. This is on their '
              'side — please try again in a little while.',
          retryLabel: 'Try again',
          accent: cs.tertiary,
        );
      case ScrapeErrorKind.navigationFailed:
        return _ErrorConfig(
          icon: Icons.explore_off_rounded,
          title: 'Couldn\'t open attendance',
          body: 'We signed in but couldn\'t reach the attendance page. A retry '
              'usually sorts it out.',
          retryLabel: 'Try again',
          accent: cs.primary,
        );
      case ScrapeErrorKind.rendererCrashed:
        return _ErrorConfig(
          icon: Icons.memory_rounded,
          title: 'In-app browser crashed',
          body: 'The in-app browser ran out of memory. Close a few background '
              'apps and try again.',
          retryLabel: 'Try again',
          accent: cs.error,
        );
      case ScrapeErrorKind.noData:
        return _ErrorConfig(
          icon: Icons.event_busy_rounded,
          title: 'No attendance found',
          body: 'There\'s nothing recorded for the selected term. You may have '
              'picked the wrong year or session.',
          retryLabel: 'Try again',
          accent: cs.primary,
        );
      case ScrapeErrorKind.invalidCredentials:
      case ScrapeErrorKind.unknown:
        return _ErrorConfig(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          body: widget.viewModel.errorMessage ??
              'We hit an unexpected snag fetching your attendance. Please try '
                  'again.',
          retryLabel: 'Try again',
          accent: cs.error,
        );
    }
  }
}

class _ErrorConfig {
  const _ErrorConfig({
    required this.icon,
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final String body;
  final String retryLabel;
  final Color accent;
}
