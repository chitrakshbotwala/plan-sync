import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_filter_bar.dart';
import 'package:plan_sync/features/attendance/view/widgets/overall_attendance_card.dart';
import 'package:plan_sync/features/attendance/view/widgets/subject_attendance_tile.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';
import 'package:provider/provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceViewModel>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            colorScheme.surfaceContainerHighest.withOpacity(0.98),
        elevation: 0.0,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        title: Text(
          'Plan Sync',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          Consumer<AttendanceViewModel>(
            builder: (context, viewModel, _) {
              final id = viewModel.registrationNumber;
              if (id == null || id.isEmpty) return const SizedBox.shrink();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID · $id',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Log out of KIIT portal',
                    onPressed: () => _logoutSap(context, viewModel),
                    icon:
                        Icon(Icons.logout_rounded, color: colorScheme.error),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AttendanceViewModel>(
        builder: (context, viewModel, _) => _contentFor(viewModel),
      ),
    );
  }

  Future<void> _logoutSap(
    BuildContext context,
    AttendanceViewModel viewModel,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHighest,
        title: Text(
          'Log out of KIIT portal?',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          'Your saved registration number and password will be removed '
          'from this device.',
          style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Log out',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await viewModel.disconnect();
    }
  }

  Widget _contentFor(AttendanceViewModel viewModel) {
    switch (viewModel.status) {
      case AttendanceStatus.needsCredentials:
        return _NeedsCredentials(viewModel: viewModel);
      case AttendanceStatus.loading:
        return _LoadingState(viewModel: viewModel);
      case AttendanceStatus.error:
        return _ErrorState(viewModel: viewModel);
      case AttendanceStatus.idle:
      case AttendanceStatus.success:
        if (viewModel.result == null) {
          return _LoadingState(viewModel: viewModel);
        }
        return _SuccessState(viewModel: viewModel);
    }
  }
}

// --- success ----------------------------------------------------------------

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = viewModel.result!;

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          AttendanceFilterBar(
            viewModel: viewModel,
            enabled: viewModel.status != AttendanceStatus.loading,
          ),
          const SizedBox(height: 16),
          OverallAttendanceCard(result: result),
          const SizedBox(height: 20),
          Text(
            'Attendance',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const _ActionsRow(),
          const SizedBox(height: 8),
          if (result.isEmpty)
            _InlineNotice(
              icon: Icons.inbox_outlined,
              text: 'No subjects found for ${result.academicYear} '
                  '· ${result.session}.',
            )
          else
            ...result.records.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SubjectAttendanceTile(record: r),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => BottomSheets.attendanceInfo(context: context),
          icon: Icon(Icons.info_outline_rounded,
              size: 18, color: colorScheme.tertiary),
          label: Text(
            'More info',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        TextButton.icon(
          onPressed: () => BottomSheets.reportError(context: context),
          icon: Icon(FontAwesomeIcons.flag,
              size: 15, color: colorScheme.error),
          label: Text(
            'Report Error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}

// --- needs credentials ------------------------------------------------------

class _NeedsCredentials extends StatelessWidget {
  const _NeedsCredentials({required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 72,
                color: colorScheme.primary.withOpacity(0.8)),
            const SizedBox(height: 20),
            Text(
              'Track your attendance',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your KIIT portal login and Plan Sync will pull your '
              'subject-wise attendance for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  BottomSheets.kiitCredentials(context: context),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect KIIT Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- loading ----------------------------------------------------------------

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.progressiveDots(
              color: colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              viewModel.currentStep ?? 'Fetching your attendance…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This can take up to a minute on the KIIT portal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _ActivityLog(logs: viewModel.logs),
          ],
        ),
      ),
    );
  }
}

// --- error ------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = viewModel.errorKind != null
        ? ScrapeException(viewModel.errorKind!, viewModel.errorMessage ?? '')
            .title
        : 'Something went wrong';

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ActivityLog(logs: viewModel.logs),
          ],
        ),
      ),
    );
  }
}

// --- shared helpers ---------------------------------------------------------

class _ActivityLog extends StatelessWidget {
  const _ActivityLog({required this.logs});
  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Activity log',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
            fontSize: 13,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: logs
                  .map((l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• $l',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.onSurfaceVariant.withOpacity(0.32)),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
