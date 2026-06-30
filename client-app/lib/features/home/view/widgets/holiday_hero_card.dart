import 'package:flutter/material.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/view/widgets/holiday_card.dart';

/// Hero card shown at the top of the "Today" tab when the viewed day falls
/// within a holiday. Styled to match [TodayHeroCard] but with a holiday accent.
class HolidayHeroCard extends StatelessWidget {
  const HolidayHeroCard({super.key, required this.holiday});

  final Holiday holiday;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = colorScheme.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HOLIDAY',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  holiday.durationDays == 1
                      ? '1 day'
                      : '${holiday.durationDays} days',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            holiday.name.isEmpty ? 'Holiday' : holiday.name,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                HolidayDateFormat.range(holiday),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
