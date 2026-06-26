import 'package:flutter/material.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:plan_sync/features/schedule/view/widgets/sections_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/semester_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/year_bar.dart';
import 'package:provider/provider.dart';

class SchedulePreferenceDialog extends StatelessWidget {
  const SchedulePreferenceDialog({super.key});

  void _onDone(BuildContext context) {
    final vm = Provider.of<FilterViewModel>(context, listen: false);
    vm.storePrimaryYear();
    vm.storePrimarySemester();
    vm.storePrimarySection();
    vm.storePrimaryElectiveScheme();
    CustomSnackbar.info(
      'Preferences Saved!',
      "Your timetable will be selected by default.",
      context,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final vm = Provider.of<FilterViewModel>(context, listen: false);

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PreferenceRow(
                      icon: Icons.book_rounded,
                      label: 'Program',
                      colorScheme: colorScheme,
                      trailing: Text(
                        'BTech.',
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                    ),
                    _PreferenceRow(
                      icon: Icons.book_rounded,
                      label: 'Year',
                      colorScheme: colorScheme,
                      trailing: const YearBar(),
                    ),
                    _PreferenceRow(
                      icon: Icons.book_rounded,
                      label: 'Semester',
                      colorScheme: colorScheme,
                      trailing: const SemesterBar(),
                    ),
                    _PreferenceRow(
                      key: vm.sectionBarKey,
                      icon: Icons.book_rounded,
                      label: 'Section',
                      colorScheme: colorScheme,
                      trailing: const SectionsBar(),
                    ),
                    Consumer<FilterViewModel>(
                      builder: (context, filterVm, _) {
                        if (!filterVm.hasElectivesForCurrentSchedule) {
                          return const SizedBox.shrink();
                        }
                        return Consumer<ElectivesViewModel>(
                          builder: (context, electivesVm, _) {
                            if (electivesVm.isLoading && !electivesVm.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final subjectNames = electivesVm.uniqueSubjectNames;

                            return Column(
                              children: [
                                const SizedBox(height: 8),
                                _PreferenceRow(
                                  icon: Icons.school_rounded,
                                  label: 'Elective 1',
                                  colorScheme: colorScheme,
                                  trailing: _ElectiveDropdown(
                                    subjects: subjectNames,
                                    chosen: filterVm.chosenElective1,
                                    onChanged: filterVm.setChosenElective1,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                                _PreferenceRow(
                                  icon: Icons.school_rounded,
                                  label: 'Elective 2',
                                  colorScheme: colorScheme,
                                  trailing: _ElectiveDropdown(
                                    subjects: subjectNames,
                                    chosen: filterVm.chosenElective2,
                                    onChanged: filterVm.setChosenElective2,
                                    colorScheme: colorScheme,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    key: vm.doneButtonKey,
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll(colorScheme.secondary),
                      foregroundColor:
                          WidgetStatePropertyAll(colorScheme.onSecondary),
                    ),
                    onPressed: () => _onDone(context),
                    child: Text(
                      'Done',
                      style: TextStyle(color: colorScheme.onSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _ElectiveDropdown extends StatelessWidget {
  const _ElectiveDropdown({
    required this.subjects,
    required this.chosen,
    required this.onChanged,
    required this.colorScheme,
  });

  final List<String> subjects;
  final String? chosen;
  final ValueChanged<String?> onChanged;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
          child: DropdownButton<String?>(
            isExpanded: true,
            elevation: 0,
            style: TextStyle(color: colorScheme.surface, fontSize: 13),
            icon: Icon(Icons.arrow_drop_down, color: colorScheme.surface),
            value: chosen,
            dropdownColor: colorScheme.onSurface,
            hint: Text(
              'None',
              style: TextStyle(color: colorScheme.surface, fontSize: 13),
            ),
            menuMaxHeight: 280,
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  'None',
                  style: TextStyle(color: colorScheme.surface),
                ),
              ),
              ...subjects.map(
                (s) => DropdownMenuItem<String?>(
                  value: s,
                  child: Text(
                    s,
                    style: TextStyle(color: colorScheme.surface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
