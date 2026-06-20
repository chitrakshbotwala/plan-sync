import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/util/logger.dart';
import 'package:plan_sync/util/snackbar.dart';
import 'package:provider/provider.dart';

class ElectiveYearBar extends StatefulWidget {
  const ElectiveYearBar({super.key});

  @override
  State<ElectiveYearBar> createState() => _ElectiveYearBarState();
}

class _ElectiveYearBarState extends State<ElectiveYearBar> {
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
              if (filterController.electiveYears != null &&
                  filterController.electiveYears!.isNotEmpty) {
                _hasShownSnackbar = false;
              }

              if (filterController.electiveYears == null ||
                  filterController.electiveYears!.isEmpty) {
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
                value: filterController.selectedElectiveYear,
                dropdownColor: colorScheme.onSurface,
                hint: Text(
                  'Year',
                  style: TextStyle(color: colorScheme.surface, fontSize: 16),
                ),
                menuMaxHeight: 376,
                items: filterController.electiveYears
                    ?.map((year) => _buildMenuItem(year, colorScheme.surface))
                    .toList(),
                onChanged: (String? newSelection) {
                  if (newSelection == null) return;
                  Logger.i(newSelection);
                  filterController.selectedElectiveYear = newSelection;
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

DropdownMenuItem<String> _buildMenuItem(String year, Color color) {
  return DropdownMenuItem(
    value: year,
    child: Text(year, style: TextStyle(color: color)),
  );
}
