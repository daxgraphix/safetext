import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class StepHeader extends StatelessWidget {
  final int number;
  final String title;
  final bool isDone;

  const StepHeader({
    super.key,
    required this.number,
    required this.title,
    this.isDone = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDone ? scheme.secondary : scheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: scheme.outline, width: 2.0),
          ),
          child: isDone
              ? Icon(Icons.check, size: 16, color: scheme.onSecondary)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: isDone ? scheme.secondary : scheme.onSurface,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Container(
            height: 2,
            color: isDone ? scheme.secondary.withValues(alpha: 0.3) : scheme.outline,
          ),
        ),
      ],
    );
  }
}
