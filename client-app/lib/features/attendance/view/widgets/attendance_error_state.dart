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

  /// Set the instant the retry is tapped. The view model switches to the
  /// loading screen a frame later, and if the failure is immediate (no network
  /// at all) the tap would otherwise produce no visible change at all.
  bool _retrying = false;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      await widget.viewModel.refresh();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
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
        // The bottom nav bar floats over the body, so keep the last control
        // clear of it (same allowance as the success list).
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 120),
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
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: _FixItSteps(steps: cfg.steps, accent: accent),
            ),
            const SizedBox(height: 22),
            FadeSlideIn(
              delay: const Duration(milliseconds: 220),
              // Retry and the reporting escape hatch share a row (wrapping on
              // narrow screens) so neither ends up under the nav bar.
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.icon(
                    onPressed: _retrying ? null : _retry,
                    icon: _retrying
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_retrying ? 'Trying…' : cfg.retryLabel),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: colorScheme.onPrimary,
                      disabledBackgroundColor: accent.withValues(alpha: 0.5),
                      disabledForegroundColor:
                          colorScheme.onPrimary.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  // Reporting stays behind a disclosure and only appears once a
                  // retry has also failed — a single transient failure
                  // shouldn't turn into a support ticket.
                  if (widget.viewModel.canReportIssue)
                    _ReportDisclosure(
                      onReport: () =>
                          PopupsWrapper.reportAttendanceIssue(context: context),
                    ),
                ],
              ),
            ),
            if (widget.viewModel.consecutiveFailures > 1)
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'Failed ${widget.viewModel.consecutiveFailures} times in '
                    'a row.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                      fontSize: 12,
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
          body: 'We couldn\'t reach the internet, so the KIIT portal was never '
              'contacted.',
          retryLabel: 'Retry',
          accent: cs.error,
          extraSteps: [
            'Turn Wi-Fi or mobile data back on, or step out of aeroplane mode.',
            'On campus Wi-Fi, open any website once to clear the login page.',
          ],
        );
      case ScrapeErrorKind.timeout:
        return _ErrorConfig(
          icon: Icons.hourglass_empty_rounded,
          title: 'This took too long',
          body: 'The KIIT portal was slow to respond and we stopped waiting. '
              'This is usually temporary.',
          retryLabel: 'Try again',
          accent: cs.tertiary,
          extraSteps: [
            'Check your connection is stable — a weak signal stalls the portal.',
            'Wait a minute before retrying; the portal is slowest at peak hours.',
          ],
        );
      case ScrapeErrorKind.portalUnavailable:
        return _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          title: 'Portal is down',
          body: 'The KIIT portal isn\'t serving pages right now. This one is on '
              'their side, not yours.',
          retryLabel: 'Try again',
          accent: cs.tertiary,
          extraSteps: [
            'Open kiitportal.kiituniversity.net in a browser — if it fails '
                'there too, the portal is down for everyone.',
            'Give it a few minutes before retrying.',
          ],
        );
      case ScrapeErrorKind.navigationFailed:
        return _ErrorConfig(
          icon: Icons.explore_off_rounded,
          title: 'Couldn\'t open attendance',
          body: 'We signed in, but the attendance page never finished loading.',
          retryLabel: 'Try again',
          accent: cs.primary,
          extraSteps: [
            'Retry once — the portal often serves the page on a second attempt.',
            'Check the portal isn\'t asking you to change your password.',
          ],
        );
      case ScrapeErrorKind.rendererCrashed:
        return _ErrorConfig(
          icon: Icons.memory_rounded,
          title: 'In-app browser crashed',
          body: 'The browser we use to read the portal ran out of memory.',
          retryLabel: 'Try again',
          accent: cs.error,
          extraSteps: [
            'Close a few background apps to free up memory, then retry.',
          ],
        );
      case ScrapeErrorKind.noData:
        return _ErrorConfig(
          icon: Icons.event_busy_rounded,
          title: 'No attendance found',
          body: 'There\'s nothing recorded for the selected term.',
          retryLabel: 'Try again',
          accent: cs.primary,
          extraSteps: [
            'Check the year and session below — Autumn and Spring are stored '
                'separately.',
            'Early in a semester the portal may not publish attendance yet.',
          ],
        );
      case ScrapeErrorKind.invalidCredentials:
      case ScrapeErrorKind.unknown:
        return _ErrorConfig(
          icon: Icons.error_outline_rounded,
          title: 'Something went wrong',
          body: widget.viewModel.errorMessage ??
              'We hit an unexpected snag fetching your attendance.',
          retryLabel: 'Try again',
          accent: cs.error,
          extraSteps: [
            'Retry once — most of these clear on a second attempt.',
            'Check your connection, then retry.',
          ],
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
    this.extraSteps = const [],
  });
  final IconData icon;
  final String title;
  final String body;
  final String retryLabel;
  final Color accent;

  /// Failure-specific things to try, shown above the retry button.
  final List<String> extraSteps;

  /// Every failure ends with the same last resort: the headless browser and the
  /// portal session live for as long as the app does, so a restart clears state
  /// no retry can.
  List<String> get steps => [
        ...extraSteps,
        'Still stuck? Close Plan Sync completely and open it again.',
      ];
}

/// The "try this" checklist on the failure screen. Staggered in so it reads as
/// guidance rather than more error text.
class _FixItSteps extends StatelessWidget {
  const _FixItSteps({required this.steps, required this.accent});
  final List<String> steps;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 200 + i * 70),
              offsetY: 8,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: i == steps.length - 1 ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Keeps "Report issue" two taps away: the user first has to say the retries
/// didn't help, which is also the point where a report is actually useful.
class _ReportDisclosure extends StatefulWidget {
  const _ReportDisclosure({required this.onReport});
  final VoidCallback onReport;

  @override
  State<_ReportDisclosure> createState() => _ReportDisclosureState();
}

class _ReportDisclosureState extends State<_ReportDisclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.5);

    // Sits inline next to the retry button, so it swaps in place rather than
    // growing a block below (which is how it ended up under the nav bar).
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.centerLeft,
      child: _open
          ? TextButton.icon(
              onPressed: widget.onReport,
              icon: const Icon(Icons.mail_outline_rounded, size: 17),
              label: const Text('Report issue', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            )
          : TextButton(
              onPressed: () => setState(() => _open = true),
              style: TextButton.styleFrom(
                foregroundColor: muted,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Tried everything?',
                style: TextStyle(fontSize: 12),
              ),
            ),
    );
  }
}
