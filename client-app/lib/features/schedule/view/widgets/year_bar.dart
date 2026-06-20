import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/util/logger.dart';
import 'package:plan_sync/util/snackbar.dart';
import 'package:provider/provider.dart';

class YearBar extends StatefulWidget {
  const YearBar({super.key});

  @override
  State<YearBar> createState() => _YearBarState();
}

class _YearBarState extends State<YearBar> {
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
              if (filterController.years != null &&
                  filterController.years!.isNotEmpty) {
                _hasShownSnackbar = false;
              }

              if (filterController.years == null ||
                  filterController.years!.isEmpty) {
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
                value: filterController.selectedYear,
                dropdownColor: colorScheme.onSurface,
                hint: Text(
                  'Year',
                  style: TextStyle(
                    color: colorScheme.surface,
                    fontSize: 16,
                  ),
                ),
                menuMaxHeight: 376,
                items: filterController.years
                    ?.map((year) => _buildMenuItem(year, colorScheme.surface))
                    .toList(),
                onChanged: (String? newSelection) {
                  if (newSelection == null) return;
                  Logger.i(newSelection);
                  filterController.selectedYear = newSelection;
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
