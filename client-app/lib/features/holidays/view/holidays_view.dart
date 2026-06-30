import 'package:flutter/material.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/view/widgets/holiday_card.dart';
import 'package:plan_sync/features/holidays/viewmodel/holidays_view_model.dart';
import 'package:provider/provider.dart';

class HolidaysView extends StatelessWidget {
  const HolidaysView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<HolidaysViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurface,
        elevation: 0.0,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        title: Text(
          "Holidays",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: _HolidaysBody(viewModel: viewModel),
    );
  }
}

class _HolidaysBody extends StatelessWidget {
  const _HolidaysBody({required this.viewModel});

  final HolidaysViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading && !viewModel.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null && !viewModel.hasData) {
      return _HolidaysMessage(
        icon: Icons.cloud_off_rounded,
        message: viewModel.errorMessage!,
        onRetry: viewModel.retry,
      );
    }

    if (viewModel.year == null) {
      return const _HolidaysMessage(
        icon: Icons.event_busy_rounded,
        message:
            'Pick your academic year in schedule preferences to see holidays.',
      );
    }

    if (viewModel.notPublished) {
      return _HolidaysMessage(
        icon: Icons.event_note_rounded,
        message: 'The holiday list for ${viewModel.year} '
            "hasn't been published yet.",
        onRetry: viewModel.retry,
      );
    }

    if (!viewModel.hasData) {
      return _HolidaysMessage(
        icon: Icons.beach_access_rounded,
        message: 'No holidays found for ${viewModel.year}.',
        onRetry: viewModel.retry,
      );
    }

    return _HolidaysList(viewModel: viewModel);
  }
}

/// Renders the full academic year eagerly (a year of holidays is small) and,
/// on first paint, scrolls to the first ongoing/upcoming holiday so the user
/// lands on what's relevant. Past holidays remain above, dimmed — scroll up.
class _HolidaysList extends StatefulWidget {
  const _HolidaysList({required this.viewModel});

  final HolidaysViewModel viewModel;

  @override
  State<_HolidaysList> createState() => _HolidaysListState();
}

class _HolidaysListState extends State<_HolidaysList> {
  final _upcomingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Scroll once, after the first frame, to the first non-past holiday.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _upcomingKey.currentContext;
      if (ctx == null) return; // everything is in the past → stay at top
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!ctx.mounted) return;
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.08,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final now = DateTime.now();
    final groups = viewModel.grouped;

    // First ongoing/upcoming holiday in chronological order; the card for it
    // gets [_upcomingKey] so we can scroll it into view.
    Holiday? firstUpcoming;
    for (final h in viewModel.holidays) {
      if (!h.isPast(now) &&
          (firstUpcoming == null ||
              h.startDate.isBefore(firstUpcoming.startDate))) {
        firstUpcoming = h;
      }
    }

    return RefreshIndicator(
      onRefresh: () async => viewModel.retry(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _YearHeader(
              year: viewModel.year!,
              count: viewModel.holidays.length,
            ),
            for (final group in groups)
              _MonthSection(
                month: group.key,
                holidays: group.value,
                now: now,
                highlightHoliday: firstUpcoming,
                highlightKey: _upcomingKey,
              ),
          ],
        ),
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  const _YearHeader({required this.year, required this.count});

  final String year;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.celebration_outlined,
              size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Academic Year $year',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            count == 1 ? '1 holiday' : '$count holidays',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSection extends StatelessWidget {
  const _MonthSection({
    required this.month,
    required this.holidays,
    required this.now,
    this.highlightHoliday,
    this.highlightKey,
  });

  final DateTime month;
  final List<Holiday> holidays;
  final DateTime now;

  /// The single holiday to tag with [highlightKey] (used for auto-scroll).
  final Holiday? highlightHoliday;
  final Key? highlightKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8, left: 2),
          child: Text(
            HolidayDateFormat.monthYear(month).toUpperCase(),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        for (final h in holidays)
          Padding(
            key: identical(h, highlightHoliday) ? highlightKey : null,
            padding: const EdgeInsets.only(bottom: 10),
            child: HolidayCard(holiday: h, now: now),
          ),
      ],
    );
  }
}

class _HolidaysMessage extends StatelessWidget {
  const _HolidaysMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
