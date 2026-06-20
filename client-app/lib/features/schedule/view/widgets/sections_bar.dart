import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:provider/provider.dart';

class SectionsBar extends StatefulWidget {
  const SectionsBar({super.key});

  @override
  State<SectionsBar> createState() => _SectionsBarState();
}

class _SectionsBarState extends State<SectionsBar> {
  bool _hasShownSnackbar = false;

  void _showNetworkError() {
    if (!_hasShownSnackbar) {
      _hasShownSnackbar = true;
      CustomSnackbar.error(
        'Poor Internet Connection',
        'Please restart app with a better connection',
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: colorScheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: 128,
        height: 48,
        child: DropdownButtonHideUnderline(
          child: Consumer<FilterViewModel>(
            builder: (ctx, filterController, child) {
              if (filterController.activeSemester != null &&
                  filterController.sections != null &&
                  filterController.sections!.isNotEmpty) {
                _hasShownSnackbar = false;
              }

              if (filterController.activeSemester != null &&
                  (filterController.sections == null ||
                      filterController.sections!.isEmpty)) {
                return GestureDetector(
                  onTap: _showNetworkError,
                  child: Container(
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        LoadingAnimationWidget.progressiveDots(
                          color: Colors.black,
                          size: 24,
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.surface,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return DropdownButton<String>(
                isExpanded: true,
                elevation: 0,
                enableFeedback: true,
                style: TextStyle(color: colorScheme.onSurface),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.surface,
                ),
                value: filterController.activeSection,
                dropdownColor: colorScheme.onSurface,
                disabledHint: Text(
                  'Select Semester First',
                  style: TextStyle(color: colorScheme.surface, fontSize: 16),
                ),
                hint: Text(
                  'Section',
                  style: TextStyle(color: colorScheme.surface, fontSize: 16),
                ),
                menuMaxHeight: 376,
                items: filterController.sections?.keys
                    .toList()
                    .map((e) => _buildMenuItem(
                          filterController.sections?[e] ?? e,
                          colorScheme.surface,
                        ))
                    .toList(),
                onChanged: filterController.activeSemester == null
                    ? null
                    : (String? newSelection) {
                        Logger.i('new section selected: $newSelection');
                        filterController.activeSection = newSelection;
                      },
              );
            },
          ),
        ),
      ),
    );
  }
}

DropdownMenuItem<String> _buildMenuItem(String section, Color color) {
  return DropdownMenuItem(
    value: section,
    child: Text(section, style: TextStyle(color: color)),
  );
}
