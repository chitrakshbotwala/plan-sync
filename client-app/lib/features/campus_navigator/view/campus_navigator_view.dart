import 'package:flutter/material.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository.dart';
import 'package:plan_sync/features/campus_navigator/view/widgets/campus_location_card.dart';
import 'package:plan_sync/features/campus_navigator/view/widgets/empty_campus_widget.dart';
import 'package:plan_sync/features/campus_navigator/viewmodel/campus_navigator_view_model.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CampusNavigatorView extends StatelessWidget {
  const CampusNavigatorView({super.key});

  Future<void> _launchMaps(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      CustomSnackbar.error(
        'Navigation Launch Failed',
        'The nav link was not found.',
        context,
      );
      return;
    }
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CampusNavigatorViewModel(
        repository: ctx.read<CampusNavigatorRepository>(),
      )..load(),
      child: _CampusNavigatorBody(onLaunchMaps: _launchMaps),
    );
  }
}

class _CampusNavigatorBody extends StatelessWidget {
  final Future<void> Function(BuildContext context, String? url) onLaunchMaps;

  const _CampusNavigatorBody({required this.onLaunchMaps});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<CampusNavigatorViewModel>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 0.0,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        title: Text(
          "Campus Navigator",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (scrollInfo.metrics.pixels ==
                    scrollInfo.metrics.maxScrollExtent &&
                !viewModel.isLoading &&
                viewModel.hasMore) {
              viewModel.fetchNextPage();
            }
            return false;
          },
          child: ListView.separated(
            itemCount: 1 +
                (viewModel.items.isEmpty && !viewModel.isLoading
                    ? 1
                    : viewModel.items.length) +
                (viewModel.isLoading ? 1 : 0),
            separatorBuilder: (context, index) {
              if (index == viewModel.items.length) return const SizedBox.shrink();
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  decoration: ShapeDecoration(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: colorScheme.outline.withAlpha(128),
                        width: 1.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 8),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: TextFormField(
                    decoration: InputDecoration(
                      hintText: 'Search Campus Locations',
                      hintStyle: TextStyle(color: colorScheme.onSurface),
                      prefixIcon:
                          Icon(Icons.search, color: colorScheme.onSurface),
                      border: InputBorder.none,
                    ),
                    onChanged: viewModel.onSearchChanged,
                  ),
                );
              }

              if (viewModel.items.isEmpty && !viewModel.isLoading && index == 1) {
                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
                    const EmptyCampusWidget(),
                  ],
                );
              }

              final loadingIndex = 1 +
                  (viewModel.items.isEmpty && !viewModel.isLoading
                      ? 1
                      : viewModel.items.length);
              if (viewModel.isLoading && index == loadingIndex) {
                return const Center(child: CircularProgressIndicator());
              }

              if (index > 0 && index <= viewModel.items.length) {
                final item = viewModel.items[index - 1];
                return CampusLocationCard(
                  item: item,
                  onLaunch: () => onLaunchMaps(context, item.mapsLink),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
