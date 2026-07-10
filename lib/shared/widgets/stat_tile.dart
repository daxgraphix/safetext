import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class StatTile extends StatelessWidget {
  final String label;
  final num value;
  final Color? valueColor;
  final String? prefix;
  final String? suffix;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.outline, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutExpo,
            builder: (context, val, child) {
              return Text(
                '${prefix ?? ''}${val.toInt()}${suffix ?? ''}',
                style: TextStyle(
                  fontFamily: 'Roboto Mono',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: valueColor ?? scheme.onSurface,
                  letterSpacing: -1.0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
