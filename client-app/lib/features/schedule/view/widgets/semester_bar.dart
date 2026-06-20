import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:provider/provider.dart';

class SemesterBar extends StatefulWidget {
  const SemesterBar({super.key});

  @override
  State<SemesterBar> createState() => _SemesterBarState();
}

class _SemesterBarState extends State<SemesterBar> {
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
              if (filterController.selectedYear != null &&
                  filterController.semesters != null &&
                  filterController.semesters!.isNotEmpty) {
                _hasShownSnackbar = false;
              }

              if (filterController.selectedYear != null &&
                  (filterController.semesters == null ||
                      filterController.semesters!.isEmpty)) {
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
                value: filterController.activeSemester,
                dropdownColor: colorScheme.onSurface,
                menuMaxHeight: 256,
                disabledHint: Text(
                  'Select Year First',
                  style: TextStyle(color: colorScheme.surface, fontSize: 16),
                ),
                hint: filterController.semesters == null
                    ? LoadingAnimationWidget.progressiveDots(
                        color: colorScheme.onPrimary, size: 18)
                    : Text(
                        'Semester',
                        style: TextStyle(
                            color: colorScheme.surface, fontSize: 16),
                      ),
                items: filterController.semesters
                    ?.map((e) => _buildMenuItem(e, colorScheme.surface))
                    .toList(),
                onChanged: (String? newSelection) {
                  Logger.i('new semester: $newSelection');
                  filterController.activeSemester = newSelection;
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

DropdownMenuItem<String> _buildMenuItem(String semester, Color color) {
  return DropdownMenuItem(
    value: semester,
    child: Text(semester, style: TextStyle(color: color)),
  );
}
